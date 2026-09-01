# 真机验收清单

这份清单只针对当前 `spritekit-mainline`，不包含 Live2D 恢复门禁。模拟器通过不能替代真机通过；每个设备都要记录型号、系统版本、构建号和截图路径。

## 验收前

1. 在 Xcode 中选择 `VirtualPet` 或 `VirtualPetWatch` scheme，并确认私人 v3 图像和三条私人音频已位于本机忽略目录。
2. 使用无签名模拟器构建或个人开发者签名真机构建；不要把 `PrivateAssets/` 或私人音频提交到公开仓库。
3. 关闭或开启 Reduce Motion 各验一次；安静模式需要单独记录声音关闭但动作仍保留。
4. 先运行 `./scripts/check_physical_acceptance.sh`；它只读检查 iPhone/Watch destination、iPhone/Watch Developer Mode/DDI/tunnel 和 Mac 显示器状态。退出码为 `1` 只表示尚未具备真机验收资格，不会修改设备或桌面状态，并会打印针对当前状态的手动下一步。
   默认检查范围为 `all`；若先只恢复一端，可使用 `PHYSICAL_SCOPE=ios ./scripts/check_physical_acceptance.sh` 或 `PHYSICAL_SCOPE=watch ./scripts/check_physical_acceptance.sh`，不会因另一端尚未就绪而隐藏当前端状态。

资格通过后，使用显式 CoreDevice ID 启动部署脚本：

```bash
DEVICE_ID='你的 iPhone CoreDevice ID' PLATFORM=ios ./scripts/run_physical_preview.sh
DEVICE_ID='你的 Apple Watch CoreDevice ID' PLATFORM=watchos ./scripts/run_physical_preview.sh
```

脚本会再次检查目标设备；门禁失败时不会构建、安装或启动。部署需要 Xcode Automatic Signing 和可用的个人开发团队。

## Apple Watch 真机资格恢复

当前连接的 Series 11（`Watch7,18`、watchOS 26.2.1、`arm64e`）已经配对且 CoreDevice 显示 `available (paired)`，但 `xcodebuild` 仍标记为 `ineligible`。`devicectl device info details` 的直接原因是 Developer Mode 为 `disabled`、DDI services 不可用、网络 tunnel 为 `disconnected`。部署前需要在手表/配对 iPhone 上开启 Developer Mode，保持手表解锁并重新连接到 Mac；然后重新运行 `xcodebuild -showdestinations`，只有出现可选的物理 watch destination 后才开始签名部署。

## iPhone / iPad

- [ ] 启动后待机台词、时间氛围、角色比例和底部控件无裁切。
- [ ] 点击帽子、头部、身体，确认台词、反应图标、关键姿态和触觉分别变化。
- [ ] 在 0.72 秒内连续点击三次，确认触发 `rapidTap` 吐槽；长按约 0.62 秒，确认压扁反馈后回到待机。
- [ ] 点击“啾比”和“叫她一声”，确认正确的 Q 版语音播放（iOS 首次播放会准备 `.ambient` 音频会话）；开启安静模式后再次操作，确认没有声音但仍有动作和台词。
- [ ] 旋转到横屏再回竖屏，确认布局重新计算，角色和控件没有侧转或越界。
- [ ] 开启系统 Reduce Motion，确认漂浮循环停止、反应仍可读。

## Apple Watch

- [ ] 确认标题、角色、两行台词和“啾比”按钮都在安全区内。
- [ ] 轻点不同角色区域与长按，确认反馈 glyph 不遮挡脸部，按钮仍可点击。
- [ ] 触发“啾比”，确认动作、触觉和声音策略符合当前 watchOS 目标；若系统策略禁止播放声音，记录为平台限制而不是素材缺失。
- [ ] 在 40mm、42mm、46mm 表壳（如可用）各保存一张截图；若设备架构或 provisioning 不合格，只记录为 `ineligible`，不要标记通过。

## macOS

- [x] 启动窗口后检查角色、气泡和按钮在默认尺寸可见。
- [x] 拖动窗口变窄、变宽，确认内容仍居中且没有裁切。
- [x] 点击“叫她一声”、触摸帽子/头部/身体对应的鼠标位置，并切换安静模式；确认状态、动作、台词和安静模式 UI 与 iOS 一致；macOS 不要求 UIKit 触觉。
- [ ] 在正常模式下确认“啾比”与“叫她一声”的实际扬声器听感；Bundle 资源和 `AVAudioPlayer` 解析已自动验证。
- [x] 开启 Reduce Motion，确认 idle 漂浮停止。

## 证据记录模板

```text
设备：
系统：
构建：
日期：
截图：
动作/声音结果：
失败项与复现步骤：
```

## 当前状态

