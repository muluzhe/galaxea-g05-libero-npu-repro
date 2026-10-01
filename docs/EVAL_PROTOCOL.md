# G0.5 LIBERO NPU 验证流程与参数规范

本仓库的 G0.5 闭环验证遵循以下规范。默认参数定义在 [`scripts/eval_defaults.sh`](../scripts/eval_defaults.sh)（编排脚本 [`scripts/run_g05_full_libero.sh`](../scripts/run_g05_full_libero.sh) source 它）。多模型通用规范见母项目 [libero-npu-migration](https://github.com/muluzhe/libero-npu-migration)。

## 一、评测协议参数

| 参数 | 取值 | 依据 |
|---|---|---|
| 随机种子 | 42 | 固定种子，保证可复现 |
| trials/task | **50**（对照官方的默认全量） | LIBERO 官方 benchmark 每 task 50 个初始状态；缩减验证（如 10）必须在 manifest 与结果 JSON 中标注 |
| horizon 上限 | spatial 220 / object 280 / goal 300 / libero_10 520 | G0.5 官方 evaluator 固定值，**勿改** |
| 相机分辨率 | 256x256 | 官方评测默认 |
| 初始静置步 | 20 | G0.5 官方 `--num_steps_wait 20` |
| 并行环境数 | 10（资源受限可降） | 官方默认；影响吞吐不影响协议 |
| 视频输出 | **强制开启** | 视频必须来自模型实际 NPU 闭环 rollout |
| 成功判定 | LIBERO `env.check_success()` | 官方定义 |

**G0.5 固有参数**（由 checkpoint 训练分布决定，在 manifest 中记录）：动作空间为 ActionCodec 20D、action chunk 步数 10（`--action_steps 10`）、推理精度 fp32（`--no-bf16`）、server 协议 WebSocket + msgpack。

## 二、验证流程（两阶段）

### 阶段 1：冒烟（每次适配变更后必做）

1. 启动 NPU server（单卡，`ASCEND_RT_VISIBLE_DEVICES` 指定空闲卡）。
2. 单 suite（建议 libero_spatial）单 task × 1~5 trials，固定 seed。
3. 检查：闭环能跑、动作语义正确（成功率合理）、**视频生成且解码核验通过**（帧数/尺寸/非静态）。
4. 冒烟不通过不得进入全量。本项目实测：单环境 1/1、并行 5/5 全部成功后才启动全量。

### 阶段 2：全量（四 suite 串行）

1. 编排脚本 `scripts/run_g05_full_libero.sh`：server 全 suite 复用，四 suite 串行评估。
2. 参数：`eval_defaults.sh` 默认值（50 trials/task）、seed 42、强制视频。
3. G0.5 官方 evaluator 不支持断点续跑，中途失败按 suite 重跑，不得伪造数据。
4. 完成后生成 summary（四 suite 成功率 + 总平均，见 `results/summary.json`）。

## 三、目录与产物结构

```text
scripts/run_g05_full_libero.sh       # 编排器
scripts/eval_defaults.sh             # 统一默认参数
models/g05/g05_npu.patch             # NPU 补丁（见 models/g05/README.md）
results/full_libero/<YYYYmmdd_HHMMSS_PID>/
├── manifest.json          # 完整配置：模型、checkpoint、设备、精度、seed、trials、horizon、视频开关
├── server.log             # NPU 推理日志（含 torch_npu/Ascend 运行证据）
├── server.pid / server.port
└── <suite>/
    ├── client.log
    ├── <suite>_parallel_results.json  # 原始统计：per-task successes/total、success_rate
    └── videos/*.mp4          # 每 trial 一段，文件名含任务描述/episode/success 标记
```

原始运行产物（JSON/日志/视频）留档于运行机器；本仓库发布脱敏汇总 `results/summary.json`。

## 四、结果记录与对比规范

1. **NPU 原始统计**与**官方参考值**分开记录，不混写；参考值注明来源与协议。
2. 协议差异（trials 数、精度、后端替换）如实标注；不作"统计等价""逐字节一致"等未经验证的断言。
3. 视频证据：G0.5 官方 JSON 为 per-task 汇总，不逐条记录 video_path；按视频文件名与 suite 成功/失败总数交叉核验。本项目对全部 2000 段视频做首帧实解码，另抽 12 段多帧解码，不声称全片逐帧核验。
4. 适配过程与结果记录在 [`docs/G05_TRACKING.md`](G05_TRACKING.md)。
