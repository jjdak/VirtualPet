# E3 研究与 harness 定位

检索日期：2026-11-01。优先阅读论文原文、作者官方工程文章、项目文档；下列是相关样本，不声称穷尽最新成果或按热度排名。未安装外部框架，也未将论文结论当成本项目验证。

## 我们正在做什么

可以称作 **面向持续适应的 agent harness 组件实验**。世界执行器与信息边界、独立状态、反馈、存档、轨迹和评估属于运行支撑；“意外检测→复查选择”属于策略机制。当前二选一问题更接近非平稳 bandit：行走由固定 BFS 完成，并没有学习身体控制。

完整 LLM harness 通常还包含模型调用、上下文管理、工具调度、重试/权限与运行恢复。E2/E3 不调用模型，不能称为通用 LLM 框架或能任意接插件的成品。我们关心的是：**角色能否凭经历改变下一次行为，以及这种改变是否值得观察**。暂不以开发一个通用 harness 平台作为产品目标。

## 近期研究

1. [Detection Augmented Learning in Non-Stationary Bandit Environments](https://arxiv.org/abs/2610.25782)，2026-10-19 预印本，扩展此前工作。原文把行动算法、变化检测、强制探索分开，分析探查、检测延迟及误报的成本。借鉴：将 E3 的残差监测、探查调度和价值更新分别记录；用探索对照和伪遗憾评价。**本项目的两次残差阈值不是该文检测算法，也不继承其理论保证。** 阅读：[HTML 原文](https://arxiv.org/html/2610.25782v1)。
2. [Adaptive Exploration for Latent-State Bandits](https://arxiv.org/abs/2602.05139)，2026-02-04，当前 v3 修订于 2026-05-31。作者以滞后反馈、多个选项探查形成的状态摘要辅助选择，并用残差、不确定性和信息年龄调度刷新；报告噪声、区分能力弱、探查中状态改变等局限。借鉴：旧判断需保留最近亲历时间；增加噪声与“别处悄悄变好”的反例。本轮只实现有限启发式，不复现 LinUCB 或完整状态指纹。[原文](https://arxiv.org/html/2602.05139v3)。

## 工程项目与可借鉴部分

| 来源 | 已核实内容 | 应用到 E3 |
| --- | --- | --- |
| [Deep Agents](https://github.com/langchain-ai/deepagents) / [官方能力说明](https://docs.langchain.com/oss/python/deepagents/overview) | 模型周边的计划、上下文、文件存储、子代理等运行支撑；GitHub 读取时 30,833 stars、MIT，说明关注度而非效果保证 | 按状态与执行职责分层；此小实验不引入整个 SDK |
| [LangChain harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering)，2026-02-17 | 固定模型，通过轨迹发现失败模式，调整工具/流程并验证；警惕任务过拟合 | 保持基础策略与更新率，加入触发随机对照、噪声反例，完整保留负结果 |
| [Anthropic 长任务 harness](https://www.anthropic.com/research/effective-harnesses-for-long-running-agents)，2025-11-26；[后续工程实验](https://www.anthropic.com/research/harness-design-long-running-apps)，2026-03-24 | 清晰的进度产物、可续接状态、真实运行验证；评价器也会漏检 | 协议先固定、跨进程恢复、独立结果审计、浏览器交互证据分别保留 |
| [Harbor](https://docs.harborframework.com/) | 运行任务、代理、环境和 verifier 的评估框架 | 将任务配置、执行轨迹、评价指标分开；不为本地标准库实验新增容器/云依赖。仅参考文档，未实测框架 |
| [PettingZoo Parallel API](https://pettingzoo.farama.org/api/parallel/) | 多角色动作/观察映射；[GitHub](https://github.com/Farama-Foundation/PettingZoo) 读取时 3,546 stars、MIT | 两角色先做决定，再执行反馈，最后通信，避免同回合顺序泄漏；并未实现或通过其 API 兼容测试 |
| [Gymnasium 截断与终止](https://farama.org/Gymnasium-Terminated-Truncated-Step-API)，2023-10-27 | 实验时间上限不等于任务终止 | 120 回合结束标为 truncated，未适应不能算成功；这是较早的稳定接口知识 |

热度数字是本次连接器读取快照，不代表趋势/下载量；研究日期与网页检索日期分开记录。上述依赖均未安装，未复制第三方实现。

## 本轮明确采用与暂缓

采用：个人预测误差日志、旧证据年龄、探查预算/冷却、真实机会成本、共享外源随机环境、预定反例、角色状态与评价用真值隔离、可恢复回放。

暂缓：通用插件系统、LLM 反思长文、主角神经网络训练、更多角色/生态、Godot 迁回。只有小任务中出现可解释且有趣的持续适应，才值得讨论下一层载体。E3 不应通过不断添加规则来保证“看上去聪明”。
