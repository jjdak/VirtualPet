# Roadmap

## V0 — 方向初稿

- [x] 删除惩罚型成长系统和功能堆叠
- [x] 重建 iOS/iPadOS/macOS 共用 SwiftUI target
- [x] 增加 Apple Watch target
- [x] 实现单屏陪伴、角色触摸、回应和安静模式
- [x] 加入原创角色占位资产
- [x] 完成 macOS 与 watchOS 构建验证

## V1 — 角色与核心互动

- [x] 选定私人非商业菲比同人原型路线
- [x] 选定触摸反馈作为主互动
- [x] 增加跨平台触觉与可关闭的私人 Q 版语音
- [x] 验证 Cubism Editor 5.3.03 PRO 试用和 Native R5 官方 Metal Demo
- [x] 生成并接入可选的 Native R5 Core XCFramework bootstrap
- [x] 将私人原型最低系统提高到 iOS 26.2 / macOS 15.7

### V1A — SpriteKit / 动作图集主线（当前）

- [x] iOS/macOS 使用 SpriteKit 关键姿态与轻量变换
- [x] watchOS 使用 SwiftUI 关键姿态，并保留静态后备
- [x] 触摸、台词、音频与触觉保持渲染器无关
- [x] 完成首个 idle 呼吸/微摆增量，并在 Reduce Motion 下保持静止
- [x] 完成首轮 idle、greet、pat、sleep 的动作节奏调优和状态切换验收
- [x] 完成 iOS 26.2 与 watchOS 26.2 模拟器视觉验收，修正 watchOS 台词换行与按钮裁切
- [x] 补充 iPadOS 26.2 regular-size 模拟器视觉验收，确认居中内容宽度与角色比例稳定
- [x] 补充 Apple Watch SE 3 40mm、Series 11 42mm 与 46mm 模拟器视觉验收，按表壳安全区自适应紧凑布局
- [x] 为 watchOS 反应图标增加小屏尺寸，避免 `zzz` 等反馈遮挡角色脸部
- [x] 复跑 iPhone 17 Simulator 6 项 UI 测试与 macOS arm64 11 项单元测试，修正跨平台 UI 测试编译条件
- [x] 为三条用户确认的 Q 版语音生成原始 A 与轻降噪 B 私人试听候选，暂不替换当前 App 音频
- [x] 固化 iPhone 与 Apple Watch 模拟器的一键构建、安装、启动和截屏预览脚本
- [x] 增加 macOS 一键构建、启动和截屏预览脚本，并修复增量构建遗漏私有 Live2D 纹理的问题
- [x] 将私有姿势 PNG 显式复制到 iOS/macOS Bundle，消除冷启动灰色占位并完成 iOS/macOS 冷启动预览验证
- [x] 将三条私有 Q 版音频显式复制到各 App Bundle，修复仅有按钮而无音频文件的冷启动路径
- [x] 增加公开树守门、无私人素材公开副本跨平台构建与回归验证，确保未来发布不会泄露私人资源且 iOS/macOS/watchOS 仍可独立编译与测试
- [x] 清理旧版 Sunling/成长系统遗留物，创建 `jjdak/VirtualPet` 公开仓库并推送仅代码版本
- [ ] 仅在明显改善 Watch 体验时制作透明动作图集
- [ ] 完成 iPhone、Apple Watch 和 Mac 的真机与视觉验收

当前版本不再被 Live2D 阻塞。唯一下一动作和禁止项见 [`docs/live2d/continuation.json`](docs/live2d/continuation.json)。

### V1B — Live2D 条件分支（暂停）

- [x] 生成 RigLite PSD、可恢复 `.cmo3` 和 `model3/moc3/cdi3` 导出
- [x] 用 Native R5 Core 验证 Moc 6、28 个参数、6 个 Drawable 和九个逻辑参数 ID
- [x] 验证模型资源复制进 macOS App bundle，并通过相对引用加载门禁
- [x] 确认当前 12 个参数极值均不改变 Drawable 顶点哈希，动作探针退出码为 2
- [ ] 由熟悉 Cubism 的人只制作一个可见嘴型或眼睛 keyform，并完成一次隔离导出
- [ ] 仅当 `scripts/verify_live2d_model3_motion.sh` 返回 0 时恢复 Native Metal host
- [ ] 仅在运行时闭环通过后，重新评估正式 PSD、物理、动作和 watchOS 图集

在恢复门禁通过前，停止安装 Cubism MCP、编写画布/坐标自动化、反复读取按钮、继续 Metal host，以及扩展正式模型范围。唯一人工验证仍失败时，当前版本冻结 Live2D，继续 SpriteKit 主线。

## V2 — 跨设备陪伴

- [ ] 使用 WatchConnectivity 同步当前心情与最近一句话
- [ ] 增加 WidgetKit / complication 的只读状态
- [ ] 评估 CloudKit 是否真的需要
- [ ] 在不引入登录系统的前提下同步偏好

## 暂不进入范围

- 数值衰减、死亡、连续签到
- 等级、经验、进化、技能树
- 商店、货币、抽卡
- 排行榜、公会、PVP
- 需要每日维护的任务系统
