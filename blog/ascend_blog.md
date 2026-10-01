# 零 CUDA 依赖：G0.5 VLA 模型在昇腾 910B4 上的 LIBERO 全量仿真复现

> 本文记录将 Galaxea G0.5 视觉-语言-动作（VLA）模型的 LIBERO 仿真评测完整迁移到 Ascend 910B4 的过程：不安装任何 CUDA 原生扩展，按官方全量协议（4 suite × 10 task × 50 trials = 2000 episodes）完成闭环验证，总成功率 1977/2000（98.85%）。全部改动收敛为 12 文件补丁，已开源：https://github.com/muluzhe/galaxea-g05-libero-npu-repro

## 一、背景与目标

G0.5 是 OpenGalaxea 发布的自回归 VLA 模型（Qwen3.5-2B 主干 + ActionCodec 20 维动作空间 + 10 步 action chunk），官方 LIBERO 评测栈以 CUDA 12.8 为前提，依赖 flash-attn-4、flash-linear-attention 等 CUDA 原生扩展，官方技术报告成绩 98.9%。

本工作的目标有三点：其一，让 G0.5 推理服务在昇腾 NPU 上原样跑通；其二，按官方全量协议完成四套件闭环验证，与官方成绩做精度对照；其三，把迁移改动收敛成可复现的最小补丁，而不是散落的现场修改。

## 二、软硬件环境

| 项 | 配置 |
|---|---|
| NPU | Ascend 910B4（单卡推理） |
| CANN | 8.5.2 |
| PyTorch | 2.7.1（CPU 版）+ torch-npu 2.7.1.post2 |
| Python / transformers | 3.10.20 / 4.57.1（官方锁定版本） |
| CUDA 原生扩展 | **全部未安装**（flash-attn-4、flash-linear-attention、causal-conv1d、liger-kernel） |
| 仿真渲染 | LIBERO + robosuite 1.4.0 + MuJoCo 3.3.2，OSMesa 软件渲染（256×256 双相机） |
| checkpoint | 官方 `g05-libero` bundle（11.4GB model.pt + action_tokenizer.pt + Qwen3.5 processor） |

## 三、迁移挑战与解决方案

### 3.1 昇腾 ACL 算子的张量维度上限

**问题**：首条推理请求即报 `AclNN_Parameter_Error(EZ1001): The self tensor cannot be larger than 8 dimensions.`。定位到 G0.5 视觉塔的图像 patch 化：官方实现将观测张量 reshape 为 9 维 `[K, t, C, gh2, m, p, gw2, m, p]` 后 `permute(0,3,6,4,7,2,1,5,8)` 再压平，昇腾 ACL 算子最多支持 8 维张量，直接越界。

**解决**：将 9 维变换分解为每步不超过 8 维的等价链。这里有一个容易踩的坑：原实现的 reshape 隐含 `(C,t) → (t,C)` 的行主序重切（通道与时间维错位），这是模型训练时的真实数据流，迁移时必须逐位复现而不是"顺手修正"。新链以显式的 `reshape(K, C*t, H, W) → reshape(K, t, C, H, W)` 复现该语义，再做分步空间重排。

**验证**：随机张量下与原 9 维实现逐位对比，K=2/56×56 与 K=4/224×224 两组尺寸均为 bitwise equal（max abs diff = 0.0）。

### 3.2 CUDA 原生扩展的回退矩阵

逐项分析推理链路上的 CUDA 依赖后，全部可以走官方代码自带的回退实现，无需自写算子：

| CUDA 依赖 | 用途 | NPU 回退 | 回退来源 |
|---|---|---|---|
| flash-attn-4 | ViT / 主干注意力 | `F.scaled_dot_product_attention`（逐 cu_seqlens 分块） | 官方 vision.py 内置 |
| flash-linear-attention | Gated DeltaNet 线性注意力（18/24 层） | 纯 PyTorch chunk / recurrent 实现 | 官方 gated_deltanet.py 内置，配置 `linear_attn_backend: torch` |
| causal-conv1d | GDN 的 conv1d 核 | `F.silu(conv1d(...))` | 官方内置 |
| liger-kernel | 融合线性交叉熵 | 不需要（仅训练路径） | — |

ActionCodec 动作头在 fp32 下天然走 SDPA；RVQ 为纯 PyTorch 自研实现，无 CUDA 依赖。

### 3.3 autocast 与设备感知

