import Foundation
import Combine
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// Make Color Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decodeIfPresent(Double.self, forKey: .alpha) ?? 1.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let color = self.toRGB()
        try container.encode(color.r, forKey: .red)
        try container.encode(color.g, forKey: .green)
        try container.encode(color.b, forKey: .blue)
        try container.encode(color.a, forKey: .alpha)
    }

    private func toRGB() -> (r: Double, g: Double, b: Double, a: Double) {
        // Convert SwiftUI Color to components using SwiftUI API
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Get color components using platform-specific approach
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        // Fallback for non-UIKit platforms (macOS)
        let resolved = NSColor(self)
        
        // Handle dynamic colors by converting to RGB color space
        if resolved.colorSpaceName != NSColorSpaceName.deviceRGB {
            let rgbColor = resolved.usingColorSpace(.deviceRGB) ?? resolved
            rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        } else {
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        #endif

        return (r, g, b, a)
    }
}

// 宠物心情枚举
enum PetMood: String, CaseIterable, Codable {
    case happy = "开心"
    case normal = "正常"
    case hungry = "饥饿"
    case sad = "伤心"
    case sick = "生病"
    case excited = "兴奋"
    case sleepy = "困倦"
}

// 宠物类型
enum PetType: String, CaseIterable, Codable {
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
struct Activity: Identifiable, Codable {
    var id = UUID()
    let title: String
    let icon: String
    let color: Color
    let date: Date
    let value: Int?
}

// 状态记录
struct PetStatsRecord: Codable {
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

    // 缓存的统计数据
    private var cachedFeedCount: Int = 0
    private var feedCountCacheValid: Bool = false

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

    // 互动结果
    enum InteractionResult {
        case success(String)
        case failure(String)
        case warning(String)
    }

