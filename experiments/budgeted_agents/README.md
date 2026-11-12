# E4：预算内的偶尔复查与意外复查

同一预算上限下比较随机、日常、意外与混合四种策略；E3 原规则单列为非等预算参考。只读复用 `../reinspection_agents/src/core.py` 和它引用的 E2 世界/经验原语，保持旧阶段源码与结果。

| 目录 | 内容 |
| --- | --- |
| `src/` | 预算决策、场景时序、批处理、独立审计、统计与回放模板 |
| `tests/` | 机制与恢复、E3 一致性、损坏数据拒绝、页面逻辑检查 |
| `protocols/` | 批量运行前固定的 E4 参数 |
| `results/<run>/raw/` | 全量摘要、3 个预定样本情景×5 策略的种子 100 完整轨迹/存档 |
| `results/<run>/review/` | 测试日志、浏览器截图/记录、旧实验完整性与产物指纹 |

[冻结计划](../../docs/sim/experiments/e4/PLAN.md) / [进展与结果](../../docs/sim/experiments/e4/PROGRESS.md)。本轮沿用 [E3 研究](../../docs/sim/experiments/e3/RESEARCH.md)，没有新增依赖或模型调用。

## 查看

离线直接打开 `results/e4-v1/replay.html`；或从仓库根目录启动：

```bash
python3.11 -m http.server 4190 --bind 127.0.0.1 --directory experiments/budgeted_agents/results
```

访问 `http://127.0.0.1:4190/e4-v1/replay.html`。回放是保存的轨迹；下方可以展开全部 14 情景统计。回放样本在运行前指定，不按结果挑选。

## 重现

从项目根目录执行，输出目录必须不存在，拒绝覆盖旧证据。

```bash
python3.11 -m unittest discover -s experiments/budgeted_agents/tests -v
python3.11 experiments/budgeted_agents/src/run.py --output experiments/budgeted_agents/results/new-run
python3.11 experiments/budgeted_agents/src/verify.py experiments/budgeted_agents/results/new-run
python3.11 experiments/budgeted_agents/src/report.py experiments/budgeted_agents/results/new-run
node experiments/budgeted_agents/tests/check_replay.cjs experiments/budgeted_agents/results/new-run/replay.html
```

Python 标准库运行实验；已有 Node 仅验证页面逻辑。manifest 记录方案、源码及只读 E2/E3 依赖指纹，不能修改旧文件后仍称原批次可复现。

## 边界

预算限制探索次数，不保证净收益：被预算拒绝的尝试可能恰好是关键机会。所有策略先各尝试两个未知选项（不扣探索预算），其余四主要策略每人最多 12 次；E3 参考同时保留普通随机与独立意外复查，不在同一预算约束内。分享、寻路与阈值是设计规则，不是角色自发创造的认知能力。噪声真值与变化日程只给世界/评价；180 回合结束是截断，阶段内未恢复单独计数。
