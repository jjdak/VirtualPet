//
//  GuildSystem.swift
//  VirtualPet
//
//  公会/社团系统
//  支持公会创建、管理、成员互动和公会任务
//

import SwiftUI
import Combine

// MARK: - 公会职位

enum GuildRole: String, CaseIterable, Codable {
    case leader = "会长"
    case viceLeader = "副会长"
    case elder = "长老"
    case member = "成员"
    case recruit = "学徒"

    var icon: String {
        switch self {
        case .leader: return "crown.fill"
        case .viceLeader: return "star.circle.fill"
        case .elder: return "star.fill"
        case .member: return "person.fill"
        case .recruit: return "person.badge.plus"
        }
    }

    var color: Color {
        switch self {
        case .leader: return .yellow
        case .viceLeader: return .orange
        case .elder: return .purple
        case .member: return .blue
        case .recruit: return .gray
        }
    }

    var permissions: GuildPermissions {
        switch self {
        case .leader:
            return GuildPermissions(all: true)
        case .viceLeader:
            return GuildPermissions(
                canInvite: true,
                canKick: true,
                canEditSettings: true,
                canPostNotice: true,
                canStartTasks: true,
                canTransfer: false
            )
        case .elder:
            return GuildPermissions(
                canInvite: true,
                canKick: false,
                canEditSettings: false,
                canPostNotice: true,
                canStartTasks: true,
                canTransfer: false
            )
        case .member:
            return GuildPermissions(
                canInvite: false,
                canKick: false,
                canEditSettings: false,
                canPostNotice: false,
                canStartTasks: true,
                canTransfer: false
            )
        case .recruit:
            return GuildPermissions(
                canInvite: false,
                canKick: false,
                canEditSettings: false,
                canPostNotice: false,
                canStartTasks: false,
                canTransfer: false
            )
        }
    }
}

// MARK: - 公会权限

struct GuildPermissions: Codable {
    var canInvite: Bool
    var canKick: Bool
    var canEditSettings: Bool
    var canPostNotice: Bool
    var canStartTasks: Bool
    var canTransfer: Bool

    init(all: Bool = false) {
        self.canInvite = all
        self.canKick = all
        self.canEditSettings = all
        self.canPostNotice = all
        self.canStartTasks = all
        self.canTransfer = all
    }

    init(
        canInvite: Bool,
        canKick: Bool,
        canEditSettings: Bool,
        canPostNotice: Bool,
        canStartTasks: Bool,
        canTransfer: Bool
    ) {
        self.canInvite = canInvite
        self.canKick = canKick
        self.canEditSettings = canEditSettings
        self.canPostNotice = canPostNotice
        self.canStartTasks = canStartTasks
        self.canTransfer = canTransfer
    }
}

// MARK: - 公会成员

struct GuildMember: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let petTypeString: String
    let petLevel: Int
    var role: GuildRole
    var contribution: Int  // 贡献值
    var joinDate: Date
    var lastActive: Date

    var petEmoji: String {
        petTypeString
    }

    var roleIcon: String {
        role.icon
    }

    enum CodingKeys: String, CodingKey {
        case id, playerName, petTypeString, petLevel, role, contribution, joinDate, lastActive
    }

    init(
        id: UUID = UUID(),
        playerName: String,
        petTypeString: String,
        petLevel: Int,
        role: GuildRole = .member,
        contribution: Int = 0,
        joinDate: Date = Date(),
        lastActive: Date = Date()
    ) {
        self.id = id
        self.playerName = playerName
        self.petTypeString = petTypeString
        self.petLevel = petLevel
        self.role = role
        self.contribution = contribution
        self.joinDate = joinDate
        self.lastActive = lastActive
    }
}

// MARK: - 公会任务

struct GuildTask: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let target: Int
    var current: Int = 0
    var isCompleted: Bool = false
    let reward: GuildTaskReward
    let requiredMembers: Int  // 需要的最少成员数

    var progress: Double {
        Double(current) / Double(target)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, target, current, isCompleted, reward, requiredMembers
    }
}

