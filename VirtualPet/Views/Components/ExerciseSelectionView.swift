//
//  ExerciseSelectionView.swift
//  VirtualPet
//
//  运动选择界面
//  提供不同类型运动的选择,每种运动有不同的效果
//

import SwiftUI

// 运动类型枚举
enum ExerciseType: String, CaseIterable, Codable {
    case walk = "散步"
    case run = "跑步"
    case swim = "游泳"
    case fly = "飞行"
    case dance = "跳舞"

    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .swim: return "figure.pool.swim"
        case .fly: return "bird"
        case .dance: return "music.note"
        }
    }

    var color: Color {
        switch self {
        case .walk: return .green
        case .run: return .orange
        case .swim: return .blue
        case .fly: return .cyan
        case .dance: return .purple
        }
    }

    var energyCost: Int {
        switch self {
        case .walk: return 10
        case .run: return 25
        case .swim: return 20
        case .fly: return 30
        case .dance: return 15
        }
    }

    var healthGain: Int {
        switch self {
        case .walk: return 8
        case .run: return 15
        case .swim: return 12
        case .fly: return 18
        case .dance: return 10
        }
    }

    var happinessGain: Int {
        switch self {
        case .walk: return 5
        case .run: return 8
        case .swim: return 10
        case .fly: return 15
        case .dance: return 20
        }
    }

    var experienceGain: Int {
        switch self {
        case .walk: return 5
        case .run: return 10
        case .swim: return 8
        case .fly: return 12
        case .dance: return 15
        }
    }

    var hungerIncrease: Int {
        switch self {
        case .walk: return 5
        case .run: return 15
        case .swim: return 12
        case .fly: return 20
        case .dance: return 10
        }
    }

    var description: String {
        switch self {
        case .walk: return "轻松的散步,消耗较少能量"
        case .run: return "剧烈运动,快速增强体质"
        case .swim: return "全身锻炼,快乐度提升"
        case .fly: return "高难度运动,奖励丰厚"
        case .dance: return "有趣的活动,大幅提升快乐"
        }
    }

    var difficulty: String {
        switch self {
        case .walk: return "简单"
        case .run: return "中等"
        case .swim: return "中等"
        case .fly: return "困难"
        case .dance: return "简单"
        }
    }
}

struct ExerciseSelectionView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("🏃 运动选择")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 运动卡片列表
                    ForEach(ExerciseType.allCases, id: \.self) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            pet: pet,
                            action: {
                                performExercise(exercise)
                            }
                        )
                    }

                    // 关闭按钮
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("关闭")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.background)
                        .shadow(radius: 20)
                )
                .padding(40)
            }
        }
    }

    // 执行运动
    private func performExercise(_ exercise: ExerciseType) {
        // 检查能量是否足够
        guard pet.energy >= exercise.energyCost else {
            // 能量不足提示
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: ["text": "❌ 能量不足", "color": Color.red]
            )
            HapticManager.shared.trigger(.notification)
            return
        }

        // 应用进化加成
        let bonusMultiplier = pet.evolutionStage.bonusMultiplier

        // 计算效果
        let healthGain = Int(Double(exercise.healthGain) * bonusMultiplier)
        let happinessGain = Int(Double(exercise.happinessGain) * bonusMultiplier)
        let experienceGain = Int(Double(exercise.experienceGain) * bonusMultiplier)
        let hungerIncrease = exercise.hungerIncrease
        let energyCost = exercise.energyCost

        // 应用到宠物
        pet.health = min(100, pet.health + healthGain)
        pet.happiness = min(100, pet.happiness + happinessGain)
        pet.experience += experienceGain
        pet.hunger = min(100, pet.hunger + hungerIncrease)
        pet.energy = max(0, pet.energy - energyCost)

        // 记录活动
        pet.logActivity(
            Activity(
                title: exercise.rawValue,
                icon: exercise.icon,
                color: CodableColor(from: exercise.color),
                date: Date(),
                value: healthGain
            )
        )

        // 连击系统
        ComboSystem.shared.incrementCombo()

        // 发送飘字通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFloatingText"),
            object: nil,
            userInfo: [
                "text": "+\(healthGain) 健康 ↑",
                "color": exercise.color
            ]
        )

        // 发送表情通知
        let emojis = ["💪", "😤", "🏃", "✨", "😊"]
        let randomEmoji = emojis.randomElement() ?? "💪"
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": randomEmoji]
        )

        // 震动反馈 (根据运动强度)
        if exercise.energyCost >= 20 {
            HapticManager.shared.trigger(.heavy)
        } else if exercise.energyCost >= 15 {
            HapticManager.shared.trigger(.medium)
        } else {
            HapticManager.shared.trigger(.light)
        }

        // 延迟关闭界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// 运动卡片组件
struct ExerciseCard: View {
    let exercise: ExerciseType
    let pet: Pet
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部: 图标 + 名称 + 难度
                HStack {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(exercise.color.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: exercise.icon)
                            .font(.system(size: 24))
                            .foregroundColor(exercise.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(exercise.difficulty)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // 描述
                Text(exercise.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 效果列表
                HStack(spacing: 16) {
                    EffectItem(
                        icon: "heart.fill",
                        label: "健康",
                        value: "+\(exercise.healthGain)",
                        color: .red
                    )

                    EffectItem(
                        icon: "bolt.fill",
                        label: "能量",
                        value: "-\(exercise.energyCost)",
                        color: pet.energy >= exercise.energyCost ? .blue : .orange
                    )

                    EffectItem(
                        icon: "star.fill",
                        label: "经验",
                        value: "+\(exercise.experienceGain)",
                        color: .yellow
                    )

                    Spacer()

                    // 能量不足警告
                    if pet.energy < exercise.energyCost {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("能量不足")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(exercise.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(exercise.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(pet.energy < exercise.energyCost)
    }
}

// 效果项组件
struct EffectItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
    }
}

// 预览
#Preview {
    ExerciseSelectionView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
