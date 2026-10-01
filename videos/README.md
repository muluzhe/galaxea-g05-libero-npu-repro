# 实测视频样例

以下 9 段视频截选自本机 2000 段全量 rollout 留档，作为 NPU 闭环验证的直接证据分发。每段画面左侧为主视角相机、右侧为腕部相机（256×256×2，30fps）。其中前 4 段与 `xiaohongshu/images/03_rollouts.png` 的截帧画面一一对应。

| 文件 | Suite | 结果 | 任务 |
|---|---|---|---|
| `libero_spatial_bowl_ramekin_ep0_success.mp4` | libero_spatial | 成功 | pick up the black bowl between the plate and the ramekin and place it on the plate（task0，截帧对应） |
| `libero_spatial_bowl_table_center_ep0_success.mp4` | libero_spatial | 成功 | pick up the black bowl from table center and place it on the plate |
| `libero_object_alphabet_soup_ep0_success.mp4` | libero_object | 成功 | pick up the alphabet soup and place it in the basket（task0，截帧对应） |
| `libero_object_bbq_sauce_ep0_success.mp4` | libero_object | 成功 | pick up the bbq sauce and place it in the basket |
| `libero_goal_open_middle_drawer_ep0_success.mp4` | libero_goal | 成功 | open the middle drawer of the cabinet（task0，截帧对应） |
| `libero_goal_push_plate_stove_ep0_success.mp4` | libero_goal | 成功 | push the plate to the front of the stove |
| `libero_10_book_to_caddy_ep0_success.mp4` | libero_10 | 成功 | pick up the book and place it in the back compartment of the caddy（task0，截帧对应） |
| `libero_10_moka_pots_stove_ep0_success.mp4` | libero_10 | 成功 | put both moka pots on the stove |
| `libero_goal_open_top_drawer_bowl_ep20_failure.mp4` | libero_goal | 失败 | open the top drawer and put the bowl inside（23 次失手之一，如实收录） |

完整 2000 段视频（约 400MB）因体积留档于运行机器；文件名 success/failure 标记已与 `results/summary.json` 逐套件核对一致。
