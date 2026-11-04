# E6：保留未解决的异常

[固定计划](../../docs/sim/experiments/e6/PLAN.md) · [进展与结果](../../docs/sim/experiments/e6/PROGRESS.md)。从 E1–E5 [冻结归档](https://github.com/jjdak/VirtualPet/tree/agent-lab-e1-e5-2026-11-02)另开实验，不改旧数据。

| 目录 | 内容 |
| --- | --- |
| `src/` | 有限待核查事项、批处理、独立生命周期审计、统计/回放 |
| `tests/` | 门槛/预算/冷却/到期/解决/恢复/历史一致性及页面逻辑 |
| `protocols/` | 固定策略、38 情景和种子 |
| `results/<run>/raw/` | 全量摘要及预定 16 段完整轨迹/存档 |
| `results/<run>/review/` | 测试、浏览器、旧文件完整性、交付指纹 |

## 查看与复现

直接打开 `results/e6-v1/replay.html`，或从仓库根目录运行：

```bash
python3.11 -m http.server 4192 --bind 127.0.0.1 --directory experiments/unresolved_agents/results
```

访问 `http://127.0.0.1:4192/e6-v1/replay.html`。这是保存轨迹的交互回放，不是实时控制模型的世界。

```bash
python3.11 -m unittest discover -s experiments/unresolved_agents/tests -v
python3.11 experiments/unresolved_agents/src/run.py --output experiments/unresolved_agents/results/new-run
python3.11 experiments/unresolved_agents/src/verify.py experiments/unresolved_agents/results/new-run
python3.11 experiments/unresolved_agents/src/report.py experiments/unresolved_agents/results/new-run
node experiments/unresolved_agents/tests/check_replay.cjs experiments/unresolved_agents/results/new-run/replay.html
```

新结果目录必须不存在。Python 标准库即可，既有 Node 只检查页面逻辑；只读导入 E2–E5 的历史原语，不安装框架或调用模型。批次记录源码/配置散列；不要修改冻结代码再宣称旧结果可复现。

## 边界

`oneshot_adaptive` 与 `persistent_adaptive` 使用相同异常信号、年龄/预算/冷却条件，仅有效期不同。`legacy_adaptive` 保留 E5 原行为，`fixed30` 保留 E5 的固定日常间隔＋原意外触发，后者不是完全无触发的定时器。

待核查事项是“亲自再采样另一个选项”，一次样本完成不等于解释了异常或保证判断正确。到期、完成、仍待处理分别计数；消息不直接完成事项，重复异常不延长有效期。四策略都是真实行动付费，没有免费全局观察。维持两角色、两食物、预定分享与寻路，没有神经训练或主动创造技能。
