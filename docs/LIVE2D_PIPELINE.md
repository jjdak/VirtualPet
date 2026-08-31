# Live2D 与 watchOS 动画管线

## 当前结论

当前版本以 SpriteKit 作为 iOS/macOS 正式渲染主线，以 SwiftUI 关键姿态或透明动作图集作为 watchOS 主线。Live2D 不再是当前版本的交付前置条件，只保留一个有明确证据门槛的条件分支。

本轮已经取得 `CubismSdkForNative-5-r.5` 完整包，并在被 Git 忽略的本地目录中固定副本；公开仓库仍不包含 Cubism Core。2026-08-02 使用 Xcode 26.2 对官方 Metal Demo 做了 Apple Silicon iOS Simulator 无签名构建，Core、Native Framework、954 个 `.metallib` 和示例 App 均编译、链接成功。私人配置下 App 已链接 Core bootstrap，但 Native R5 Metal model host 已暂停，现有 SpriteKit 渲染器继续承担当前版本。

## 2026-08-28 Go / No-Go 结论

| 路线 | 决定 | 证据与边界 |
| --- | --- | --- |
| SpriteKit / SwiftUI / 透明图集 | Go，当前主线 | 已有关键姿态、反应契约和跨平台后备，可直接继续打磨并做真机验收 |
| Native R5 资源与 Core 接入 | 技术验证完成，渲染暂停 | 导出、Core、参数 ID、bundle 复制和 `model3` 相对引用均通过确定性检查 |
| 当前 RigLite 可动性 | No-Go | 12 个参数极值全部保持同一 Drawable 顶点哈希，动作探针退出码为 2 |
| Cubism MCP / GUI / 画布自动化 | Stop | 5.4 Alpha 外部 API 不提供 ArtMesh 顶点坐标写入，无法消除真正的建模瓶颈 |
| 正式 Live2D 模型 | 条件暂停 | 只有一次人工可见 keyform 证明通过后才重新评估 |

暂停期间不要打开或远程操作 Cubism，不安装 MCP，不开发关键形桥接、坐标录制或视觉点击工具，不继续 Metal host，也不扩展正式 PSD、物理和动作范围。这些工作不会阻塞当前版本。

唯一允许的恢复验证是：由熟悉 Cubism 的人，在隔离的可编辑 checkpoint 中为 `ParamMouthOpenY` 或一个眼睛参数制作一个肉眼可见的 keyform，保存后只导出一次。只有 `scripts/verify_live2d_model3_motion.sh` 返回 0 且报告至少一个 Drawable 顶点哈希变化，才恢复 Native Metal host；仍返回 2 就冻结当前版本的 Live2D 工作。

2026-08-24 状态：Cubism Editor 5.4.00 alpha1 已与 5.3 并行安装，原始 5.3 `.cmo3` 未修改。用户在隔离副本中创建并保存了 `ParamHatSwing`，可恢复 checkpoint 为 `PrivateAssets/Live2D/Models/PhoebeRigLiteV1/phoebe-rig-lite-v1-5.4-alpha-test0.cmo3`；从该副本导出的 `model3/moc3/cdi3` 已固定到 `PrivateAssets/Live2D/Exports/PhoebeLive2D/`。`ParamEyeSmile` 和 `ParamHairSwing` 仍由现有左右微笑、前/侧/后发参数映射；九个逻辑参数 ID 已通过导出与 Core 探针，但帽子真实 keyform 和可视变形仍未验收。

运行时导出门禁 `scripts/verify_live2d_export.sh` 已确认 `model3/moc3/cdi3` 引用完整，纹理为 1024 × 1024 且带 alpha。`VirtualPet` macOS arm64 目标已验证能把私有导出以 `PhoebeLive2D/` 目录复制进 App bundle。项目 Debug/Release 已默认关闭 `ENABLE_USER_SCRIPT_SANDBOXING`，使 Xcode 可直接运行；下面的历史验证命令仍显式传入 `NO`，以保持在独立命令行环境中的可复现性：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -scheme VirtualPet -destination 'platform=macOS' \
  -derivedDataPath .runtime/DerivedDataWithModel9 \
  CODE_SIGNING_ALLOWED=NO ENABLE_USER_SCRIPT_SANDBOXING=NO build