// MARK: - 公会任务奖励

struct GuildTaskReward: Codable {
    let guildExp: Int
    let personalExp: Int
    let contribution: Int
    let specialCurrency: Int
}

// MARK: - 公会数据

struct Guild: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    var level: Int
    var experience: Int
    var members: [GuildMember]
    var notice: String
    var createdAt: Date
    var totalContribution: Int

    var leader: GuildMember? {
        members.first { $0.role == .leader }
    }

    var memberCount: Int {
        members.count
    }

    var maxMembers: Int {
        level * 10 + 10
    }

    var levelProgress: Double {
        Double(experience) / Double(level * 1000)
    }

    var requiredExp: Int {
        level * 1000
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, description, level, experience, members, notice, createdAt, totalContribution
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        level: Int = 1,
        experience: Int = 0,
        members: [GuildMember] = [],
        notice: String = "",
        createdAt: Date = Date(),
        totalContribution: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.level = level
        self.experience = experience
        self.members = members
        self.notice = notice
        self.createdAt = createdAt
        self.totalContribution = totalContribution
    }
}

// MARK: - 公会申请

struct GuildApplication: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let petTypeString: String
    let petLevel: Int
    let message: String
    let applyDate: Date

    var petEmoji: String {
        petTypeString
    }

    init(
        playerName: String,
        petTypeString: String,
        petLevel: Int,
        message: String = "",
        applyDate: Date = Date()
    ) {
        self.id = UUID()
        self.playerName = playerName
        self.petTypeString = petTypeString
        self.petLevel = petLevel
        self.message = message
        self.applyDate = applyDate
    }
}

// MARK: - 公会管理器

class GuildManager: ObservableObject {
    static let shared = GuildManager()

    @Published var playerGuild: Guild? = nil
    @Published var guildApplications: [GuildApplication] = []
    @Published var guildTasks: [GuildTask] = []
    @Published var allGuilds: [Guild] = []

    private let defaults = UserDefaults.standard

    // MARK: - 初始化

    init() {
        loadData()
        setupDailyTasks()
    }

    // MARK: - 公会创建

    func createGuild(name: String, icon: String, description: String, creator: GuildMember) -> Guild {
        var leader = creator
        leader.role = .leader

        let guild = Guild(
            name: name,
            icon: icon,
            description: description,
            members: [leader]
        )

        playerGuild = guild
        allGuilds.append(guild)
        saveData()

        return guild
    }

    // MARK: - 成员管理

    func addMember(_ member: GuildMember, to guild: Guild) {
        guard guild.memberCount < guild.maxMembers else { return }

        if let index = allGuilds.firstIndex(where: { $0.id == guild.id }) {
            allGuilds[index].members.append(member)
            playerGuild = allGuilds[index]
            saveData()
        }
    }

    func removeMember(_ member: GuildMember, from guild: Guild) {
        if let index = allGuilds.firstIndex(where: { $0.id == guild.id }) {
            allGuilds[index].members.removeAll { $0.id == member.id }
            playerGuild = allGuilds[index]
            saveData()
        }
    }

    func promoteMember(_ member: GuildMember, to role: GuildRole, in guild: Guild) {
        guard let index = allGuilds.firstIndex(where: { $0.id == guild.id }) else { return }
        guard let memberIndex = allGuilds[index].members.firstIndex(where: { $0.id == member.id }) else { return }

        allGuilds[index].members[memberIndex].role = role
        playerGuild = allGuilds[index]
        saveData()
    }

    // MARK: - 申请管理

    func submitApplication(to guild: Guild, from playerName: String, petTypeString: String, petLevel: Int, message: String) {
        let application = GuildApplication(
            playerName: playerName,
            petTypeString: petTypeString,
            petLevel: petLevel,
            message: message
        )
        guildApplications.append(application)
        saveData()
    }

