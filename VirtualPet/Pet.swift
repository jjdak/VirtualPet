import Foundation
import Combine
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// 导入 AudioManager 用于音效播放
import VirtualPet

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

        // 尝试转换到 RGB 色彩空间
        if let rgbColor = resolved.usingColorSpace(.deviceRGB) {
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

// 天气系统
enum WeatherType: String, CaseIterable, Codable {
    case sunny = "晴天"
    case rainy = "雨天"
    case snowy = "雪天"
    case cloudy = "多云"
    case stormy = "暴风雨"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .cloudy: return "cloud.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .rainy: return .blue
        case .snowy: return .cyan
        case .cloudy: return .gray
        case .stormy: return .purple
        }
    }

    var description: String {
        switch self {
        case .sunny: return "阳光明媚，宠物心情愉悦"
        case .rainy: return "下雨了，记得保持干燥"
        case .snowy: return "下雪了，注意保暖"
        case .cloudy: return "多云天气，一切正常"
        case .stormy: return "暴风雨！请待在室内"
        }
    }

    // 天气效果
    var happinessModifier: Double {
        switch self {
        case .sunny: return 1.2
        case .rainy: return 0.8
        case .snowy: return 0.9
        case .cloudy: return 1.0
        case .stormy: return 0.6
        }
    }

    var experienceModifier: Double {
        switch self {
        case .sunny: return 1.0
        case .rainy: return 1.2
        case .snowy: return 1.5
        case .cloudy: return 1.0
        case .stormy: return 0.7
        }
    }

    var healthDecayModifier: Double {
        switch self {
        case .sunny: return 1.0
        case .rainy: return 1.3
        case .snowy: return 1.5
        case .cloudy: return 1.0
        case .stormy: return 2.0
        }
    }
}

// 宠物技能系统
enum PetSkill: String, CaseIterable, Codable, Identifiable {
    case music = "音乐天赋"
    case sports = "运动健将"
    case study = "学霸"
    case social = "社交达人"
    case cooking = "小厨师"
    case cleaning = "洁癖"
    case lucky = "幸运星"
    case guardian = "守护者"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .music: return "music.note"
        case .sports: return "figure.run"
        case .study: return "book.fill"
        case .social: return "person.2.fill"
        case .cooking: return "fork.knife"
        case .cleaning: return "sparkles"
        case .lucky: return "star.fill"
        case .guardian: return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .music: return .purple
        case .sports: return .orange
        case .study: return .blue
        case .social: return .pink
        case .cooking: return .red
        case .cleaning: return .green
        case .lucky: return .yellow
        case .guardian: return .indigo
        }
    }

    var description: String {
        switch self {
        case .music: return "亲密度增长 +50%"
        case .sports: return "能量恢复 +30%"
        case .study: return "训练经验 +100%"
        case .social: return "生病概率 -50%"
        case .cooking: return "喂食效果 +30%"
        case .cleaning: return "清洁效果 +50%"
        case .lucky: return "幸运事件概率 +20%"
        case .guardian: return "自动保护机制"
        }
    }

    var maxLevel: Int {
        return 5
    }

    func effect(at level: Int) -> String {
        let bonus = (level - 1) * 20
        switch self {
        case .music: return "亲密度增长 +\(bonus + 50)%"
        case .sports: return "能量恢复 +\(bonus + 30)%"
        case .study: return "训练经验 +\(bonus + 100)%"
        case .social: return "生病概率 -\(bonus + 50)%"
        case .cooking: return "喂食效果 +\(bonus + 30)%"
        case .cleaning: return "清洁效果 +\(bonus + 50)%"
        case .lucky: return "幸运事件概率 +\(bonus + 20)%"
        case .guardian: return "自动保护激活"
        }
    }
}

// 迷你游戏类型
enum MiniGameType: String, CaseIterable, Codable {
    case feedingFrenzy = "觅食大作战"
    case memoryMatch = "记忆翻翻看"
    case catchToys = "玩具接接乐"

    var icon: String {
        switch self {
        case .feedingFrenzy: return "fork.knife"
        case .memoryMatch: return "brain.head.profile"
        case .catchToys: return "gamecontroller"
        }
    }

    var color: Color {
        switch self {
        case .feedingFrenzy: return .orange
        case .memoryMatch: return .purple
        case .catchToys: return .blue
        }
    }

    var description: String {
        switch self {
        case .feedingFrenzy: return "点击出现的食物获得奖励！"
        case .memoryMatch: return "记住卡片位置并配对！"
        case .catchToys: return "移动篮子接住掉落的玩具！"
        }
    }

    var cooldownMinutes: Int {
        switch self {
        case .feedingFrenzy: return 10
        case .memoryMatch: return 30
        case .catchToys: return 20
        }
    }
}

