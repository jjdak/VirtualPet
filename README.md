# VirtualPet

<div align="center">
  <div id="language-toggle">
    <button onclick="setLanguage('zh')" id="zh-btn" class="lang-btn active">中文</button>
    <button onclick="setLanguage('en')" id="en-btn" class="lang-btn">English</button>
  </div>
</div>

<style>
  .lang-btn {
    padding: 8px 16px;
    margin: 0 5px;
    border: 2px solid #2196F3;
    background: white;
    color: #2196F3;
    border-radius: 20px;
    cursor: pointer;
    font-weight: bold;
    transition: all 0.3s ease;
  }

  .lang-btn.active {
    background: #2196F3;
    color: white;
  }

  .lang-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
  }
</style>

<script>
  function setLanguage(lang) {
    const zhContent = document.getElementById('zh-content');
    const enContent = document.getElementById('en-content');
    const zhBtn = document.getElementById('zh-btn');
    const enBtn = document.getElementById('en-btn');

    if (lang === 'zh') {
      zhContent.style.display = 'block';
      enContent.style.display = 'none';
      zhBtn.classList.add('active');
      enBtn.classList.remove('active');
    } else {
      zhContent.style.display = 'none';
      enContent.style.display = 'block';
      zhBtn.classList.remove('active');
      enBtn.classList.add('active');
    }

    // Save preference
    localStorage.setItem('preferredLanguage', lang);
  }

  // Load saved preference
  document.addEventListener('DOMContentLoaded', function() {
    const savedLang = localStorage.getItem('preferredLanguage') || 'zh';
    setLanguage(savedLang);
  });
</script>

<div id="zh-content">

### 🐾 宠物模拟
- **5种宠物类型**: 可选择5种不同颜色的宠物
- **心情系统**: 7种不同心情状态（开心、正常、饥饿、悲伤、生病、兴奋、困倦）
- **属性管理**: 追踪饥饿度、快乐度、健康度和能量值（0-100范围）
- **年龄系统**: 宠物会随着年龄增长而发展

### 🎮 互动游戏
- **5种互动**: 喂食、玩耍、清理、运动和拥抱你的宠物
- **实时属性**: 属性每分钟自动衰减，增加真实感
- **经验值与等级**: 通过互动获得经验值并升级
- **等级奖励**: 每个等级提供+20健康值奖励

### 🏆 成就系统
- **4个预设成就**: 通过各种互动解锁成就
- **活动记录**: 带时间戳的所有互动记录
- **进度追踪**: 监控宠物的旅程和里程碑

### 🎨 视觉设计
- **动态UI**: 基于心情的视觉反馈和样式
- **流畅动画**: 所有互动的弹簧动画效果
- **粒子特效**: 互动的视觉反馈
- **活动日志**: 查看互动历史
- **快速统计**: 一目了然的状态概览

## English

A modern iOS virtual pet application built with SwiftUI and Swift 5.0. The app features a comprehensive pet simulation system with mood tracking, achievements, level progression, and rich visual animations.

### 🐾 Pet Simulation
- **5 Pet Types**: Choose from 5 different pet types with unique colors
- **Mood System**: 7 different mood states (happy, normal, hungry, sad, sick, excited, sleepy)
- **Stats Management**: Track hunger, happiness, health, and energy (0-100 scale)
- **Age System**: Pets age over time with visual progression

### 🎮 Interactive Gameplay
- **5 Interactions**: Play, feed, clean, exercise, and cuddle your pet
- **Real-time Stats**: Stats decay automatically every minute for realism
- **Experience & Levels**: Gain XP from interactions and level up
- **Level Bonuses**: Each level grants +20 health bonus

### 🏆 Achievement System
- **4 Predefined Achievements**: Unlock achievements through various interactions
- **Activity Logging**: Track all interactions with timestamps
- **Progress Tracking**: Monitor your pet's journey and milestones

### 🎨 Visual Design
- **Dynamic UI**: Mood-based visual feedback and styling
- **Smooth Animations**: Spring-based animations for all interactions
- **Particle Effects**: Visual feedback for interactions
- **Activity Log**: View interaction history
- **Quick Stats**: At-a-glance status overview

## Architecture

### 🐾 Pet Simulation
- **5 Pet Types**: Choose from 5 different pet types with unique colors
- **Mood System**: 7 different mood states (happy, normal, hungry, sad, sick, excited, sleepy)
- **Stats Management**: Track hunger, happiness, health, and energy (0-100 scale)
- **Age System**: Pets age over time with visual progression

### 🎮 Interactive Gameplay
- **5 Interactions**: Play, feed, clean, exercise, and cuddle your pet
- **Real-time Stats**: Stats decay automatically every minute for realism
- **Experience & Levels**: Gain XP from interactions and level up
- **Level Bonuses**: Each level grants +20 health bonus

