//
//  EnvironmentSystem.swift
//  VirtualPet
//
//  环境影响系统
//  包含天气、时间段等环境因素对宠物的影响
//

import SwiftUI
import Combine

// 时间段
enum TimeOfDay: String, CaseIterable, Codable {
    case morning = "早晨"
    case afternoon = "下午"
    case evening = "傍晚"
    case night = "深夜"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .purple
        case .night: return .indigo
        }
    }

    var hours: Range<Int> {
        switch self {
        case .morning: return 6..<12
        case .afternoon: return 12..<18
        case .evening: return 18..<22
        case .night: return 22..<24
        }
    }

    var description: String {
        switch self {
        case .morning: return "清晨的阳光,充满活力"
        case .afternoon: return "午后时光,适合活动"
        case .evening: return "黄昏时分,需要休息"
        case .night: return "夜深人静,好好睡觉"
        }
    }

    // 时间段效果
    var energyModifier: Double {
        switch self {
        case .morning: return 1.3      // 早晨精力充沛
        case .afternoon: return 1.0     // 下午正常
        case .evening: return 0.8       // 傍晚开始疲倦
        case .night: return 0.5         // 深夜很累
        }
    }

    var happinessModifier: Double {
        switch self {
        case .morning: return 1.2
        case .afternoon: return 1.0
        case .evening: return 0.9
        case .night: return 0.7
        }
    }

    var experienceModifier: Double {
        switch self {
        case .morning: return 1.2       // 早晨训练效果好
        case .afternoon: return 1.0
        case .evening: return 0.8
        case .night: return 0.5         // 深夜不适合训练
        }
    }
}

// 环境状态管理器
class EnvironmentSystem: ObservableObject {
    static let shared = EnvironmentSystem()

    @Published var currentTimeOfDay: TimeOfDay = .morning
    @Published var currentWeather: WeatherType = .sunny

    private init() {
        updateCurrentTimeOfDay()
    }

    // 更新当前时间段
    func updateCurrentTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())

        for timeOfDay in TimeOfDay.allCases {
            if timeOfDay.hours.contains(hour) {
                currentTimeOfDay = timeOfDay
                break
            }
        }

        // 深夜时段特殊处理
        if hour >= 0 && hour < 6 {
            currentTimeOfDay = .night
        }
    }

    // 获取综合环境效果
    func getCombinedEffects() -> EnvironmentEffects {
        let energyMod = currentTimeOfDay.energyModifier
        let happinessMod = currentTimeOfDay.happinessModifier * currentWeather.happinessModifier
        let expMod = currentTimeOfDay.experienceModifier * currentWeather.experienceModifier

        return EnvironmentEffects(
            energyModifier: energyMod,
            happinessModifier: happinessMod,
            experienceModifier: expMod,
            healthDecayModifier: currentWeather.healthDecayModifier
        )
    }

    // 环境建议
    func getAdvice() -> String {
        switch (currentTimeOfDay, currentWeather) {
        case (.morning, .sunny):
            return "☀️ 阳光明媚的早晨,适合训练和运动!"
        case (.morning, .rainy):
            return "🌧️ 下雨的早晨,室内活动也不错"
        case (.afternoon, .sunny):
            return "🌞 午后阳光正好,来玩耍吧!"
        case (.evening, _):
            return "🌆 傍晚了,该让宠物休息了"
        case (.night, _):
            return "🌙 夜深了,宠物需要睡眠"
        case (_, .stormy):
            return "⚡️ 暴风雨天气,待在室内更安全"
        default:
            return "✨ 现在是个好时候!"
        }
    }
}

// 环境效果数据结构
struct EnvironmentEffects {
    let energyModifier: Double
    let happinessModifier: Double
    let experienceModifier: Double
    let healthDecayModifier: Double
}

// 环境信息视图组件
struct EnvironmentInfoView: View {
    @ObservedObject var environmentSystem = EnvironmentSystem.shared
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("环境信息")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            // 时间段信息
            EnvironmentCard(
                icon: environmentSystem.currentTimeOfDay.icon,
                title: environmentSystem.currentTimeOfDay.rawValue,
                description: environmentSystem.currentTimeOfDay.description,
                color: environmentSystem.currentTimeOfDay.color
            )

            // 天气信息
            EnvironmentCard(
                icon: environmentSystem.currentWeather.icon,
                title: environmentSystem.currentWeather.rawValue,
                description: environmentSystem.currentWeather.description,
                color: environmentSystem.currentWeather.color
            )

            // 综合效果
            VStack(alignment: .leading, spacing: 8) {
                Text("当前效果")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                let effects = environmentSystem.getCombinedEffects()

                EffectRow(
                    label: "精力",
                    value: effects.energyModifier,
                    icon: "bolt.fill",
                    color: .blue
                )

                EffectRow(
                    label: "快乐",
                    value: effects.happinessModifier,
                    icon: "heart.fill",
                    color: .pink
                )

                EffectRow(
                    label: "经验",
                    value: effects.experienceModifier,
                    icon: "star.fill",
                    color: .yellow
                )
            }

            // 环境建议
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 建议")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(environmentSystem.getAdvice())
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.background)
                .shadow(radius: 5)
        )
    }
}

// 环境卡片组件
struct EnvironmentCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(color)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// 效果行组件
struct EffectRow: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(formatModifier(value))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(value > 1.0 ? .green : (value < 1.0 ? .red : .primary))
        }
    }

    private func formatModifier(_ value: Double) -> String {
        if value > 1.0 {
            return "+\(Int((value - 1.0) * 100))%"
        } else if value < 1.0 {
            return "-\(Int((1.0 - value) * 100))%"
        } else {
            return "正常"
        }
    }
}

// 预览
#Preview {
    EnvironmentInfoView(pet: Pet())
        .padding()
        .background(Color.gray.opacity(0.1))
}
