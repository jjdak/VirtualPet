//
//  LeaderboardSystem.swift
//  VirtualPet
//
//  排行榜系统
//  支持多维度、多分类的玩家排名
//

import SwiftUI
import Combine

// MARK: - 排行榜类型

enum LeaderboardType: String, CaseIterable, Codable {
    case level = "等级排行"
    case intimacy = "亲密度排行"
    case miniGame = "小游戏排行"
    case achievement = "成就排行"

    var icon: String {
        switch self {
        case .level: return "star.circle.fill"
        case .intimacy: return "heart.circle.fill"
        case .miniGame: return "gamecontroller.fill"
        case .achievement: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .level: return .yellow
        case .intimacy: return .pink
        case .miniGame: return .purple
        case .achievement: return .orange
        }
    }
}

// MARK: - 排行榜范围

enum LeaderboardScope: String, CaseIterable, Codable {
    case global = "全局排行"
    case friends = "好友排行"
    case weekly = "本周排行"
    case allTime = "历史最高"

    var icon: String {
        switch self {
        case .global: return "globe"
        case .friends: return "person.2.fill"
        case .weekly: return "calendar.badge.clock"
        case .allTime: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - 排行榜条目

struct LeaderboardEntry: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let petTypeString: String
    let petLevel: Int
    let score: Int
    let change: Int  // 排名变化: 正数=上升, 负数=下降, 0=不变
    let lastUpdated: Date

    var petEmoji: String {
        petTypeString
    }

    var changeIcon: String? {
        if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        }
        return nil
    }

    var changeColor: Color {
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        }
        return .gray
    }

    enum CodingKeys: String, CodingKey {
        case id, playerName, petTypeString, petLevel, score, change, lastUpdated
    }

    init(
        id: UUID = UUID(),
        playerName: String,
        petTypeString: String,
        petLevel: Int,
        score: Int,
        change: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.playerName = playerName
        self.petTypeString = petTypeString
        self.petLevel = petLevel
        self.score = score
        self.change = change
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 小游戏排行条目

struct MiniGameScoreEntry: Identifiable, Codable {
    let id = UUID()
    let playerName: String
    let petTypeString: String
    let gameTypeString: String
    let score: Int
    let achievedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, playerName, petTypeString, gameTypeString, score, achievedAt
    }

    init(
        playerName: String,
        petTypeString: String,
        gameTypeString: String,
        score: Int,
        achievedAt: Date = Date()
    ) {
        self.playerName = playerName
        self.petTypeString = petTypeString
        self.gameTypeString = gameTypeString
        self.score = score
        self.achievedAt = achievedAt
    }
}

// MARK: - 排行榜管理器

class LeaderboardManager: ObservableObject {
    static let shared = LeaderboardManager()

    @Published var levelEntries: [LeaderboardEntry] = []
    @Published var intimacyEntries: [LeaderboardEntry] = []
    @Published var miniGameEntries: [MiniGameScoreEntry] = []
    @Published var achievementEntries: [LeaderboardEntry] = []

    private let defaults = UserDefaults.standard
    private let updateInterval: TimeInterval = 3600  // 1小时更新一次

    // MARK: - 初始化

    init() {
        loadData()
        setupAutoUpdate()
    }

    // MARK: - 获取排行榜数据

    func getLeaderboard(for type: LeaderboardType, scope: LeaderboardScope) -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry]

        switch type {
        case .level:
            entries = levelEntries
        case .intimacy:
            entries = intimacyEntries
        case .miniGame:
            // 小游戏使用特殊处理
            return getMiniGameLeaderboard(scope: scope)
        case .achievement:
            entries = achievementEntries
        }

