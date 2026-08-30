# 依赖与制作工具清单

## 约定

项目允许新增或下载依赖，但必须在同一次变更中记录：

- 名称与锁定版本
- 用途和使用范围
- 安装或恢复方式
- 许可证
- 是否进入最终 App 包

新增依赖后未更新本文件，视为变更未完成。

## App 运行时

当前没有第三方运行时依赖，也没有 Swift Package Manager、CocoaPods 或 Carthage 包。

| 名称 | 版本 | 用途 | 进入 App | 许可证/来源 |
| --- | --- | --- | --- | --- |
| SwiftUI | 随 Xcode 26.2 SDK | 跨平台界面和手势 | 是 | Apple SDK |
| Combine | 随 Xcode 26.2 SDK | `ObservableObject` 状态发布 | 是 | Apple SDK |
| Foundation | 随 Xcode 26.2 SDK | 日期、偏好和 Bundle 资源 | 是 | Apple SDK |
| AVFoundation | 随 Xcode 26.2 SDK | 本地私人短语音播放 | 是 | Apple SDK |
| SpriteKit | 随 Xcode 26.2 SDK | 当前 iOS/macOS 正式动画主线 | 仅 iOS/macOS | Apple SDK |
| libc++ | 随 Xcode 26.2 SDK | Native R5 bootstrap 的 `model3.json` 资源解析（`std::string`/文件流） | 仅 iOS/macOS 私人构建 | Apple SDK；通过私有 `Live2D.private.xcconfig` 的 `-lc++` 链接 |
| UIKit | 随 iOS SDK | iOS 触觉反馈 | 仅 iOS | Apple SDK |
| WatchKit | 随 watchOS SDK | Apple Watch 触觉反馈 | 仅 watchOS | Apple SDK |

## 构建与制作工具

