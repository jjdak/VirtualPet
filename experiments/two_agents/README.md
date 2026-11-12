# 两角色经验实验 E1

本地独立实验，不启动 Godot，不访问 exploreBrain。实验计划见 [TWO_AGENT_EXPERIMENT_PLAN](../../docs/sim/TWO_AGENT_EXPERIMENT_PLAN.md)。

当前结果：`results/e1-v2/replay.html`（离线可直接打开）。原始输出、完整输入与动作保存在同目录 JSONL；v1 记录严格 JSON 解析的失败，不能与 v2 合并成单一成绩。表格中的“有益选择”由世界执行取食后的健康变化判定，不读模型自评。

新增 `results/e1-v3/replay.html`：同样观察的中文输入诊断，对照结果见 [完整报告](../../docs/sim/TWO_AGENT_EXPERIMENT_RESULTS.md)。`run_text.py` 是冻结的编码对照 runner；复现时将下列 `run.py` 换成 `run_text.py`，使用新的结果目录。两套 runner 的其他推理参数与世界相同。

## 复现

依赖与权重放在 Git 忽略的 `PrivateAssets/`。Python 3.11 / Apple Silicon，模型使用固定 revision，禁止远端自定义 Python 代码。

```bash
python3.11 -m venv PrivateAssets/Tools/agent-lab-venv
PrivateAssets/Tools/agent-lab-venv/bin/python -m pip install -r experiments/two_agents/requirements-lock.txt
HF_HOME=PrivateAssets/AgentLab/hf-cache HF_HUB_DISABLE_TELEMETRY=1 PrivateAssets/Tools/agent-lab-venv/bin/python experiments/two_agents/download_models.py
python3.11 -m unittest discover -s experiments/two_agents -v
```

从项目根目录运行，每个后端使用独立进程且依次执行。选择未存在的新结果目录；程序拒绝覆盖已有 JSONL。`client_date` 是本次冻结实验的记录日期，复现时应更新该字段再运行三个后端；实际执行 UTC 时间另行自动记录。

```bash
HF_HUB_OFFLINE=1 TOKENIZERS_PARALLELISM=false PrivateAssets/Tools/agent-lab-venv/bin/python experiments/two_agents/run.py --backend value --output experiments/two_agents/results/new-run
HF_HUB_OFFLINE=1 TOKENIZERS_PARALLELISM=false PrivateAssets/Tools/agent-lab-venv/bin/python experiments/two_agents/run.py --backend 0.6B --output experiments/two_agents/results/new-run
HF_HUB_OFFLINE=1 TOKENIZERS_PARALLELISM=false PrivateAssets/Tools/agent-lab-venv/bin/python experiments/two_agents/run.py --backend 1.7B --output experiments/two_agents/results/new-run
python3.11 experiments/two_agents/verify_results.py experiments/two_agents/results/new-run
python3.11 experiments/two_agents/report.py experiments/two_agents/results/new-run
node experiments/two_agents/check_replay.cjs experiments/two_agents/results/new-run/replay.html
```

`results/e1-v1/run_protocol.py` 和 `world.py` 是历史源码快照，用于核对 fingerprint，不从快照目录直接运行（其中路径基于原源码位置）。

`check_replay.cjs` 只用 Node 内置模块和 DOM 测试替身检验页面逻辑，不替代真实浏览器视觉检查。

## 解释边界

- 甲的两次尝试和告知由实验员安排；模型只选择食物目标。
- 行为成长测试是“能否使用持久化记录中的证据”；语言模型权重没有训练。
- 价值表对照按观测收益取均值，无经验时采用固定平局规则；这个简单任务本身有利于该专用算法。
- 每个探针从独立快照开始，身体状态归一；“相反经历”不代表同一个角色适应世界变化。
- 相同权重和引擎，但个人记忆隔离；模型调用逐个处理，未测并发群体或与游戏渲染同时运行。
- MLX 峰值、进程 RSS 高水位是两种不同指标，不相加，也不能当作系统总内存占用。
- 单次输出很短，tokens/s 容易受固定开销影响；选择端到端决策延迟作为主要性能指标。
