import Foundation
import Combine
import SwiftUI

// 宠物心情枚举
enum PetMood: String, CaseIterable {
    case happy = "开心"
    case normal = "正常"
    case hungry = "饥饿"
    case sad = "伤心"
    case sick = "生病"
    case excited = "兴奋"
    case sleepy = "困倦"
}

// 宠物类型
enum PetType: String, CaseIterable {
    case cat = "🐱"
    case dog = "🐶"
    case rabbit = "🐰"
    case hamster = "🐹"
    case bird = "🐦"

    var color: Color {
        switch self {
        case .cat: return .orange
        case .dog: return .brown
        case .rabbit: return .pink
        case .hamster: return .yellow
        case .bird: return .blue
        }
    }
}

// 活动记录
struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let date: Date
    let value: Int?
}

// 状态记录
struct PetStatsRecord {
    let date: Date
    let hunger: Int
    let happiness: Int
    let health: Int
}

// 成就
class Achievement: ObservableObject, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let requirement: () -> Bool
    @Published var unlocked: Bool = false

    init(title: String, description: String, icon: String, requirement: @escaping () -> Bool) {
        self.title = title
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.unlocked = false
    }
}

class Pet: ObservableObject {
    @Published var hunger: Int = 50 // 0-100
    @Published var happiness: Int = 50 // 0-100
    @Published var health: Int = 100 // 0-100
    @Published var energy: Int = 100 // 能量值
    @Published var age: Int = 0 // 年龄（天）
    @Published var experience: Int = 0 // 经验值
    @Published var level: Int = 1 // 等级
    @Published var lastFed = Date() // 上次喂食时间
    @Published var petType: PetType = .cat
    @Published var mood: PetMood = .normal
    @Published var totalInteractions: Int = 0
    @Published var maxHappiness: Int = 50
    @Published var careStreak: Int = 0
    @Published var unlockedAchievements: Int = 0
    @Published var activities: [Activity] = []
    @Published var statsHistory: [PetStatsRecord] = []
    @Published var achievements: [Achievement] = []

    // 辅助方法：确保值在有效范围内
    private func clampValue(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    // 初始化方法
    init(hunger: Int = 50, happiness: Int = 50, health: Int = 100) {
        self.hunger = clampValue(hunger)
        self.happiness = clampValue(happiness)
        self.health = clampValue(health)
        setupAchievements()
        updateMood()
    }

    // 设置成就
    private func setupAchievements() {
        let achievement1 = Achievement(
            title: "初次见面",
            description: "第一次与宠物互动",
            icon: "star.fill",
            requirement: { self.totalInteractions >= 1 }
        )

        let achievement2 = Achievement(
            title: "美食家",
            description: "喂养宠物10次",
            icon: "fork.knife",
            requirement: { self.feedCount >= 10 }
        )

        let achievement3 = Achievement(
            title: "快乐源泉",
            description: "让宠物快乐度达到100",
            icon: "heart.fill",
            requirement: { self.maxHappiness >= 100 }
        )

        let achievement4 = Achievement(
            title: "健康达人",
            description: "连续7天保持宠物健康度80+",
            icon: "leaf.fill",
            requirement: { self.healthStreak >= 7 }
        )

        achievements = [achievement1, achievement2, achievement3, achievement4]
    }

    // 互动类型
    enum InteractionType {
        case play, feed, clean, exercise, cuddle
    }

    // 喂养计数
    private var feedCount: Int {
        return activities.filter { $0.icon == "fork.knife" }.count
    }

    // 健康连续天数
    private var healthStreak: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return statsHistory.filter { record in
            record.date >= sevenDaysAgo && record.health >= 80
        }.count
    }

    // 更新宠物心情
    func updateMood() {
        if health < 30 {
            mood = .sick
        } else if hunger > 80 {
            mood = .hungry
        } else if energy < 20 {
            mood = .sleepy
        } else if happiness > 80 {
            mood = .happy
        } else if happiness < 20 {
            mood = .sad
        } else if happiness > 60 && energy > 50 {
            mood = .excited
        } else {
            mood = .normal
        }
    }

