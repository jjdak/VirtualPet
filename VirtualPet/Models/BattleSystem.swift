//
//  BattleSystem.swift
//  VirtualPet
//
//  宠物对战系统
//  支持PVP竞技、天梯排行、技能战斗
//

import SwiftUI
import Combine

// MARK: - 战斗技能

enum BattleSkillType: String, CaseIterable, Codable {
    case attack = "普通攻击"
    case special = "特殊技能"
    case defense = "防御姿态"
    case heal = "治疗术"
    case ultimate = "终极技能"

    var icon: String {
        switch self {
        case .attack: return "bolt.fill"
        case .special: return "star.fill"
        case .defense: return "shield.fill"
        case .heal: return "heart.fill"
        case .ultimate: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .attack: return .red
        case .special: return .purple
        case .defense: return .blue
        case .heal: return .green
        case .ultimate: return .orange
        }
    }
}

// MARK: - 战斗技能

struct BattleSkill: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: BattleSkillType
    let power: Int              // 威力
    let accuracy: Double        // 命中率 (0-1)
    let cooldown: Int           // 冷却回合
    let mpCost: Int             // 消耗能量
    let description: String

    var currentCooldown: Int = 0

    var isReady: Bool {
        currentCooldown == 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: BattleSkillType,
        power: Int,
        accuracy: Double = 1.0,
        cooldown: Int = 0,
        mpCost: Int = 0,
        description: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.power = power
        self.accuracy = accuracy
        self.cooldown = cooldown
        self.mpCost = mpCost
        self.description = description
    }
}

// MARK: - 战斗宠物

struct BattlePet: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let petTypeString: String
    let level: Int
    var hp: Int                 // 生命值
    let maxHp: Int
    var mp: Int                 // 能量值
    let maxMp: Int
    var attack: Int             // 攻击力
    var defense: Int            // 防御力
    var speed: Int              // 速度
    var skills: [BattleSkill]   // 技能列表

    var petEmoji: String {
        petTypeString
    }

    var hpPercent: Double {
        Double(hp) / Double(maxHp)
    }

    var mpPercent: Double {
        Double(mp) / Double(maxMp)
    }

    var isAlive: Bool {
        hp > 0
    }

    enum CodingKeys: String, CodingKey {
        case id, playerName, petTypeString, level, hp, maxHp, mp, maxMp
        case attack, defense, speed, skills
    }

    init(
        id: UUID = UUID(),
        playerName: String,
        petTypeString: String,
        level: Int,
        hp: Int? = nil,
        maxHp: Int? = nil,
        mp: Int? = nil,
        maxMp: Int? = nil,
        attack: Int? = nil,
        defense: Int? = nil,
        speed: Int? = nil,
        skills: [BattleSkill] = []
    ) {
        self.id = id
        self.playerName = playerName
        self.petTypeString = petTypeString
        self.level = level

        // 根据等级计算属性
        let baseHp = level * 20 + 100
        let baseMp = level * 10 + 50
        let baseStats = level * 5 + 20

        self.maxHp = maxHp ?? baseHp
        self.hp = hp ?? self.maxHp
        self.maxMp = maxMp ?? baseMp
        self.mp = mp ?? self.maxMp
        self.attack = attack ?? baseStats
        self.defense = defense ?? baseStats
        self.speed = speed ?? baseStats
        self.skills = skills.isEmpty ? BattlePet.getDefaultSkills() : skills
    }

    static func getDefaultSkills() -> [BattleSkill] {
        return [
            BattleSkill(
                name: "撞击",
                type: .attack,
                power: 20,
                accuracy: 0.95,
                cooldown: 0,
                mpCost: 0,
                description: "普通攻击,造成20点伤害"
            ),
            BattleSkill(
                name: "强击",
                type: .special,
                power: 35,
                accuracy: 0.85,
                cooldown: 2,
                mpCost: 10,
                description: "强力一击,造成35点伤害"
            ),
            BattleSkill(
                name: "防御",
                type: .defense,
                power: 0,
                accuracy: 1.0,
                cooldown: 3,
                mpCost: 5,
                description: "提升防御力,减少50%伤害"
            ),
            BattleSkill(
                name: "治疗",
                type: .heal,
                power: 30,
                accuracy: 1.0,
                cooldown: 4,
                mpCost: 15,
                description: "恢复30点生命值"
            ),
            BattleSkill(
                name: "终极技能",
                type: .ultimate,
                power: 50,
                accuracy: 0.7,
                cooldown: 5,
                mpCost: 25,
                description: "全力一击,造成50点伤害"
            )
        ]
    }
}

