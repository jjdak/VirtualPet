# E3：意外后的主动复查

比较固定随机探索、更多随机探索、意外触发随机探查、意外触发复查旧选项。用两角色持续行为检验适应速度和试错成本；不是 LLM 或神经网络训练。只读复用 `../adaptive_agents/src/core.py`，保留 E2 源文件指纹。

| 目录 | 内容 |
| --- | --- |
| `src/` | 个人反馈检测、探查策略、世界执行/批处理、独立审计、报告与回放模板 |
| `tests/` | 机制、对照一致性、跨进程恢复、UI 逻辑检查 |
| `protocols/` | 批量运行前固定参数 |
| `results/<run>/raw/` | 全部摘要、预先指定的种子 0 完整轨迹与存档 |
| `results/<run>/review/` | 测试日志、浏览器证据、旧实验完整性核验 |

人工记录：[计划](../../docs/sim/experiments/e3/PLAN.md) / [研究与定位](../../docs/sim/experiments/e3/RESEARCH.md) / [进展结果](../../docs/sim/experiments/e3/PROGRESS.md)。

## 查看

直接打开 `results/e3-v1/replay.html`。或从仓库根目录运行：

```bash
python3.11 -m http.server 4189 --bind 127.0.0.1 --directory experiments/reinspection_agents/results
```

打开 `http://127.0.0.1:4189/e3-v1/replay.html`。页面并排回放种子 0 的同回合；真实平均统计来自 100 种子。播放是保存的轨迹，不是页面内实时重跑。

## 重现

从仓库根目录执行。结果目录必须不存在，禁止覆盖旧证据。

```bash
python3.11 -m unittest discover -s experiments/reinspection_agents/tests -v
python3.11 experiments/reinspection_agents/src/run.py --output experiments/reinspection_agents/results/new-run
python3.11 experiments/reinspection_agents/src/verify.py experiments/reinspection_agents/results/new-run
python3.11 experiments/reinspection_agents/src/report.py experiments/reinspection_agents/results/new-run
node experiments/reinspection_agents/tests/check_replay.cjs experiments/reinspection_agents/results/new-run/replay.html
```

实验仅用 Python 标准库；Node 只测页面逻辑，不是运行依赖。原始结果含真实执行 UTC 时间、协议与源码指纹，日期字段为用户时区日期。禁止以网页逻辑替身测试代替浏览器视觉检查。

## 边界

120 回合是截断，恢复到连续 5 次选择最优项是人为评价标准。触发规则、分享规则、地图与动作由程序规定；角色不自主发明复查机制。噪声世界的评价使用环境期望值，这些值只给报告、不传入角色。来源信任不是判断欺骗意图。没有 PettingZoo/Harbor/Deep Agents 兼容性声明或第三方依赖。
