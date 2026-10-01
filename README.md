# Galaxea G0.5 LIBERO 全量复现 · 昇腾 NPU 版

星海图 G05「开源共创」挑战作品。在**华为昇腾 Ascend 910B4 NPU**（无 GPU、无 CUDA）上完成 G0.5 官方 LIBERO 仿真评测的**全量协议**验证：4 suite × 10 task × **50 trials** = **2000 episodes**，总成功率 **1977/2000 = 98.85%**。

- 官方仓库：https://github.com/OpenGalaxea/GalaxeaVLA（基线 commit `89f2322`）
- 技术报告：https://opengalaxea.github.io/G05/（官方 LIBERO 平均 98.9%）
- 模型权重：https://huggingface.co/OpenGalaxea/G05（gated，`g05-libero` checkpoint）
- GPU 对照（同作者 RTX 4090 版）：https://github.com/muluzhe/galaxea-g05-libero-repro
- 母项目（多模型 NPU 迁移框架）：https://github.com/muluzhe/libero-npu-migration

## 结果

| Suite | Success | Rate |
|---|---|---|
| libero_spatial | 496/500 | 99.2% |
| libero_object | 500/500 | 100.0% |
| libero_goal | 490/500 | 98.0% |
| libero_10 | 491/500 | 98.2% |
| **OVERALL** | **1977/2000** | **98.85%** |

逐 task 统计见 [`results/summary.json`](results/summary.json)。协议：seed 42、horizon 220/280/300/520（官方硬编码）、`action_steps=10`、10 并行环境、fp32、每 trial 强制保存视频。

## 三方对比（同一 `g05-libero` checkpoint）

| | 本作品（昇腾 910B4） | 官方技术报告 | RTX 4090 复现（同作者） |
|---|---|---|---|
| 成功率 | **98.85%**（1977/2000） | 98.9% | 100.0%（400/400） |
| 协议 | 50 trials/task（官方全量，2000 ep） | 官方口径 | 10 trials/task（缩减，400 ep） |
| 精度 | fp32 | bf16 | bf16 |
| 注意力后端 | SDPA + 纯 PyTorch 回退 | flash-attn-4 + FLA | flash-attn-4 + FLA |
| CUDA 依赖 | **无** | CUDA 12.8 全家桶 | CUDA 12.8 全家桶 |

三方数字接近；NPU 版样本量最大（2000 ep），且在拆除全部 CUDA 原生扩展后仍达到该水平。RTX 4090 的 100% 来自更小的 10-trials 样本，两组协议不同，不构成严格等价比较——这也是我们补跑 50-trials 全量的原因。

## NPU 迁移三道关

1. **昇腾算子 8 维上限**：视觉 patch 化的 9 维 reshape+permute 触发 `AclNN_Parameter_Error(EZ1001)`；分解为等价 ≤8 维链，随机张量逐位比对 **bitwise equal**（保留原实现的通道/时间重切语义）。
2. **CUDA 原生扩展全回退**：flash-attn-4 → SDPA、flash-linear-attention → 官方自带纯 PyTorch 回退（`linear_attn_backend: torch`）、liger-kernel 仅训练路径不需要；`autocast("cuda")` 改为按设备感知。
3. **fp32 验证模式**：`--no-bf16` 规避混合精度风险，冒烟 5/5 通过后直接上全量。

全部改动收敛为 **12 个文件的补丁**：[`models/g05/g05_npu.patch`](models/g05/g05_npu.patch)。

## 复现步骤

```bash
# 0) 环境：Ascend 910B4 + CANN 8.5.2 + torch 2.7.1 + torch-npu 2.7.1.post2
#    conda env：Python 3.10、transformers 4.57.1；不安装任何 CUDA 原生扩展
git clone https://github.com/OpenGalaxea/GalaxeaVLA && cd GalaxeaVLA
git checkout 89f2322
git apply /path/to/g05_npu.patch

# 1) 权重（gated：需在 HuggingFace 同意条款；国内可走 hf-mirror）
#    g05-libero bundle：model.pt + action_tokenizer.pt + dataset_stats.json
#    + .hydra/config.yaml + qwen3_5_2b_base_processor（软链为 hf_processor/）
ln -s /path/to/g05_libero_ckpt checkpoints

# 2) 一键四套件全量（server 全程复用 + 四 suite 串行）
bash scripts/run_g05_full_libero.sh
```

统一评测参数见 [`scripts/eval_defaults.sh`](scripts/eval_defaults.sh)（seed 42、50 trials/task、官方 horizon、强制视频）；完整协议规范见 [`docs/EVAL_PROTOCOL.md`](docs/EVAL_PROTOCOL.md)。

## 视频证据

2000 段 rollout 视频全部在本机留档（体积与许可约束不入库）：每段经 ffmpeg 实际解码首帧核验（2000/2000 通过），每套件抽首/中/尾三段多帧解码（12/12 通过），文件名 success/failure 标记与结果 JSON 逐套件核对一致。截帧样例见 [`xiaohongshu/images/`](xiaohongshu/images/)。

## 仓库结构

```text
├── models/g05/g05_npu.patch        # 12 文件 NPU 补丁（基线 89f2322）
├── scripts/run_g05_full_libero.sh  # 四套件全量编排器
├── scripts/eval_defaults.sh        # 统一评测默认参数
├── docs/EVAL_PROTOCOL.md           # 评测协议规范
├── docs/G05_TRACKING.md            # 迁移过程全记录
├── results/summary.json            # 逐 task 结构化结果
└── xiaohongshu/                    # 作品发布图文
```

## License

遵循 G0.5 Community License（非商业研究用途）。本仓库仅包含补丁、脚本与结果，不重分发模型权重。
