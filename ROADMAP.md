# VirtualPet 项目发展路线图

> **文档版本**: v1.0
> **最后更新**: 2025-02-11
> **当前版本**: v0.5.0 (Alpha)

---

## 📋 项目现状分析

### 已有功能

#### 核心玩法
- ✅ **宠物养成系统**: 喂食、玩耍、清洁、运动、拥抱、训练、管教、夸奖、学习(9种互动)
- ✅ **进化系统**: 7阶段进化(蛋→幼体→成长期→青春期→成年→长者→传说),5条进化路径
- ✅ **成就系统**: 12个预设成就
- ✅ **天气系统**: 5种天气类型,影响游戏机制
- ✅ **技能系统**: 8种宠物技能,最大等级5
- ✅ **迷你游戏**: 3种迷你游戏(觅食大作战、记忆翻翻看、玩具接接乐)
- ✅ **生命周期系统**: 出生、成长、死亡、重生机制
- ✅ **特质系统**: 12种个性特质,可传承

#### 技术架构
- **语言**: Swift 5.0
- **框架**: SwiftUI (iOS 26.2+, macOS 26.1+, visionOS 26.2)
- **数据持久化**: UserDefaults
- **架构模式**: MVVM
- **第三方依赖**: 无(纯原生开发)

#### 代码质量评估

**ContentView.swift** (~2400 行)
- ⚠️ 文件过大,需模块化拆分
- ✅ UI组件化良好
- ⚠️ 动画逻辑与视图耦合
- ⚠️ 缺少单元测试

**Pet.swift** (~2050 行)
- ✅ 业务逻辑完整
- ⚠️ 单一类承担过多职责
- ⚠️ 状态管理可优化
- ⚠️ 测试覆盖率几乎为0

#### 用户体验
- ✅ 界面美观,动画流畅
- ❌ 缺少新手引导
- ❌ 缺少设置页面
- ❌ 缺少音效和背景音乐
- ❌ 活动记录缺少筛选功能
- ⚠️ 长期留存动力不足

---

## 🎯 发展路线图

### Phase 1: 基础完善 (高优先级)
**目标**: 稳定核心体验,建立质量基线
**预估工时**: 80-100 小时
**依赖**: 无

#### 1.1 测试覆盖和质量保障 (P0) - 20h
- [ ] **单元测试框架搭建**
  - 配置 XCTest 测试环境
  - 为 Pet 类核心方法编写测试
  - 覆盖率目标: 70%+
  - **技术要点**: 使用 `@testable import`, Mock 对象, XCTest 断言
  - **验证方式**: `swift test --enable-code-coverage`

- [ ] **UI 测试**
  - 关键用户流程自动化测试
  - 测试场景: 新手引导、互动流程、进化动画
  - **技术要点**: XCUITest, Accessibility Identifiers
  - **验证方式**: `xcodebuild test -scheme VirtualPet`

- [ ] **Bug 修复和边界情况处理**
  - 修复数值溢出问题
  - 处理极端边界值
  - 增加错误日志和崩溃报告
  - **技术要点**: 断言、防御性编程、Crashlytics 集成
  - **验证方式**: 压力测试、Monkey Testing

#### 1.2 性能优化 (P0) - 15h
- [ ] **ContentView 模块化拆分**
  - 拆分为独立视图文件
  - 提取可复用组件
  - 目录结构重构
  - **技术要点**: 单一职责原则、协议抽象、依赖注入
  - **目标文件**:
    ```
    Views/
    ├── Pet/ (宠物相关)
    ├── Status/ (状态显示)
    ├── Interaction/ (交互)
    ├── MiniGame/ (迷你游戏)
    └── Components/ (通用组件)
    ```

- [ ] **Pet 类重构**
  - 拆分服务层(WeatherService, EvolutionService, SkillService)
  - 使用 Repository 模式管理数据
  - 状态机模式管理生命周期
  - **技术要点**: SOLID 原则、设计模式
  - **架构设计**:
    ```swift
    PetCoordinator (协调器)
    ├── PetStateManager (状态管理)
    ├── EvolutionService (进化)
    ├── WeatherService (天气)
    └── AchievementService (成就)
    ```