    // 记录活动
    func logActivity(_ activity: Activity) {
        activities.append(activity)
        if activities.count > 100 {
            activities.removeFirst()
        }

        // 更新最高快乐度
        if happiness > maxHappiness {
            maxHappiness = happiness
        }

        // 更新状态历史
        if activities.count % 10 == 0 {
            let record = PetStatsRecord(
                date: Date(),
                hunger: hunger,
                happiness: happiness,
                health: health
            )
            statsHistory.append(record)
        }

        // 检查成就
        checkAchievements()
    }

    // 检查成就
    func checkAchievements() {
        for achievement in achievements {
            if !achievement.unlocked && achievement.requirement() {
                achievement.unlocked = true
                unlockedAchievements += 1
                logActivity(
                    Activity(
                        title: "成就解锁：\(achievement.title)",
                        icon: "trophy.fill",
                        color: .yellow,
                        date: Date(),
                        value: nil
                    )
                )
            }
        }
    }

    // 高级互动
    func interact(type: InteractionType) {
        switch type {
        case .play:
            happiness = clampValue(happiness + 15)
            energy = clampValue(energy - 10)
            experience += 5
            logActivity(
                Activity(
                    title: "玩耍",
                    icon: "gamecontroller",
                    color: .purple,
                    date: Date(),
                    value: 15
                )
            )
        case .feed:
            hunger = clampValue(hunger - 25)
            happiness = clampValue(happiness + 5)
            lastFed = Date()
            experience += 3
            logActivity(
                Activity(
                    title: "喂养",
                    icon: "fork.knife",
                    color: .orange,
                    date: Date(),
                    value: 25
                )
            )
        case .clean:
            health = clampValue(health + 15)
            happiness = clampValue(happiness + 5)
            experience += 2
            logActivity(
                Activity(
                    title: "清理",
                    icon: "sparkles",
                    color: .green,
                    date: Date(),
                    value: 15
                )
            )
        case .exercise:
            health = clampValue(health + 10)
            hunger = clampValue(hunger + 15)
            energy = clampValue(energy - 20)
            experience += 8
            logActivity(
                Activity(
                    title: "运动",
                    icon: "figure.walk",
                    color: .blue,
                    date: Date(),
                    value: 10
                )
            )
        case .cuddle:
            happiness = clampValue(happiness + 20)
            health = clampValue(health + 5)
            energy = clampValue(energy - 5)
            experience += 4
            logActivity(
                Activity(
                    title: "拥抱",
                    icon: "heart.fill",
                    color: .red,
                    date: Date(),
                    value: 20
                )
            )
        }

        totalInteractions += 1
        updateMood()
        checkLevelUp()
        saveData()
    }

    // 检查升级
    private func checkLevelUp() {
        let requiredExp = level * 100
        if experience >= requiredExp {
            level += 1
            experience = 0
            // 升级奖励
            health = min(100, health + 20)
            logActivity(
                Activity(
                    title: "升级到\(level)级！",
                    icon: "star.fill",
                    color: .yellow,
                    date: Date(),
                    value: nil
                )
            )
        }
    }

    // 原有方法保持兼容性
    func feed() {
        interact(type: .feed)
    }

    func clean() {
        interact(type: .clean)
    }

    func play() {
        interact(type: .play)
    }

    // 自动衰减：每分钟饥饿度+1，快乐度-1，能量-2
    func decay() {
        hunger = clampValue(hunger + 1)
        happiness = clampValue(happiness - 1)
        energy = clampValue(energy - 2)
        age += 1
        updateMood()
        saveData()
    }
    
    // UserDefaults键名
    private let defaults = UserDefaults.standard
    private let hungerKey = "pet_hunger"
    private let happinessKey = "pet_happiness"
    private let healthKey = "pet_health"
    
    // 保存数据到UserDefaults
    func saveData() {
        defaults.set(hunger, forKey: hungerKey)
        defaults.set(happiness, forKey: happinessKey)
        defaults.set(health, forKey: healthKey)
    }
    
    // 从UserDefaults加载数据
    static func loadData() -> Pet {
        let defaults = UserDefaults.standard
        let hunger = defaults.integer(forKey: "pet_hunger")
        let happiness = defaults.integer(forKey: "pet_happiness")
        let health = defaults.integer(forKey: "pet_health")
        
        // 如果是第一次加载，使用默认值
        if hunger == 0 && happiness == 0 && health == 0 {
            return Pet()
        }
        
        return Pet(hunger: hunger, happiness: happiness, health: health)
    }
}