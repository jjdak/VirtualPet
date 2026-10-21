# VirtualPet 工作入口

## 当前方向覆盖说明（2026-10-21）

用户已授权收束 B2、保存 GitHub，并开启“观察、干预、接管”的小型 sim 阶段。每轮仍先读 continuation 和 COURTYARD_PROTOTYPE，再读 `docs/SIM_STAGE_PLAN.md`；以下旧方向与此处冲突时，以本段和 continuation 为准。

- 主线 `courtyard-sim`，S0 归档与研究完成，下一步 S1：独立 Godot 小场景迁移/人工控制/第一视角验证。Godot 是推荐候选，尚未安装/实测；不宣称 sim 已存在。
- Blender 继续作为美术源，B2 v6 主线/v7 候选及 v5 视频均归档。无需继续等 v6/v7 选择或补同版短片才研究 sim；不改写原 `.blend`。
- 用户已允许研究 LLM 角色控制；旧“不得扩展交互/LLM”不阻止新阶段计划。先落实世界状态、有限技能、局部观察和人工接管，再在 S4 接真实 LLM。不自动扩展聊天、RL、训练或 exploreBrain。
- 原角色、服装、头发/面部不得自行建模；动作优先找许可明确的现成素材并验证重定向。静态脸仍可用。
- `docs/archive/B2_CLOSEOUT.md` 记录公开/私有边界。GitHub 保存源码和文档，私有文件继续忽略，快照只在本地；不得把公开归档称为完整资产云备份。
- Live2D/Cubism 与旧 App 自动扩展继续暂停。每阶段交付可见结果，主观体验由用户评价。

每轮先读 `docs/live2d/continuation.json` 和 `docs/COURTYARD_PROTOTYPE.md`。continuation 的位置沿用历史路径，但记录的是整个项目当前方向。

## 当前方向（2026-09-12）

- 主线为 `courtyard-blender`：一个不用说话也能感到彼此存在的安静小世界。用户已决定转入 Blender，在软件内建模、优化、渲染，不要求回到浏览器。先读 `blender/README.md`，从现有 `.blend` 继续，禁止重跑迁移覆盖后续美术编辑。
- 概念板 v1 已获认可；保持用户认可的完整庭院布局与整体视角。浏览器 C2 位于 `courtyard/`，仅作为布局与动作基线。当前 B0 迁移后先做 B1 单帧美术，再按反馈做 B2 原生短动画；不要自动继续浏览器适配或扩展 C3。
- 旧 SpriteKit/SwiftUI App 保留为基线；不要自动继续旧版真机部署、跨设备适配或反复回归。
- Live2D 维持暂停，Cubism 自动化维持停止。不得因庭院改用新方向而重开 Cubism 或 Native Metal host。
- 若 Live2D skill 的旧主线表述与当前方向不同，以本文件和 continuation 为准；人工可动性恢复门槛继续保留。
- AIRI、TalkingHead 是参考；尚未采用其运行时。历史 C2 使用 Three.js + three-vrm；当前制作工具是 Blender 5.2.1 LTS，最终人物外观和发布平台未锁定。
- exploreBrain 仅为未来研究方向，当前不实施学习或聊天系统。
- 每个阶段交付能看见或体验的结果；主观静谧感与回应感必须经用户反馈，不从测试通过推断。
- 新增依赖或素材时更新 `docs/DEPENDENCIES.md`；私人素材保持 Git 忽略。
- 2026-09-13 用户明确要求人物不要自行建模，改找开放许可的现成模型。停止自制头发、服装和人物网格；`courtyard-b1-character-*` 仅保留为停止的实验，不作为当前主工程。保留环境 v3，从现成模型选择、导入与摆姿继续。候选与许可见 `docs/courtyard/OPEN_CHARACTER_REVIEW.md`。
- 用户明确否决 Rain，偏好最初效果图的亚系短发少女。现成人物优先深色短发、柔和五官、朴素衣着；不得再默认选 Rain，也不把短发候选自动视为用户已认可。
- 用户随后对少女A的脸与发型评价「不错不错」，该方向已认可；衣服、模型实际形变和庭院效果仍待检查。Tripo 研究见 `docs/courtyard/TRIPO_RIGGING_RESEARCH.md`，尚未接入或运行；先检查原 VRM 绑定，不默认重绑或重新生成角色。