- [ ] **渲染性能优化**
  - 减少重绘次数
  - 使用 `@State` vs `@Binding` vs `@ObservedObject` 优化
  - LazyVStack/LazyHStack 优化列表
  - **技术要点**: SwiftUI 性能分析工具、Instruments Time Profiler
  - **性能目标**: 60fps 稳定运行

#### 1.3 存档系统改进 (P1) - 12h
- [ ] ** CoreData 迁移**
  - 从 UserDefaults 迁移到 CoreData
  - 支持多宠物存档
  - 数据版本管理和迁移
  - **技术要点**: NSManagedObject, NSPersistentContainer, 数据迁移策略
  - **实现示例**:
    ```swift
    // PetEntity CoreData 模型
    entity PetEntity {
      id: UUID
      name: String
      hunger: Int16
      happiness: Int16
      // ... 其他属性
    }
    ```

- [ ] **存档管理界面**
  - 多存档槽位(3个)
  - 自动存档时间戳
  - 存档预览功能
  - **技术要点**: File I/O, Snapshot 生成
  - **UI 组件**: SaveGameListView, SaveGameSlotView

- [ ] **导出/导入存档**
  - JSON 格式导出
  - 分享存档功能
  - 跨设备同步(可选)
  - **技术要点**: Codable, UIDocumentInteractionController, iCloud Drive
  - **验证方式**: 导入导出数据完整性校验

#### 1.4 音效和简单动画 (P1) - 15h
- [ ] **音效系统**
  - AVAudioPlayer 播放音效
  - 15-20 种互动音效
  - 音量控制和静音选项
  - **音效清单**:
    - 喂食、玩耍、清洁、运动、拥抱
    - 进化、升级、成就解锁
    - 天气变化、随机事件
  - **技术要点**: AVFoundation, 资源管理, 内存优化
  - **文件格式**: MP3/CAF (压缩),采样率 44.1kHz

- [ ] **动画增强**
  - Lottie 动画集成(可选)
  - 自转、缩放、位移动画
  - 粒子效果优化
  - **技术要点**: AnimationModifier, GeometryEffect, Metal 粒子系统
  - **性能优化**: 粒子池、对象复用

#### 1.5 设置页面 (P1) - 10h
- [ ] **SettingsView 实现**
  - 音效开关/音量控制
  - 震动反馈开关
  - 自动存档频率设置
  - 语言切换(未来)
  - **技术要点**: @AppStorage, Settings Link, 用户偏好存储
  - **实现要点**:
    ```swift
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoSaveInterval") private var saveInterval = 300
    ```

- [ ] **通知权限请求**
  - 宠物状态提醒
  - 定时喂食提醒
  - 特殊事件通知
  - **技术要点**: UNUserNotificationCenter, 权限请求流程
  - **通知类型**:
    - 宠物生病提醒
    - 饥饿度警告
    - 进化完成通知
    - 每日任务提醒

#### 1.6 新手引导 (P0) - 18h
- [ ] **OnboardingFlow 设计**
  - 5 步引导流程
  - 交互式教程
  - 跳过选项
  - **引导内容**:
    1. 欢迎界面和宠物蛋选择
    2. 基础互动教学(喂食、玩耍)
    3. 状态监控说明
    4. 进化和路径选择
    5. 天气和技能介绍
  - **技术要点**: OnboardingCoordinator, UserDefaults 完成标记
  - **UI 组件**: OnboardingView, TutorialOverlayView

- [ ] **帮助系统**
  - 内置 FAQ (10-15 个常见问题)
  - 互动提示系统
  - 长按手势显示详情
  - **技术要点**: HelpViewController, 动态提示生成
  - **内容示例**:
    - Q: 如何快速增加亲密度?
    - A: 多进行拥抱和夸奖互动,选择快乐型进化路径

**Phase 1 完成标准**:
- 测试覆盖率 ≥ 70%
- 所有 P0 任务完成
- 性能稳定在 60fps
- 用户留存率 > 60% (Day 1)

---

### Phase 2: 核心玩法扩展
**目标**: 增加游戏深度和长期可玩性
**预估工时**: 120-150 小时
**依赖**: Phase 1 完成

