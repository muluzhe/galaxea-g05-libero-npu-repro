# 运行证据

本目录保存适合公开分发的脱敏日志摘录。

- `server_npu_sanitized.log`：G0.5 server 在 Ascend 910B4 上加载并完成批量推理的日志证据。
- 原始 server/client 日志不直接上传，因为其中包含本地路径、进程信息、端口和运行时地址。
- 逐任务统计见 [`../results/summary.json`](../results/summary.json)。
- 代表性真实 rollout 视频见 [`../videos/`](../videos/)。

脱敏日志用于证明运行链路和结果范围，不能替代完整原始日志。完整原始日志保留在验证服务器中。
