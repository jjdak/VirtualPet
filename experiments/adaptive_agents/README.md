# E2：连续经验与来源信任

两角色、两食物的持续在线价值更新实验。仅用 Python 标准库；不调用 LLM、不下载依赖、不修改 E1 或原庭院。角色自己的价值估计与来源可靠度会更新；策略公式、行动集合和回营分享规则由程序预设。

## 目录

| 位置 | 内容 |
| --- | --- |
| `src/` | 世界、策略、批处理、核验、报告生成及回放模板 |
| `tests/` | 机制、跨进程恢复、页面逻辑检查 |
| `protocols/` | 运行前固定的实验配置，不以结果反向调参 |
| `results/e2-v1/raw/` | 320 个 episode 摘要、16 条预定完整轨迹和结束存档 |
| `results/e2-v1/` | 实际运行协议、源码指纹、统计、核验与离线回放 |
| `results/e2-v1/review/` | 浏览器检查记录与截图 |

人工记录：[计划](../../docs/sim/experiments/e2/PLAN.md) / [进展与结果](../../docs/sim/experiments/e2/PROGRESS.md)。E1 历史入口见 [实验总索引](../README.md)。

## 查看

直接打开 `results/e2-v1/replay.html`，不需要模型或网络；也可在项目根目录运行：

```bash
python3.11 -m http.server 4188 --bind 127.0.0.1 --directory experiments/adaptive_agents/results
```

访问 `http://127.0.0.1:4188/e2-v1/replay.html`。浏览器页面是已保存轨迹的回放，不会重新训练/运行代理。回合滑块、播放、情景/策略选择均可操作；平均统计覆盖 20 种子，动画固定展示事先选定的种子 0。

## 重现

从项目根目录执行。输出路径必须是未存在的新目录，程序拒绝覆盖旧证据。配置中的 `client_date` 属于协议记录日期；实际运行 UTC 时间自动写入 manifest。

```bash
python3.11 -m unittest discover -s experiments/adaptive_agents/tests -v
python3.11 experiments/adaptive_agents/src/run.py --output experiments/adaptive_agents/results/new-run
python3.11 experiments/adaptive_agents/src/verify.py experiments/adaptive_agents/results/new-run
python3.11 experiments/adaptive_agents/src/report.py experiments/adaptive_agents/results/new-run
node experiments/adaptive_agents/tests/check_replay.cjs experiments/adaptive_agents/results/new-run/replay.html
```

Node 只用于生成页的 DOM 测试替身，不是实验运行依赖。真实浏览器播放检查另记，不能由该测试代替。

## 能力边界

- 目标选择会利用个人经验；行走由 BFS 执行器完成，没有学习运动控制。
- 收益可正可负，未实现代谢、死亡、库存或复杂生态。
- 信任是可验证消息的近期准确度；无法判断欺骗意图。信任只会因亲历验证和向先验衰减而变化。
- 角色共享策略代码但状态独立。没有独立神经网络、主角适配器或通用自我改进。
- 全量摘要可确定性重算；完整轨迹只保留协议指定的种子，避免冗余日志失控。