// 迷你游戏结果
struct MiniGameResult {
    let success: Bool
    let score: Int
    let rewards: MiniGameReward
    let message: String
}

struct MiniGameReward {
    let experience: Int
    let happiness: Int
    let energy: Int
    let specialCurrency: Int
    let items: [String]
}

// 活动类型
enum ActivityType: String, CaseIterable, Codable {
    case feed = "喂食"
    case play = "玩耍"
    case hug = "拥抱"
    case sleep = "睡觉"
    case clean = "清洁"
    case train = "训练"
    case medical = "医疗"
    case discipline = "管教"
    case praise = "夸奖"
    case study = "学习"
    
    var icon: String {
        switch self {
        case .feed: return "leaf.fill"
        case .play: return "gamecontroller.fill"
        case .hug: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .clean: return "sparkles"
        case .train: return "dumbbell.fill"
        case .medical: return "cross.circle.fill"
        case .discipline: return "hand.raised.fill"
        case .praise: return "hand.thumbsup.fill"
        case .study: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return .green
        case .play: return .blue
        case .hug: return .pink
        case .sleep: return .purple
        case .clean: return .cyan
        case .train: return .orange
        case .medical: return .red
        case .discipline: return .gray
        case .praise: return .yellow
        case .study: return .indigo
        }
    }
}

// 生命阶段
enum LifeStage: String, CaseIterable, Codable {
    case egg = "蛋"
    case baby = "幼体"
    case child = "成长期"
    case teen = "青春期"
    case adult = "成年"
    case senior = "老年"
    case ancient = "远古"
    
    var emoji: String {
        switch self {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teen: return "🐥"
        case .adult: return "🐓"
        case .senior: return "🦄"
        case .ancient: return "🌟"
        }
    }
    
    var minAge: Int {
        switch self {
        case .egg: return 0
        case .baby: return 1
        case .child: return 5
        case .teen: return 10
        case .adult: return 20
        case .senior: return 35
        case .ancient: return 50
        }
    }
}

// 死亡原因
enum DeathCause: String, CaseIterable, Codable {
    case oldAge = "寿终正寝"
    case neglected = "疏忽照顾"
    case sickness = "疾病"
    case starvation = "饥饿"
    case overwork = "过度疲劳"
    case accident = "意外"
    
    var icon: String {
        switch self {
        case .oldAge: return "clock.fill"
        case .neglected: return "heart.slash.fill"
        case .sickness: return "cross.circle.fill"
        case .starvation: return "leaf.slash.fill"
        case .overwork: return "bed.double.fill"
        case .accident: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .oldAge: return .gray
        case .neglected: return .red
        case .sickness: return .orange
        case .starvation: return .brown
        case .overwork: return .purple
        case .accident: return .yellow
        }
    }
}

// 特质
enum Trait: String, CaseIterable, Codable {
    case glutton = "贪吃"
    case energetic = "活力四射"
    case lazy = "懒散"
    case curious = "好奇"
    case shy = "害羞"
    case brave = "勇敢"
    case smart = "聪明"
    case clumsy = "笨拙"
    case affectionate = "粘人"
    case independent = "独立"
    case playful = "爱玩"
    case calm = "冷静"
    
    var icon: String {
        switch self {
        case .glutton: return "fork.knife"
        case .energetic: return "bolt.fill"
        case .lazy: return "bed.double.fill"
        case .curious: return "eye.fill"
        case .shy: return "eye.slash.fill"
        case .brave: return "shield.fill"
        case .smart: return "brain.head.profile"
        case .clumsy: return "shuffle"
        case .affectionate: return "heart.fill"
        case .independent: return "person.crop.circle.fill"
        case .playful: return "gamecontroller.fill"
        case .calm: return "wind"
        }
    }
    
    var description: String {
        switch self {
        case .glutton: return "更容易感到饥饿，但喂食获得更多经验"
        case .energetic: return "精力恢复更快，但消耗也更快"
        case .lazy: return "精力消耗更慢，但互动效果减弱"
        case .curious: return "更容易触发随机事件"
        case .shy: return "需要更多时间建立亲密度"
        case .brave: return "不容易生病"
        case .smart: return "训练效果翻倍"
        case .clumsy: return "偶尔会笨拙地摔倒"
        case .affectionate: return "亲密度增长更快"
        case .independent: return "可以更好地照顾自己"
        case .playful: return "玩耍效果增强"
        case .calm: return "不容易受到压力影响"
        }
    }
}

// 个性
enum Personality: String, CaseIterable, Codable {
    case cheerful = "开朗"
    case calm = "冷静"
    case naughty = "调皮"
    case serious = "认真"
    case shy = "害羞"
    case brave = "勇敢"
    