    func acceptApplication(_ application: GuildApplication, for guild: Guild) {
        let member = GuildMember(
            playerName: application.playerName,
            petTypeString: application.petTypeString,
            petLevel: application.petLevel,
            role: .recruit
        )

        addMember(member, to: guild)
        guildApplications.removeAll { $0.id == application.id }
        saveData()
    }

    func rejectApplication(_ application: GuildApplication) {
        guildApplications.removeAll { $0.id == application.id }
        saveData()
    }

    // MARK: - 贡献系统

    func addContribution(_ amount: Int, from member: GuildMember, to guild: Guild) {
        guard let index = allGuilds.firstIndex(where: { $0.id == guild.id }) else { return }
        guard let memberIndex = allGuilds[index].members.firstIndex(where: { $0.id == member.id }) else { return }

        // 更新成员贡献
        allGuilds[index].members[memberIndex].contribution += amount
        allGuilds[index].members[memberIndex].lastActive = Date()

        // 更新公会总贡献
        allGuilds[index].totalContribution += amount

        // 增加公会经验
        allGuilds[index].experience += amount

        // 检查升级
        checkLevelUp(for: &allGuilds[index])

        playerGuild = allGuilds[index]
        saveData()
    }

    private func checkLevelUp(for guild: inout Guild) {
        while guild.experience >= guild.requiredExp {
            guild.experience -= guild.requiredExp
            guild.level += 1
        }
    }

    // MARK: - 公会任务

    func updateGuildTask(_ taskId: UUID, progress: Int) {
        guard let index = guildTasks.firstIndex(where: { $0.id == taskId }) else { return }

        guildTasks[index].current += progress
        guildTasks[index].isCompleted = guildTasks[index].current >= guildTasks[index].target

        saveData()
    }

    func completeGuildTask(_ task: GuildTask) -> GuildTaskReward {
        // 奖励公会经验
        if var guild = playerGuild {
            guild.experience += task.reward.guildExp
            checkLevelUp(for: &guild)

            if let index = allGuilds.firstIndex(where: { $0.id == guild.id }) {
                allGuilds[index] = guild
                playerGuild = guild
            }
        }

        // 移除已完成任务
        guildTasks.removeAll { $0.id == task.id }
        saveData()

        return task.reward
    }

    // MARK: - 公会设置

    func updateNotice(_ newNotice: String, for guild: Guild) {
        if let index = allGuilds.firstIndex(where: { $0.id == guild.id }) {
            allGuilds[index].notice = newNotice
            playerGuild = allGuilds[index]
            saveData()
        }
    }

    // MARK: - 数据持久化

    private func saveData() {
        if let guild = playerGuild,
           let data = try? JSONEncoder().encode(guild) {
            defaults.set(data, forKey: "guild_playerGuild")
        }

        if let applications = try? JSONEncoder().encode(guildApplications) {
            defaults.set(applications, forKey: "guild_applications")
        }

        if let tasks = try? JSONEncoder().encode(guildTasks) {
            defaults.set(tasks, forKey: "guild_tasks")
        }

        if let guilds = try? JSONEncoder().encode(allGuilds) {
            defaults.set(guilds, forKey: "guild_allGuilds")
        }
    }

    private func loadData() {
        if let data = defaults.data(forKey: "guild_playerGuild"),
           let guild = try? JSONDecoder().decode(Guild.self, from: data) {
            playerGuild = guild
        }

        if let data = defaults.data(forKey: "guild_applications"),
           let applications = try? JSONDecoder().decode([GuildApplication].self, from: data) {
            guildApplications = applications
        }

        if let data = defaults.data(forKey: "guild_tasks"),
           let tasks = try? JSONDecoder().decode([GuildTask].self, from: data) {
            guildTasks = tasks
        }

        if let data = defaults.data(forKey: "guild_allGuilds"),
           let guilds = try? JSONDecoder().decode([Guild].self, from: data) {
            allGuilds = guilds
        }
    }

    // MARK: - 每日任务

