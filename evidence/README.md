# 真实终端证据

本目录用于保存由验证服务器终端直接截取的公开证据截图。

建议保存以下文件：

1. `01_terminal_result.png`：终端执行结果汇总，展示四套件成功率和总结果
2. `02_terminal_npu_server.png`：真实 server.log 终端输出，展示 `loaded on npu:0`、fp32、batch/chunk 配置
3. `03_terminal_config.png`：真实终端输出的评测 manifest、模型配置和关键参数

截图应来自已经完成的 G0.5 Ascend 910B4 验证结果，不需要重新运行 2000 个 episode。推荐直接使用下面的复现查看命令生成输出后截图：

```bash
cd /path/to/galaxea-g05-libero-npu-repro
bash evidence/show_terminal_evidence.sh
```

命令只读取公开汇总和脱敏日志，不启动模型、不修改结果、不下载权重。

原始 server/client 日志不直接公开，因为包含本地路径、进程信息、端口和动态运行地址。完整 rollout 视频和原始运行产物仍保留在验证服务器；仓库 `videos/` 目录提供代表性视频样例。
