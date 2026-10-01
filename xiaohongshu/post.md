# 小红书发布文案

**配图顺序**（见 images/）：
1. `01_cover.png` 封面
2. `02_compare.png` 三方对比
3. `03_rollouts.png` 实测画面
4. `04_migration.png` 迁移三关
5. `05_evidence.png` 终端证据
6. `06_links.png` 仓库链接（尾图引流）

---

**标题**（19 字）：G0.5 昇腾NPU复现：98.85%

**正文**：

星海图 G05「开源共创」挑战作品：G0.5 LIBERO 评测的昇腾 NPU 全量复现。

官方栈依赖 CUDA 12.8 与 flash-attn-4 / flash-linear-attention。本工作将评测链路迁移至 Ascend 910B4（CANN 8.5.2/torch-npu），零 CUDA 原生扩展，按官方全量协议执行。

协议：4 suite × 10 task × 50 trials = 2000 episodes；horizon 220/280/300/520；chunk = 10；seed 42；fp32；逐 episode 留存视频。

NPU 结果（fp32，SDPA + 纯 PyTorch 回退）：
· spatial 496/500（99.2%）· object 500/500（100.0%）
· goal 490/500（98.0%）· libero_10 491/500（98.2%）
· 总计 1977/2000 = 98.85%

对照：官方技术报告 98.9%（CUDA/bf16）；同作者 RTX 4090 复现 100.0%（400/400，10-trials 缩减协议，非等价比较）。

迁移要点：
1. 昇腾 ACL 算子张量上限 8 维，官方视觉 patch 化为 9 维 reshape+permute，触发 EZ1001；重写为等价 ≤8 维链，随机张量逐位比对一致。
2. 注意力后端回退：flash-attn → SDPA；Gated DeltaNet → 官方纯 PyTorch 实现；liger-kernel 仅训练路径。
3. autocast 设备感知 + fp32 验证模式（--no-bf16）。

全部改动收敛为 12 文件补丁（基线 commit 89f2322，git apply 可复现）：
github.com/muluzhe/galaxea-g05-libero-npu-repro

证据链：9 段代表性视频（含 1 段失败案例）随仓库分发；2000 段全量视频首帧实解码 2000/2000，多帧抽检 12/12；success/failure 标记与结果 JSON 逐套件核对一致。

#G05 #星海图 #具身智能 #昇腾 #国产算力 #NPU #开源 #机器人 #VLA #技术分享
