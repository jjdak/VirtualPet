# VirtualPet

一个以角色触摸反馈为核心的轻量陪伴 App 初稿，使用 SwiftUI 同时面向 iPhone、iPad、macOS 和 Apple Watch。

当前产品方向已经确定为：菲比同人原型、仅私人非商业测试、直接触摸与动作反馈、活泼吐槽。旧版的饥饿、健康、等级、进化、商店、任务、公会、战斗和排行榜均不再保留；角色不会因为用户离开而受罚。

## 当前体验

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

依赖与制作工具登记规则见 [依赖清单](docs/DEPENDENCIES.md)，状态结构见 [架构说明](docs/ARCHITECTURE.md)。

## 下一轮

1. 读取 [`docs/live2d/continuation.json`](docs/live2d/continuation.json)，继续 `spritekit-mainline`；不要打开 Cubism 或继续 Metal host。
2. 用现有反应和关键姿态契约继续做动作细节验收；首轮 idle、greet、pat、sleep 节奏已完成。
3. 当前 Watch SwiftUI 轻量运动已通过 40/42/44/46mm 连续帧检查；仅在后续真机测试证明有明显收益时制作透明动作图集，并始终保留 SwiftUI 后备。
4. iOS、iPadOS 与 watchOS 模拟器视觉验收已完成（含 Apple Watch 40mm/42mm/46mm 表壳）；下一步完成 iPhone、Apple Watch 和 Mac 的真机验收（当前连接的 Apple Watch 因架构/签名资格暂不可用）。
5. 当前 iPhone 17 Simulator UI 7 项与 macOS arm64 单元 12 项均通过；Live2D 只保留一次人工嘴型或眼睛 keyform 恢复门禁，动作探针返回 0 前不安装 MCP、不自研画布自动化、不扩展正式模型。
6. 已生成三条语音的 A/B 本地试听候选；待听感确认后再决定是否把 B 替换进 App，记录见 [语音素材记录](docs/AUDIO_SOURCE.md)。
7. 真机验收按 [真机验收清单](docs/PHYSICAL_ACCEPTANCE.md) 执行；当前设备资格不足时保留 `ineligible` 记录，不把模拟器结果冒充真机通过。