| 名称 | 版本 | 用途 | 安装/恢复 | 进入 App | 许可证/来源 |
| --- | --- | --- | --- | --- | --- |
| Xcode | 26.2 | 构建 iOS、macOS、watchOS targets | Mac App Store / Apple Developer | 否 | Apple |
| Xcode Metal Toolchain | 17C7003j | 编译 Cubism Native R5 的 Metal shader | `xcodebuild -downloadComponent MetalToolchain`；约 704.6 MB | 否 | Apple |
| CMake | 4.3.4 | 生成 Cubism 官方 Metal iOS 示例工程 | Homebrew `brew install cmake` | 否 | BSD-3-Clause；Kitware/Homebrew |
| ios-cmake | 4.5.0 | 为官方 Metal 示例生成 iOS / Simulator Xcode 工程 | SDK 内 `Samples/Metal/thirdParty/scripts/setup_ios_cmake` 从 GitHub 下载 | 否 | BSD-3-Clause；leetal/ios-cmake |
| Live2D Cubism Editor | 5.3.03 PRO；当前试用结束后续费 | PSD 导入、网格、Deformer、参数、物理和 `.moc3` 导出 | Live2D 官网 Apple Silicon 安装包 | 否 | Live2D Proprietary Software License |
| Live2D Cubism Editor Alpha | 5.4.00 alpha1（Apple Silicon）；评估已停止 | 保留隔离 checkpoint；当前版本不再用于 External App Integration、MCP 或 UI 自动化 | Live2D 官方创作者论坛安装包；安装于 `/Applications/Live2D Cubism 5.4 alpha/` | 否 | Live2D Proprietary Software License；限时 Alpha，2026-09-14 后不可用 |
| Live2D Cubism SDK for Native | 5 R5 (`5-r.5`) | iOS/macOS Metal 实时模型、物理和动作播放 | 官网取得完整包，私人副本位于 `PrivateAssets/SDK/CubismSdkForNative-5-r.5/` | 私人 iOS/macOS 构建已链接 Core bootstrap；公开构建不含 | Live2D 官方 Native Framework 与专有 Core |
| Codex 内置 ImageGen | 当前会话提供 | 从确认的 v3 概念板生成待机图、Live2D 中立源图和三张关键姿势 | Codex 环境提供 | 否 | OpenAI 工具 |
| Pillow | 12.2.0（Codex runtime `26.731.11130`） | 去除立绘和关键姿势绿幕并生成透明 PNG | 使用 Codex 工作区 Python；未写入项目 | 否 | Pillow 许可证 |
| psd-tools | 1.17.4 | 从中立 PNG 生成可重复构建、带透明像素图层的 Cubism 导入 PSD | `python3 -m pip install --target PrivateAssets/Tools/python-packages psd-tools==1.17.4` | 否 | MIT；PyPI/GitHub |
| NumPy / Pillow（psd-tools 私人工具环境） | 2.5.1 / 12.3.0 | 面部底图拟合、透明图层和像素差异 QA；由 psd-tools 1.17.4 安装解析得到 | 与上一行同一条固定版本安装命令恢复 | 否 | BSD-3-Clause / Pillow 许可证 |
| PyYAML | 6.0.2 | 运行 Codex `skill-creator` 的 `quick_validate.py`，校验项目内 Live2D Skill 的 YAML frontmatter 和目录命名 | `python3 -m pip install --target PrivateAssets/Tools/skill-validator PyYAML==6.0.2` | 否 | MIT；PyPI |
| `remove_chroma_key.py` | 随 Codex imagegen skill | 软边缘抠图与去绿边 | Codex imagegen skill 内置 | 否 | OpenAI 工具 |
| `scripts/run_ios_preview.sh` | 随项目 | 选择或启动 iOS 模拟器，构建、安装、启动并截屏当前 App | 无需安装；依赖 Xcode `xcodebuild`、`simctl` 与系统 Python 3 | 否 | 项目脚本 |
| `scripts/run_watch_preview.sh` | 随项目 | 选择或启动 watchOS 模拟器，构建、安装、启动并截屏当前 Watch App | 无需安装；依赖 Xcode `xcodebuild`、`simctl` 与系统 Python 3 | 否 | 项目脚本 |
| `scripts/run_macos_preview.sh` | 随项目 | 构建、启动并截屏 macOS 当前 App | 无需安装；依赖 Xcode `xcodebuild`、macOS `open`、`screencapture` | 否 | 项目脚本 |
| `scripts/play_audio_ab.sh` | 随项目 | 顺序或单独播放三条私有 A/B 连续试听候选；不修改 App 资源 | 无需安装；依赖 macOS 内置 `/usr/bin/afplay` | 否 | 项目脚本 |
| `docs/PHYSICAL_ACCEPTANCE.md` | 随项目 | 记录 iPhone、iPad、Apple Watch 与 Mac 的真机验收动作和证据格式 | 无需安装 | 否 | 项目文档 |
| yt-dlp | 2026.07.04 | 下载项目所有者指定的公开视频独立音轨，供本地私人候选裁剪 | `brew install yt-dlp` | 否 | Unlicense；Homebrew |
| FFmpeg | 8.1.1 | 从公开视频独立音轨裁剪、单声道化、淡入淡出和响度统一 | `brew install ffmpeg` | 否 | GPL-3.0-or-later；Homebrew |
| whisper.cpp | 1.9.1 | 对候选音轨做本地中文转写并输出时间戳 | `brew install whisper-cpp` | 否 | MIT |
| Whisper `ggml-base.bin` | multilingual base；SHA-256 `60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe` | 48 秒和 10 秒候选音频的离线语音识别 | 从 `ggerganov/whisper.cpp` Hugging Face 仓库下载到 `PrivateAssets/Models/` | 否 | MIT；模型卡许可随上游 |

Pillow、psd-tools、NumPy、PyYAML、yt-dlp、FFmpeg、whisper.cpp 和 Whisper 模型都只用于制作或工作流校验，不是复现 App 构建所需依赖。`psd-tools` 及其 Python 依赖安装在被 Git 忽略的 `PrivateAssets/Tools/python-packages/`；PyYAML 安装在被 Git 忽略的 `PrivateAssets/Tools/skill-validator/`；`whisper-cpp` 通过 Homebrew 安装时同时安装或升级其 `libomp`、`ggml`、`sdl3`、`sdl2-compat` 依赖；模型与转写产物均位于被 Git 忽略的 `PrivateAssets/`。

2026-08-18 从 Live2D 官方创作者论坛下载并并行安装 Cubism Editor 5.4.00 alpha1 Apple Silicon 版。安装包 SHA-256 为 `2c7471109f76762727046647a5a7e60fa842e8b15bab79aa3c9aac119cf7525a`；两次独立下载字节完全一致，但 macOS `pkgutil`、`codesign` 与 Gatekeeper 均报告签名无效。项目所有者在获知风险后明确授权使用 `sudo installer` 完成安装。评估期间 5.4 只允许打开 `PrivateAssets/Live2D/Models/PhoebeRigLiteV1/phoebe-rig-lite-v1-5.4-alpha-test.cmo3` 等隔离副本，不得覆盖 5.3 原始工作文件。

