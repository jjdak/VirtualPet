# 架构说明

## 当前实现：S1 控制小样（2026-10-22）

独立 Godot 工程 `sim/` 已实现静态庭院导入、CharacterBody3D 控制与碰撞、观察/眼部相机、捕获鼠标/方向键环顾、原坐姿动画预览。当前没有 AI 控制权仲裁、局部观察或 LLM；这些仍是下段设计。证据见 [S1](sim/S1_PROGRESS.md)。

## SIM 后续架构设计（2026-10-21）

见 [新阶段计划](SIM_STAGE_PLAN.md)。推荐 Godot 独立运行时 + 可替换规则/LLM 决策层；Blender 保留为美术源。引擎持有世界事实，局部观察输入决策，有限技能执行后返回结果。人工/AI 共用一个控制权仲裁器，接管递增世代号并拒绝旧回复。观察、动作和事件需可记录/重放；先无模型闭环再接真实模型。

以下为历史已实现系统，不代表 sim 已实现。

## 当前制作：Blender 原生工程（2026-09-12）

主工程保存在 Git 忽略的 `PrivateAssets/Courtyard/Blender/courtyard-b1-v3.blend`（`courtyard.blend` 为保留的 B0 基线），贴图内嵌，分为庭院、人物、灯光相机和辅助集合。`blender/scripts/` 保留一次性迁移与非破坏验证脚本。正常制作直接编辑原生工程并另存版本，不用脚本重新生成覆盖美术编辑。网页 ShaderMaterial 改为 Blender 材质，网页行为逻辑不作为本阶段依赖；原始 VRM 与历史 C2 保留。当前没有原生动作片段，也未安装额外 VRM 插件。详见 [制作入口](../blender/README.md)。

以下为历史浏览器和 Swift 架构。

## 庭院原型：独立浏览器 3D（2026-09-10）

C2 在 `courtyard/` 实现，不改旧 Swift App。`environment.js` 生成庭院与水面，`character.js` 加载 VRM 并驱动坐姿、眼睑、眼球与头颈，`attention.js` 管理察觉、注视和恢复，`main.js` 处理命中、涟漪、渲染循环及检查界面。输入只在水面命中时进入注意力选择；快速输入保留首次察觉期限并更新目标。动作由当前姿态平滑趋近目标。

`surfaces.js` 生成可复现的灰泥、石板、树叶和软接触阴影。`environment.js` 额外加载本地 CC0 石材贴图；加载完成后创建场景。水体共享 `WATER_BOUNDS` 限定波纹边界；静态环境倒影在初始化、视窗和检查镜头变化时重新捕获，不逐帧反射人物。保留实际 3D 几何与射线命中，未采用绘制背景替代庭院。2026-09-10 恢复原始有限庭院布局，水体和涟漪共享有限池边界，池沿参与遮挡；相机恢复原整体视角。

正常页面无制作参数；`?inspect=1` 提供独立制作控件与录屏。服务仅监听本机 127.0.0.1。素材恢复脚本核验固定下载哈希，源模型和暂存副本保持 Git 忽略。依赖由 package-lock 固定；详情见 [依赖清单](DEPENDENCIES.md)。

已验证实际表演链路；用户对静谧感和自然度的验收仍待完成。最终发布平台未锁定。未来 exploreBrain 仅可作为行为选择层的候选扩展，本轮不实施。下文其余章节描述旧版基线。

2026-09-11：`seated-support.js` 为当前固定坐姿求解双段手臂和掌面方向，`character.js` 在呼吸后、VRM 更新前维持手部目标。求解保持骨长并限制不可达目标，未引入物理引擎；支撑腕误差进入检查快照。材质去重后只调整一次共享材质，保留原模型与表情管理器。

## Targets

`VirtualPet` 是 iOS/iPadOS/macOS 多平台 App target。`VirtualPetWatch` 是 watchOS App target。两者直接引用 `Shared/` 和 `SharedAssets/`，避免复制状态逻辑、反馈逻辑或角色视图。

## State

`CompanionStore` 是一个 `@MainActor ObservableObject`，只保存：

- 当前时间段与心情
- 当前反应 `CompanionReaction`
- 当前一句话
- 安静模式
- 用于重播微动画的 reaction ID
- 仅驻留内存的近期触摸时间，用于识别三连点

标准反应为：

```text
idle
hatTouch
headPat
bodyPoke
rapidTap
longPress
chirp
sleepy
```

“叫她一声”始终触发 `chirp` 动作和对应的 Q 版软音效；`responseIndex` 只轮换吐槽文案与心情，不把按钮调用伪装成帽子、头部或身体触摸。这样按钮语义在 SpriteKit、SwiftUI 和未来 Live2D 渲染器之间保持一致。