    var icon: String {
        switch self {
        case .cheerful: return "face.smiling.fill"
        case .calm: return "moon.fill"
        case .naughty: return "face.smiling.inverse"
        case .serious: return "face.dashed.fill"
        case .shy: return "face.dashed"
        case .brave: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cheerful: return .yellow
        case .calm: return .blue
        case .naughty: return .orange
        case .serious: return .gray
        case .shy: return .purple
        case .brave: return .red
        }
    }
}

// 食物类型
enum FoodType: String, CaseIterable, Codable {
    case regular = "普通食物"
    case delicious = "美味食物"
    case healthy = "健康食物"
    case premium = "高级食物"
    case special = "特殊食物"
    
    var icon: String {
        switch self {
        case .regular: return "leaf.fill"
        case .delicious: return "star.fill"
        case .healthy: return "heart.fill"
        case .premium: return "crown.fill"
        case .special: return "sparkles"
        }
    }
    
    var nutritionValue: Int {
        switch self {
        case .regular: return 10
        case .delicious: return 15
        case .healthy: return 12
        case .premium: return 20
        case .special: return 25
        }
    }
    
    var experienceBonus: Int {
        switch self {
        case .regular: return 5
        case .delicious: return 10
        case .healthy: return 8
        case .premium: return 15
        case .special: return 20
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
    
    // 生命周期系统
    @Published var generation: Int = 1
    @Published var lifeStage: LifeStage = .egg
    @Published var isDead: Bool = false
    @Published var deathCause: DeathCause? = nil
    @Published var birthDate: Date = Date()
    @Published var lifeSpan: Int = 30
    @Published var daysUntilDeath: Int = 30
    
    // 传承系统
    @Published var inheritedTraits: [Trait] = []
    @Published var unlockedTraits: [Trait] = []
    @Published var legendaryCount: Int = 0
    
    // 养成记录（用于影响进化结果）
    @Published var feedCount: Int = 0
    @Published var playCount: Int = 0
    @Published var hugCount: Int = 0
    @Published var cleanCount: Int = 0
    @Published var trainCount: Int = 0
    @Published var medicalCount: Int = 0
    
    // 个性化特征
    @Published var personality: Personality? = nil
    @Published var favoriteFood: FoodType? = nil
    @Published var favoriteActivity: ActivityType? = nil
    
    // 其他需要的状态
    @Published var trainingLevel: Int = 0
    @Published var isAsleep: Bool = false
    @Published var sleepTime: Date? = nil
    @Published var cleanliness: Int = 100
    @Published var name: String = ""

    // 天气系统
    @Published var currentWeather: WeatherType = .sunny
    @Published var lastWeatherChange: Date = Date()

    // 技能系统
    @Published var unlockedSkills: [PetSkill: Int] = [:]
    @Published var availableSkillPoints: Int = 0
    @Published var totalSkillPointsEarned: Int = 0

    // 迷你游戏系统
    @Published var lastMiniGamePlay: Date = Date()
    @Published var miniGameCooldowns: [MiniGameType: Date] = [:]
    @Published var totalMiniGameWins: Int = 0
    @Published var specialCurrency: Int = 0  // 特殊货币，用于兑换奖励
    @Published var unlockedMiniGames: [MiniGameType] = []

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
        case play, feed, clean, exercise, cuddle, train, discipline, praise, study
    }

    // 互动结果
    enum InteractionResult {
        case success(String)
        case failure(String)
        case warning(String)
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
                hugCount += 1
                logActivity(
                    Activity(
                        title: "拥抱",
                        icon: "heart.fill",
                        color: CodableColor(from: .red),
                        date: Date(),
                        value: happinessGain
                    )
                )
            case .train:
                let healthGain = Int(Double(12) * bonusMultiplier)
                health = clampValue(health + healthGain)
                energy = clampValue(energy - 25)
                hunger = clampValue(hunger + 10)
                let trainBonus = hasTrait(.smart) ? 2.0 : 1.0
                expGain = Int(Double(12) * bonusMultiplier * trainBonus)
                intimacyGain = 2
                trainCount += 1
                trainingLevel += 1
                logActivity(
                    Activity(
                        title: "训练",
                        icon: "dumbbell.fill",
                        color: CodableColor(from: .orange),
                        date: Date(),
                        value: healthGain
                    )
                )
            case .discipline:
                if personality == .naughty {
                    happiness = clampValue(happiness - 10)
                    intimacy = clampValue(intimacy - 5)
                } else {
                    happiness = clampValue(happiness - 5)
                }
                energy = clampValue(energy - 5)
                expGain = Int(Double(3) * bonusMultiplier)
                logActivity(
                    Activity(
                        title: "管教",
                        icon: "hand.raised.fill",
                        color: CodableColor(from: .gray),
                        date: Date(),
                        value: nil
                    )
                )
            case .praise:
                let happinessGain = Int(Double(15) * bonusMultiplier)
                happiness = clampValue(happiness + happinessGain)
                let praiseBonus = hasTrait(.affectionate) ? 2 : 1
                intimacy = min(100, intimacy + 5 * praiseBonus)
                expGain = Int(Double(4) * bonusMultiplier)
                logActivity(
                    Activity(
                        title: "夸奖",
                        icon: "hand.thumbsup.fill",
                        color: CodableColor(from: .yellow),
                        date: Date(),
                        value: happinessGain
                    )
                )
            case .study:
                health = clampValue(health + 8)
                energy = clampValue(energy - 20)
                hunger = clampValue(hunger + 8)
                let studyBonus = hasTrait(.smart) ? 1.5 : 1.0
                expGain = Int(Double(15) * bonusMultiplier * studyBonus)
                intimacyGain = 1
                logActivity(
                    Activity(
                        title: "学习",
                        icon: "book.fill",
                        color: CodableColor(from: .indigo),
                        date: Date(),
                        value: expGain
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

            // 播放对应音效
            switch type {
            case .play:
                AudioManager.shared.playSound(.play)
            case .feed:
                AudioManager.shared.playSound(.feed)
            case .clean:
                AudioManager.shared.playSound(.clean)
            case .exercise:
                AudioManager.shared.playSound(.exercise)
            case .cuddle:
                AudioManager.shared.playSound(.cuddle)
            case .praise:
                AudioManager.shared.playSound(.achievement)
            default:
                break
            }

            // 异步保存数据，避免阻塞主线程
            DispatchQueue.global(qos: .userInitiated).async {
                self.saveData()
            }

            // 检查随机事件 (阶段一: 简单随机事件)
            checkRandomEvent(type)
        }

        return result
    }

    // MARK: - 随机事件系统 (阶段一)
    private func checkRandomEvent(_ type: InteractionType) {
        let roll = Int.random(in: 1...100)

        switch roll {
        case 1...5:  // 5% 暴击
            triggerCriticalSuccess()

        case 6...8:  // 3% 幸运发现
            triggerLuckyFind()

        case 9...13: // 5% 滑稽反应
            triggerFunnyReaction()

        case 99...100: // 2% 拒绝
            triggerRefusal()

        default:
            break // 正常互动
        }
    }

    // 暴击效果
    private func triggerCriticalSuccess() {
        // 2倍奖励
        happiness = min(100, happiness + 10)
        experience += 5

        // 记录活动
        logActivity(
            Activity(
                title: "✨ 暴击！✨",
                icon: "star.fill",
                color: CodableColor(from: .yellow),
                date: Date(),
                value: 20
            )
        )

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFloatingText"),
            object: nil,
            userInfo: ["text": "✨ 暴击！✨", "color": Color.yellow]
        )

        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": "🤩"]
        )

        HapticManager.shared.trigger(.heavy)
    }