        // 根据范围过滤
        switch scope {
        case .global:
            return entries
        case .friends:
            // 仅返回好友
            return filterFriends(entries)
        case .weekly:
            // 过滤本周数据
            return filterWeekly(entries)
        case .allTime:
            // 返回所有历史数据
            return loadHistoricalEntries(for: type)
        }
    }

    private func filterFriends(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        // 简化版本 - 随机返回一些条目作为"好友"
        return Array(entries.shuffled().prefix(Int(Double(entries.count) * 0.3)))
    }

    private func filterWeekly(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.lastUpdated >= oneWeekAgo }
    }

    private func loadHistoricalEntries(for type: LeaderboardType) -> [LeaderboardEntry] {
        // 从 UserDefaults 加载历史数据
        let key = "leaderboard_\(type.rawValue)_historical"
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func getMiniGameLeaderboard(scope: LeaderboardScope) -> [LeaderboardEntry] {
        // 将小游戏分数转换为排行榜条目
        var grouped: [String: (score: Int, playerName: String, petType: String, petLevel: Int, date: Date)] = [:]

        for entry in miniGameEntries {
            let key = entry.playerName
            if let existing = grouped[key] {
                if entry.score > existing.score {
                    grouped[key] = (entry.score, entry.playerName, entry.petTypeString, 0, entry.achievedAt)
                }
            } else {
                grouped[key] = (entry.score, entry.playerName, entry.petTypeString, 0, entry.achievedAt)
            }
        }

        let entries = grouped.map { (name, data) in
            LeaderboardEntry(
                playerName: name,
                petTypeString: data.petType,
                petLevel: data.petLevel,
                score: data.score,
                lastUpdated: data.date
            )
        }

        return entries.sorted { $0.score > $1.score }
    }

    // MARK: - 更新排行榜

    func updateLevelLeaderboard(playerName: String, petTypeString: String, petLevel: Int, experience: Int) {
        updateLeaderboard(&levelEntries, playerName: playerName, petTypeString: petTypeString, petLevel: petLevel, score: experience, type: .level)
    }

    func updateIntimacyLeaderboard(playerName: String, petTypeString: String, petLevel: Int, totalIntimacy: Int) {
        updateLeaderboard(&intimacyEntries, playerName: playerName, petTypeString: petTypeString, petLevel: petLevel, score: totalIntimacy, type: .intimacy)
    }

    func updateAchievementLeaderboard(playerName: String, petTypeString: String, petLevel: Int, achievementCount: Int) {
        updateLeaderboard(&achievementEntries, playerName: playerName, petTypeString: petTypeString, petLevel: petLevel, score: achievementCount, type: .achievement)
    }

    func addMiniGameScore(playerName: String, petTypeString: String, gameTypeString: String, score: Int) {
        let entry = MiniGameScoreEntry(
            playerName: playerName,
            petTypeString: petTypeString,
            gameTypeString: gameTypeString,
            score: score,
            achievedAt: Date()
        )
        miniGameEntries.append(entry)
        saveData()
    }

    private func updateLeaderboard(
        _ entries: inout [LeaderboardEntry],
        playerName: String,
        petTypeString: String,
        petLevel: Int,
        score: Int,
        type: LeaderboardType
    ) {
        // 查找现有条目
        if let index = entries.firstIndex(where: { $0.playerName == playerName }) {
            // 计算排名变化
            let oldEntry = entries[index]
            let oldRank = index + 1

            // 更新分数
            entries[index] = LeaderboardEntry(
                id: oldEntry.id,
                playerName: playerName,
                petTypeString: petTypeString,
                petLevel: petLevel,
                score: score,
                change: 0,  // 稍后计算
                lastUpdated: Date()
            )

            // 重新排序
            entries.sort { $0.score > $1.score }

            // 计算新排名和变化
            if let newIndex = entries.firstIndex(where: { $0.playerName == playerName }) {
                let newRank = newIndex + 1
                let change = oldRank - newRank  // 正数=排名上升
                entries[newIndex] = LeaderboardEntry(
                    id: entries[newIndex].id,
                    playerName: playerName,
                    petTypeString: petTypeString,
                    petLevel: petLevel,
                    score: score,
                    change: change,
                    lastUpdated: Date()
                )
            }
        } else {
            // 添加新条目
            let newEntry = LeaderboardEntry(
                playerName: playerName,
                petTypeString: petTypeString,
                petLevel: petLevel,
                score: score
            )
            entries.append(newEntry)
            entries.sort { $0.score > $1.score }

            // 计算新进入者的排名变化
            if let index = entries.firstIndex(where: { $0.playerName == playerName }) {
                entries[index] = LeaderboardEntry(
                    id: entries[index].id,
                    playerName: playerName,
                    petTypeString: petTypeString,
                    petLevel: petLevel,
                    score: score,
                    change: entries.count - index - 1,
                    lastUpdated: Date()
                )
            }
        }

        // 限制排行榜数量 (保留前100名)
        if entries.count > 100 {
            entries = Array(entries.prefix(100))
        }

        saveData()
    }

    // MARK: - 获取玩家排名

    func getPlayerRank(for type: LeaderboardType, playerName: String, scope: LeaderboardScope = .global) -> Int? {
        let entries = getLeaderboard(for: type, scope: scope)
        return entries.firstIndex(where: { $0.playerName == playerName }).map { $0 + 1 }
    }

    // MARK: - 数据持久化

    private func saveData() {
        // 保存各类型排行榜
        saveLeaderboardEntries(levelEntries, forKey: "leaderboard_level")
        saveLeaderboardEntries(intimacyEntries, forKey: "leaderboard_intimacy")
        saveLeaderboardEntries(achievementEntries, forKey: "leaderboard_achievement")

        // 保存小游戏分数
        if let data = try? JSONEncoder().encode(miniGameEntries) {
            defaults.set(data, forKey: "leaderboard_miniGame")
        }

        // 保存历史数据
        saveHistoricalData()
    }

    private func saveLeaderboardEntries(_ entries: [LeaderboardEntry], forKey key: String) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }

    private func saveHistoricalData() {
        // 定期保存历史数据
        let shouldArchive = defaults.object(forKey: "lastArchiveDate") as? Date ?? Date.distantPast
        let timeSinceArchive = Date().timeIntervalSince(shouldArchive)

        if timeSinceArchive > 86400 {  // 24小时归档一次
            archiveLeaderboard()
            defaults.set(Date(), forKey: "lastArchiveDate")
        }
    }

    private func archiveLeaderboard() {
        // 将当前数据添加到历史记录
        let types: [LeaderboardType] = [.level, .intimacy, .achievement]

        for type in types {
            let key = "leaderboard_\(type.rawValue)_historical"
            var historical: [LeaderboardEntry] = loadHistoricalEntries(for: type)

            var currentEntries: [LeaderboardEntry]
            switch type {
            case .level: currentEntries = levelEntries
            case .intimacy: currentEntries = intimacyEntries
            case .achievement: currentEntries = achievementEntries
            case .miniGame: continue
            }

            historical.append(contentsOf: currentEntries)

            // 限制历史数据量
            if historical.count > 1000 {
                historical = Array(historical.suffix(1000))
            }

            if let data = try? JSONEncoder().encode(historical) {
                defaults.set(data, forKey: key)
            }
        }
    }

    private func loadData() {
        // 加载各类型排行榜
        levelEntries = loadLeaderboardEntries(forKey: "leaderboard_level")
        intimacyEntries = loadLeaderboardEntries(forKey: "leaderboard_intimacy")
        achievementEntries = loadLeaderboardEntries(forKey: "leaderboard_achievement")

        // 加载小游戏分数
        if let data = defaults.data(forKey: "leaderboard_miniGame"),
           let entries = try? JSONDecoder().decode([MiniGameScoreEntry].self, from: data) {
            miniGameEntries = entries
        }
    }

    private func loadLeaderboardEntries(forKey key: String) -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - 自动更新

    private func setupAutoUpdate() {
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.refreshLeaderboards()
        }
    }

    private func refreshLeaderboards() {
        // 模拟从服务器获取最新数据
        // 在实际应用中,这里会调用API获取最新排名

        // 重新排序所有排行榜
        levelEntries.sort { $0.score > $1.score }
        intimacyEntries.sort { $0.score > $1.score }
        achievementEntries.sort { $0.score > $1.score }

        saveData()
    }

    // MARK: - 生成模拟数据

    func generateMockData() {
        let mockNames = [
            "小明", "小红", "小刚", "小丽", "小华",
            "小李", "小王", "小张", "小陈", "小刘",
            "小龙", "小凤", "小虎", "小豹", "小狼"
        ]

        let petEmojis = ["🐱", "🐶", "🐰", "🐹", "🐦"]

        // 生成等级排行
        for name in mockNames {
            let petType = petEmojis.randomElement() ?? "🐱"
            let level = Int.random(in: 1...50)
            let experience = level * 100 + Int.random(in: 0...99)

            updateLevelLeaderboard(
                playerName: name,
                petTypeString: petType,
                petLevel: level,
                experience: experience
            )
        }

        // 生成亲密度排行
        for name in mockNames.shuffled() {
            let petType = petEmojis.randomElement() ?? "🐱"
            let level = Int.random(in: 1...50)
            let intimacy = Int.random(in: 0...500)

            updateIntimacyLeaderboard(
                playerName: name,
                petTypeString: petType,
                petLevel: level,
                totalIntimacy: intimacy
            )
        }

        // 生成成就排行
        for name in mockNames.shuffled() {
            let petType = petEmojis.randomElement() ?? "🐱"
            let level = Int.random(in: 1...50)
            let achievements = Int.random(in: 0...20)

            updateAchievementLeaderboard(
                playerName: name,
                petTypeString: petType,
                petLevel: level,
                achievementCount: achievements
            )
        }
    }
}

