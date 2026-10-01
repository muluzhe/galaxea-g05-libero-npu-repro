# g05_npu.patch 说明

对官方 GalaxeaVLA 仓库（基线 commit `89f2322`）的 12 文件 NPU 补丁，使 G0.5 推理服务在昇腾 NPU 上运行。

| 官方仓库位置 | 修改 | 原因 |
|---|---|---|
| `src/g05/models/g05/g05_model_qwen35.py` | 9 维图像 patch 变换分解为最多 8 维的等价操作；与原输出逐位比对通过 | 昇腾 ACL 算子最多支持 8 维张量（EZ1001） |
| `src/g05/models/g05/inferencer.py` | 按设备选择 autocast，支持关闭 bf16 | `autocast("cuda")` 对 NPU 张量静默失效 |
| `configs/model/g05.yaml` | 线性注意力后端设为 `torch` | 使用官方纯 PyTorch 回退，替代 flash-linear-attention |
| `gated_deltanet.py`、`checkpoint_utils.py` 等 | autocast 与缓存操作的设备选择修正 | 消除 CUDA 硬编码 |
| `scripts/serve_policy_batched.py` | 支持 `--device npu:0` 与 `--no-bf16` | NPU fp32 验证入口 |

应用方式（干净的官方工作区）：

```bash
git checkout 89f2322
git apply --check models/g05/g05_npu.patch
git apply models/g05/g05_npu.patch
```

CUDA 依赖回退均为官方代码自带实现：ViT 注意力 → SDPA；Gated DeltaNet → 纯 PyTorch chunk/recurrent；ActionCodec fp32 → SDPA。补丁不含权重、令牌或任何绝对路径。
