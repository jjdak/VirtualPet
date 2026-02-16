//
//  AdvancedEventManager.swift
//  VirtualPet
//
//  高级随机事件系统
//  实现每日特殊事件和动态事件
//

import SwiftUI
import Combine

// 高级事件类型
enum AdvancedEventType: String, CaseIterable {
    case tripleXP = "三倍经验日"
    case foodFestival = "美食节"
    case sportsDay = "运动日"
    case luckyDay = "幸运日"
    case saleEvent = "特卖活动"
    case weatherEvent = "特殊天气"
    case mysteryEvent = "神秘事件"

    var icon: String {
        switch self {
        case .tripleXP: return "star.circle.fill"
        case .foodFestival: return "birthday.cake.fill"
        case .sportsDay: return "figure.run"
        case .luckyDay: return "shamrock"
        case .saleEvent: return "tag.fill"
        case .weatherEvent: return "cloud.sun.rain.fill"
        case .mysteryEvent: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .tripleXP: return .yellow
        case .foodFestival: return .orange
        case .sportsDay: return .green
        case .luckyDay: return .purple
        case .saleEvent: return .red
        case .weatherEvent: return .blue
        case .mysteryEvent: return .pink
        }
    }

    var description: String {
        switch self {
        case .tripleXP: return "所有经验获取翻3倍!"
        case .foodFestival: return "食物效果大幅提升!"
        case .sportsDay: return "运动无能量消耗!"
        case .luckyDay: return "幸运事件概率翻倍!"
        case .saleEvent: return "商店物品半价!"
        case .weatherEvent: return "特殊天气现象!"
        case .mysteryEvent: return "未知的惊喜..."
        }
    }
}

// 活动事件数据
struct ActiveEvent: Identifiable {
    let id = UUID()
    let type: AdvancedEventType
    let startTime: Date
    let duration: TimeInterval // 持续时间(秒)
    let effects: EventEffects

    var isActive: Bool {
        Date().timeIntervalSince(startTime) < duration
    }

    var remainingTime: String {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, duration - elapsed)

        if remaining < 60 {
            return "\(Int(remaining))秒"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))分钟"
        } else {
            return "\(Int(remaining / 3600))小时"
        }
    }
}

// 事件效果
struct EventEffects {
    let experienceMultiplier: Double?
    let foodEffectBonus: Double?
    let energyCostReduction: Double?
    let luckBonus: Double?
    let discount: Double?

    init(
        experienceMultiplier: Double? = nil,
        foodEffectBonus: Double? = nil,
        energyCostReduction: Double? = nil,
        luckBonus: Double? = nil,
        discount: Double? = nil
    ) {
        self.experienceMultiplier = experienceMultiplier
        self.foodEffectBonus = foodEffectBonus
        self.energyCostReduction = energyCostReduction
        self.luckBonus = luckBonus
        self.discount = discount
    }
}

// 高级事件管理器
class AdvancedEventManager: ObservableObject {
    static let shared = AdvancedEventManager()

    @Published var activeEvents: [ActiveEvent] = []
    @Published var eventHistory: [AdvancedEventType] = []

    private var eventTimer: Timer?

    private init() {
        setupEventScheduler()
    }

    // 设置事件调度器
    private func setupEventScheduler() {
        // 每小时检查一次是否触发新事件
        eventTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndTriggerEvent()
        }