// MARK: - 战斗记录

struct BattleLog: Identifiable {
    let id = UUID()
    let round: Int
    let attacker: String
    let skill: String
    let damage: Int
    let isCritical: Bool
    let message: String
}

// MARK: - 战斗结果

enum BattleResult: String, Codable {
    case win = "win"
    case lose = "lose"
    case draw = "draw"
}

// MARK: - 战斗管理器

class BattleManager: ObservableObject {
    static let shared = BattleManager()

    @Published var playerPet: BattlePet? = nil
    @Published var enemyPet: BattlePet? = nil
    @Published var currentRound = 1
    @Published var battleLogs: [BattleLog] = []
    @Published var isPlayerTurn = true
    @Published var battleInProgress = false
    @Published var battleResult: BattleResult? = nil

    @Published var ladderScore: Int = 1000  // 天梯分数
    @Published var winStreak: Int = 0        // 连胜
    @Published var totalBattles: Int = 0     // 总场次
    @Published var wins: Int = 0             // 胜场
    @Published var losses: Int = 0           // 败场
    @Published var battleHistory: [BattleRecord] = []

    private let defaults = UserDefaults.standard

    // MARK: - 初始化

    init() {
        loadData()
    }

    // MARK: - 创建战斗宠物

    func createBattlePet(from pet: Pet) -> BattlePet {
        BattlePet(
            playerName: "我的宠物",
            petTypeString: pet.petType.rawValue,
            level: pet.level,
            hp: nil,
            maxHp: nil,
            mp: nil,
            maxMp: nil,
            attack: nil,
            defense: nil,
            speed: nil,
            skills: BattlePet.getDefaultSkills()
        )
    }

    func createRandomEnemy(playerLevel: Int) -> BattlePet {
        let levelRange = max(1, playerLevel - 2)...(playerLevel + 2)
        let enemyLevel = Int.random(in: levelRange)

        return BattlePet(
            playerName: "野生宠物",
            petTypeString: ["🐱", "🐶", "🐰", "🐹", "🐦"].randomElement() ?? "🐱",
            level: enemyLevel
        )
    }

    // MARK: - 开始战斗

    func startBattle(player: BattlePet, enemy: BattlePet) {
        playerPet = player
        enemyPet = enemy
        currentRound = 1
        battleLogs = []
        isPlayerTurn = player.speed >= enemy.speed
        battleInProgress = true
        battleResult = nil

        addLog(
            round: 0,
            attacker: "系统",
            skill: "战斗开始",
            damage: 0,
            isCritical: false,
            message: "\(player.playerName) VS \(enemy.playerName)"
        )
    }

    // MARK: - 执行技能