    // 喂养计数（使用缓存）
    private var feedCount: Int {
        if !feedCountCacheValid {
            cachedFeedCount = activities.filter { $0.icon == "fork.knife" }.count
            feedCountCacheValid = true
        }
        return cachedFeedCount
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
        
        // 更新缓存
        if activity.icon == "fork.knife" {
            cachedFeedCount += 1
        } else if activities.count > 100 && activities.first?.icon == "fork.knife" {
            cachedFeedCount -= 1
        }
        
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

    // 公开的检查成就方法（会记录活动）
    func checkAchievements() {
        var newlyUnlockedAchievements: [Achievement] = []
        
        for achievement in achievements {
            if !achievement.unlocked && achievement.requirement() {
                achievement.unlocked = true
                unlockedAchievements += 1
                newlyUnlockedAchievements.append(achievement)
            }
        }
        
        // 记录新解锁的成就
        for achievement in newlyUnlockedAchievements {
            let activity = Activity(
                title: "成就解锁：\(achievement.title)",
                icon: "trophy.fill",
                color: .yellow,
                date: Date(),
                value: nil
            )
            
            activities.append(activity)
            if activities.count > 100 {
                activities.removeFirst()
            }
        }
    }

    // 高级互动
    func interact(type: InteractionType) -> InteractionResult {
        let result = validateInteraction(type: type)

        switch result {
        case .failure(_):
            return result
        case .warning(_), .success(_):
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
            
            // 异步保存数据，避免阻塞主线程
            DispatchQueue.global(qos: .userInitiated).async {
                self.saveData()
            }
        }

        return result
    }

    // 验证互动
    func validateInteraction(type: InteractionType) -> InteractionResult {
        switch type {
        case .feed:
            if health < 30 {
                return .failure("宠物生病了，暂时不能喂食！")
            }
            if hunger < 10 {
                return .warning("宠物已经很饱了，不需要再喂食了！")
            }
            if Date().timeIntervalSince(lastFed) < 300 {
                return .warning("喂食太频繁了，等一会儿再喂吧！")
            }

        case .play:
            if energy < 20 {
                return .failure("宠物太累了，需要休息才能玩耍！")
            }
            if health < 30 {
                return .warning("宠物生病了，可能不想玩耍...")
            }

        case .exercise:
            if energy < 30 {
                return .failure("宠物太累了，不能运动！")
            }
            if health < 30 {
                return .failure("宠物生病了，不能运动！")
            }

        case .clean:
            if health >= 95 {
                return .warning("宠物很干净了，不需要清理！")
            }

        case .cuddle:
            if health < 30 {
                return .warning("宠物生病了，虚弱地接受拥抱...")
            }
        }

        return .success("互动成功！")
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
    
    // 保存数据到UserDefaults
    func saveData() {
        defaults.set(hunger, forKey: "pet_hunger")
        defaults.set(happiness, forKey: "pet_happiness")
        defaults.set(health, forKey: "pet_health")
        defaults.set(energy, forKey: "pet_energy")
        defaults.set(age, forKey: "pet_age")
        defaults.set(experience, forKey: "pet_experience")
        defaults.set(level, forKey: "pet_level")
        defaults.set(lastFed, forKey: "pet_last_fed")
        defaults.set(petType.rawValue, forKey: "pet_type")
        defaults.set(mood.rawValue, forKey: "pet_mood")
        defaults.set(totalInteractions, forKey: "pet_total_interactions")
        defaults.set(maxHappiness, forKey: "pet_max_happiness")
        defaults.set(careStreak, forKey: "pet_care_streak")
        defaults.set(unlockedAchievements, forKey: "pet_unlocked_achievements")

        // 保存活动记录
        if let encoded = try? JSONEncoder().encode(activities) {
            defaults.set(encoded, forKey: "pet_activities")
        }

        // 保存统计历史
        if let encoded = try? JSONEncoder().encode(statsHistory) {
            defaults.set(encoded, forKey: "pet_stats_history")
        }
    }
    
    // 从UserDefaults加载数据
    static func loadData() -> Pet {
        let defaults = UserDefaults.standard
        let pet = Pet()

        // 读取基础数据
        pet.hunger = defaults.integer(forKey: "pet_hunger")
        pet.happiness = defaults.integer(forKey: "pet_happiness")
        pet.health = defaults.integer(forKey: "pet_health")

        // 如果是第一次加载，使用默认值
        if pet.hunger == 0 && pet.happiness == 0 && pet.health == 0 {
            return pet
        }

        // 加载其他属性
        pet.energy = defaults.integer(forKey: "pet_energy")
        pet.age = defaults.integer(forKey: "pet_age")
        pet.experience = defaults.integer(forKey: "pet_experience")
        pet.level = defaults.integer(forKey: "pet_level")
        pet.totalInteractions = defaults.integer(forKey: "pet_total_interactions")
        pet.maxHappiness = defaults.integer(forKey: "pet_max_happiness")
        pet.careStreak = defaults.integer(forKey: "pet_care_streak")
        pet.unlockedAchievements = defaults.integer(forKey: "pet_unlocked_achievements")

        // 加载宠物类型
        if let petTypeRaw = defaults.string(forKey: "pet_type"),
           let petType = PetType(rawValue: petTypeRaw) {
            pet.petType = petType
        }

        // 加载心情
        if let moodRaw = defaults.string(forKey: "pet_mood"),
           let mood = PetMood(rawValue: moodRaw) {
            pet.mood = mood
        }

        // 加载上次喂食时间
        if let lastFedTime = defaults.object(forKey: "pet_last_fed") as? Date {
            pet.lastFed = lastFedTime
        }

        // 加载活动记录
        if let data = defaults.data(forKey: "pet_activities"),
           let decodedActivities = try? JSONDecoder().decode([Activity].self, from: data) {
            pet.activities = decodedActivities
        }

        // 加载统计历史
        if let data = defaults.data(forKey: "pet_stats_history"),
           let decodedStats = try? JSONDecoder().decode([PetStatsRecord].self, from: data) {
            pet.statsHistory = decodedStats
        }

        return pet
    }
}