        // 每分钟清理过期事件
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupExpiredEvents()
        }
    }

    // 检查并触发事件
    private func checkAndTriggerEvent() {
        // 只有在没有活动事件时才触发新事件
        guard activeEvents.isEmpty else { return }

        // 10% 概率触发每日特殊事件
        if Double.random(in: 0...1) < 0.1 {
            triggerRandomEvent()
        }
    }

    // 触发随机事件
    private func triggerRandomEvent() {
        let eventType = AdvancedEventType.allCases.randomElement() ?? .tripleXP
        let duration: TimeInterval

        // 根据事件类型设置持续时间
        switch eventType {
        case .tripleXP, .foodFestival, .sportsDay, .luckyDay:
            duration = 3600 // 1小时
        case .saleEvent:
            duration = 7200 // 2小时
        case .weatherEvent:
            duration = 5400 // 1.5小时
        case .mysteryEvent:
            duration = 1800 // 30分钟
        }

        // 创建事件效果
        let effects = createEventEffects(for: eventType)

        // 创建活动事件
        let activeEvent = ActiveEvent(
            type: eventType,
            startTime: Date(),
            duration: duration,
            effects: effects
        )

        activeEvents.append(activeEvent)
        eventHistory.append(eventType)

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("SpecialEventStarted"),
            object: nil,
            userInfo: [
                "type": eventType.rawValue,
                "description": eventType.description
            ]
        )

        // 震动反馈
        HapticManager.shared.trigger(.notification)
    }

    // 创建事件效果
    private func createEventEffects(for type: AdvancedEventType) -> EventEffects {
        switch type {
        case .tripleXP:
            return EventEffects(experienceMultiplier: 3.0)
        case .foodFestival:
            return EventEffects(foodEffectBonus: 2.0)
        case .sportsDay:
            return EventEffects(energyCostReduction: 1.0) // 免费运动
        case .luckyDay:
            return EventEffects(luckBonus: 2.0)
        case .saleEvent:
            return EventEffects(discount: 0.5)
        case .weatherEvent:
            // 特殊天气事件 - 暂时只返回经验加成
            return EventEffects(experienceMultiplier: 1.5)
        case .mysteryEvent:
            // 神秘事件随机效果
            let randomBonus = Double.random(in: 1.5...2.5)
            return EventEffects(experienceMultiplier: randomBonus)
        }
    }

    // 清理过期事件
    private func cleanupExpiredEvents() {
        activeEvents.removeAll { !$0.isActive }
    }

    // 获取当前活动事件的综合效果
    func getCurrentEffects() -> EventEffects {
        var combinedEffects = EventEffects()

        for event in activeEvents {
            if let expMult = event.effects.experienceMultiplier {
                let current = combinedEffects.experienceMultiplier ?? 1.0
                combinedEffects = EventEffects(
                    experienceMultiplier: current * expMult,
                    foodEffectBonus: combinedEffects.foodEffectBonus,
                    energyCostReduction: combinedEffects.energyCostReduction,
                    luckBonus: combinedEffects.luckBonus,
                    discount: combinedEffects.discount
                )
            }

            if let foodBonus = event.effects.foodEffectBonus {
                let current = combinedEffects.foodEffectBonus ?? 1.0
                combinedEffects = EventEffects(
                    experienceMultiplier: combinedEffects.experienceMultiplier,
                    foodEffectBonus: current + foodBonus,
                    energyCostReduction: combinedEffects.energyCostReduction,
                    luckBonus: combinedEffects.luckBonus,
                    discount: combinedEffects.discount
                )
            }

            // 其他效果类似处理...
        }

        return combinedEffects
    }

    // 手动触发事件(用于测试)
    func triggerEvent(_ type: AdvancedEventType) {
        let effects = createEventEffects(for: type)

        let activeEvent = ActiveEvent(
            type: type,
            startTime: Date(),
            duration: 3600,
            effects: effects
        )

        activeEvents.append(activeEvent)
        eventHistory.append(type)
    }
}

// 活动事件视图组件
struct ActiveEventsView: View {
    @ObservedObject var eventManager = AdvancedEventManager.shared

    var body: some View {
        VStack(spacing: 12) {
            if eventManager.activeEvents.isEmpty {
                EmptyEventsView()
            } else {
                ForEach(eventManager.activeEvents) { event in
                    ActiveEventCard(event: event)
                }
            }
        }
    }
}

// 空事件视图
struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("暂无活动事件")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// 活动事件卡片
struct ActiveEventCard: View {
    let event: ActiveEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                Image(systemName: event.type.icon)
                    .foregroundColor(event.type.color)

                Text(event.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(event.remainingTime)
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // 描述
            Text(event.type.description)
                .font(.caption)
                .foregroundColor(.secondary)

            // 进度条
            ProgressView(value: eventProgress)
                .accentColor(event.type.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(event.type.color.opacity(0.1))
        )
    }

    private var eventProgress: Double {
        let elapsed = Date().timeIntervalSince(event.startTime)
        return min(1.0, elapsed / event.duration)
    }
}

// 预览
#Preview {
    VStack(spacing: 20) {
        Text("🎉 活动事件")
            .font(.title)

        ActiveEventsView()
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}