2026-08-28 结束 5.4 Alpha External Application Integration 与 Cubism 自动化评估：当前 API 不提供完成真实 keyform 所需的 ArtMesh 顶点坐标写入，自研 MCP/GUI/画布自动化对单角色项目不经济。当前版本不新增相关依赖；只有稳定 API 补齐几何写入能力，或出现可摊销成本的多模型生产需求并经用户重新批准，才重开评估。

2026-08-02 安装 yt-dlp 2026.07.04 时，Homebrew 同步安装或升级了以下制作环境传递依赖；它们均不链接或复制进 App：`certifi` 2026.7.22、`giflib` 6.1.3、`webp` 1.6.0、`libtiff` 4.7.2、`little-cms2` 2.19、`sqlite` 3.53.4、`deno` 2.9.4、`python@3.14` 3.14.6。各自许可证和恢复来源以对应 Homebrew Core formula 为准。

最终本机 App 包含 `phoebe-chirubi-angry-private.m4a`、`phoebe-chirubi-soft-private.m4a`、`phoebe-chirubi-mildly-angry-private.m4a`，但所在的 `SharedAssets/PrivateAudio/` 被 Git 忽略。公开仓库没有合成提示音，也不包含视频来源音频；语音缺失时保持静默。

## Cubism SDK 固定与验证

`cubism-info.yml` 记录 SDK `version: 5-r.5`、创建时间 `20260401T135000+0900`。本地校验值如下；可运行 `scripts/verify_live2d_sdk.sh` 复核：

| 文件 | SHA-256 |
| --- | --- |
| `cubism-info.yml` | `0a7b16f8a3d9d536b86fda65e25b090099c1f78340195e4df5c475d60f372fb4` |
| `Core/include/Live2DCubismCore.h` | `6f1802780d1eb36ff39705e0764f9eeed9b41c313a13ac155270c6f4ad51d53f` |
| `Core/lib/macos/arm64/libLive2DCubismCore.a` | `318da4dcfb4ced7221f7ec1487541152dee8c5275059b74156768d66499f0238` |
| `Core/lib/ios/Release-iphoneos/libLive2DCubismCore.a` | `544ef4945c19d43919b861567328da6bfd95b99c2474114db403d24ed8292fcc` |
| `Core/lib/ios/Release-iphonesimulator-arm64/libLive2DCubismCore.a` | `315c224a1fb2d968822549070698e19081919f548f9120c279363735321f4632` |
| `ios-cmake/ios.toolchain.cmake` | `72b5d9470dad5b2cfe72d43583888afce0779fd557a425bc487b02a7c33ba855` |

2026-08-02 验证环境为 Xcode 26.2、AppleClang 17.0.0、CMake 4.3.4、ios-cmake 4.5.0 和 Metal Toolchain 17C7003j。官方 iOS Simulator arm64 Demo 使用 `CODE_SIGNING_ALLOWED=NO` 完整构建成功，生成 App 约 29 MB；首次构建生成 954 个 `.metallib`。

R5 Core 的二进制最低系统标记为 iOS 26.2、macOS 15.7。项目所有者已接受同步提高私人测试版的最低系统；watchOS 仍维持 10，并且不链接 Cubism Core。

`Live2DRuntime/scripts/build_xcframework.sh` 会把三套 Core 静态库与轻量 bootstrap 合并为被忽略的 `PrivateAssets/Build/PhoebeLive2DRuntime.xcframework`；脚本使用 Unix Makefiles，避免 CMake/Xcode 临时 DerivedData 写入受限用户目录。公开的 `Config/VirtualPet.xcconfig` 使用可选 include：没有私人配置和 Core 时不增加链接参数，App 自动保持 SpriteKit 后备。

2026-08-24 Native R5 bootstrap 增加了无第三方依赖的 `model3.json` 相对引用解析器；由于该解析器使用 C++ 标准库，私有配置为 iOS、Simulator 和 macOS 三个 slice 补充 `-lc++`。该库随 Apple SDK 提供，不另行下载，也不复制到 App 包中。

R5 的 iOS 模拟器 Core 只提供 arm64，因此私人配置排除 `x86_64` 模拟器架构。Apple Silicon 模拟器、iPhone/iPad 真机和 arm64 macOS 均不受影响。

不能只克隆公开的 `CubismNativeFramework`：它不包含加载模型所需的 Cubism Core。SDK、Core、官方示例构建产物和私人角色模型都由 `/PrivateAssets/` 规则排除，不会进入公开 Git。若将 App 分发或改变私人非商业用途，必须重新按官方 SDK Release License 流程判断发布许可。详细步骤见 `docs/LIVE2D_PIPELINE.md`。