    func executeSkill(skill: BattleSkill, isPlayer: Bool) -> Bool {
        guard battleInProgress else { return false }

        let attacker = isPlayer ? playerPet : enemyPet
        let defender = isPlayer ? enemyPet : playerPet

        guard attacker?.isAlive == true else { return false }
        guard defender?.isAlive == true else { return false }

        guard var attackerPet = attacker,
              var defenderPet = defender else { return false }

        // 检查冷却
        guard let skillIndex = attackerPet.skills.firstIndex(where: { $0.id == skill.id }),
              attackerPet.skills[skillIndex].isReady else {
            return false
        }

        // 检查能量
        guard attackerPet.mp >= skill.mpCost else {
            return false
        }

        // 消耗能量
        attackerPet.mp -= skill.mpCost

        // 设置冷却
        attackerPet.skills[skillIndex].currentCooldown = skill.cooldown

        var damage = 0
        var isCritical = false
        var message = ""

        switch skill.type {
        case .attack, .special, .ultimate:
            // 攻击技能
            if Double.random(in: 0...1) <= skill.accuracy {
                // 命中
                var baseDamage = skill.power + attackerPet.attack - defenderPet.defense / 2
                baseDamage = max(1, baseDamage)

                // 暴击判定 (10%几率)
                if Double.random(in: 0...1) < 0.1 {
                    baseDamage = Int(Double(baseDamage) * 1.5)
                    isCritical = true
                }

                // 随机浮动 ±10%
                let variance = Int(Double(baseDamage) * 0.1)
                damage = baseDamage + Int.random(in: -variance...variance)
                damage = max(1, damage)

                defenderPet.hp = max(0, defenderPet.hp - damage)
                message = "\(attackerPet.playerName)使用\(skill.name),造成\(damage)点伤害!"
            } else {
                message = "\(attackerPet.playerName)使用\(skill.name),但是未命中!"
            }

        case .defense:
            // 防御技能
            defenderPet.attack = max(1, defenderPet.attack - 10)
            message = "\(attackerPet.playerName)进入防御姿态,降低了对方攻击力!"

        case .heal:
            // 治疗技能
            let healAmount = min(skill.power, defenderPet.maxHp - defenderPet.hp)
            defenderPet.hp += healAmount
            damage = healAmount
            message = "\(attackerPet.playerName)使用\(skill.name),恢复了\(healAmount)点生命!"
        }

        // 更新宠物状态
        if isPlayer {
            playerPet = attackerPet
            enemyPet = defenderPet
        } else {
            enemyPet = attackerPet
            playerPet = defenderPet
        }

        // 记录日志
        addLog(
            round: currentRound,
            attacker: attackerPet.playerName,
            skill: skill.name,
            damage: damage,
            isCritical: isCritical,
            message: message
        )

        // 减少所有技能冷却
        reduceCooldowns(for: isPlayer ? playerPet : enemyPet)

        // 切换回合
        isPlayerTurn.toggle()

        // 检查战斗结束
        checkBattleEnd()

        return true
    }

    // MARK: - 减少冷却

    private func reduceCooldowns(for pet: BattlePet?) {
        guard let pet = pet else { return }

        for index in pet.skills.indices {
            if pet.skills[index].currentCooldown > 0 {
                var updatedPet = pet
                updatedPet.skills[index].currentCooldown -= 1
                if playerPet?.id == updatedPet.id {
                    playerPet = updatedPet
                } else {
                    enemyPet = updatedPet
                }
            }
        }
    }

    // MARK: - 检查战斗结束

    private func checkBattleEnd() {
        guard let player = playerPet,
              let enemy = enemyPet else { return }

        if !player.isAlive || !enemy.isAlive {
            battleInProgress = false

            if player.hp <= 0 && enemy.hp <= 0 {
                battleResult = .draw
            } else if player.hp > 0 {
                battleResult = .win
                wins += 1
                winStreak += 1
                ladderScore += 25
            } else {
                battleResult = .lose
                losses += 1
                winStreak = 0
                ladderScore = max(0, ladderScore - 20)
            }

            totalBattles += 1

            // 记录战斗
            let record = BattleRecord(
                opponentName: enemy.playerName,
                result: battleResult!,
                rounds: currentRound,
                date: Date()
            )
            battleHistory.insert(record, at: 0)

            // 限制历史记录数量
            if battleHistory.count > 50 {
                battleHistory = Array(battleHistory.prefix(50))
            }

            saveData()
        }
    }

    // MARK: - 添加日志

    private func addLog(round: Int, attacker: String, skill: String, damage: Int, isCritical: Bool, message: String) {
        let log = BattleLog(
            round: round,
            attacker: attacker,
            skill: skill,
            damage: damage,
            isCritical: isCritical,
            message: message
        )
        battleLogs.append(log)
    }

    // MARK: - 下一回合

    func nextRound() {
        currentRound += 1
    }

    // MARK: - 战胜率

    var winRate: Double {
        guard totalBattles > 0 else { return 0 }
        return Double(wins) / Double(totalBattles)
    }

    // MARK: - 数据持久化

    private func saveData() {
        defaults.set(ladderScore, forKey: "battle_ladderScore")
        defaults.set(winStreak, forKey: "battle_winStreak")
        defaults.set(totalBattles, forKey: "battle_totalBattles")
        defaults.set(wins, forKey: "battle_wins")
        defaults.set(losses, forKey: "battle_losses")

        if let data = try? JSONEncoder().encode(battleHistory) {
            defaults.set(data, forKey: "battle_history")
        }
    }

