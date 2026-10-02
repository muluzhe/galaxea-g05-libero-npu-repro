# 真实终端运行证据

本目录中的 PNG 均由验证服务器终端实际运行命令后手动截取，不是生成式信息卡。截图已避免本地绝对路径、个人信息、访问令牌、PID、端口和动态客户端地址。

| 文件 | 内容 |
|---|---|
| `01_real_result_terminal.png` | 由公开 `results/summary.json` 读取的四套件逐项统计与总结果 |
| `02_real_npu_log_start.png` | 真实 server 启动记录：模型加载到 `npu:0`、fp32、chunk(10)、纯 PyTorch/SDPA 回退 |
| `02_real_npu_log_finished.png` | 真实四套件 client 运行完成记录与结果保存信息 |
| `03_real_config_terminal.png` | 真实复现配置：硬件、精度、seed、trials、horizon、action chunk、视频证据范围 |

原始完整日志包含运行服务器路径、进程信息、端口和动态地址，不直接公开；完整原始 JSON、日志和 2000 段视频留档于验证服务器。公开仓库同时提供脱敏日志、结果汇总和 9 段代表性 rollout 视频。