每次反应约 1.65 秒后回到当前时间段的待机状态。这个计时只控制动画，不产生数值衰减、连续签到或离线惩罚。

安静模式使用 `UserDefaults` 持久化。初稿没有数据库、后台计时器或网络依赖。

## Input and feedback

`CompanionSpriteView` 和静态后备 `PhoebeCharacterView` 使用同一套 `SpatialTapGesture` 分区：

- 画面高度前 34%：帽子
- 34%–63%：头部
- 其余区域：身体
- 长按 0.62 秒：压扁反馈

`CompanionFeedback` 在 iOS 使用 UIKit 触觉，在 watchOS 使用 WatchKit 触觉，macOS 保持无触觉。`CompanionAudioPlayer` 使用 AVFoundation，并由 `CompanionReaction.voiceTone` 选择 bundle 内被 Git 忽略的三条私人音效：`rapidTap/longPress` 使用 `angry`，`hatTouch/bodyPoke` 使用 `mildlyAngry`，`headPat/chirp` 使用 `soft`；待机和困倦不主动发声。iOS 首次播放前准备 `.ambient` 音频会话并允许与其他音频混音，尊重系统静音开关；若当前路由拒绝会话激活，仍继续尝试 `AVAudioPlayer`，不让会话错误短路播放。安静模式跳过所有语音。任一私有语音缺失、播放器初始化失败或播放失败时才返回 `false`，不以提示音冒充角色语音。

## View adaptation

`ContentView` 在编译期区分 watchOS：

- iOS/iPadOS/macOS 使用完整单屏布局、触摸提示和三个底部控件
- watchOS 使用紧凑角色、两行消息和一个“啾比”按钮

角色、主题和状态模型仍是共享代码。

## Animation rendering

`CompanionReaction.motionFrame` 是渲染器无关的动作契约，包含缩放、偏移、旋转、眼笑、开口、呼吸、头发和帽子摆动参数。

当前版本把两个轻量渲染器作为正式主线，并通过 `CompanionAssets.artworkName(for:)` 把反应映射到待机、摸头、身体受戳和啾比跳跃关键姿势：

- iOS/macOS：SpriteKit 切换透明关键姿势，并执行连续轻微漂浮和短过渡
- watchOS：SwiftUI 切换同一组透明关键姿势并应用相同动作参数；仅在明显改善体验时使用 `TimelineView` 播放小尺寸动作图集

`scripts/verify_watch_motion.sh` 会截取同一 Watch 模拟器的两个时刻，只比较角色区域的哈希，排除状态栏时钟和台词变化。当前连续截图已确认轻量漂浮/缩放持续产生变化，因此 watchOS 仍保留 SwiftUI 关键姿态后备，不为当前版本引入额外动作图集资源。

Live2D 现在是条件分支：只有人工在隔离 checkpoint 中制作出一个可见嘴型或眼睛 keyform，且 `scripts/verify_live2d_model3_motion.sh` 返回 0 并报告 Drawable 顶点变化后，iOS/macOS 才恢复 Native Metal host。门禁通过前不安装 Cubism MCP、不自研 GUI/画布自动化，也不让 Live2D 阻塞当前版本。watchOS 始终不链接 Cubism Core。虽然 SpriteKit 框架支持 watchOS，但 SwiftUI `SpriteView` 在 watchOS 不可用，因此本项目不为播放图集倒退到旧式 WatchKit storyboard。模型发现规则、暂停原因和恢复门禁见 `docs/LIVE2D_PIPELINE.md`。

## Assets

公开仓库保留 `PhoebePlaceholder.imageset/phoebe-public-placeholder.svg`。私人 v3 待机图和三张关键姿势分别位于独立 imageset，目录通过 `.gitignore` 排除。

`CompanionAssets` 分别使用 `NSImage` 或 `UIImage` 检测每张私有资源是否存在。iOS/macOS 构建阶段会把本地忽略的姿势 PNG 复制到 `PhoebePrivateArt/`，SpriteKit 优先从明确 Bundle URL 加载，避免冷启动时 `SKTexture(imageNamed:)` 名称缓存未就绪；各 App target 也会把三条本地忽略的 Q 版音频复制到 `PrivateAudio/`，由 `CompanionAudioPlayer` 通过明确子目录 URL 读取。某个关键姿势缺失时回退到私人待机图，私人资源全部缺失时加载公开占位或保持静默，因此公开代码仍可构建。

## 后续同步

只有在核心互动确认后再增加同步：

1. iPhone ↔ Apple Watch：WatchConnectivity
2. Apple 平台间偏好：优先考虑 App Groups 或 iCloud key-value
3. 有真实跨设备历史需求时才引入 CloudKit

同步失败不应阻止本地陪伴体验。