```

`scripts/verify_live2d_moc.sh` 已用 R5 Core 直接加载新的 `phoebe.moc3`：Core 版本 6.0.1、Moc 版本 6、28 个参数、6 个 Drawable，九个逻辑参数全部可读取。该结果只证明 ID 与 Core 数据完整，不代表帽子已有可见变形；Native wrapper 的离线探针接口位于 `Live2DRuntime/include/PhoebeLive2DRuntime.h`。

2026-08-24 又完成了 Native R5 的第一步 `model3` 资源加载门禁：`PLDProbeModel3File` 在不引入第三方 JSON 库的前提下解析 `phoebe.model3.json` 的相对 `moc3`、纹理和可选 `cdi3` 引用，拒绝绝对路径与 `..` 路径，再交给 Cubism Core 读取 Moc。`scripts/verify_live2d_model3.sh` 对源目录和 macOS App bundle 均通过（1 张纹理、cdi3 存在、28 参数、6 Drawable、`0x1ff`）。这仍是资源/模型加载证明，不等同于 Metal 画面已显示；`PLDRenderingBridgeReady()` 继续为 `false`，SpriteKit 回退保持不变。

同一轮还加入了持久化 `PLDModel3Handle`、参数写入和 Drawable 快照接口。`scripts/verify_live2d_model3_motion.sh` 对当前导出逐一尝试角度、眼睛、嘴、呼吸、头发和帽子参数；所有参数的 Core 顶点哈希均未改变。因此当前 `.cmo3` 只有参数 ID/空变形，尚未达到“可见参数驱动”门禁。该结果触发 Live2D 暂停，不再由代理回到 Cubism 反复操作。

## 恢复后的能力门禁

Live2D 只有在上面的人工恢复验证通过后，才按两个独立门禁继续：

| 门禁 | 恢复后目标 | 完成条件 | 不阻塞事项 |
| --- | --- | --- | --- |
| `rig-lite-runtime` | 证明现有轻量导出能在 Native R5 中运行 | macOS 与 iOS Simulator arm64 显示模型；眼睛、嘴或呼吸至少一个参数产生可见变化；私人模型缺失时保持 SpriteKit 后备 | 帽子真实 keyform、正式帽子/头发/披风拆层、物理、动作 |
| `production-v1` | 完成可交付正式角色模型 | 正式 PSD 与遮挡补画；完整九参数；物理与动作；通过静止、眨眼、转头、相位和触摸延迟质量门槛 | 无 |

`docs/live2d/continuation.json` 的 `activeTrack` 为 `spritekit-mainline`、`live2dStatus` 为 `paused` 时，不执行任何 Cubism UI 或 Native Metal 工作。恢复后先完成 `rig-lite-runtime`，再单独决定是否值得进入 `production-v1`。

`scripts/verify_live2d_export.sh` 现在已通过完整九参数 ID 契约；这只是导出引用门禁。`ParamHatSwing` 仍须在真实帽子 ArtMesh 上建立 keyform 并通过默认值/极值视觉检查，才能计入 Production V1。

每轮开始先读机器可读的 [`docs/live2d/continuation.json`](live2d/continuation.json)。只有人工恢复门禁已经通过、继续工作卡明确切回 Live2D 时，才读取 [`docs/live2d/CUBISM_RUNBOOK.md`](live2d/CUBISM_RUNBOOK.md) 并恢复单步闭环；accessibility index 永远只是临时值。

## 私人素材目录

这些目录被 Git 忽略：

```text
PrivateAssets/Live2D/Source/
PrivateAssets/SDK/CubismSdkForNative-5-r.5/
PrivateAssets/Live2D/Exports/PhoebeLive2D/
SharedAssets/PrivateMotionAtlases/PhoebeWatch/
```

当前中立姿势源图：

```text
PrivateAssets/Live2D/Source/phoebe-neutral-rig-v1.png
```

它用于拆层，不替换已确认的 v3 待机图。当前文件是 1024 × 1536 透明扁平 PNG，只能作为视觉基准，不能直接生成可用模型；眼白、瞳孔、眼睑、嘴、前后发、帽檐、手臂、披风等仍需拆成独立图层，并补画所有被遮挡区域。生成时只使用一次 ImageGen 编辑调用，随后使用本地 chroma-key 工具生成透明 PNG。

首个 Cubism 纵向切片由 `scripts/build_live2d_psd.py` 生成。它不会重新生成角色，只在原图面部拟合被眼睛、眉毛、腮红和嘴遮挡的肤色，并把原始像素拆回透明控制层。输出位于被忽略的 `PrivateAssets/Live2D/RigLiteV1/`：

```bash
/Users/fengzhuo/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/build_live2d_psd.py
```

`phoebe-rig-lite-v1.psd` 只用于验证眨眼、口型、呼吸和 Native Runtime 加载链路；它不是正式生产 PSD。`qa-report.json` 和 difference PNG 用于确认所有控制层叠回底图后与输入一致。帽子、前后发、披风、手臂和遮挡补画仍按完整清单继续制作。

## PSD 拆层

拆层清单见 `docs/live2d/phoebe-layer-manifest.json`。制作文件应满足：

- 当前 1024 × 1536 中立图只用于拆层流程验证；正式分层源文件目标为 2048 × 3072
- iOS/macOS 第一版使用最多两张 2048 × 2048 纹理；watchOS 继续使用单张 2048 × 2048 以内的离线图集
- RGB、8 bit/channel、sRGB
- 每个最终可动部件使用唯一图层名
- 被头发、眼球、袖子遮挡的区域需要补画
- 线稿、填色和剪贴蒙版在每个部件内部合并
- 帽檐前后层、刘海与后发、左右眼和上下嘴必须分开
- 当前 v3 的脸型、下巴长度和瞳孔比例是不可变基准

## 动作参数契约

`CompanionReaction.motionFrame` 同时驱动当前 SpriteKit 后备和未来 Cubism 模型。Cubism 模型必须提供：

```text
ParamAngleX
ParamAngleY
ParamAngleZ
ParamBodyAngleX
ParamEyeSmile
ParamMouthOpenY
ParamBreath
ParamHairSwing
ParamHatSwing
```

首个轻量模型的兼容映射记录在 `docs/live2d/phoebe-layer-manifest.json`：`ParamEyeSmile` 由 `ParamEyeLSmile` 与 `ParamEyeRSmile` 合成，`ParamHairSwing` 由 `ParamHairFront`、`ParamHairSide`、`ParamHairBack` 合成；`ParamHatSwing` 已在 5.4 测试副本中创建，但真实帽子变形仍属于 Production V1。

标准反应仍为 `idle / hatTouch / headPat / bodyPoke / rapidTap / longPress / chirp / sleepy`。这样替换渲染器时不需要重写状态、触摸、台词、触觉或声音逻辑。

## PRO 长期制作规格

项目所有者会在当前试用结束后续费 Cubism Editor PRO，因此模型按长期 PRO 工程维护，不设置试用期交付节点，也不为 FREE 的纹理、Deformer 和 Parts 上限牺牲帽子、头发、披风或面部层次。仍按移动端性能主动控制规模：

- 60–80 个 ArtMesh，复杂度优先给眼睛、嘴、脸缘、刘海和披风
- 不超过约 120 个 Deformer，避免为了层级整齐而创建无动作价值的空层
- 先完成 9 个既定动作参数，总数保持在 30 以内，给表情和物理留余量
- 两张 2048 × 2048 纹理；只有接缝或缩放质量实测不合格时才增加
- 物理只覆盖帽穗、刘海、侧发、后发和披风，并使用不同相位

同时保留 `.cmo3`、分层 PSD、纹理、物理、动作与运行时导出，避免只剩不可编辑的 `.moc3`。

## Cubism 接入检查点

锁定 Cubism Editor 5.3.03 和 `Cubism 5 SDK for Native R5`（`5-r.5`）。当前检查点如下：

1. 已完成：项目所有者取得官网 SDK 包并启用 Editor 5.3.03 PRO；当前试用结束后续费。
2. 已完成：SDK/Core 固定在 `PrivateAssets/SDK/`，角色模型继续固定在私人目录。
3. 已完成：官方 Metal Demo 在 Xcode 26.2 / iOS Simulator arm64 上构建成功。
4. 已暂停：正式分层 PSD 与遮挡补画不再阻塞当前版本。
5. 已完成：导出带 `ParamHatSwing` ID 的 `phoebe.model3.json`、`.moc3`、`.cdi3.json` 与 1024 × 1024 纹理；RigLite 引用、纹理和 Core 读取均已验证。帽子真实 keyform 尚未完成。
6. 已决定：私人原型最低系统提高到 iOS 26.2 / macOS 15.7，继续使用 R5 Core。
7. 已完成：生成 iOS device、iOS Simulator arm64、macOS arm64 私有 XCFramework；App 和测试 target 已可选接入，公开仓库缺少 Core 时仍保持 SpriteKit 后备可构建。
8. 已暂停：Native R5 `model3` 资源加载门禁与持久化 Core handle 已完成；当前导出没有任何参数造成顶点变化。只有人工 keyform 恢复门禁通过后才继续 Metal renderer。当前受限环境的 iOS Simulator build 仍被“无可用 simulator runtime”阻塞，非 Swift 或资源编译错误。

在 SDK 已放到约定私人目录后，可这样重建本机 bootstrap：

```bash
mkdir -p PrivateAssets/Config
cp Config/Live2D.private.xcconfig.example PrivateAssets/Config/Live2D.private.xcconfig
./Live2DRuntime/scripts/build_xcframework.sh
```

删除或不创建 `PrivateAssets/Config/Live2D.private.xcconfig` 即切回公开 SpriteKit 构建；不需要修改 Xcode 工程文件。

期望的 bundle 结构：

```text
PhoebeLive2D/
  phoebe.model3.json
  phoebe.moc3
  phoebe.physics3.json
  textures/
  motions/
