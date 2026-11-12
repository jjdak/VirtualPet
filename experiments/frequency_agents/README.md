# E5：根据复查收益调整频率

[固定计划](../../docs/sim/experiments/e5/PLAN.md) · [进展与结果](../../docs/sim/experiments/e5/PROGRESS.md)。只读复用 E4 混合预算、E3 个人意外检测和 E2 世界/经验/通信原语；不修改旧实验。

| 目录 | 内容 |
| --- | --- |
| `src/` | 动态间隔、批处理、独立审计、统计和离线回放模板 |
| `tests/` | 机制/恢复/历史一致性测试及 DOM 逻辑检查 |
| `protocols/` | 批量生成前固定的参数与情景 |
| `results/<run>/raw/` | 全部组摘要及预定 16 条完整轨迹/存档 |
| `results/<run>/review/` | 验证记录、截图、旧文件与产物指纹 |

## 查看与重现

直接打开 `results/e5-v1/replay.html`，或从项目根目录启动：

```bash
python3.11 -m http.server 4191 --bind 127.0.0.1 --directory experiments/frequency_agents/results
```

访问 `http://127.0.0.1:4191/e5-v1/replay.html`。页面播放保存的动作轨迹，不是实时接入模型的世界。完整情景表在页面下方，负面情景与成功情景同时保留。

```bash
python3.11 -m unittest discover -s experiments/frequency_agents/tests -v
python3.11 experiments/frequency_agents/src/run.py --output experiments/frequency_agents/results/new-run
python3.11 experiments/frequency_agents/src/verify.py experiments/frequency_agents/results/new-run
python3.11 experiments/frequency_agents/src/report.py experiments/frequency_agents/results/new-run
python3.11 experiments/frequency_agents/scripts/finalize_replay.py experiments/frequency_agents/results/new-run
node experiments/frequency_agents/tests/check_replay.cjs experiments/frequency_agents/results/new-run/replay.html
```

输出目录必须不存在，拒绝覆盖结果。Python 仅用标准库；既有 Node 只做页面逻辑测试。manifest 固定源码/方案指纹，之后的文档与浏览器证据单独保存。

“收益代理”是实际亲历结果减去当时原优选估计，不是世界真值或实际反事实净收益；规则由人设计，不是角色训练出了新算法。间隔是最久未亲历项的请求阈值，执行仍受共享预算、冷却、意外优先与保留额度影响。固定 18 回合与 E4 hybrid 一致；固定 12/30 是预先指定的敏感性对照。

`scripts/finalize_replay.py` 修正生成页面的页脚说明，并保存前后散列；不改变批次冻结模板、数据或策略。