#### 2.1 每日任务系统 (P0) - 20h
- [ ] **DailyTaskManager 实现**
  - 每日 3-5 个随机任务
  - 任务难度分级(简单/普通/困难)
  - 连续完成奖励
  - **任务示例**:
    - 完成 5 次喂食 (奖励: 50 经验, 10 钻石)
    - 让宠物快乐度达到 90+ (奖励: 1 技能点)
    - 玩 2 次迷你游戏 (奖励: 20 钻石)
    - 连续 3 天登录 (奖励: 传说宝箱)
  - **技术要点**: Date 重置逻辑、任务生成算法、持久化
  - **数据结构**:
    ```swift
    struct DailyTask: Identifiable, Codable {
      let id: UUID
      let title: String
      let description: String
      let requirement: TaskRequirement
      var progress: Int
      let target: Int
      let rewards: TaskRewards
      let difficulty: TaskDifficulty
      let expiryDate: Date
    }
    ```

- [ ] **DailyTaskView UI**
  - 任务列表展示
  - 进度条动画
  - 一键领取奖励
  - **技术要点**: TimelineView, 动画效果
  - **视觉设计**: 卡片式布局、渐变进度条

- [ ] **任务奖励机制**
  - 经验值、钻石、道具
  - 特殊货币(钻石)系统
  - 连续签到奖励
  - **奖励池设计**:
    ```
    Day 1-3: 普通道具
    Day 4-6: 稀有道具
    Day 7: 传说宝箱
    ```

#### 2.2 商店系统 (P0) - 25h
- [ ] **商店核心逻辑**
  - 物品管理系统
  - 货币系统(金币/钻石)
  - 购买和消耗逻辑
  - **商品分类**:
    - 食物: 普通食物、美味食物、健康食物、高级食物、特殊食物
    - 道具: 能量药水、快乐糖果、清洁喷雾
    - 装饰品: 项圈、帽子、衣服
    - 特殊物品: 进化石、技能书
  - **技术要点**: InventoryManager, 交易验证、货币同步
  - **数据结构**:
    ```swift
    struct ShopItem: Identifiable, Codable {
      let id: UUID
      let name: String
      let description: String
      let icon: String
      let price: ItemPrice
      let category: ItemCategory
      let stock: Int?
      let discount: Double?
    }
    ```

- [ ] **ShopView 实现**
  - 分类标签页
  - 商品详情页
  - 购买确认对话框
  - **技术要点**: TabView, Sheet 展示, 动画过渡
  - **UI 组件**: ShopItemCard, CheckoutView

- [ ] **货币获取渠道**
  - 完成每日任务
  - 迷你游戏奖励
  - 成就解锁
  - 看广告获得(可选,谨慎设计)
  - **平衡性**: 避免付费墙,保证免费可玩性

#### 2.3 迷你游戏扩充 (P1) - 30h
- [ ] **新增 5 种迷你游戏**
  - **猜拳游戏**: 简单的石头剪刀布
  - **接球游戏**: 类似打地鼠
  - **记忆翻牌**: 卡片配对游戏(3x3, 4x4, 5x5)
  - **节奏游戏**: 简单的音乐节拍
  - **拼图游戏**: 滑动拼图
  - **技术要点**: 游戏引擎基础、状态机、分数计算
  - **性能优化**: 游戏预热、资源复用

- [ ] **MiniGameManager 重构**
  - 统一的游戏接口
  - 难度动态调整
  - 排行榜功能
  - **技术要点**: 协议抽象、策略模式
  - **接口设计**:
    ```swift
    protocol MiniGame {
      var name: String { get }
      var icon: String { get }
      var cooldownMinutes: Int { get }

      func start() -> MiniGameSession
      func calculateScore(session: MiniGameSession) -> Int
    }
    ```

- [ ] **游戏大厅 UI**
  - 游戏选择界面
  - 冷却时间显示
  - 奖励预览
  - **技术要点**: Grid 布局、动画效果

#### 2.4 技能系统完善 (P1) - 20h
- [ ] **被动技能效果**
  - 技能自动触发逻辑
  - 技能组合效果
  - 视觉反馈
  - **实现技能**:
    - 音乐天赋: 亲密度增长加成
    - 运动健将: 能量恢复加成
    - 学霸: 训练经验加成
    - 社交达人: 生病概率降低
  - **技术要点**: 观察者模式、事件驱动、技能触发器

- [ ] **技能树可视化**
  - 技能依赖关系图
  - 解锁路径动画
  - **技术要点**: 图形绘制、路径动画
  - **实现方案**: Canvas + 自定义节点视图