- 2026-09-13 用户提供少女A GLB 已导入独立检查工程：58 骨骼身体蒙皮通过，但 17 个表情绑定为空、无 Shape Keys/眼球骨骼。见 `docs/courtyard/GIRL_A_RIG_REVIEW.md`。先确认是否有完整原始版本，不为补表情自行建模，不默认重绑 Tripo；庭院 v3 尚未替换人物。

- 2026-09-14 用户接受少女A缺少面部数据，明确不影响进展，当前优先让场景整体感受活起来。撤销“先取得完整表情版本才能入景”的前置要求；沿用现有模型和身体骨架，不追查下载来源或自制面部。果蝇研究只作未来行为设计启发，见 `docs/courtyard/FLY_BRAIN_BEHAVIOR_RESEARCH.md`；当前不接入神经模拟/学习系统。

- 2026-09-19：用户明确授权的 B2 光色静帧与 8 秒短片已交付。当前主工程是 `PrivateAssets/Courtyard/Blender/B2/courtyard-b2-light-motion-v1.blend`，从此文件另存继续，不重跑迁移或人物入景脚本。见 `docs/courtyard/B2_LIGHT_MOTION_STUDY.md`。原生动作/重开/视频解码通过，主观画面与动态感受待反馈；不自动增加交互或学习。

- 2026-10-02：当前主工程更新为 `PrivateAssets/Courtyard/Blender/B2/courtyard-b2-color-v2.blend`，已交付光色静帧与同机位对照，见 `docs/courtyard/B2_COLOR_PASS.md`。相机、人物网格和原动作保持；原 8 秒视频仍为 v1 光色，v2 尚未重渲染动画。主观验收待反馈，从 v2 另存继续。

- 2026-10-02 轮廓迭代后：当前主工程为 `PrivateAssets/Courtyard/Blender/B2/courtyard-b2-shapes-v3.blend`。静帧与 v2/v3 对照见 `docs/courtyard/B2_SHAPE_PASS.md`；人物、相机、动作和坐姿支撑面保留，原视频仍是 v1。等待对更浓密树冠的主观反馈，从 v3 另存继续。

- 2026-10-02 持续推进授权：用户认可 v3 方向，要求计划、执行并持续记录。当前主工程更新为 `PrivateAssets/Courtyard/Blender/B2/courtyard-b2-presence-v4.blend`；同版静帧和 8 秒短片已交付，见 `docs/courtyard/B2_PRESENCE_PASS.md`。按 `B2_NEXT_PLAN.md` 在现有范围继续，不重复请求相同授权。主观画质/实时播放验收仍须区分；不扩展聊天、学习或自行建模人物。

- 2026-10-02 播放检查：当前轻便视频为 `b2-presence-v4-review.mp4`，ProRes 母版为 `b2-v4-master.mov`，工程仍为 v4。见 `docs/courtyard/B2_PLAYBACK_AUDIT.md`。QuickTime 操作报告 Mac 锁屏；解锁前不要反复重试长 UI 调用，不把编码或抽帧检查当作实时播放/静谧感验收。

- 2026-10-03：Mac 锁屏阻塞已解除。QuickTime 当前 v4 MP4 循环运行的计时观察窗口为 34.475 秒，间歇截图/时间线回绕正常，见 `v4-native-playback.json` 与播放检查记录。不要继续沿用“必须先解锁”门槛。细微闪动与主观自然度尚未充分验收；下一轮默认人物动作全景可读性，用户优先级问题待回复。

- 2026-10-09：社区 GPT/Opus 工作流调研已落实为 v6 光色小样，当前继续工程 `PrivateAssets/Courtyard/Blender/B2/courtyard-b2-reference-v6-focused.blend`，见 `docs/courtyard/AI_BLENDER_COMMUNITY_RESEARCH.md`。保留 v5 肩背动作、所有几何/布局和相机；当前视频 `b2-body-v5-review.mp4` 仍为 v5 光色，不能称为 v6 成片。两种候选/正式帧/对照已交付，主观验收待定；下一项限定现有树冠的色块与高亮分布。

- 2026-10-09 P8：v7 balanced 树冠候选与正式对照已交付，见 `docs/courtyard/B2_CANOPY_STUDY.md`。保留 v6 主线，v7 为候选；已询问浓密/轻盈偏好，不把沉默视为认可。不要继续无限微调树冠，先根据画面反馈选择，再做同版动画。