### 🏆 Achievement System
- **4 Predefined Achievements**: Unlock achievements through various interactions
- **Activity Logging**: Track all interactions with timestamps
- **Progress Tracking**: Monitor your pet's journey and milestones

### 🎨 Visual Design
- **Dynamic UI**: Mood-based visual feedback and styling
- **Smooth Animations**: Spring-based animations for all interactions
- **Particle Effects**: Visual feedback for interactions
- **Activity Log**: View interaction history
- **Quick Stats**: At-a-glance status overview

## Architecture

### 核心组件

- **Pet.swift**: 中央业务逻辑和数据模型
  - 继承自 `ObservableObject` 的主 `Pet` 类
  - 管理所有宠物状态和互动
  - 实现自动属性衰减
  - 带持久化的成就系统

- **ContentView.swift**: 主要UI组成
  - 具有多种子视图的模块化SwiftUI视图
  - 使用SwiftUI状态管理的响应式更新
  - 清晰的关注点分离

- **VirtualPetApp.swift**: 应用入口点
  - 标准的 SwiftUI `@main` 应用结构

### 设计模式

- **MVVM架构**: 视图绑定到ViewModel/Model
- **状态管理**: 使用 `@Published` 属性的SwiftUI响应式状态
- **事件驱动**: 用户互动触发状态更新
- **数据持久化**: UserDefaults 用于核心属性

## 构建和开发

### 前置要求
- Xcode 15.0 或更高版本
- iOS 26.2 或更高版本（最低部署目标）

### 构建和运行

```bash
# 构建项目
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# 在模拟器上运行
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# 在设备上运行（替换为实际设备ID）
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### 测试

```bash
# 运行单元测试
swift test

# 通过Xcode运行单元测试
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# 运行UI测试
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### 代码检查

```bash
# SwiftLint（如果可用）
swiftlint lint --strict

# 构建时语法检查
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
```

### Core Components

- **Pet.swift**: Central business logic and data model
  - Main `Pet` class inheriting from `ObservableObject`
  - Manages all pet state and interactions
  - Implements automatic stat decay
  - Achievement system with persistence

- **ContentView.swift**: Main UI composition
  - Modular SwiftUI view with multiple sub-views
  - Reactive updates using SwiftUI's state management
  - Clean separation of concerns

- **VirtualPetApp.swift**: App entry point
  - Standard SwiftUI `@main` app structure

### Design Patterns

- **MVVM Architecture**: View binds to ViewModel/Model
- **State Management**: SwiftUI reactive state with `@Published` properties
- **Event-Driven**: User interactions trigger state updates
- **Data Persistence**: UserDefaults for core stats

## Build and Development

### Prerequisites
- Xcode 15.0 or later
- iOS 26.2 or later (minimum deployment target)

### Building and Running

```bash
# Build the project
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# Run on simulator
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Run on device (replace with actual device ID)
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### Testing

```bash
# Run unit tests
swift test

# Run unit tests via Xcode
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Linting

```bash
# SwiftLint (if available)
swiftlint lint --strict

# Build-time syntax checking
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
```

## Build and Development

### Prerequisites
- Xcode 15.0 or later
- iOS 26.2 or later (minimum deployment target)

### Building and Running

```bash
# Build the project
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# Run on simulator
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Run on device (replace with actual device ID)
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### Testing

```bash
# Run unit tests
swift test

# Run unit tests via Xcode
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Linting

```bash
# SwiftLint (if available)
swiftlint lint --strict

# Build-time syntax checking
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
```

## 游戏机制

### 属性系统
- 所有属性范围在0-100之间
- 自动衰减：饥饿度+1，快乐度-1，能量-2每分钟
- 互动同时影响多个属性

### 心情计算
- 基于属性阈值的7种心情状态
- 每次互动后动态更新心情
- 通过UI变化提供视觉反馈

### 进阶系统
- 通过互动获得经验值
- 每`等级 * 100`经验值升级
- 等级奖励：+20健康值

## Game Mechanics

### Stat System
- All stats range from 0-100
- Automatic decay: hunger +1, happiness -1, energy -2 per minute
- Interactions affect multiple stats simultaneously

### Mood Calculation
- 7 mood states based on stat thresholds
- Dynamic mood updates after each interaction
- Visual feedback through UI changes

### Progression System
- Experience points from interactions
- Level up every `level * 100` experience
- Level bonuses: +20 health

## 数据结构

### PetMood 枚举
```swift
enum PetMood: CaseIterable {
    case happy, normal, hungry, sad, sick, excited, sleepy
}
```

### PetType 枚举
```swift
enum PetType: CaseIterable {
    case dog, cat, rabbit, hamster, bird
}
```

