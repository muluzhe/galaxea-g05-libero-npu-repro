# 小红书发布文案

**配图顺序**（见 images/）：
1. `01_cover.png` 封面
2. `02_compare.png` 三方对比
3. `03_rollouts.png` 实测画面
4. `04_migration.png` 迁移三关
5. `05_evidence.png` 终端证据
6. `06_links.png` 仓库链接（尾图引流）

---

**标题**（19 字内）：零CUDA！昇腾NPU全量复现G0.5

**正文**：

星海图G05开源共创挑战，我交作业了🎯

官方G0.5只给了CUDA版本，我把整套LIBERO仿真验证搬到了华为昇腾910B4上——没有GPU、没有CUDA，一个flash-attn都没装，跑完了官方全量协议：

📊 4大套件 × 10任务 × 50次 = 2000个episode
总成功率 98.85%（1977/2000）
官方技术报告：98.9%
我之前在RTX4090上跑的是100%（但那是10-trials缩减协议，只有400次，样本小上限高，不作数，所以这次NPU直接上满50-trials全量）

50次尝试并行跑，一个任务平均20分钟内拿下，机械臂抓碗、开抽屉、放书全流程丝滑✨

🔧 迁移拆了三道关：
① 昇腾算子最多8维张量，视觉patch化是9维的→拆成等价低维链，逐位比对bitwise equal
② CUDA原生扩展全部回退：flash-attn→SDPA，FLA→纯PyTorch（官方自带回退，不是我硬改的）
③ NPU走fp32全精度，规避bf16数值风险

改动收敛成12个文件的patch，git apply就能复现，已开源👇
github.com/muluzhe/galaxea-g05-libero-npu-repro

2000段rollout视频全部留档，每段都实解码核验过；日志、JSON、manifest齐全，欢迎来查作业👀

国产算力跑具身智能，这条链路是真的通了。

#G05 #星海图 #具身智能 #昇腾 #国产算力 #NPU #开源 #机器人 #VLA #大模型 #程序员日常 #技术分享