- [ ] **技能点获取优化**
  - 升级获得技能点
  - 特殊事件奖励
  - 成就解锁
  - **平衡性调整**:
    - 每 5 级获得 1 技能点
    - 完成困难任务获得额外技能点

#### 2.5 互动系统扩展 (P2) - 15h
- [ ] **新增互动类型**
  - 训练: 提升训练等级
  - 管教: 降低亲密度,改变性格
  - 夸奖: 提升亲密度和快乐
  - 学习: 获得大量经验
  - **技术要点**: 互动验证、结果计算
  - **效果调优**: 基于数值平衡

- [ ] **互动动画升级**
  - 更丰富的反馈动画
  - 特效组合
  - 音效配合
  - **技术要点**: 组合动画、时序控制

**Phase 2 完成标准**:
- 至少 8 种迷你游戏
- 用户平均游戏时长 > 15 分钟/会话
- 日活跃用户留存率 > 40%
- 任务完成率 > 70%

---

### Phase 3: 社交和内容
**目标**: 增加社交互动,扩展内容广度
**预估工时**: 150-200 小时
**依赖**: Phase 2 完成

#### 3.1 多宠物支持 (P0) - 35h
- [ ] **PetCollectionManager 实现**
  - 支持 3-5 个宠物同时饲养
  - 宠物切换界面
  - 宠物互动系统
  - **技术要点**: 集合管理、状态同步、内存优化
  - **数据结构**:
    ```swift
    class PetCollectionManager: ObservableObject {
      @Published var pets: [Pet] = []
      @Published var activePetId: UUID?

      func addPet(_ pet: Pet)
      func removePet(id: UUID)
      func switchPet(id: UUID)
    }
    ```

- [ ] **宠物互动系统**
  - 宠物之间的互动
  - 好友系统
  - 互动历史记录
  - **互动类型**:
    - 玩耍: 提升双方快乐度
    - 交换礼物
    - 聊天(简单对话系统)
  - **技术要点**: 关系图、事件系统

- [ ] **PetSelectorView UI**
  - 宠物卡片展示
  - 快速切换动画
  - 状态概览
  - **UI 设计**: 横向滚动卡片、状态徽章

#### 3.2 宠物社交系统 (P1) - 40h
- [ ] **好友系统**
  - 添加/删除好友
  - 好友列表界面
  - 好友状态显示
  - **技术要点**:
    - 本地好友: 直接设备配对
    - 远程好友: Game Center / CloudKit (Phase 4)
  - **隐私设计**: 隐身模式、互动限制

- [ ] **社交互动**
  - 访问好友宠物
  - 送礼物功能
  - 留言/访客记录
  - **技术要点**: 权限管理、消息队列
  - **限制设计**:
    - 每日送礼上限
    - 冷却时间
    - 互惠机制

- [ ] **SocialHubView**
  - 好友动态流
  - 互动请求列表
  - 社交统计
  - **技术要点**: TimelineView、下拉刷新

#### 3.3 收集图鉴 (P1) - 25h
- [ ] **PetEncyclopedia 系统**
  - 已发现宠物记录
  - 进化路径树
  - 统计数据
  - **技术要点**: 数据收集、分类系统
  - **数据结构**:
    ```swift
    struct PetEntry: Identifiable, Codable {
      let id: UUID
      let petType: PetType
      let evolutionPath: EvolutionPath?
      let maxLevel: Int
      let discoveredDate: Date
      let playTime: Int
      var notes: String
      var screenshots: [Data]
    }
    ```

- [ ] **EncyclopediaView UI**
  - 图鉴网格展示
  - 详情页展示
  - 搜索和筛选
  - **技术要点**: Grid 布局、搜索过滤
  - **视觉设计**: 卡片翻转效果、解锁动画

- [ ] **成就和奖励**
  - 收集完成奖励
  - 稀有发现庆祝
  - **特殊解锁条件**:
    - 收集全部 5 种宠物类型
    - 每种宠物达到传说阶段
    - 解锁全部进化路径

#### 3.4 装扮系统 (P2) - 30h
- [ ] **AccessoryManager 实现**
  - 服装/饰品管理
  - 装备和卸载
  - 视觉叠加渲染
  - **饰品分类**:
    - 头部: 帽子、眼镜、头饰
    - 颈部: 项圈、领带
    - 身体: 衣服、背包
  - **技术要点**: Z-index 层级管理、碰撞检测
  - **数据结构**:
    ```swift
    struct Accessory: Identifiable, Codable {
      let id: UUID
      let name: String
      let icon: String
      let category: AccessoryCategory
      let rarity: ItemRarity
      let assetName: String
      let position: CGPoint
      let zIndex: Double
    }
    ```