### Activity
带时间戳和值的互动历史

### Achievement
带解锁条件的成就系统

## Data Structures

### PetMood Enum
```swift
enum PetMood: CaseIterable {
    case happy, normal, hungry, sad, sick, excited, sleepy
}
```

### PetType Enum
```swift
enum PetType: CaseIterable {
    case dog, cat, rabbit, hamster, bird
}
```

### Activity
Interaction history with timestamps and values

### Achievement
Achievement system with unlock conditions

## 截图

*(截图将添加在这里)*

## 贡献

这是一个使用 SwiftUI 进行 iOS 开发的个人学习项目。欢迎贡献！

## 许可证

本项目用于教育目的。

## 致谢

- 使用 SwiftUI 和 Swift 5.0 构建
- 针对 iOS 26.2 及更高版本设计
- 仅使用原生 Apple 框架
- 中文语言界面，基于表情符号的宠物类型
</div>

<div id="en-content" style="display: none;">
A modern iOS virtual pet application built with SwiftUI and Swift 5.0. The app features a comprehensive pet simulation system with mood tracking, achievements, level progression, and rich visual animations.

### 🐾 Pet Simulation
- **5 Pet Types**: Choose from 5 different pet types with unique colors
- **Mood System**: 7 different mood states (happy, normal, hungry, sad, sick, excited, sleepy)
- **Stats Management**: Track hunger, happiness, health, and energy (0-100 scale)
- **Age System**: Pets age over time with visual progression

### 🎮 Interactive Gameplay
- **5 Interactions**: Play, feed, clean, exercise, and cuddle your pet
- **Real-time Stats**: Stats decay automatically every minute for realism
- **Experience & Levels**: Gain XP from interactions and level up
- **Level Bonuses**: Each level grants +20 health bonus

### 🏆 Achievement System
- **4 Predefined Achievements**: Unlock achievements through various interactions
- **Activity Logging**: Track all interactions with timestamps
- **Progress Tracking**: Monitor your pet's journey and milestones

### 🎨 Visual Design
- **Dynamic UI**: Mood-based visual feedback and styling
- **Smooth Animations**: Spring-based animations for all interactions
- **Particle Effects**: Visual feedback for interactions
- **Activity Log**: View interaction history
- **Quick Stats**: At-a-glance status overview

## Architecture

### Core Components
- **Pet.swift**: Central business logic and data model
  - Main `Pet` class inheriting from `ObservableObject`
  - Manages all pet state and interactions
  - Implements automatic stat decay
  - Achievement system with persistence

- **ContentView.swift**: Main UI composition
  - Modular SwiftUI view with multiple sub-views
  - Reactive updates using SwiftUI's state management
  - Clean separation of concerns

- **VirtualPetApp.swift**: App entry point
  - Standard SwiftUI `@main` app structure

### Design Patterns
- **MVVM Architecture**: View binds to ViewModel/Model
- **State Management**: SwiftUI reactive state with `@Published` properties
- **Event-Driven**: User interactions trigger state updates
- **Data Persistence**: UserDefaults for core stats

## Build and Development

### Prerequisites
- Xcode 15.0 or later
- iOS 26.2 or later (minimum deployment target)

### Building and Running

```bash
# Build the project
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# Run on simulator
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Run on device (replace with actual device ID)
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### Testing

```bash
# Run unit tests
swift test

# Run unit tests via Xcode
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Linting

```bash
# SwiftLint (if available)
swiftlint lint --strict

# Build-time syntax checking
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
```

## Game Mechanics

### Stat System
- All stats range from 0-100
- Automatic decay: hunger +1, happiness -1, energy -2 per minute
- Interactions affect multiple stats simultaneously

### Mood Calculation
- 7 mood states based on stat thresholds
- Dynamic mood updates after each interaction
- Visual feedback through UI changes

### Progression System
- Experience points from interactions
- Level up every `level * 100` experience
- Level bonuses: +20 health

## Data Structures

### PetMood Enum
```swift
enum PetMood: CaseIterable {
    case happy, normal, hungry, sad, sick, excited, sleepy
}
```

### PetType Enum
```swift
enum PetType: CaseIterable {
    case dog, cat, rabbit, hamster, bird
}
```

### Activity
Interaction history with timestamps and values

### Achievement
Achievement system with unlock conditions

## Screenshots

*(Screenshots would be added here)*

## Contributing

This is a personal learning project for iOS development with SwiftUI. Contributions are welcome!

## License

This project is for educational purposes.

## Acknowledgments

- Built with SwiftUI and Swift 5.0
- Designed for iOS 26.2 and later
- Uses native Apple frameworks only
- Chinese language interface with emoji-based pet types
</div>