- iPhone、iPad、Apple Watch 40/42/46mm 和 macOS 模拟器验收已完成。
- 2026-09-02 当前 macOS Preview（显式路径 `.runtime/macOSPreviewDerivedData/Build/Products/Debug/VirtualPet.app`）已由 Computer Use 重新检查：启动时显示夜间渐变、菲比角色、困倦台词和“啾比/叫她一声/安静陪伴”控件；当前截图为 `.runtime/macos-current-20260902.jpeg`。
- 2026-09-02 macOS 运行时交互通过：点击“叫她一声”切换到 `开心`、台词“菲比啾比！这声招呼还算有精神。”、音符反馈；点击“啾比”切换到另一条开心台词；安静模式开启后切换为 `平静`、静音图标和安静台词，再次点击恢复正常模式。此次记录只证明 UI/状态/动作路径，不把 Computer Use 的可见反馈当作扬声器听感。
- 2026-09-02 当前 Mac 显示器已在线且桌面可操作；预检脚本兼容新版 `system_profiler` 的 `Online: Yes` 字段并报告 `Mac display: Online`。iPhone 15 Pro 已配对但仍是 unavailable（Developer Mode disabled、DDI false、tunnel unavailable）；Apple Watch 仍是 Developer Mode disabled/DDI false/tunnel disconnected，因此真机部署门禁仍未通过。
- 2026-09-02 最新只读预检报告 Mac display: `Asleep`，因此暂不执行桌面视觉或扬声器验收；脚本已将 `Display Asleep: Yes/No` 规范为 `Asleep/Awake`，并继续保留 iPhone/Apple Watch Developer Mode 与 DDI/tunnel 门禁。
- 2026-09-02 预检支持 `PHYSICAL_SCOPE=ios|watch|all`；在当前设备状态下三种范围均安全退出 1，分别只提示对应未就绪设备或同时提示两端。
- 2026-09-02 Apple Watch SE 3（44mm）模拟器补充预览成功：`./scripts/run_watch_preview.sh` 构建、安装、启动和截屏均通过，截图为 `.runtime/watch-preview-44-current.png`；标题、角色、两行台词和“啾比”按钮均在安全区内。该结果不替代实体手表验收。
- 2026-08-31 `My Mac` 已完成默认窗口、缩窄/放宽、叫她一声、帽子/头部/身体鼠标触摸和安静模式 UI 验收；基线截图保存在 `.runtime/macos-physical-acceptance.png`。
- 2026-08-31 `My Mac` 正常模式点击“啾比”后，界面出现开心姿势、音符和对应台词；按钮到 `CompanionAudioPlayer` 的调用路径已触发，但扬声器是否实际出声仍待项目所有者确认。
- 2026-08-31 在 Mac 上实际执行 `./scripts/play_audio_ab.sh all`，01/02/03 三条 A→静音→B 连续试听均正常退出；最终听感选择仍由项目所有者决定。
- 2026-08-31 在系统设置中将“减弱动态效果”临时打开后，App 间隔 3.5 秒的两张截图 SHA-256 相同；恢复关闭后截图哈希再次变化，Reduce Motion 行为通过且系统原值已恢复。
- 2026-08-31 `devicectl` 诊断连接的 Apple Watch 为已配对且可见的 Series 11（`arm64e`），但 Developer Mode disabled、DDI services unavailable、tunnel disconnected；因此物理 Watch 仍记录为 `ineligible`，不是项目 `ARCHS` 配置错误。
- 2026-08-31 项目以 `ARCHS=arm64e ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO` 执行 generic watchOS 构建并成功生成 `VirtualPetWatch.app`；实体手表不可部署与项目架构无关。
- 2026-08-31 干净 macOS 预览期间全屏 `screencapture` 明确显示 Computer Use 的“ChatGPT is Using Your Mac / Press any key or click to unlock”遮罩；遮罩期间 App-level 截图中的灰色 SpriteView 表面不作为渲染回归判断。
- 2026-08-31 冷启动构建已确认 iOS、macOS 和 watchOS Bundle 均包含三条 `PrivateAudio/*.m4a`；扬声器实际播放与 A/B 听感仍需解锁本机后由项目所有者确认。
- 2026-08-31 当前代码版本重新生成了 iPhone 17、Apple Watch SE 3 40mm、Series 11 42mm 与 46mm 冷启动截图：`.runtime/ios-preview-current.png`、`.runtime/watch-preview-40-current.png`、`.runtime/watch-preview-42-current.png`、`.runtime/watch-preview-46-current.png`；均由一键预览脚本在全新 DerivedData 下构建并成功截屏。
- 2026-08-31 当前代码版本再次完成 macOS arm64 无截图冷编译，生成的 `VirtualPet.app` 也通过三条 `PrivateAudio/*.m4a` Bundle 校验；桌面锁屏期间不把该结果当作 Mac 视觉或听感验收。
- 2026-08-31 iPhone 17 iOS 26.2 模拟器 UI 回归实际执行 7 项且 0 失败：回应、重复呼叫、启动性能，以及四种明暗/横竖屏启动配置。
- 2026-08-31 检查发现主显示器处于休眠；无破坏唤醒后显示 macOS 登录窗口，未输入凭据，也未进行 Computer Use 或 App 视觉/听感验收。
- 当前没有可用的物理 iPhone destination；已配对的 iPhone 15 Pro 与 Apple Watch 都因开发者模式/DDI/tunnel 状态未就绪而不可部署，Apple Watch 另外在 Xcode 中显示为架构未知/ineligible。
- 因此本清单暂不勾选真机通过，也不把模拟器结果表述为发布资格。