- [ ] **WardrobeView**
  - 衣柜界面
  - 试穿预览
  - 装备搭配
  - **技术要点**: 拖放、图层合成

- [ ] **饰品获取渠道**
  - 商店购买
  - 活动奖励
  - 迷你游戏掉落
  - **稀有度系统**: 普通、稀有、史诗、传说

**Phase 3 完成标准**:
- 支持至少 3 个宠物同时饲养
- 社交功能使用率 > 30%
- 图鉴完成率 > 50%
- 装饰品数量 ≥ 50 个

---

### Phase 4: 高级功能
**目标**: 提升产品品质,增加留存机制
**预估工时**: 100-130 小时
**依赖**: Phase 3 完成

#### 4.1 主题和皮肤 (P1) - 25h
- [ ] **ThemeManager 实现**
  - 5-8 种主题配色
  - 自定义主题编辑器
  - 主题预览
  - **预设主题**:
    - 默认(蓝色系)
    - 温暖(橙色系)
    - 清新(绿色系)
    - 暗黑(深色模式)
    - 可爱(粉色系)
  - **技术要点**: ColorPalette, Environment Values
  - **实现方案**:
    ```swift
    struct AppTheme {
      let primary: Color
      let secondary: Color
      let accent: Color
      let background: Color
      let surface: Color
    }
    ```

- [ ] **主题切换 UI**
  - 主题选择界面
  - 实时预览
  - 自定义颜色选择器
  - **技术要点**: ColorPicker, 实时绑定

- [ ] **宠物皮肤系统**
  - 不同外观样式
  - 特殊节日皮肤
  - **皮肤类型**: 默认、经典、卡通、像素、3D

#### 4.2 音效和背景音乐 (P0) - 20h
- [ ] **背景音乐系统**
  - 3-5 首背景曲目
  - 平滑淡入淡出
  - 音乐切换时机
  - **技术要点**: AVAudioPlayer, 淡入淡出算法, 循环播放
  - **音乐风格**: 轻快、温馨、治愈

- [ ] **音效库扩充**
  - 增加到 50+ 种音效
  - 动态音量控制
  - 音效组合系统
  - **音效分类**:
    - 互动音效(15种)
    - 环境音效(10种)
    - UI 音效(10种)
    - 特殊音效(15种)

- [ ] **音频设置优化**
  - 独立音量控制
  - 音频预设(标准、安静、生动)
  - 空间音频支持(可选)

#### 4.3 云存档同步 (P2) - 30h
- [ ] **CloudKit 集成**
  - iCloud 自动同步
  - 冲突解决策略
  - 离线模式支持
  - **技术要点**: CKRecord, CKQuery, CloudKit Dashboard
  - **同步策略**:
    - 实时同步: 关键数据变更
    - 定时同步: 每 5 分钟检查
    - 手动同步: 用户主动触发

- [ ] **跨设备同步**
  - iPhone/iPad/Mac 同步
  - 数据迁移工具
  - 同步状态指示器
  - **技术要点**: 设备配对、数据验证
  - **限制设计**:
    - 最多 3 台设备
    - 每日同步流量限制

- [ ] **同步管理 UI**
  - 同步设置
  - 冲突解决界面
  - 同步日志
  - **技术要点**: ProgressView, Alert 设计

#### 4.4 推送通知 (P1) - 25h
- [ ] **通知系统实现**
  - 宠物状态提醒
  - 定时喂食提醒
  - 特殊事件通知
  - **通知类型**:
    - 生病提醒
    - 饥饿警告
    - 进化完成
    - 每日任务重置
    - 特殊节日活动
  - **技术要点**: UNNotificationRequest, UNMutableNotificationContent
  - **实现示例**:
    ```swift
    func scheduleNotification(title: String, body: String, delay: TimeInterval) {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
      let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

      UNUserNotificationCenter.current().add(request)
    }
    ```

- [ ] **通知权限管理**
  - 优雅的权限请求
  - 通知设置引导
  - 通知分类管理
  - **技术要点**: 权限请求流程、设置跳转