官方 `inferencer.py` 中 `torch.autocast("cuda", dtype=torch.bfloat16)` 对 NPU 张量是**静默 no-op**——不报错，但 autocast 完全不生效，这种"沉默失败"比报错更危险。修复为按 `self.device` 的类型选择 autocast 设备，并新增 `--no-bf16` 开关显式进入 fp32 验证模式。本次全量验证即以 fp32 运行，规避混合精度在跨硬件迁移初期的数值不确定性。

### 3.4 工程细节

hydra 配置内 `checkpoints/...` 相对路径按 cwd 解析，编排器必须以官方仓库为工作目录；gated 权重经 HF 镜像下载后按官方 README 组装 sidecar 软链；无 GPU 环境的仿真渲染用 OSMesa（swrast）替代 EGL。

## 四、验证协议与精度结果

协议：seed 42、horizon 220/280/300/520（官方 evaluator 硬编码）、action chunk = 10、10 并行仿真环境、每 episode 强制留存视频。

| Suite | 成功数 | 成功率 |
|---|---|---|
| libero_spatial | 496/500 | 99.2% |
| libero_object | 500/500 | 100.0% |
| libero_goal | 490/500 | 98.0% |
| libero_10 | 491/500 | 98.2% |
| **总计** | **1977/2000** | **98.85%** |

三方对照（同一 `g05-libero` checkpoint）：

| | 昇腾 910B4（本工作） | 官方技术报告 | RTX 4090 复现 |
|---|---|---|---|
| 成功率 | 98.85% | 98.9% | 100.0% |
| 样本量 | 2000（50-trials 全量） | 官方口径 | 400（10-trials 缩减） |
| 精度 / 后端 | fp32 / SDPA+纯PyTorch | bf16 / FA4+FLA | bf16 / FA4+FLA |

NPU 结果与官方 98.9% 处于同一水平；RTX 4090 的 100% 来自更小的 10-trials 样本，两组协议不同，不构成等价比较。

## 五、推理性能分析

**NPU 实测**（全量运行期间 3633 个推理批的统计）：批大小中位数 10，动作头（fm_action）单批耗时中位 **927ms**（820–1136ms），整批前向（含 VLM prefill + 自回归动作生成）中位 **1558ms**，折合约 **156ms/样本**。四套件全量 wall time 约 11.7 小时（含 OSMesa CPU 渲染与仿真步进，渲染同样是瓶颈之一）。

**参考对照**：同作者在 RTX 4090（bf16 + flash-attn-4 + FLA）上的复现记录为 batch=8 时 prefill ≈ 89ms、动作生成 ≈ 390ms，合计约 480ms/批、60ms/样本。

**差距归因**：单样本耗时约 2.6 倍差距，主要来自三个可解释的因素——fp32 相对 bf16 的计算与带宽开销；Gated DeltaNet 从 Triton kernel 回退到纯 PyTorch chunk 实现（含 Python 层循环）；SDPA 相对 FA4 的注意力差距。这些是迁移初期的保守选择，而非昇腾平台的能力上限。

**优化方向**：切换 bf16 autocast（补丁已支持，去掉 `--no-bf16` 即可，预计收益显著）；将 flash-linear-attention 的 chunk kernel 移植到 torch-npu；利用 CANN 图模式与算子融合减少 Python 调度开销；渲染侧从 OSMesa 迁移到硬件/加速方案。这些留作后续工作。

## 六、复现步骤

```bash
# 环境：Ascend 910B4 + CANN 8.5.2 + torch 2.7.1 + torch-npu（不装 CUDA 扩展）
git clone https://github.com/OpenGalaxea/GalaxeaVLA && cd GalaxeaVLA
git checkout 89f2322
git apply /path/to/g05_npu.patch        # 12 文件补丁

# 权重：HF 同意条款后下载 g05-libero bundle，软链为 checkpoints/
ln -s /path/to/g05_libero_ckpt checkpoints

bash scripts/run_g05_full_libero.sh     # server 全程复用 + 四套件串行
```

证据链：9 段代表性 rollout 视频（含 1 段失败案例）随仓库 `videos/` 分发，与图文截帧一一对应；2000 段全量视频逐段首帧实解码核验 2000/2000、多帧抽检 12/12，文件名 success/failure 标记与结果 JSON 逐套件核对一致。

## 七、开源与致谢

补丁、编排脚本、协议规范、结果与视频样例均已开源：**https://github.com/muluzhe/galaxea-g05-libero-npu-repro**（母项目多模型迁移框架见 [libero-npu-migration](https://github.com/muluzhe/libero-npu-migration)）。本工作同时作为星海图 G05「开源共创」挑战的参赛作品提交。感谢 OpenGalaxea 开源的模型与评测代码，以及昇腾社区提供的硬件环境。
