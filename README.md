# VirtualPet

## 当前阶段：小庭院仿真研究（2026-10-21）

用户已认可“观察、干预、接管”的新方向，B2 美术阶段已收束并保存至 GitHub 归档标签 [`courtyard-b2-archive-2026-10-21`](https://github.com/jjdak/VirtualPet/tree/courtyard-b2-archive-2026-10-21)。**S2 转身、停步与脚底接触候选已交付**：现成动作、受碰撞约束的位移、脚部校正、去池边、纸船阻挡/清障，以及原控制/第一视角；本轮同时修正 Godot 画面泛白。[启动小样](sim/run.command) · [操作说明](sim/README.md) · [最新进展](docs/sim/S2_CONTACT_PASS.md)。角色手部清障、完整寻路与 LLM 尚未实现；动作衔接、实时美术和主观自然度仍待改进/反馈。

[新阶段计划与一手来源](docs/SIM_STAGE_PLAN.md) · [旧成果收束及恢复](docs/archive/B2_CLOSEOUT.md) · [继续工作卡](docs/live2d/continuation.json)

Blender 保留为美术源；v6/v7 工程与 v5 视频保留。私人模型、`.blend`、视频在本地忽略目录及校验快照中，**未上传 GitHub，不是异地备份**。下述制作状态与旧 App 描述为历史记录，当前下一步以新阶段计划为准。

## 当前制作：Blender

当前工程为 **B2 v6 focused**：社区 GPT/Opus 工作流调研已应用到两版原生光色小样，选出并交付正式静帧、同机位对照。保留完整庭院、相机、少女A和 v5 身体跟随动作。**当前 8 秒视频仍是 v5 光色，不能当作 v6 成片。**

[制作入口与文件](blender/README.md) · [社区调研及实际应用](docs/courtyard/AI_BLENDER_COMMUNITY_RESEARCH.md) · [执行计划](docs/courtyard/B2_NEXT_PLAN.md) · [进度记录](docs/courtyard/PROGRESS.md)

v6 保存重开、几何/动作/相机保持、正式关键帧检查通过；主观自然度与插画完成度待评价。以下为历史阶段记录。

## 当前方向：庭院原型（2026-09-11）

一个不用说话，也能感到彼此存在的安静小世界。以水边庭院、一个角色和三种轻互动（水面、风铃、叶子）验证微型独立游戏式的陪伴感。概念板已获认可；C2 点水片段已实现。用户已选择原版完整庭院布局与新版画面质感的组合，现已恢复整体视角、围墙和池沿，保留新版石阶、细叶树影与倒影；合并后的布局与氛围方向已获认可，已完成首轮人物支撑坐姿与材质受光调整，[同机位对照](docs/courtyard/POSE_LIGHT_PASS.md)已保留。用户再次指出整体画质仍远离概念图，当前讨论 [美术制作路线复评](docs/courtyard/ILLUSTRATION_GAP_RESEARCH.md)；静谧感与自然度尚未验收。

执行与验收标准见 [庭院原型](docs/COURTYARD_PROTOTYPE.md)，计划和实际进度见 [执行记录](docs/courtyard/PROGRESS.md)，当前下一动作见 [继续工作卡](docs/live2d/continuation.json)。

本地运行：`cd courtyard && npm ci && npm run assets && npm run dev`，打开 http://127.0.0.1:4173/ 。已安装依赖与素材时只需 `npm run dev`。详见 [运行说明](courtyard/README.md)。C2 使用 Three.js + three-vrm，临时角色能眨眼、看向点击位置、转头和恢复。当前无声音，外观与 [概念板 v1](docs/courtyard/concept-v1.png) 不同；最终人物和发布平台仍待定。

现有 SwiftUI/SpriteKit App 保留为旧版基线。旧版真机交付和跨设备扩展暂缓，Live2D 继续暂停，自研 Cubism 自动化继续停止。以下功能与构建说明针对已实现的旧版，不代表庭院已经完成。

## 已实现的旧版体验

- 分区触摸：帽子、头部和身体分别触发不同反应
- 连点识别：0.72 秒内连续三次触摸会触发专属吐槽
- 长按反馈：角色被压扁，并配合平台触觉反馈
- “啾比”按钮：触发独立跳跃姿势、台词和本地私人语音
- “叫她一声”按钮：始终触发啾比回应，轮换吐槽文案和心情，不冒充帽子/头部/身体触摸
- 活泼吐槽：当前文案为原型原创，不复刻游戏或短视频台词
- 安静陪伴：降低打扰和声音，保留轻触回应
- 时间氛围：清晨、午后、黄昏和夜间使用不同背景与开场白
- 动画主线：当前由三张关键姿势负责可读动作，SpriteKit 驱动过渡和呼吸；Live2D 仅保留条件恢复门禁

## 同人素材边界

仓库只公开代码和 `PhoebePlaceholder` 原创占位剪影，不包含菲比立绘、拆帧动作或参考视频声音。运行时会检测 `PhoebePrivate` 是否存在；缺失时自动回退，不产生空角色或资源编译警告。

本地私人版本使用以下被 Git 忽略的资源：

```text
PrivateAssets/
SharedAssets/Assets.xcassets/PhoebePrivate.imageset/phoebe-private-idle-2x.png
SharedAssets/Assets.xcassets/PhoebePrivate.imageset/phoebe-private-idle-3x.png
SharedAssets/Assets.xcassets/PhoebeHeadPatPrivate.imageset/phoebe-headpat-private.png
SharedAssets/Assets.xcassets/PhoebeBodyPokePrivate.imageset/phoebe-bodypoke-private.png
SharedAssets/Assets.xcassets/PhoebeChirpPrivate.imageset/phoebe-chirp-private.png
SharedAssets/PrivateAudio/phoebe-chirubi-angry-private.m4a
SharedAssets/PrivateAudio/phoebe-chirubi-soft-private.m4a
SharedAssets/PrivateAudio/phoebe-chirubi-mildly-angry-private.m4a
```

其中私有音频支持 `.m4a`、`.caf` 或 `.wav`。本机版本按反应强度使用三条 Q 版“菲比啾比”：三连点/长按为明显生气，帽子或身体被戳为轻微生气，摸头与啾比按钮为正常偏委屈。音频本体不进入公开仓库；任一语音缺失时对应互动仍保留动作、台词和触觉，不以合成提示音冒充角色语音。来源、时间段和复现步骤见 [语音素材记录](docs/AUDIO_SOURCE.md)。

如需在 Mac 上听候选 A/B（A 原始 / B 轻度降噪连续拼接），运行 `./scripts/play_audio_ab.sh` 顺序试听 01、02、03，或传入 `01`、`02`、`03` 只试听单条。脚本仅访问被 Git 忽略的 `PrivateAssets/`，不会替换 App 默认语音。

构建后可用 `./scripts/verify_private_audio_bundle.sh /path/to/VirtualPet.app` 检查私有音频是否已进入 Bundle；脚本会自动识别 iOS/watchOS 的 `PrivateAudio/` 和 macOS 的 `Contents/Resources/PrivateAudio/`。

准备发布公开源码前运行 `./scripts/verify_public_tree.sh`。它检查 Git index 不含私人素材和已清理的旧文档，并检查工作树空白错误；私人资源即使存在于本机，也不会因此进入公开树。

提交前还可运行 `./scripts/verify_public_build.sh`，它从当前 `HEAD` 生成不含私人素材的临时公开副本，并依次构建 iOS Simulator、macOS arm64 和 generic watchOS，验证公开仓库能跨平台独立编译。公开副本的 macOS 单元回归和 iOS UI 回归也已在本机通过。

若要连同回归一起验证公开副本，可运行 `./scripts/verify_public_regression.sh`。它会从当前 `HEAD` 生成同样的无私人素材副本，检查 macOS Swift Testing 的真实测试计数（当前 12 项）以及 iPhone 17 Simulator UI 回归（当前 7 项）；脚本不会把 macOS XCTest 的 `Executed 0 tests` 适配器汇总误认为真实通过。

当前仅代码公开版本已推送到 [jjdak/VirtualPet](https://github.com/jjdak/VirtualPet) 的 `main` 分支。公开仓库不包含私人立绘、音频、Cubism SDK、模型导出或本机 Xcode 状态；这些内容仍只在本地忽略目录中使用。

当前本机待机图和三张关键姿势由 v3 概念板派生，保留 v3 的脸型、下巴长度和原服装。摸头、身体受戳和啾比跳跃会切换独立姿势；帽子、三连点和长按复用身体受戳姿势并叠加轻量运动参数。它们是当前版本采用的可交互关键帧方案。

已额外生成一张私人中立姿势源图用于 Live2D 拆层，不会替换当前 v3 待机图。分层清单、参数命名、Cubism 接入检查点和 watchOS 图集规则见 [Live2D 动画管线](docs/LIVE2D_PIPELINE.md)。

## 平台结构

| Target | 平台 | 说明 |
| --- | --- | --- |
| `VirtualPet` | iOS、iPadOS、macOS | 共用主界面、状态模型和触摸区域 |
| `VirtualPetWatch` | watchOS | 专用紧凑布局，共用角色状态和反馈逻辑 |

核心代码位于 `Shared/`。初稿只保存安静模式偏好；没有数据库、后台衰减、账号或网络请求。

## 构建与测试

需要 Xcode 26.2。最低系统版本：iOS/iPadOS 26.2、macOS 15.7、watchOS 10。

项目已将 `ENABLE_USER_SCRIPT_SANDBOXING` 默认设为 `NO`，所以在 Xcode 中可直接运行；下面的命令仍显式传入该设置，便于复制到独立命令行或 CI 环境。

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project VirtualPet.xcodeproj \
  -scheme VirtualPet \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/VirtualPetDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO build
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project VirtualPet.xcodeproj \
  -scheme VirtualPetWatch \
  -destination 'generic/platform=watchOS' \
  -derivedDataPath /tmp/VirtualPetWatchDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO build
```

验证 iOS 真机 arm64 编译链（不安装到设备、不需要签名）：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project VirtualPet.xcodeproj \
  -scheme VirtualPet \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/VirtualPetGenericDeviceDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO build
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project VirtualPet.xcodeproj \
  -scheme VirtualPet \
  -destination 'platform=macOS' \
  -only-testing:VirtualPetTests \
  -skip-testing:VirtualPetUITests \
  -skip-testing:VirtualPetUITestsLaunchTests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO test
```

在 iPhone 17 Simulator 上运行完整 UI 回归（回应、重复呼叫、启动性能和四种明暗/横竖屏配置）：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project VirtualPet.xcodeproj \
  -scheme VirtualPet \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -only-testing:VirtualPetUITests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO test
```

使用 `-only-testing:VirtualPetUITests` target 级筛选，避免只写方法名时出现“成功但实际执行 0 项”的假阳性。

快速启动 iPhone 17 模拟器、构建、安装、运行并截取当前画面：

```bash
./scripts/run_ios_preview.sh
```

脚本默认使用 `iPhone 17` 和 Xcode 26.2，并在启动后等待 4 秒让 SpriteKit 纹理完成首帧加载；可用 `DEVICE_NAME`、`DEVICE_UDID`、`DERIVED_DATA`、`SCREENSHOT`、`PREVIEW_WAIT` 覆盖目标。构建产物和截图写入被 Git 忽略的 `.runtime/`，不会进入仓库。

快速启动 Apple Watch SE 3（40mm）模拟器并截屏：

```bash
./scripts/run_watch_preview.sh
```

Watch 脚本默认等待 2 秒；可用同名环境变量覆盖设备、构建目录、截图路径和等待时间。

验证 Watch 角色区域在连续截图间确实发生轻量运动（默认 Apple Watch SE 3 44mm，不把时钟或台词变化计入比较）：

```bash
./scripts/verify_watch_motion.sh
```

可用 `DEVICE_NAME`、`DEVICE_UDID`、`DERIVED_DATA`、`CAPTURE_DIR`、`PREVIEW_WAIT` 和 `MOTION_WAIT` 覆盖目标与采样间隔；截图写入被 Git 忽略的 `.runtime/`。当前结果支持继续采用 SwiftUI 关键姿态与变换，透明动作图集仅在后续实测有明显收益时再加入。

在 Mac 上构建、启动并截取当前 App：

```bash
./scripts/run_macos_preview.sh
```

默认截图写入 `.runtime/macos-preview.png`；设置 `CAPTURE_SCREENSHOT=0` 可只构建并启动，不抓取桌面。

开始真机验收前可运行 `./scripts/check_physical_acceptance.sh`，只读汇总 iPhone/Watch destination、iPhone/Watch Developer Mode/DDI/tunnel 和 Mac 显示器状态；退出码为 `1` 时不会改变设备或桌面状态。
若资格未就绪，脚本还会根据当前状态打印开启 Developer Mode、重新连接设备或唤醒 Mac 的手动下一步。
默认 `PHYSICAL_SCOPE=all` 要求 iPhone、Apple Watch 和 Mac 都就绪；设备可以分阶段恢复时，可改用 `PHYSICAL_SCOPE=ios` 或 `PHYSICAL_SCOPE=watch` 单独检查一端。
预检还会打印当前配对设备的 CoreDevice ID；若目标未就绪，会直接给出对应的 `run_physical_preview.sh` 命令，避免脚本猜错设备。

资格恢复后可用显式 CoreDevice ID 构建、安装并启动真机 App（脚本不会猜设备；资格检查失败时不会构建或安装）：

```bash
DEVICE_ID='你的 iPhone CoreDevice ID' PLATFORM=ios ./scripts/run_physical_preview.sh
DEVICE_ID='你的 Apple Watch CoreDevice ID' PLATFORM=watchos ./scripts/run_physical_preview.sh
```

该脚本使用项目的 Automatic Signing；如需覆盖团队，可额外传入 `DEVELOPMENT_TEAM`。它只在 Developer Mode、DDI 服务和 tunnel 均就绪后执行安装与启动。

依赖与制作工具登记规则见 [依赖清单](docs/DEPENDENCIES.md)，状态结构见 [架构说明](docs/ARCHITECTURE.md)。

## 下一轮

1. 读取 [继续工作卡](docs/live2d/continuation.json) 与 [庭院原型](docs/COURTYARD_PROTOTYPE.md)。
2. 讨论插画差距与美术样块建议，保持认可的完整布局；该路线尚未选定，不自动进入分层表演。
3. 只有主观反馈支持后才扩展风铃、叶子。旧版真机交付、Watch、聊天和 exploreBrain 学习仍暂缓。