// MARK: - UI 组件

struct LeaderboardView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var selectedType: LeaderboardType = .level
    @State private var selectedScope: LeaderboardScope = .global
    @State private var showMyRank = false

    @StateObject private var leaderboardManager = LeaderboardManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [selectedType.color.opacity(0.3), Color.white.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部选择器
                    leaderboardTypePicker
                    leaderboardScopePicker

                    Divider()

                    // 排行榜列表
                    if showMyRank {
                        myRankSection
                    }

                    leaderboardList
                }
            }
            .navigationTitle("🏆 排行榜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            // 生成模拟数据 (仅用于演示)
            if leaderboardManager.levelEntries.isEmpty {
                leaderboardManager.generateMockData()
            }

            // 更新当前玩家数据
            leaderboardManager.updateLevelLeaderboard(
                playerName: "我的宠物",
                petTypeString: pet.petType.rawValue,
                petLevel: pet.level,
                experience: pet.experience
            )
        }
    }

    // MARK: - 排行榜类型选择器

    private var leaderboardTypePicker: some View {
        Picker("排行榜类型", selection: $selectedType) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Label(type.rawValue, systemImage: type.icon)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color.white.opacity(0.8))
    }

    // MARK: - 排行榜范围选择器

    private var leaderboardScopePicker: some View {
        Picker("排行榜范围", selection: $selectedScope) {
            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                Label(scope.rawValue, systemImage: scope.icon)
                    .tag(scope)
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 我的排名

    private var myRankSection: some View {
        VStack(spacing: 0) {
            Divider()

            if let rank = leaderboardManager.getPlayerRank(
                for: selectedType,
                playerName: "我的宠物",
                scope: selectedScope
            ) {
                HStack {
                    Text("#\(rank)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 50)

                    Text(pet.petType.rawValue)
                        .font(.title2)
                        .foregroundColor(selectedType.color)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的宠物")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Lv.\(pet.level)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(pet.experience)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(selectedType.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(selectedType.color.opacity(0.3))
            }

            Divider()
        }
    }

    // MARK: - 排行榜列表

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(
                    Array(leaderboardManager.getLeaderboard(for: selectedType, scope: selectedScope).enumerated()),
                    id: \.element.id
                ) { index, entry in
                    LeaderboardEntryRow(
                        entry: entry,
                        rank: index + 1,
                        color: selectedType.color
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 排行榜条目行

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // 排名
            rankBadge

            // 宠物图标
            Text(entry.petEmoji)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            // 玩家信息
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.playerName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Lv.\(entry.petLevel)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // 分数和变化
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.score)")
                    .font(.headline)
                    .foregroundColor(.white)

                if let changeIcon = entry.changeIcon {
                    HStack(spacing: 4) {
                        Image(systemName: changeIcon)
                        Text("\(abs(entry.change))")
                    }
                    .font(.caption)
                    .foregroundColor(entry.changeColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 40, height: 40)

            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return color.opacity(0.5)
        }
    }
}

// MARK: - 预览

#Preview {
    LeaderboardView(pet: Pet(), isPresented: .constant(true))
}