- [ ] **通知内容优化**
  - 可操作通知(动作按钮)
  - 通知分组
  - 自定义声音
  - **技术要点**: UNNotificationCategory, UNNotificationAction

**Phase 4 完成标准**:
- 至少 5 种主题
- 完整音效库(50+ 音效)
- 云同步功能可用
- 通知送达率 > 90%

---

### Phase 5: 内容丰富化
**目标**: 保持内容新鲜度,提升长期留存
**预估工时**: 80-100 小时
**依赖**: Phase 4 完成

#### 5.1 节日活动 (P0) - 30h
- [ ] **SeasonEventManager 实现**
  - 节日时间判定
  - 专属内容解锁
  - 活动商店
  - **节日列表**:
    - 春节(中国新年主题)
    - 情人节(爱情主题)
    - 复活节(春季主题)
    - 儿童节(童趣主题)
    - 中秋节(月亮主题)
    - 万圣节(南瓜主题)
    - 圣诞节(雪景主题)
  - **技术要点**: 日期计算、活动触发器、内容包管理
  - **实现方案**:
    ```swift
    struct SeasonEvent {
      let id: String
      let name: String
      let startDate: Date
      let endDate: Date
      let theme: EventTheme
      let exclusiveItems: [ShopItem]
      let specialTasks: [DailyTask]
    }
    ```

- [ ] **节日主题切换**
  - UI 主题自动切换
  - 特殊宠物外观
  - 节日专属物品
  - **技术要点**: 动态资源加载、主题引擎

- [ ] **节日专属任务**
  - 限时挑战
  - 成就解锁
  - **奖励设计**:
    - 传说宠物皮肤
    - 稀有饰品
    - 大量钻石

#### 5.2 特殊事件系统 (P1) - 20h
- [ ] **RandomEventManager 扩充**
  - 增加事件类型到 20+
  - 事件链系统
  - 条件触发事件
  - **事件分类**:
    - 幸运事件(10种)
    - 挑战事件(5种)
    - 剧情事件(5种)
  - **技术要点**: 事件引擎、条件判断、概率加权

- [ ] **剧情模式**
  - 5-10 个剧情章节
  - 选择分支
  - 剧情成就
  - **技术要点**: 故事引擎、分支系统
  - **实现示例**:
    ```swift
    struct StoryEvent {
      let id: String
      let title: String
      let narrative: String
      let choices: [StoryChoice]
    }

    struct StoryChoice {
      let text: String
      let consequences: (Pet) -> Void
      let nextEventId: String?
    }
    ```

- [ ] **特殊挑战**
  - Boss 挑战
  - 限时活动
  - 排行榜竞争

#### 5.3 成就系统扩展 (P1) - 15h
- [ ] **新增成就类型**
  - 隐藏成就(20个)
  - 统计成就(15个)
  - 特殊成就(10个)
  - **总成就数目标**: 60-80 个
  - **技术要点**: 成就触发器、进度追踪

- [ ] **成就奖励优化**
  - 解锁特殊宠物
  - 获得独有饰品
  - 解锁新功能
  - **奖励设计**:
    - 收集 50% 成就: 解锁新宠物类型
    - 收集 80% 成就: 解锁传说宠物
    - 收集 100% 成就: 解锁开发者称号

- [ ] **成就 UI 改进**
  - 成就树可视化
  - 进度追踪
  - 分享功能

#### 5.4 游戏平衡性调整 (P0) - 15h
- [ ] **数值系统重构**
  - 平衡性数据分析
  - 难度曲线调整
  - A/B 测试框架
  - **关键指标**:
    - 用户留存率
    - 平均游戏时长
    - 任务完成率
    - 付费转化率(如果有)
  - **技术要点**: 数据收集、分析工具、平衡性计算

- [ ] **游戏节奏优化**
  - 早期体验优化
  - 中期目标引导
  - 长期动力机制
  - **设计原则**:
    - 前 10 分钟: 快速上手
    - 前 1 小时: 核心玩法体验
    - 第一周: 深度内容探索
    - 长期: 收集和社交

**Phase 5 完成标准**:
- 每年至少 7 个节日活动
- 成就总数 ≥ 60 个
- 剧情章节 ≥ 5 章
- 7 日留存率 > 50%

---

## 📊 优先级定义