    private func setupDailyTasks() {
        // 每天0点重置任务
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.resetDailyTasks()
        }
    }

    private func resetDailyTasks() {
        let calendar = Calendar.current
        let now = Date()

        // 检查是否是新的一天
        if let lastReset = defaults.object(forKey: "lastGuildTaskReset") as? Date {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                generateDailyTasks()
                defaults.set(now, forKey: "lastGuildTaskReset")
            }
        } else {
            generateDailyTasks()
            defaults.set(now, forKey: "lastGuildTaskReset")
        }
    }

    private func generateDailyTasks() {
        guildTasks = [
            GuildTask(
                title: "集体喂食",
                description: "成员共同完成100次喂食",
                target: 100,
                reward: GuildTaskReward(
                    guildExp: 200,
                    personalExp: 50,
                    contribution: 10,
                    specialCurrency: 5
                ),
                requiredMembers: 3
            ),
            GuildTask(
                title: "快乐聚会",
                description: "成员共同完成50次玩耍",
                target: 50,
                reward: GuildTaskReward(
                    guildExp: 150,
                    personalExp: 30,
                    contribution: 8,
                    specialCurrency: 3
                ),
                requiredMembers: 3
            ),
            GuildTask(
                title: "健身运动",
                description: "成员共同完成30次锻炼",
                target: 30,
                reward: GuildTaskReward(
                    guildExp: 180,
                    personalExp: 40,
                    contribution: 9,
                    specialCurrency: 4
                ),
                requiredMembers: 2
            )
        ]
    }

    // MARK: - 获取成员权限

    func getPermissions(for member: GuildMember, in guild: Guild) -> GuildPermissions {
        return member.role.permissions
    }

    // MARK: - 生成模拟数据

    func generateMockGuilds() {
        let guildNames = [
            "快乐宠物园", "精英训练营", "萌宠之家", "星际联盟",
            "王者公会", "梦幻天堂", "战神殿", "龙腾四海"
        ]

        let icons = ["star.circle.fill", "heart.circle.fill", "bolt.circle.fill", "flame.fill"]

        for name in guildNames {
            let icon = icons.randomElement() ?? "star.circle.fill"

            // 创建会长
            let leader = GuildMember(
                playerName: "\(name)会长",
                petTypeString: ["🐱", "🐶", "🐰", "🐹"].randomElement() ?? "🐱",
                petLevel: Int.random(in: 30...50),
                role: .leader,
                contribution: Int.random(in: 500...1000)
            )

            // 创建成员
            var members: [GuildMember] = [leader]
            let memberCount = Int.random(in: 5...20)

            for i in 0..<memberCount {
                let role: GuildRole = i < 2 ? .viceLeader : (i < 4 ? .elder : .member)
                let member = GuildMember(
                    playerName: "成员\(Int.random(in: 1000...9999))",
                    petTypeString: ["🐱", "🐶", "🐰", "🐹", "🐦"].randomElement() ?? "🐱",
                    petLevel: Int.random(in: 10...40),
                    role: role,
                    contribution: Int.random(in: 50...500)
                )
                members.append(member)
            }

            let guild = Guild(
                name: name,
                icon: icon,
                description: "欢迎加入\(name),一起养宠!",
                level: Int.random(in: 1...10),
                experience: Int.random(in: 0...5000),
                members: members,
                notice: "公会公告: 每日记得完成公会任务哦!",
                totalContribution: members.reduce(0) { $0 + $1.contribution }
            )

            allGuilds.append(guild)
        }

        saveData()
    }
}

// MARK: - UI 组件

