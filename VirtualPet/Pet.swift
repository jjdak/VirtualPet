import Foundation
import Combine
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// Color wrapper for Codable support
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(from color: Color) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        let resolved = NSColor(color)
        
        if resolved.colorSpaceName != NSColorSpaceName.deviceRGB {
            let rgbColor = resolved.usingColorSpace(.deviceRGB) ?? resolved
            rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        } else {
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        #endif
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
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

// 进化阶段
enum EvolutionStage: String, CaseIterable, Codable {
    case egg = "蛋"
    case baby = "幼体"
    case child = "成长期"
    case teen = "青春期"
    case adult = "成年"
    case elder = "长者"
    case legendary = "传说"
    
    var requiredLevel: Int {
        switch self {
        case .egg: return 0
        case .baby: return 1
        case .child: return 5
        case .teen: return 10
        case .adult: return 20
        case .elder: return 30
        case .legendary: return 50
        }
    }
    
    var bonusMultiplier: Double {
        switch self {
        case .egg: return 0.5
        case .baby: return 1.0
        case .child: return 1.2
        case .teen: return 1.5
        case .adult: return 1.8
        case .elder: return 2.0
        case .legendary: return 2.5
        }
    }
}

// 进化路径
enum EvolutionPath: String, CaseIterable, Codable {
    case balanced = "平衡型"
    case strong = "力量型"
    case happy = "快乐型"
    case healthy = "健康型"
    case mysterious = "神秘型"
    
    var icon: String {
        switch self {
        case .balanced: return "scale.3d"
        case .strong: return "figure.strengthtraining.traditional"
        case .happy: return "face.smiling"
        case .healthy: return "heart.pulse"
        case .mysterious: return "sparkles"
        }
    }
    
    var description: String {
        switch self {
        case .balanced: return "各项能力均衡发展"
        case .strong: return "更快的经验获取和进化"
        case .happy: return "更高的快乐度上限和恢复速度"
        case .healthy: return "更强的健康和抗病能力"
        case .mysterious: return "更多随机事件和隐藏奖励"
        }
    }
    
    var color: Color {
        switch self {
        case .balanced: return .blue
        case .strong: return .orange
        case .happy: return .pink
        case .healthy: return .green
        case .mysterious: return .purple
        }
    }
}

// 活动记录
struct Activity: Identifiable, Codable {
    var id = UUID()
    let title: String
    let icon: String
    let color: CodableColor
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
    
    @Published var intimacy: Int = 0 // 亲密度 0-100
    @Published var evolutionStage: EvolutionStage = .egg // 进化阶段
    @Published var evolutionPath: EvolutionPath? = nil // 进化路径
    @Published var totalPlayTime: Int = 0 // 总游玩时间（分钟）
    @Published var lastInteractionDate: Date = Date() // 上次互动时间
    @Published var specialMoments: Int = 0 // 特殊时刻次数
    @Published var luckyEvents: Int = 0 // 幸运事件次数

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
        
        let achievement5 = Achievement(
            title: "亲密伙伴",
            description: "亲密度达到50",
            icon: "heart.circle.fill",
            requirement: { self.intimacy >= 50 }
        )
        
        let achievement6 = Achievement(
            title: "灵魂伴侣",
            description: "亲密度达到100",
            icon: "heart.fill",
            requirement: { self.intimacy >= 100 }
        )
        
        let achievement7 = Achievement(
            title: "成长之路",
            description: "宠物第一次进化",
            icon: "arrow.up.forward",
            requirement: { self.evolutionStage != .egg && self.evolutionStage != .baby }
        )
        
        let achievement8 = Achievement(
            title: "青春年少",
            description: "进化到青春期",
            icon: "figure.run",
            requirement: { self.evolutionStage == .teen || self.evolutionStage.rawValue == "青春期" }
        )
        
        let achievement9 = Achievement(
            title: "成熟稳重",
            description: "进化到成年期",
            icon: "figure.stand",
            requirement: { self.evolutionStage == .adult || self.evolutionStage.rawValue == "成年" }
        )
        
        let achievement10 = Achievement(
            title: "传说之宠",
            description: "进化到传说阶段",
            icon: "crown.fill",
            requirement: { self.evolutionStage == .legendary || self.evolutionStage.rawValue == "传说" }
        )
        
        let achievement11 = Achievement(
            title: "幸运之星",
            description: "触发5次幸运事件",
            icon: "star.circle.fill",
            requirement: { self.luckyEvents >= 5 }
        )
        
        let achievement12 = Achievement(
            title: "特殊时刻",
            description: "经历10次特殊时刻",
            icon: "sparkles",
            requirement: { self.specialMoments >= 10 }
        )

        achievements = [achievement1, achievement2, achievement3, achievement4, achievement5, achievement6, achievement7, achievement8, achievement9, achievement10, achievement11, achievement12]
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
                color: CodableColor(from: .yellow),
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
            let bonusMultiplier = evolutionStage.bonusMultiplier
            var expGain = 0
            var intimacyGain = 1
            
            switch type {
            case .play:
                let happinessGain = Int(Double(15) * bonusMultiplier)
                happiness = clampValue(happiness + happinessGain)
                energy = clampValue(energy - 10)
                expGain = Int(Double(5) * bonusMultiplier)
                intimacyGain = 2
                logActivity(
                    Activity(
                        title: "玩耍",
                        icon: "gamecontroller",
                        color: CodableColor(from: .purple),
                        date: Date(),
                        value: happinessGain
                    )
                )
            case .feed:
                let hungerReduction = Int(Double(25) * bonusMultiplier)
                hunger = clampValue(hunger - hungerReduction)
                happiness = clampValue(happiness + 5)
                lastFed = Date()
                expGain = Int(Double(3) * bonusMultiplier)
                logActivity(
                    Activity(
                        title: "喂养",
                        icon: "fork.knife",
                        color: CodableColor(from: .orange),
                        date: Date(),
                        value: hungerReduction
                    )
                )
            case .clean:
                let healthGain = Int(Double(15) * bonusMultiplier)
                health = clampValue(health + healthGain)
                happiness = clampValue(happiness + 5)
                expGain = Int(Double(2) * bonusMultiplier)
                logActivity(
                    Activity(
                        title: "清理",
                        icon: "sparkles",
                        color: CodableColor(from: .green),
                        date: Date(),
                        value: healthGain
                    )
                )
            case .exercise:
                let healthGain = Int(Double(10) * bonusMultiplier)
                health = clampValue(health + healthGain)
                hunger = clampValue(hunger + 15)
                energy = clampValue(energy - 20)
                expGain = Int(Double(8) * bonusMultiplier)
                intimacyGain = 2
                logActivity(
                    Activity(
                        title: "运动",
                        icon: "figure.walk",
                        color: CodableColor(from: .blue),
                        date: Date(),
                        value: healthGain
                    )
                )
            case .cuddle:
                let happinessGain = Int(Double(20) * bonusMultiplier)
                happiness = clampValue(happiness + happinessGain)
                health = clampValue(health + 5)
                energy = clampValue(energy - 5)
                expGain = Int(Double(4) * bonusMultiplier)
                intimacyGain = 3
                logActivity(
                    Activity(
                        title: "拥抱",
                        icon: "heart.fill",
                        color: CodableColor(from: .red),
                        date: Date(),
                        value: happinessGain
                    )
                )
            }

            experience += expGain
            totalInteractions += 1
            lastInteractionDate = Date()
            
            // 更新亲密度
            if intimacy < 100 {
                let pathBonus = getEvolutionPathBonus()
                intimacy = min(100, intimacy + intimacyGain + pathBonus)
            }
            
            updateMood()
            checkLevelUp()
            checkEvolution()
            triggerRandomEvent()
            
            // 异步保存数据，避免阻塞主线程
            DispatchQueue.global(qos: .userInitiated).async {
                self.saveData()
            }
        }

        return result
    }
    
    // 获取进化路径加成
    private func getEvolutionPathBonus() -> Int {
        guard let path = evolutionPath else { return 0 }
        
        switch path {
        case .balanced: return 0
        case .strong: return 1
        case .happy: return 2
        case .healthy: return 1
        case .mysterious: return Int.random(in: 0...3)
        }
    }
    
    // 检查进化
    private func checkEvolution() {
        let currentStageIndex = EvolutionStage.allCases.firstIndex(of: evolutionStage) ?? 0
        let nextStages = Array(EvolutionStage.allCases.dropFirst(currentStageIndex + 1))
        
        for nextStage in nextStages {
            if level >= nextStage.requiredLevel {
                evolveTo(nextStage)
                break
            }
        }
    }
    
    // 执行进化
    private func evolveTo(_ stage: EvolutionStage) {
        guard evolutionStage != stage else { return }
        
        let oldStage = evolutionStage
        evolutionStage = stage
        
        // 进化奖励
        health = min(100, health + 30)
        happiness = min(100, happiness + 20)
        energy = min(100, energy + 25)
        
        specialMoments += 1
        
        logActivity(
            Activity(
                title: "进化！\(oldStage.rawValue) → \(stage.rawValue)",
                icon: "sparkles",
                color: CodableColor(from: .purple),
                date: Date(),
                value: nil
            )
        )
        
        // 如果是第一次进化，让玩家选择进化路径
        if evolutionStage == .child && evolutionPath == nil {
            logActivity(
                Activity(
                    title: "可以选择进化路径了！",
                    icon: "arrow.triangle.2.circlepath",
                    color: CodableColor(from: .blue),
                    date: Date(),
                    value: nil
                )
            )
        }
    }
    
    // 设置进化路径
    func setEvolutionPath(_ path: EvolutionPath) {
        guard evolutionPath == nil else { return }
        
        evolutionPath = path
        logActivity(
            Activity(
                title: "选择了\(path.rawValue)进化路径",
                icon: path.icon,
                color: CodableColor(from: .blue),
                date: Date(),
                value: nil
            )
        )
    }
    
    // 触发随机事件 - 优化版本
    private func triggerRandomEvent() {
        let baseChance = 0.05
        let pathBonus = evolutionPath == .mysterious ? 0.1 : 0.0
        let stageBonus = evolutionStage.bonusMultiplier * 0.05
        let totalChance = min(0.25, baseChance + pathBonus + stageBonus)
        
        guard Double.random(in: 0...1) < totalChance else { return }
        
        handleRandomEvent()
    }
    
    // 处理随机事件 - 优化版本（缓存事件池）
    private static var eventPool: [RandomEvent]?
    
    private func handleRandomEvent() {
        // 延迟初始化事件池
        if Self.eventPool == nil {
            Self.eventPool = [
                RandomEvent(
                    title: "幸运时刻",
                    description: "你的宠物发现了一个隐藏的宝藏！",
                    effect: { pet in
                        pet.experience += 10
                        pet.luckyEvents += 1
                    },
                    icon: "star.fill",
                    color: .yellow
                ),
                RandomEvent(
                    title: "突然饿了",
                    description: "你的宠物突然感到非常饥饿...",
                    effect: { pet in
                        pet.hunger = min(100, pet.hunger + 20)
                    },
                    icon: "fork.knife",
                    color: .orange
                ),
                RandomEvent(
                    title: "快乐惊喜",
                    description: "你的宠物因为一件小事而变得超级开心！",
                    effect: { pet in
                        pet.happiness = min(100, pet.happiness + 25)
                        pet.specialMoments += 1
                    },
                    icon: "heart.fill",
                    color: .pink
                ),
                RandomEvent(
                    title: "意外收获",
                    description: "你的宠物在玩耍时发现了一些有用的东西！",
                    effect: { pet in
                        pet.health = min(100, pet.health + 15)
                        pet.energy = min(100, pet.energy + 10)
                    },
                    icon: "sparkles",
                    color: .green
                ),
                RandomEvent(
                    title: "亲密时刻",
                    description: "你和宠物之间建立了更深的联系！",
                    effect: { pet in
                        pet.intimacy = min(100, pet.intimacy + 15)
                        pet.specialMoments += 1
                    },
                    icon: "heart.circle.fill",
                    color: .red
                ),
                RandomEvent(
                    title: "神秘礼物",
                    description: "你的宠物收到了一个神秘礼物！",
                    effect: { pet in
                        let reward = Int.random(in: 5...15)
                        pet.experience += reward
                        pet.luckyEvents += 1
                    },
                    icon: "gift.fill",
                    color: .purple
                )
            ]
        }
        
        guard let event = Self.eventPool?.randomElement() else { return }
        event.effect(self)
        logActivity(
            Activity(
                title: "事件：\(event.title)",
                icon: event.icon,
                color: CodableColor(from: event.color),
                date: Date(),
                value: nil
            )
        )
    }

    // 随机事件结构
    struct RandomEvent {
        let title: String
        let description: String
        let effect: (Pet) -> Void
        let icon: String
        let color: Color
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
                    color: CodableColor(from: .yellow),
                    date: Date(),
                    value: nil
                )
            )
        }
    }

    // 原有方法保持兼容性
    func feed() {
        _ = interact(type: .feed)
    }

    func clean() {
        _ = interact(type: .clean)
    }

    func play() {
        _ = interact(type: .play)
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
        defaults.set(intimacy, forKey: "pet_intimacy")
        defaults.set(evolutionStage.rawValue, forKey: "pet_evolution_stage")
        defaults.set(evolutionPath?.rawValue, forKey: "pet_evolution_path")
        defaults.set(totalPlayTime, forKey: "pet_total_play_time")
        defaults.set(lastInteractionDate, forKey: "pet_last_interaction_date")
        defaults.set(specialMoments, forKey: "pet_special_moments")
        defaults.set(luckyEvents, forKey: "pet_lucky_events")

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
        pet.intimacy = defaults.integer(forKey: "pet_intimacy")
        pet.totalPlayTime = defaults.integer(forKey: "pet_total_play_time")
        pet.specialMoments = defaults.integer(forKey: "pet_special_moments")
        pet.luckyEvents = defaults.integer(forKey: "pet_lucky_events")

        // 加载进化阶段
        if let evolutionStageRaw = defaults.string(forKey: "pet_evolution_stage"),
           let evolutionStage = EvolutionStage(rawValue: evolutionStageRaw) {
            pet.evolutionStage = evolutionStage
        }

        // 加载进化路径
        if let evolutionPathRaw = defaults.string(forKey: "pet_evolution_path"),
           let evolutionPath = EvolutionPath(rawValue: evolutionPathRaw) {
            pet.evolutionPath = evolutionPath
        }

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
        
        // 加载上次互动时间
        if let lastInteractionTime = defaults.object(forKey: "pet_last_interaction_date") as? Date {
            pet.lastInteractionDate = lastInteractionTime
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