# S2 动作与因果交互调研

2026-10-22。目标是解决脚滑、硬转身、无反馈交互；不以 skill 热度代替实际结果。

## 选用素材

[Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) / [作者官网](https://quaternius.com/packs/universalanimationlibrary.html)，Standard 免费版，包内 License.txt 为 CC0。作者标注 v3.0（2026-06-16）：增加 root motion，修复八方向步相不同步；2.1 曾修复 24/30 fps 导出错误。这说明版本和时长检查是接入必要步骤。

实际下载 Standard 包为 **43 个动作**，不是宣传的全套 120+；使用 `Idle_Loop`（2.5 秒）与 `Walk_Loop`（1.333 秒）。免费包没有独立原地左右转身片段。本轮转弯是沿曲线走动时的连续朝向控制，不声称新增了原地转身 mocap。没有用战斗、舞蹈等与气质不符的片段。

## 经验如何落地

| 来源 | 有用经验 | 本项目应用 |
| --- | --- | --- |
| [Godot 官方骨骼重定向文档](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html) | 骨名相同不等于静置轴相同，位置轨道可能改变身体比例；尺度影响步幅。 | 在独立 Blender 导出中用 T-pose 世界旋转差转移至原骨架，保留原骨长；按髋高缩放位移。不改旧 B2 工程，不重绑模型。 |
| [Godot AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html) | 动作混合和时间缩放分离；root motion 与代码控制各有用途。 | Idle/Walk 混合 + TimeScale，使用碰撞处理后实际速度，撞墙时不继续原地快走。 |
| [Daniel Holden: Code vs Data Driven Displacement](https://www.theorangeduck.com/page/code-vs-data-driven-displacement) | 动画与控制器的速度、加速度和转向风格要一致；仅靠移动碰撞体无法保证脚不滑。 | 测量重定向后低位支撑脚回撤速度，作为播放倍率分母；限制转向速度，缓起缓停，急转减速。仍须近景观察启动/停止/转弯，不能从逻辑测试宣布完全自然。 |
| [Quaternius 作者更新日志](https://quaternius.itch.io/universal-animation-library/devlog/1555893/added-root-motion-and-other-fixes) | 方向动作必须同相位，版本更新可修实际制作问题。 | 检查素材真实时长和动作清单，保留包哈希，不盲用旧教程里的参数。 |

## Skill 检索与取舍

按 find-skills 工作流先看 [skills.sh](https://skills.sh/)，再 `npx skills find godot animation`。

- `gamedev-skills/awesome-gamedev-agent-skills@godot-animation`：检索当时约 5.5K installs，GitHub API 查询仓库 2,730 stars。检索审阅显示主要为 AnimationPlayer/Tree 基础工作流；不是少女A重定向成品。
- `scenario-labs/skills@scenario-godot-animation`：检索当时约 108 installs。内容包含支撑脚速度测量和定时姿态检查，直接相关；但依赖其工具脚本，部分配置假定 Forward+/Jolt，与当前 Compatibility 工程不同。
- 本轮未全局安装新 skill 或整套插件。采用“测量脚速、固定时间截图、区分控制与表演”的检查方法，并以官方 API 和本项目实际运行验证。
- 研究 subagent 返回了来源与取舍摘要，随后额度中断；本记录与实现由主代理完成，不把未完成的代办算作验收。

## 交互取舍

第一版纸船沿确定水路运动，使用扫掠形状查询检测树枝碰撞。移开树枝改变真实碰撞位置，船下一步重新判断；不是按时间演一遍卡住/解锁。提前移走树枝应直接通过，已经漂过后放回不应把船倒拉回来。

角色可手动走到池边，或执行一次有失败结果的“去池边”指令；玩家 WASD 可打断。清障是明确标注的**导演操作**，当前不虚构少女伸手抓取动作。原计划已允许缺少合适接触动作时缩小为“靠近、观察、玩家解除阻挡”。
