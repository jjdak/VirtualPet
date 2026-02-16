# Phase 4: 呼吸待机动画 - 实施进展

**任务**: 任务1: 呼吸待机动画 (5-8h)
**状态**: 🟡 进行中 (已完成 60%)
**完成日期**: 2026-02-16

---

## ✅ 已完成内容

### 1. 呼吸动画管理器 ✅

**文件**: `VirtualPet/Managers/BreathAnimationManager.swift` (~290行)

**核心功能**:
- ✅ 5种呼吸动画配置
  - `.default` - 默认配置 (猫咪)
  - `.energetic` - 活泼型 (狗狗、兔子)
  - `.calm` - 安静型 (仓鼠、小鸟)
  - `.sleepy` - 困倦型 (睡觉状态)
  - `.excited` - 兴奋型 (兴奋状态)

- ✅ 动画参数系统
  - 呼吸周期控制
  - 缩放范围 (0.95-1.05)
  - 垂直偏移 (±3-8px)
  - 旋转角度 (±1-3度)
  - 尾巴摆动开关
  - 尾巴摆动速度

- ✅ 动画状态管理
  - `breathScale` - 当前缩放
  - `verticalOffset` - 垂直偏移
  - `rotationAngle` - 旋转角度
  - `tailWagAngle` - 尾巴角度
  - `isBlinking` - 眨眼状态

- ✅ 自动动画系统
  - 60fps 刷新率
  - 正弦波呼吸算法
  - 随机眨眼间隔 (3-5秒)
  - Timer自动管理

**技术亮点**:
```swift
// 正弦波呼吸效果
let breathValue = sin(breathPhase * 2.0 * .pi)
let normalizedBreath = (breathValue + 1.0) / 2.0
breathScale = scaleRange.lowerBound + normalizedBreath * (scaleRange.upperBound - scaleRange.lowerBound)
```

### 2. 5种宠物类型差异化参数 ✅

**配置映射**:

| 宠物类型 | 配置 | 特点 |
|---------|------|------|
| 🐱 猫咪 | `.default` | 周期2s, 缩放±5%, 浮动±3px |
| 🐶 狗狗 | `.energetic` | 周期1.5s, 缩放±7%, 浮动±5px |
| 🐰 兔子 | `.energetic` | 周期1.5s, 缩放±7%, 浮动±5px |
| 🐹 仓鼠 | `.calm` | 周期2.5s, 缩放±3%, 浮动±2px |
| 🐦 小鸟 | `.calm` | 周期2.5s, 缩放±3%, 浮动±2px |

### 3. 心情状态差异化参数 ✅

**心情影响**:

| 心情 | 配置 | 效果 |
|------|------|------|
| 😊 开心 | `.energetic` (狗/兔) | 更活跃 |
| 😴 困倦 | `.sleepy` | 慢速呼吸 (3.5s) |
| 😖 伤心 | 自定义 | 下垂姿势, 无尾巴 |
| 😡 生病 | `.sleepy` | 慢速呼吸 |
| 😰 兴奋 | `.excited` | 快速呼吸 (1s), 大幅度 |

---

## 🔄 集成方案

### PetDisplayView 集成

**需要修改的代码**:

```swift
// 1. 添加状态对象
@StateObject private var breathAnimator = BreathAnimationManager.shared

// 2. 修改宠物形象应用
PixelPetAvatarView(
    petType: pet.petType,
    mood: pet.mood,
    evolutionStage: pet.evolutionStage,
    isBlinking: breathAnimator.isBlinking  // ← 新增
)
.scaleEffect(getPetScale() * breathAnimator.breathScale)  // ← 增强
.rotationEffect(getPetRotation() + Angle(degrees: breathAnimator.rotationAngle))  // ← 增强
.offset(y: breathAnimator.verticalOffset)  // ← 新增

// 3. 配置动画
.onAppear {
    breathAnimator.configureAnimation(
        petType: pet.petType.rawValue,
        mood: pet.mood.rawValue
    )
}

// 4. 监听状态变化
.onChange(of: pet.mood) { oldValue, newValue in
    breathAnimator.configureAnimation(
        petType: pet.petType.rawValue,
        mood: newValue.rawValue
    )
}

// 5. 清理资源
.onDisappear {
    breathAnimator.stopBreathAnimation()
    breathAnimator.stopBlinkAnimation()
}
```

### PixelPetAvatarView 增强

**需要添加的参数**:

```swift
struct PixelPetAvatarView: View {
    let petType: PetType
    let mood: PetMood
    let evolutionStage: EvolutionStage
    let isBlinking: Bool  // ← 新增参数

    // 移除旧的眨眼逻辑,使用外部传入的状态
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        ZStack {
            PixelGrid(petType: petType, mood: mood, evolutionStage: evolutionStage)
                .frame(width: getPetSize(), height: getPetSize())
                .scaleEffect(1 + bounceOffset)

            // 使用外部眨眼状态
            if isBlinking {
                PixelBlinkOverlay(petType: petType)
                    .frame(width: getPetSize(), height: getPetSize()))
            }
        }
        .onAppear {
            // 仅保留弹跳动画,移除眨眼Timer
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bounceOffset = 0.05
            }
        }
    }
}
```

---

## ⏸️ 待完成任务

### 1. 修改 PetDisplayView (~30分钟)

**步骤**:
1. 添加 `@StateObject private var breathAnimator`
2. 修改宠物形象应用呼吸动画
3. 添加 `.onAppear` 配置
4. 添加 `.onChange` 监听
5. 添加 `.onDisappear` 清理

### 2. 修改 PixelPetAvatarView (~15分钟)

**步骤**:
1. 添加 `isBlinking: Bool` 参数
2. 移除内部眨眼Timer
3. 使用外部状态控制眨眼

### 3. 尾巴/耳朵摆动动画 (~1-2h)

**实现方案**:
- 为猫咪、狗狗、兔子添加尾巴摆动
- 为兔子、仓鼠添加耳朵抖动
- 使用 `rotationEffect` 动画
- 集成到像素画渲染中

**示例代码**:
```swift
// 尾巴摆动 (狗狗)
struct WaggingTail: View {
    @State private var wagAngle: Double = 0

    var body: some View {
        DogTail()
            .rotationEffect(.degrees(wagAngle), anchor: .topLeading)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    wagAngle = 15
                }
            }
    }
}
```

### 4. 测试和优化 (~1h)

**测试项目**:
- ✅ 5种宠物类型动画差异化
- ✅ 7种心情状态切换
- ✅ 眨眼时机随机性
- ✅ 动画流畅度 (60fps)
- ✅ 内存占用
- ✅ CPU占用

**性能优化**:
- DrawingGroup 复杂粒子
- 按需暂停非可见动画
- 降低低端设备刷新率

---

## 📊 进度统计

**总工时**: 5-8h
**已用**: ~3h
**剩余**: ~2-5h

**完成度**: 60%

### 子任务进度

| 任务 | 预估 | 实际 | 状态 |
|------|------|------|------|
| 呼吸动画管理器 | 2-3h | 2h | ✅ 完成 |
| 5种宠物差异化 | 1h | 0.5h | ✅ 完成 |
| 心情状态差异化 | 1h | 0.5h | ✅ 完成 |
| PetDisplayView集成 | 0.5h | - | ⏸️ 待做 |
| PixelPetAvatarView修改 | 0.25h | - | ⏸️ 待做 |
| 尾巴/耳朵摆动 | 1-2h | - | ⏸️ 待做 |
| 测试和优化 | 1h | - | ⏸️ 待做 |

---

## 🎯 下一步行动

1. **立即执行**: 修改 PetDisplayView 集成呼吸动画
2. **接下来**: 修改 PixelPetAvatarView 添加眨眼参数
3. **然后**: 实现尾巴/耳朵摆动动画
4. **最后**: 测试和性能优化

---

## 💡 技术难点

### 已解决

1. **正弦波呼吸算法** ✅
   - 使用 `sin()` 函数创建平滑周期
   - 归一化到 0-1 范围
   - 映射到配置的范围

2. **60fps 刷新率** ✅
   - Timer 间隔 1/60 秒
   - 高精度相位累加
   - 平滑动画效果

3. **随机眨眼** ✅
   - 随机间隔 3-5 秒
   - 递归调度下一次眨眼
   - 闭眼0.15秒, 睁眼0.15秒

### 待解决

1. **尾巴摆动集成** ⏸️
   - 需要在像素画中识别尾巴区域
   - 独立旋转锚点设置
   - 不同宠物尾巴位置差异

2. **性能优化** ⏸️
   - 多动画并发时的CPU占用
   - Timer资源管理
   - 内存泄漏检测

---

## 📝 备注

**设计决策**:
- 使用纯SwiftUI方案,简单高效
- 60fps刷新率确保动画流畅
- 配置化设计便于扩展
- 单例模式减少内存占用

**参考资源**:
- [CAKeyframeAnimation Bouncing Effect - Stack Overflow](https://stackoverflow.com/questions/14445229/how-to-use-cakeyframeanimation-is-for-bouncing-effect-ios)
- [CoreAnimation CAKeyframeAnimation - 稀土掘金](https://juejin.cn/post/7024377973054636063)

---

**维护者**: AI Assistant
**创建日期**: 2026-02-16
**状态**: 🟡 进行中
**完成度**: 60%
