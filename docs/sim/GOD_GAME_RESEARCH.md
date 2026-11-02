# 神明指引与角色成长：游戏先例调研

日期：2026-10-26。状态：方向研究，未选择实施方案，未修改运行时。

## 用户意图

模拟世界中生活着一群人，玩家扮演神明进行指引，角色可以学习成长。用户当前的兴趣在于探索 AI 技术及观察意外行为，不要求沿用庭院建模，也不以尽快完成商业游戏为目标。

## 最相关的参考

| 参考 | 已有机制与相似点 | 对“学习”的边界 |
| --- | --- | --- |
| Crest | 用象形语言发布神谕；居民经历影响理解，联想可能改变神谕含义，产生意外后果 | 是受约束的命令与解释系统；不能当作任意自然语言智能 |
| Black & White | 神明影响村庄，并教导可独立行动的神兽；开发者明确讨论学习、练习、强化与模仿 | 核心可教导对象是神兽；村民有欲望和个性，集体协作部分由村庄中心协调，不能等同人人拥有同一学习系统 |
| WorldBox | 世界干预与社会演变；官方更新包含家庭、文化、语言、宗教、遗传相关系统 | 社会状态演变不能直接证明每个居民在进行机器学习 |
| Creatures | 创作者介绍 Norns 在生活过程中学习、记忆并泛化经验 | 是人工生命参考，非人类宗教社会；作者明确区分反应式学习与其追求的思考能力 |
| Sapiens | 指导部落成员调查材料、研究、工作并学习技能 | 页面支持技能和技术进步，未证明开放式行为学习 |
| The Universim | 神力与文明经营，从石器时代发展到太空 | 核心是文明和建设进程，不能把科技树等同个体学习 |

## 对本项目的推论（尚未验证）

最值得拆解的是 Crest 的间接沟通、Black & White 的可教导行为、WorldBox 的观察与干预。Creatures 提供“生活中学习”的补充思路。

可探索的独立切口：少量居民各自积累经历，对同一指引作出不同解释；行为结果改变之后的选择，并能影响他人。玩家能追溯改变的原因，而非仅看到故事文本宣称他们成长。此组合是设计假设，不是对市场空白的断言。

若进入下一轮研究，先验证三个问题：玩家能教什么；不干预时居民是否仍能生活；关掉神谕后，之前的教导是否继续影响行为。技能熟练度、经验影响决策、社会传播应分别定义。LLM 可作为指引解释的候选工具，接入本身不等于在线学习。

暂不扩大地图、人物资产、工业科技树或训练框架。现有 Godot 与 Blender 成果保留；此记录不代表新方向已被用户选定。

## 一手来源

- [Crest 官方 Steam 页面](https://store.steampowered.com/app/341710/Crest/)：神谕、解释、联想与环境经历。
- [Peter Molyneux：Black & White 开发复盘，2001](https://www.gamedeveloper.com/design/postmortem-lionhead-studios-i-black-white-i-)：神兽学习与村庄协作架构。开发者的广泛宣传性表述不视为独立验证。
- [WorldBox 官方更新记录](https://www.superworldbox.com/changelog)：社会、家庭、文化等机制。
- [Steve Grand：Introduction to an artificial mind，2011](https://stevegrand.wordpress.com/2011/03/06/introduction-to-an-artificial-mind/)：回顾 Creatures 的学习目标与局限；文章后半关于 Grandroids 的愿景不当作 Creatures 已有功能。
- [Sapiens 官方 Steam 页面](https://store.steampowered.com/app/1060230/Sapiens/)：个体技能、调查材料与部落经营。
- [The Universim 官方 Steam 页面](https://store.steampowered.com/app/352720/The_Universim/)：神力、资源管理、文明推进。

证据等级：本轮为官方说明与开发者复盘调研，没有本机试玩或源码核验。Black & White 等老游戏的现代 Mac 兼容性未验证；不据历史平台标记建议直接购买。