```

`CompanionAssets.live2DModelURL()` 已固定模型发现规则，未来 Live2D host 只需消费该 URL 和 `motionFrame.live2DParameters`。

iOS/macOS 运行时采用官方 Native Framework + Cubism Core + Metal renderer。SwiftUI 只承载 `MTKView` 包装层，Cubism C++ 生命周期放在 Objective-C++ bridge 内，避免把 C++ 类型泄漏到共享 Swift 状态层。watchOS target 不链接 Core 或 bridge。

## 运行系统兼容性检查

R5 包中的静态 Core 库不是按当前 App 的最低系统版本构建的。`otool -l` 实测：

- iOS device 和 iOS Simulator arm64 Core：`minos 26.2`
- macOS arm64 Core：`minos 15.7`
- 调整前 App：iOS 17、macOS 14

项目所有者已接受将私人测试版最低系统提高到 iOS 26.2 / macOS 15.7，项目配置已同步调整。watchOS 不链接 Core，因此继续维持 watchOS 10 最低版本。

## watchOS 导出

Apple Watch 不运行 Cubism Core。当前可从已经认可的关键姿态制作小尺寸透明图集，并由 SwiftUI `TimelineView` 选择帧；如果 Live2D 将来恢复，也可以从主 App 或 Cubism 离线导出：

- 建议画布：384 × 512
- 建议帧率：12 fps
- `idle`：24 帧可循环
- 其他反应：8–16 帧，结尾能平滑回到 idle
- 图集纹理建议不超过 2048 × 2048
- 文件名使用反应 raw value，例如 `headPat`、`rapidTap`

图集和描述文件放入 `SharedAssets/PrivateMotionAtlases/PhoebeWatch/`。资源缺失时，`PhoebeCharacterView` 切换待机、摸头、身体受戳和啾比跳跃关键姿势，并执行同一组位移、缩放和旋转参数。

这些关键姿势是当前版本正式采用的轻量动画方案。若未来恢复 Live2D，其首个可接受版本仍须实现眨眼、口型、头部转向、帽子/头发/披风分相位物理以及触摸动作间的连续插值。

SpriteKit 框架虽然列出 watchOS 支持，但 SwiftUI 的 `SpriteView` 初始化器在 watchOS SDK 中不可用。项目不会仅为 SpriteKit 引入旧式 storyboard/WKInterfaceController 生命周期。

## 质量门槛

- 静止状态看不出部件接缝
- 眨眼时上下眼睑不改变脸型
- 左右转头不缩短下巴
- 帽子、头发和披风有不同相位的轻微延迟
- 触摸动作可在 300 毫秒内给出第一帧反馈
- Reduce Motion 开启时取消循环漂浮并缩短过渡