struct GuildView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @StateObject private var guildManager = GuildManager.shared
    @State private var selectedTab = 0
    @State private var showingCreateGuild = false
    @State private var showingGuildList = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let guild = guildManager.playerGuild {
                    // 已加入公会
                    guildContentView(guild: guild)
                } else {
                    // 未加入公会
                    guildListView
                }
            }
            .navigationTitle("🏰 公会")
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
            if guildManager.allGuilds.isEmpty {
                guildManager.generateMockGuilds()
            }
        }
    }

    // MARK: - 公会内容视图

    @ViewBuilder
    private func guildContentView(guild: Guild) -> some View {
        VStack(spacing: 0) {
            // Tab选择器
            Picker("公会功能", selection: $selectedTab) {
                Text("主页").tag(0)
                Text("成员").tag(1)
                Text("任务").tag(2)
                Text("申请").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // 内容区域
            ScrollView {
                switch selectedTab {
                case 0:
                    guildHomeView(guild: guild)
                case 1:
                    guildMembersView(guild: guild)
                case 2:
                    guildTasksView
                case 3:
                    guildApplicationsView
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - 公会主页

    private func guildHomeView(guild: Guild) -> some View {
        VStack(spacing: 20) {
            // 公会信息卡片
            VStack(spacing: 16) {
                // 图标和名称
                HStack(spacing: 16) {
                    Image(systemName: guild.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(guild.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Lv.\(guild.level)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }

                // 经验条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("经验值")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(guild.experience)/\(guild.requiredExp)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    ProgressView(value: guild.levelProgress)
                        .accentColor(.purple)
                }

                // 统计信息
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(guild.memberCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("成员")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(guild.totalContribution)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("总贡献")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(guild.maxMembers)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("上限")
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

            // 公会公告
            VStack(alignment: .leading, spacing: 12) {
                Text("📢 公会公告")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(guild.notice.isEmpty ? "暂无公告" : guild.notice)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.2))
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding()
    }

    // MARK: - 成员列表

    private func guildMembersView(guild: Guild) -> some View {
        VStack(spacing: 12) {
            ForEach(guild.members.sorted { $0.role.rawValue < $1.role.rawValue }) { member in
                GuildMemberRow(member: member)
            }
        }
        .padding()
    }

    // MARK: - 公会任务

    private var guildTasksView: some View {
        VStack(spacing: 16) {
            if guildManager.guildTasks.isEmpty {
                Text("暂无任务")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
            } else {
                ForEach(guildManager.guildTasks) { task in
                    GuildTaskCard(task: task)
                }
            }
        }
        .padding()
    }

    // MARK: - 申请列表

    private var guildApplicationsView: some View {
        VStack(spacing: 12) {
            if guildManager.guildApplications.isEmpty {
                Text("暂无申请")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
            } else {
                ForEach(guildManager.guildApplications) { application in
                    GuildApplicationCard(application: application)
                }
            }
        }
        .padding()
    }

    // MARK: - 公会列表视图

    private var guildListView: some View {
        VStack(spacing: 20) {
            // 操作按钮
            HStack(spacing: 16) {
                Button(action: { showingCreateGuild = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)

                        Text("创建公会")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                Button(action: { showingGuildList = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        Text("查找公会")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }

            // 推荐公会
            VStack(alignment: .leading, spacing: 12) {
                Text("🌟 推荐公会")
                    .font(.headline)
                    .foregroundColor(.white)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(guildManager.allGuilds.shuffled().prefix(5)) { guild in
                            GuildCard(guild: guild, pet: pet)
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingCreateGuild) {
            CreateGuildView(pet: pet, isPresented: $showingCreateGuild)
        }
        .sheet(isPresented: $showingGuildList) {
            GuildListView(pet: pet, isPresented: $showingGuildList)
        }
    }
}

// MARK: - 公会成员行

struct GuildMemberRow: View {
    let member: GuildMember

    var body: some View {
        HStack(spacing: 12) {
            // 职位图标
            Image(systemName: member.roleIcon)
                .font(.title2)
                .foregroundColor(member.role.color)
                .frame(width: 30)

            // 宠物图标
            Text(member.petEmoji)
                .font(.title2)

            // 成员信息
            VStack(alignment: .leading, spacing: 4) {
                Text(member.playerName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Lv.\(member.petLevel)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // 贡献值
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(member.contribution)")
                    .font(.headline)
                    .foregroundColor(.yellow)

                Text("贡献")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - 公会任务卡片

struct GuildTaskCard: View {
    let task: GuildTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(task.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            ProgressView(value: task.progress)
                .accentColor(.purple)

            HStack {
                Text("\(task.current)/\(task.target)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("需\(task.requiredMembers)人")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - 公会申请卡片

struct GuildApplicationCard: View {
    let application: GuildApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(application.petEmoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(application.playerName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Lv.\(application.petLevel)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }

            if !application.message.isEmpty {
                Text(application.message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - 公会卡片

struct GuildCard: View {
    let guild: Guild
    let pet: Pet

    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: guild.icon)
                        .font(.title)
                        .foregroundColor(.purple)

                    Text(guild.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("Lv.\(guild.level)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Text(guild.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Label("\(guild.memberCount)/\(guild.maxMembers)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()

                    Label("\(guild.totalContribution)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .sheet(isPresented: $showingDetail) {
            GuildDetailView(guild: guild, pet: pet)
        }
    }
}

// MARK: - 创建公会视图

struct CreateGuildView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var guildName = ""
    @State private var selectedIcon = "star.circle.fill"
    @State private var guildDescription = ""

    @StateObject private var guildManager = GuildManager.shared

    let icons = ["star.circle.fill", "heart.circle.fill", "bolt.circle.fill", "flame.fill", "crown.fill"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("公会名称", text: $guildName)

                    Picker("公会图标", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .foregroundColor(.purple)
                        }
                    }

                    TextEditor(text: $guildDescription)
                        .frame(height: 100)
                }
            }
            .navigationTitle("创建公会")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createGuild()
                    }
                    .disabled(guildName.isEmpty)
                }
            }
        }
    }

    private func createGuild() {
        let creator = GuildMember(
            playerName: "我的宠物",
            petTypeString: pet.petType.rawValue,
            petLevel: pet.level
        )

        _ = guildManager.createGuild(
            name: guildName,
            icon: selectedIcon,
            description: guildDescription,
            creator: creator
        )

        isPresented = false
    }
}

// MARK: - 公会列表视图

struct GuildListView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @StateObject private var guildManager = GuildManager.shared
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("搜索公会", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                )
                .padding()

                // 公会列表
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredGuilds) { guild in
                            GuildCard(guild: guild, pet: pet)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("查找公会")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private var filteredGuilds: [Guild] {
        if searchText.isEmpty {
            return guildManager.allGuilds
        }
        return guildManager.allGuilds.filter {
            $0.name.contains(searchText) || $0.description.contains(searchText)
        }
    }
}

// MARK: - 公会详情视图

struct GuildDetailView: View {
    let guild: Guild
    @ObservedObject var pet: Pet

    @State private var applicationMessage = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @StateObject private var guildManager = GuildManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 公会信息
                    VStack(spacing: 16) {
                        Image(systemName: guild.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.purple)

                        Text(guild.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Lv.\(guild.level)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text(guild.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 30) {
                            VStack(spacing: 4) {
                                Text("\(guild.memberCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("成员")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            VStack(spacing: 4) {
                                Text("\(guild.totalContribution)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("总贡献")
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

                    // 申请加入
                    VStack(spacing: 12) {
                        Text("申请留言")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextEditor(text: $applicationMessage)
                            .frame(height: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                            )

                        Button(action: submitApplication) {
                            Text("申请加入")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                    )
                }
                .padding()
            }
            .navigationTitle("公会详情")
            .navigationBarTitleDisplayMode(.inline)
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func submitApplication() {
        guard guild.memberCount < guild.maxMembers else {
            alertMessage = "公会成员已满"
            showingAlert = true
            return
        }

        guildManager.submitApplication(
            to: guild,
            from: "我的宠物",
            petTypeString: pet.petType.rawValue,
            petLevel: pet.level,
            message: applicationMessage
        )

        alertMessage = "申请已发送"
        showingAlert = true
    }
}

// MARK: - 预览

#Preview {
    GuildView(pet: Pet(), isPresented: .constant(true))
}