    private func loadData() {
        ladderScore = defaults.integer(forKey: "battle_ladderScore")
        winStreak = defaults.integer(forKey: "battle_winStreak")
        totalBattles = defaults.integer(forKey: "battle_totalBattles")
        wins = defaults.integer(forKey: "battle_wins")
        losses = defaults.integer(forKey: "battle_losses")

        if let data = defaults.data(forKey: "battle_history"),
           let history = try? JSONDecoder().decode([BattleRecord].self, from: data) {
            battleHistory = history
        }
    }
}

// MARK: - 战斗记录

struct BattleRecord: Codable, Identifiable {
    let id: UUID
    let opponentName: String
    let result: BattleResult
    let rounds: Int
    let date: Date

    enum CodingKeys: String, CodingKey {
        case id, opponentName, result, rounds, date
    }

    init(opponentName: String, result: BattleResult, rounds: Int, date: Date) {
        self.id = UUID()
        self.opponentName = opponentName
        self.result = result
        self.rounds = rounds
        self.date = date
    }

    var resultIcon: String {
        switch result {
        case .win: return "🏆"
        case .lose: return "💔"
        case .draw: return "🤝"
        }
    }

    var resultColor: Color {
        switch result {
        case .win: return .green
        case .lose: return .red
        case .draw: return .gray
        }
    }
}

// MARK: - UI 组件