    // 幸运发现
    private func triggerLuckyFind() {
        // 发现小礼物
        intimacy = min(100, intimacy + 5)

        logActivity(
            Activity(
                title: "🎁 幸运发现！",
                icon: "gift.fill",
                color: CodableColor(from: .purple),
                date: Date(),
                value: nil
            )
        )

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFloatingText"),
            object: nil,
            userInfo: ["text": "🎁 幸运发现！", "color": Color.purple]
        )

        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": "😮"]
        )

        HapticManager.shared.trigger(.heartbeat)
    }

    // 滑稽反应
    private func triggerFunnyReaction() {
        happiness = min(100, happiness + 5)

        logActivity(
            Activity(
                title: "😄 滑稽时刻",
                icon: "face.smiling.fill",
                color: CodableColor(from: .yellow),
                date: Date(),
                value: nil
            )
        )

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": "😄"]
        )

        HapticManager.shared.trigger(.light)
    }

    // 拒绝互动
    private func triggerRefusal() {
        happiness = max(0, happiness - 5)

        logActivity(
            Activity(
                title: "😅 宠物拒绝了...",
                icon: "hand.raised.fill",
                color: CodableColor(from: .gray),
                date: Date(),
                value: nil
            )
        )

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFloatingText"),
            object: nil,
            userInfo: ["text": "😅 宠物拒绝了", "color": Color.gray]
        )

        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": "😅"]
        )

        HapticManager.shared.trigger(.notification)
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
    
    // 检查生命周期阶段
    private func checkLifeStage() {
        if isDead { return }
        
        let newStage = LifeStage.allCases.first { stage in
            age >= stage.minAge
        } ?? .egg
        
        if newStage != lifeStage {
            lifeStage = newStage
            
            // 随着年龄增长，生命上限减少
            let agePenalty = max(0, age - 20) * 2
            daysUntilDeath = max(1, lifeSpan - agePenalty)
        }
    }
    
    // 检查死亡条件
    private func checkDeathConditions() {
        guard !isDead else { return }
        
        var shouldDie = false
        var cause: DeathCause = .oldAge
        
        // 检查各种死亡条件
        if hunger >= 100 {
            shouldDie = true
            cause = .starvation
        } else if health <= 0 {
            shouldDie = true
            cause = .sickness
        } else if energy <= 0 && !isAsleep {
            shouldDie = true
            cause = .overwork
        } else if happiness <= 0 && age > 3 {
            shouldDie = true
            cause = .neglected
        } else if daysUntilDeath <= 0 {
            shouldDie = true
            cause = .oldAge
        }
        
        if shouldDie {
            die(cause: cause)
        }
    }
    
    // 执行死亡
    private func die(cause: DeathCause) {
        isDead = true
        deathCause = cause
        lifeStage = .ancient
        
        logActivity(
            Activity(
                title: "宠物离开了",
                icon: cause.icon,
                color: CodableColor(from: cause.color),
                date: Date(),
                value: nil
            )
        )
        
        // 如果是寿终正寝，解锁传承奖励
        if cause == .oldAge {
            unlockLegacyRewards()
        }
    }
    
    // 解锁传承奖励
    private func unlockLegacyRewards() {
        // 根据养成方式解锁特质
        if feedCount > 50 {
            unlockTrait(.glutton)
        }
        if playCount > 50 {
            unlockTrait(.playful)
        }
        if trainCount > 30 {
            unlockTrait(.smart)
        }
        if hugCount > 40 {
            unlockTrait(.affectionate)
        }
        if cleanCount > 30 {
            unlockTrait(.calm)
        }
        
        // 根据亲密度解锁
        if intimacy >= 100 {
            unlockTrait(.brave)
        }
        
        // 根据总互动数解锁
        if totalInteractions > 200 {
            unlockTrait(.energetic)
        }
    }
    
    // 解锁特质
    private func unlockTrait(_ trait: Trait) {
        if !unlockedTraits.contains(trait) {
            unlockedTraits.append(trait)
            logActivity(
                Activity(
                    title: "解锁特质：\(trait.rawValue)",
                    icon: trait.icon,
                    color: CodableColor(from: .purple),
                    date: Date(),
                    value: nil
                )
            )
        }
    }
    
    // 检查是否拥有某个特质
    private func hasTrait(_ trait: Trait) -> Bool {
        return inheritedTraits.contains(trait) || unlockedTraits.contains(trait)
    }
    
    // 重生（培养下一代）
    func rebirth() -> Pet {
        let newPet = Pet()

        // 增加代数
        newPet.generation = generation + 1

        // 传承特质（随机选择2-3个）
        let availableTraits = unlockedTraits
        let traitCount = min(3, availableTraits.count)
        let inheritedTraits = Array(availableTraits.shuffled().prefix(traitCount))
        newPet.inheritedTraits = inheritedTraits

        // 如果是传说宠物，增加传说计数
        if evolutionStage == .legendary {
            newPet.legendaryCount = legendaryCount + 1
        }

        // 传承一些基础属性
        newPet.petType = petType
        newPet.name = ""
        newPet.birthDate = Date()
        newPet.lifeSpan = calculateNewLifeSpan(for: newPet.generation)

        // 根据代数增加初始属性
        let generationBonus = generation * 2
        newPet.health = min(100, 100 + generationBonus)
        newPet.energy = min(100, 100 + generationBonus)
        newPet.intimacy = min(20, 5 + generationBonus)

        return newPet
    }

    // 计算新宠物的寿命
    private func calculateNewLifeSpan(for generation: Int) -> Int {
        let baseSpan = 30
        let generationBonus = min(10, generation * 2)
        let legendaryBonus = legendaryCount * 5

        return baseSpan + generationBonus + legendaryBonus
    }

    // 个性化宠物
    func personalize() {
        if personality == nil {
            personality = Personality.allCases.randomElement()
            logActivity(
                Activity(
                    title: "性格觉醒：\(personality!.rawValue)",
                    icon: personality!.icon,
                    color: CodableColor(from: personality!.color),
                    date: Date(),
                    value: nil
                )
            )
        }
        
        if favoriteFood == nil {
            favoriteFood = FoodType.allCases.randomElement()
            logActivity(
                Activity(
                    title: "喜爱食物：\(favoriteFood!.rawValue)",
                    icon: favoriteFood!.icon,
                    color: CodableColor(from: .blue),
                    date: Date(),
                    value: nil
                )
            )
        }
        
        if favoriteActivity == nil && age >= 2 {
            let activities: [ActivityType] = [.play, .train, .study, .clean]
            favoriteActivity = activities.randomElement()
            logActivity(
                Activity(
                    title: "最爱活动：\(favoriteActivity!.rawValue)",
                    icon: favoriteActivity!.icon,
                    color: CodableColor(from: .green),
                    date: Date(),
                    value: nil
                )
            )
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
    private func handleRandomEvent() {
        let events = [
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
        
        guard let event = events.randomElement() else { return }
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
        case .train:
            if energy < 30 {
                return .failure("宠物太累了，不能训练！")
            }
            if health < 30 {
                return .failure("宠物生病了，不能训练！")
            }
        case .discipline, .praise:
            return .success("互动成功！")
        case .study:
            if energy < 25 {
                return .failure("宠物太累了，不能学习！")
            }
            if health < 30 {
                return .failure("宠物生病了，不能学习！")
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

    // 重置宠物到初始状态
    func reset() {
        let defaultPet = Pet()
        self.hunger = defaultPet.hunger
        self.happiness = defaultPet.happiness
        self.health = defaultPet.health
        self.energy = defaultPet.energy
        self.age = defaultPet.age
        self.experience = defaultPet.experience
        self.level = defaultPet.level
        self.lastFed = defaultPet.lastFed
        self.mood = defaultPet.mood
        self.totalInteractions = defaultPet.totalInteractions
        self.maxHappiness = defaultPet.maxHappiness
        self.careStreak = defaultPet.careStreak
        self.unlockedAchievements = defaultPet.unlockedAchievements
        self.activities = defaultPet.activities
        self.statsHistory = defaultPet.statsHistory
        self.intimacy = defaultPet.intimacy
        self.evolutionStage = defaultPet.evolutionStage
        self.evolutionPath = defaultPet.evolutionPath
        self.totalPlayTime = defaultPet.totalPlayTime
        self.lastInteractionDate = defaultPet.lastInteractionDate
        self.specialMoments = defaultPet.specialMoments
        self.luckyEvents = defaultPet.luckyEvents
        self.generation = defaultPet.generation
        self.lifeStage = defaultPet.lifeStage
        self.isDead = defaultPet.isDead
        self.deathCause = defaultPet.deathCause
        self.birthDate = defaultPet.birthDate
        self.lifeSpan = defaultPet.lifeSpan
        self.daysUntilDeath = defaultPet.daysUntilDeath
        self.inheritedTraits = defaultPet.inheritedTraits
        self.unlockedTraits = defaultPet.unlockedTraits
        self.legendaryCount = defaultPet.legendaryCount
        self.feedCount = defaultPet.feedCount
        self.playCount = defaultPet.playCount
        self.hugCount = defaultPet.hugCount
        self.cleanCount = defaultPet.cleanCount
        self.trainCount = defaultPet.trainCount
        self.medicalCount = defaultPet.medicalCount
        self.personality = defaultPet.personality
        self.favoriteFood = defaultPet.favoriteFood
        self.favoriteActivity = defaultPet.favoriteActivity
        self.cleanliness = defaultPet.cleanliness
        self.trainingLevel = defaultPet.trainingLevel
        self.isAsleep = defaultPet.isAsleep
        self.sleepTime = defaultPet.sleepTime
        self.name = defaultPet.name
        self.saveData()
    }

    // 清除 UserDefaults 数据
    static func clearSavedData() {
        let defaults = UserDefaults.standard
        let keys = [
            "pet_hunger", "pet_happiness", "pet_health", "pet_energy",
            "pet_age", "pet_experience", "pet_level", "pet_last_fed",
            "pet_type", "pet_mood", "pet_total_interactions", "pet_max_happiness",
            "pet_care_streak", "pet_unlocked_achievements", "pet_activities",
            "pet_stats_history", "pet_intimacy", "pet_evolution_stage",
            "pet_evolution_path", "pet_total_play_time", "pet_last_interaction_date",
            "pet_special_moments", "pet_lucky_events"
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
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
        guard !isDead else { return }

        // 应用天气效果到衰减
        let healthDecayMultiplier = currentWeather.healthDecayModifier

        hunger = clampValue(hunger + 1)
        happiness = clampValue(happiness - 1)
        energy = clampValue(energy - 2)
        age += 1
        daysUntilDeath = max(0, daysUntilDeath - 1)

        // 应用天气衰减效果
        if healthDecayMultiplier > 1.0 && health > 0 {
            health = max(0, health - Int(Double(health) * 0.1 * (healthDecayMultiplier - 1.0)))
        }

        updateMood()
        checkLifeStage()
        checkDeathConditions()
        checkEvolution()

        // 个性化宠物
        if age >= 2 && age <= 3 {
            personalize()
        }

        // 每6-12小时随机切换天气
        if shouldChangeWeather() {
            changeWeather()
        }

        saveData()
    }

    // MARK: - 天气系统方法

    // 检查是否应该切换天气
    private func shouldChangeWeather() -> Bool {
        guard let hoursSinceLastChange = Calendar.current.dateComponents(
            [.hour],
            from: lastWeatherChange,
            to: Date()
        ).hour else { return false }

        // 每 6-12 小时切换一次天气
        return hoursSinceLastChange >= Int.random(in: 6...12)
    }

    // 改变天气
    func changeWeather() {
        let weathers = WeatherType.allCases
        currentWeather = weathers.randomElement() ?? .sunny
        lastWeatherChange = Date()

        logActivity(
            Activity(
                title: "天气变化：\(currentWeather.rawValue)",
                icon: currentWeather.icon,
                color: CodableColor(from: currentWeather.color),
                date: Date(),
                value: nil
            )
        )
    }

    // 应用天气效果到经验值
    func applyWeatherBonus(to experience: Int) -> Int {
        return Int(Double(experience) * currentWeather.experienceModifier)
    }

    // MARK: - 技能系统方法

    // 检查是否可以学习技能
    func canLearnSkill(_ skill: PetSkill) -> Bool {
        guard let currentLevel = unlockedSkills[skill] else {
            return true  // 还没学过这个技能
        }

        return currentLevel < skill.maxLevel
    }

    // 学习技能
    func learnSkill(_ skill: PetSkill) -> Bool {
        guard canLearnSkill(skill) else { return false }
        guard availableSkillPoints > 0 else { return false }

        availableSkillPoints -= 1
        unlockedSkills[skill] = (unlockedSkills[skill] ?? 0) + 1

        logActivity(
            Activity(
                title: "学习了技能：\(skill.rawValue)",
                icon: skill.icon,
                color: CodableColor(from: skill.color),
                date: Date(),
                value: nil
            )
        )

        return true
    }

    // 获得技能点
    func earnSkillPoints() {
        availableSkillPoints += 1
        totalSkillPointsEarned += 1

        logActivity(
            Activity(
                title: "获得 1 个技能点！",
                icon: "star.circle.fill",
                color: CodableColor(from: .yellow),
                date: Date(),
                value: nil
            )
        )
    }

    // 检查技能总等级
    func getTotalSkillLevel() -> Int {
        return unlockedSkills.values.reduce(0, +)
    }

    // MARK: - 迷你游戏系统方法

    // 检查迷你游戏是否冷却中
    func isMiniGameOnCooldown(_ gameType: MiniGameType) -> Bool {
        guard let lastPlay = miniGameCooldowns[gameType] else {
            return false  // 还没玩过
        }

        let cooldownInterval: TimeInterval = Double(gameType.cooldownMinutes) * 60
        return Date().timeIntervalSince(lastPlay) < cooldownInterval
    }

    // 获取迷你游戏剩余冷却时间
    func getMiniGameCooldownRemaining(_ gameType: MiniGameType) -> String {
        guard let lastPlay = miniGameCooldowns[gameType] else {
            return "可用"
        }

        let cooldownInterval: TimeInterval = Double(gameType.cooldownMinutes) * 60
        let elapsed = Date().timeIntervalSince(lastPlay)
        let remaining = cooldownInterval - elapsed

        if remaining <= 0 {
            return "可用"
        }

        let minutes = Int(remaining / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))

        return "\(minutes)分\(seconds)秒"
    }

    // 玩迷你游戏
    func playMiniGame(_ gameType: MiniGameType) -> MiniGameResult {
        guard !isMiniGameOnCooldown(gameType) else {
            return MiniGameResult(
                success: false,
                score: 0,
                rewards: MiniGameReward(experience: 0, happiness: 0, energy: 0, specialCurrency: 0, items: []),
                message: "游戏冷却中，\(getMiniGameCooldownRemaining(gameType))后可玩"
            )
        }

        lastMiniGamePlay = Date()
        miniGameCooldowns[gameType] = Date()

        // 解锁迷你游戏
        if !unlockedMiniGames.contains(gameType) {
            unlockedMiniGames.append(gameType)
        }

        // 根据游戏类型生成结果
        let result = generateMiniGameResult(for: gameType)

        if result.success {
            totalMiniGameWins += 1

            // 应用奖励
            experience += result.rewards.experience
            happiness = clampValue(happiness + result.rewards.happiness)
            energy = clampValue(energy + result.rewards.energy)
            specialCurrency += result.rewards.specialCurrency

            logActivity(
                Activity(
                    title: "游戏胜利：\(gameType.rawValue)",
                    icon: gameType.icon,
                    color: CodableColor(from: gameType.color),
                    date: Date(),
                    value: result.score
                )
            )
        }

        return result
    }

    // 生成迷你游戏结果
    private func generateMiniGameResult(for gameType: MiniGameType) -> MiniGameResult {
        let baseScore = Int.random(in: 50...100)
        let successProbability = Double.random(in: 0.3...0.9)
        let isSuccess = successProbability > 0.4

        if isSuccess {
            let expReward = Int.random(in: 10...25)
            let happinessReward = Int.random(in: 5...15)
            let energyReward = Int.random(in: 5...10)
            let currencyReward = Int.random(in: 1...5)

            return MiniGameResult(
                success: true,
                score: baseScore,
                rewards: MiniGameReward(
                    experience: expReward,
                    happiness: happinessReward,
                    energy: energyReward,
                    specialCurrency: currencyReward,
                    items: []
                ),
                message: "恭喜！获得了 \(expReward) 经验，\(happinessReward) 快乐，\(currencyReward) 钻石"
            )
        } else {
            return MiniGameResult(
                success: false,
                score: Int(baseScore / 2),
                rewards: MiniGameReward(experience: 0, happiness: 0, energy: 0, specialCurrency: 0, items: []),
                message: "游戏失败，再接再厉！"
            )
        }
    }

    // 自动衰减：每分钟饥饿度+1，快乐度-1，能量-2
    func decay_OLD() {
        guard !isDead else { return }
        
        hunger = clampValue(hunger + 1)
        happiness = clampValue(happiness - 1)
        energy = clampValue(energy - 2)
        age += 1
        daysUntilDeath = max(0, daysUntilDeath - 1)
        
        updateMood()
        checkLifeStage()
        checkDeathConditions()
        checkEvolution()
        
        // 个性化宠物
        if age >= 2 && age <= 3 {
            personalize()
        }
        
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
        defaults.set(currentWeather.rawValue, forKey: "pet_weather")
        defaults.set(lastWeatherChange, forKey: "pet_last_weather_change")
        defaults.set(totalSkillPointsEarned, forKey: "pet_total_skill_points")

        // 保存技能数据
        if let skillData = try? JSONEncoder().encode(unlockedSkills) {
            defaults.set(skillData, forKey: "pet_unlocked_skills")
        }
        defaults.set(availableSkillPoints, forKey: "pet_available_skill_points")

        // 保存迷你游戏数据
        defaults.set(lastMiniGamePlay, forKey: "pet_last_mini_game")
        defaults.set(totalMiniGameWins, forKey: "pet_mini_game_wins")
        defaults.set(specialCurrency, forKey: "pet_special_currency")

        // 保存活动记录

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

        // 加载天气数据
        if let weatherRaw = defaults.string(forKey: "pet_weather"),
           let weather = WeatherType(rawValue: weatherRaw) {
            pet.currentWeather = weather
        }

        // 加载上次天气变化时间
        if let lastWeatherChange = defaults.object(forKey: "pet_last_weather_change") as? Date {
            pet.lastWeatherChange = lastWeatherChange
        }

        // 加载技能数据
        if let skillData = defaults.data(forKey: "pet_unlocked_skills"),
           let decodedSkills = try? JSONDecoder().decode([PetSkill: Int].self, from: skillData) {
            pet.unlockedSkills = decodedSkills
        }

        // 加载技能点
        pet.availableSkillPoints = defaults.integer(forKey: "pet_available_skill_points")
        pet.totalSkillPointsEarned = defaults.integer(forKey: "pet_total_skill_points")

        // 加载迷你游戏数据
        if let lastMiniGamePlay = defaults.object(forKey: "pet_last_mini_game") as? Date {
            pet.lastMiniGamePlay = lastMiniGamePlay
        }

        pet.totalMiniGameWins = defaults.integer(forKey: "pet_mini_game_wins")
        pet.specialCurrency = defaults.integer(forKey: "pet_special_currency")

        // 加载解锁的迷你游戏
        if let gamesData = defaults.data(forKey: "pet_unlocked_mini_games"),
           let decodedGames = try? JSONDecoder().decode([MiniGameType].self, from: gamesData) {
            pet.unlockedMiniGames = decodedGames
        }

        return pet
    }
}