| 优先级 | 定义 | 响应时间 | 示例 |
|--------|------|----------|------|
| **P0** | 核心功能,必须实现 | 2 周 | 测试覆盖、性能优化、新手引导 |
| **P1** | 重要功能,影响体验 | 1 个月 | 音效、商店、社交系统 |
| **P2** | 增强功能,锦上添花 | 2 个月 | 主题装扮、云同步、节日活动 |

---

## 🛠️ 技术债务清单

### 高优先级
- [ ] ContentView.swift 模块化拆分
- [ ] Pet.swift 职责分离
- [ ] 单元测试覆盖
- [ ] CoreData 迁移
- [ ] 内存泄漏修复

### 中优先级
- [ ] 动画性能优化
- [ ] 存档系统重构
- [ ] 错误处理完善
- [ ] 日志系统建立

### 低优先级
- [ ] 代码注释补充
- [ ] 文档完善
- [ ] 示例代码优化

---

## 🎨 设计规范

### 视觉设计
- **配色方案**: 柔和色调为主,避免高饱和度
- **图标风格**: SF Symbols, 统一线条粗细
- **动画原则**: 流畅自然,避免过度动画
- **字体**: 系统 San Francisco 字体,保持一致性

### 交互设计
- **手势操作**: 点按、长按、拖动、滑动
- **反馈机制**: 即时触觉反馈、视觉反馈、音效反馈
- **加载状态**: 进度条、骨架屏、Loading 动画
- **错误提示**: 友好语言,解决建议,避免技术术语

---

## 📈 成功指标 (KPI)

### 用户指标
- **DAU/MAU 比率**: 目标 > 25%
- **用户留存率**:
  - Day 1: > 60%
  - Day 7: > 40%
  - Day 30: > 20%
- **平均会话时长**: > 15 分钟
- **用户满意度**: > 4.5/5.0

### 业务指标
- **付费转化率**: > 5% (如果有 IAP)
- **ARPU**: > $2.00/月
- **推荐率 (NPS)**: > 50

### 技术指标
- **崩溃率**: < 0.5%
- **ANR 率**: < 0.1%
- **启动时间**: < 2 秒
- **帧率**: 稳定 60fps

---

## 🔄 迭代节奏

### 开发周期
- **Sprint 长度**: 2 周
- **发布频率**: 每 4 周
- **版本规划**:
  - v0.6.0: Phase 1 完成 (基础完善)
  - v0.7.0: Phase 2 完成 (玩法扩展)
  - v0.8.0: Phase 3 完成 (社交内容)
  - v0.9.0: Phase 4 完成 (高级功能)
  - v1.0.0: Phase 5 完成 (正式发布)

### 质量保证
- **代码审查**: 每个 PR 必须 Review
- **测试要求**: 新代码测试覆盖率 ≥ 80%
- **性能测试**: 每次发布前性能基准测试
- **Beta 测试**: 每个 Phase 完成后内部测试 1 周

---

## 📚 附录

### A. 依赖技术栈
- **Xcode**: 16.0+
- **Swift**: 5.0+
- **iOS Deployment Target**: 26.2+
- **Framework**: SwiftUI, Combine, AVFoundation, CoreData
- **Testing**: XCTest, XCUITest

### B. 第三方库评估
虽然当前无第三方依赖,未来可考虑:
- **Lottie**: 动画增强
- **Charts**: 数据可视化
- **Kingfisher**: 图片缓存(如果增加网络图片)
- **KeychainAccess**: 安全存储

### C. 平台扩展计划
- **iPad**: 适配多任务、分屏
- **Mac Catalyst**: 桌面版本
- **visionOS**: 空间计算版本(Phase 6)

---

## 🎯 总结

本路线图提供了 VirtualPet 从 Alpha 到正式发布的完整发展路径。关键要点:

1. **优先级明确**: 基础完善 > 核心玩法 > 社交内容 > 高级功能 > 内容丰富
2. **质量优先**: 测试覆盖和性能优化是 Phase 1 的核心
3. **用户体验**: 新手引导和音效对早期留存至关重要
4. **长期价值**: 社交和收集系统是长期留存的关键
5. **技术债务**: 及时重构,避免累积

**预计总工时**: 530-680 小时
**预计发布时间**: 6-9 个月(单人开发) 或 3-4 个月(2-3 人团队)

---

*文档维护: 请在每次迭代后更新进度和预估时间*