struct BattleView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @StateObject private var battleManager = BattleManager.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab选择器
                    Picker("战斗功能", selection: $selectedTab) {
                        Text("竞技").tag(0)
                        Text("记录").tag(1)
                        Text("排行").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    Divider()

                    // 内容区域
                    ScrollView {
                        switch selectedTab {
                        case 0:
                            battleArenaView
                        case 1:
                            battleHistoryView
                        case 2:
                            ladderRankingView
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("⚔️ 对战")
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
    }

    // MARK: - 竞技场

    private var battleArenaView: some View {
        VStack(spacing: 20) {
            // 统计卡片
            HStack(spacing: 16) {
                StatCard(title: "天梯分", value: "\(battleManager.ladderScore)", icon: "star.fill", color: .yellow)
                StatCard(title: "连胜", value: "\(battleManager.winStreak)", icon: "flame.fill", color: .orange)
                StatCard(title: "胜率", value: String(format: "%.1f%%", battleManager.winRate * 100), icon: "chart.bar.fill", color: .green)
            }
            .padding()

            // 开始战斗按钮
            if battleManager.battleInProgress {
                AnyView(battleProgressView)
            } else {
                Button(action: startBattle) {
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("开始匹配")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("寻找对手中...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                    )
                }
                .padding()
            }
        }
    }

    // MARK: - 战斗进行中

    private var battleProgressView: some View {
        VStack(spacing: 16) {
            if let player = battleManager.playerPet,
               let enemy = battleManager.enemyPet {

                // 回合数
                Text("第 \(battleManager.currentRound) 回合")
                    .font(.headline)
                    .foregroundColor(.white)

                // 双方宠物
                HStack(spacing: 20) {
                    BattlePetCard(pet: player, isPlayer: true)
                    BattlePetCard(pet: enemy, isPlayer: false)
                }

                // 当前回合提示
                if battleManager.battleInProgress {
                    Text(battleManager.isPlayerTurn ? "你的回合" : "对手回合")
                        .font(.headline)
                        .foregroundColor(battleManager.isPlayerTurn ? .green : .red)
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                }

                // 技能列表
                if battleManager.isPlayerTurn && player.isAlive {
                    Text("选择技能")
                        .font(.headline)
                        .foregroundColor(.white)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(player.skills) { skill in
                            BattleSkillButton(skill: skill, mp: player.mp) {
                                battleManager.executeSkill(skill: skill, isPlayer: true)
                                if battleManager.isPlayerTurn {
                                    battleManager.nextRound()
                                }
                            }
                        }
                    }
                }

                // 战斗日志
                if !battleManager.battleLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("战斗记录")
                            .font(.headline)
                            .foregroundColor(.white)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(battleManager.battleLogs.suffix(5)) { log in
                                    HStack {
                                        Text("[R\(log.round)]")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        Text(log.message)
                                            .font(.caption)
                                            .foregroundColor(log.isCritical ? .red : .white)
                                        if log.damage > 0 {
                                            Text("-\(log.damage)")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                }

                // 战斗结果
                if let result = battleManager.battleResult {
                    Button(action: {
                        battleManager.battleInProgress = false
                        battleManager.battleResult = nil
                    }) {
                        VStack(spacing: 8) {
                            Text(result == .win ? "🏆 胜利!" : (result == .lose ? "💔 失败" : "🤝 平局"))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(result == .win ? .yellow : .red)

                            Text("点击继续")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - 战斗历史

    private var battleHistoryView: some View {
        VStack(spacing: 12) {
            if battleManager.battleHistory.isEmpty {
                Text("暂无战斗记录")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
            } else {
                ForEach(battleManager.battleHistory) { record in
                    BattleRecordCard(record: record)
                }
            }
        }
        .padding()
    }

    // MARK: - 天梯排行

    private var ladderRankingView: some View {
        VStack(spacing: 16) {
            // 我的排名
            VStack(spacing: 8) {
                Text("我的天梯分")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(battleManager.ladderScore)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.yellow)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(battleManager.wins)")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("胜")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(battleManager.losses)")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("负")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(battleManager.winStreak)")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("连胜")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )

            // 排名奖励
            VStack(alignment: .leading, spacing: 12) {
                Text("🏆 赛季奖励")
                    .font(.headline)
                    .foregroundColor(.white)

                SeasonRewardCard(rank: "前10名", reward: "传说称号 + 500钻石")
                SeasonRewardCard(rank: "前50名", reward: "史诗称号 + 200钻石")
                SeasonRewardCard(rank: "前100名", reward: "稀有称号 + 100钻石")
                SeasonRewardCard(rank: "前500名", reward: "普通称号 + 50钻石")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding()
    }

    // MARK: - 开始战斗

    private func startBattle() {
        let player = battleManager.createBattlePet(from: pet)
        let enemy = battleManager.createRandomEnemy(playerLevel: pet.level)

        battleManager.startBattle(player: player, enemy: enemy)
    }
}

// MARK: - 战斗宠物卡片

struct BattlePetCard: View {
    let pet: BattlePet
    let isPlayer: Bool

    var body: some View {
        VStack(spacing: 12) {
            // 宠物图标
            Text(pet.petEmoji)
                .font(.system(size: 60))
                .opacity(pet.isAlive ? 1.0 : 0.3)

            // 玩家名字
            Text(pet.playerName)
                .font(.headline)
                .foregroundColor(.white)

            // 等级
            Text("Lv.\(pet.level)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            // HP条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("HP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(pet.hp)/\(pet.maxHp)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                ProgressView(value: pet.hpPercent)
                    .accentColor(.red)
            }

            // MP条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("MP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(pet.mp)/\(pet.maxMp)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                ProgressView(value: pet.mpPercent)
                    .accentColor(.blue)
            }

            // 状态
            if !pet.isAlive {
                Text("已战败")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPlayer ? Color.blue.opacity(0.3) : Color.red.opacity(0.3))
        )
    }
}

// MARK: - 战斗技能按钮

struct BattleSkillButton: View {
    let skill: BattleSkill
    let mp: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: skill.type.icon)
                    .font(.title2)
                    .foregroundColor(skill.isReady && mp >= skill.mpCost ? skill.type.color : .gray)

                Text(skill.name)
                    .font(.caption)
                    .foregroundColor(.white)

                if skill.cooldown > 0 {
                    Text(skill.isReady ? "就绪" : "\(skill.currentCooldown)回合")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }

                Text("MP: \(skill.mpCost)")
                    .font(.caption2)
                    .foregroundColor(mp >= skill.mpCost ? .blue : .red)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(skill.isReady && mp >= skill.mpCost ? Color.black.opacity(0.3) : Color.black.opacity(0.1))
            )
        }
        .disabled(!skill.isReady || mp < skill.mpCost)
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - 战斗记录卡片

struct BattleRecordCard: View {
    let record: BattleRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(record.resultIcon)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.opponentName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(record.rounds) 回合")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Text(formatDate(record.date))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 赛季奖励卡片

struct SeasonRewardCard: View {
    let rank: String
    let reward: String

    var body: some View {
        HStack {
            Text(rank)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text(reward)
                .font(.caption)
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

// MARK: - 预览

#Preview {
    BattleView(pet: Pet(), isPresented: .constant(true))
}
