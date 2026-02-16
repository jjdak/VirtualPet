//
//  DailyTaskManager.swift
//  VirtualPet
//
//  每日任务系统
// 生成、追踪和管理每日任务
//

import SwiftUI
import Combine

// 每日任务
struct DailyTask: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: CodableColor
    let target: Int
    let reward: TaskReward
    var current: Int = 0
    var isCompleted: Bool = false
    var isClaimed: Bool = false

    var progress: Double {
        Double(current) / Double(target)
    }

    var remaining: Int {
        max(0, target - current)
    }

    // 手动实现Codable以排除computed properties
    enum CodingKeys: String, CodingKey {
        case id, title, description, icon, color, target, reward, current, isCompleted, isClaimed
    }
}

// 任务奖励
struct TaskReward: Codable {
    let experience: Int
    let happiness: Int
    let health: Int?
    let energy: Int?
    let specialCurrency: Int
    let items: [String]

    init(
        experience: Int = 0,
        happiness: Int = 0,
        health: Int? = nil,
        energy: Int? = nil,
        specialCurrency: Int = 0,
        items: [String] = []
    ) {
        self.experience = experience
        self.happiness = happiness
        self.health = health
        self.energy = energy
        self.specialCurrency = specialCurrency
        self.items = items
    }
}

// 每日任务类型
enum DailyTaskType: String, CaseIterable {
    case feed = "喂食宠物"
    case play = "玩耍互动"
    case exercise = "运动锻炼"
    case clean = "清洁护理"
    case miniGame = "小游戏"
    case social = "社交互动"
    case training = "技能训练"
    case login = "登录游戏"

    var icon: String {
        switch self {
        case .feed: return "leaf.fill"
        case .play: return "gamecontroller.fill"
        case .exercise: return "figure.run"
        case .clean: return "sparkles"
        case .miniGame: return "star.circle.fill"
        case .social: return "person.2.fill"
        case .training: return "book.fill"
        case .login: return "app.badge.fill"
        }
    }

    var color: Color {
        switch self {
        case .feed: return .green
        case .play: return .blue
        case .exercise: return .orange
        case .clean: return .cyan
        case .miniGame: return .purple
        case .social: return .pink
        case .training: return .indigo
        case .login: return .yellow
        }
    }

    var description: String {
        switch self {
        case .feed: return "喂食宠物3次"
        case .play: return "与宠物玩耍5次"
        case .exercise: return "运动锻炼2次"
        case .clean: return "清洁护理2次"
        case .miniGame: return "完成1局小游戏"
        case .social: return "社交互动1次"
        case .training: return "技能训练1次"
        case .login: return "登录游戏1次"
        }
    }
}

// 每日任务管理器
class DailyTaskManager: ObservableObject {
    static let shared = DailyTaskManager()

    @Published var dailyTasks: [DailyTask] = []
    @Published var streak: Int = 0
    @Published var lastResetDate: Date = Date()
    @Published var allTimeCompleted: Int = 0

    private var taskTimer: Timer?

    private init() {
        loadDailyTasks()
        checkAndReset()
        setupDailyResetTimer()
    }

    // 设置每日重置定时器
    private func setupDailyResetTimer() {
        // 每小时检查一次是否需要重置
        taskTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndReset()
        }
    }

    // 检查并重置每日任务
    private func checkAndReset() {
        let calendar = Calendar.current
        let now = Date()

        // 检查是否是新的一天
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            resetDailyTasks()
        }
    }

    // 重置每日任务
    private func resetDailyTasks() {
        // 如果连续完成,增加连续天数
        if dailyTasks.allSatisfy({ $0.isCompleted }) {
            streak += 1
        } else {
            streak = 0
        }

        lastResetDate = Date()
        generateDailyTasks()
        saveData()
    }

    // 生成每日任务
    private func generateDailyTasks() {
        var tasks: [DailyTask] = []

        // 随机选择3-5个任务
        let allTaskTypes = DailyTaskType.allCases
        let selectedTypes = allTaskTypes.shuffled().prefix(Int.random(in: 3...5))

        for taskType in selectedTypes {
            let task = DailyTask(
                title: taskType.rawValue,
                description: taskType.description,
                icon: taskType.icon,
                color: CodableColor(from: taskType.color),
                target: getTarget(for: taskType),
                reward: getReward(for: taskType),
                current: 0,
                isCompleted: false
            )
            tasks.append(task)
        }

        dailyTasks = tasks
    }

    // 获取任务目标
    private func getTarget(for type: DailyTaskType) -> Int {
        switch type {
        case .feed: return 3
        case .play: return 5
        case .exercise: return 2
        case .clean: return 2
        case .miniGame: return 1
        case .social: return 1
        case .training: return 1
        case .login: return 1
        }
    }

    // 获取任务奖励
    private func getReward(for type: DailyTaskType) -> TaskReward {
        switch type {
        case .feed:
            return TaskReward(experience: 15, happiness: 5, specialCurrency: 1)
        case .play:
            return TaskReward(experience: 20, happiness: 10, specialCurrency: 1)
        case .exercise:
            return TaskReward(experience: 25, happiness: 0, health: 10, energy: -5, specialCurrency: 2)
        case .clean:
            return TaskReward(experience: 15, happiness: 5, health: 5, energy: nil, specialCurrency: 1)
        case .miniGame:
            return TaskReward(experience: 30, specialCurrency: 5)
        case .social:
            return TaskReward(experience: 20, happiness: 10, specialCurrency: 2)
        case .training:
            return TaskReward(experience: 35, energy: -10, specialCurrency: 3)
        case .login:
            return TaskReward(experience: 10, specialCurrency: 1)
        }
    }

    // 更新任务进度
    func updateTask(type: DailyTaskType) {
        guard let index = dailyTasks.firstIndex(where: { $0.title == type.rawValue }) else { return }

        let task = dailyTasks[index]
        guard !task.isCompleted && task.current < task.target else { return }

        dailyTasks[index].current += 1
        dailyTasks[index].isCompleted = dailyTasks[index].current >= dailyTasks[index].target

        // 检查是否所有任务完成
        if dailyTasks[index].isCompleted {
            checkAllTasksCompleted()
        }

        saveData()
    }

    // 检查所有任务是否完成
    private func checkAllTasksCompleted() {
        if dailyTasks.allSatisfy({ $0.isCompleted }) {
            allTimeCompleted += 1
            // 发送完成通知
            NotificationCenter.default.post(
                name: NSNotification.Name("AllDailyTasksCompleted"),
                object: nil,
                userInfo: ["streak": streak]
            )

            HapticManager.shared.trigger(.heavy)
        }
    }

    // 领取任务奖励
    func claimReward(for task: DailyTask) -> TaskReward? {
        guard let index = dailyTasks.firstIndex(where: { $0.id == task.id }) else { return nil }

        let dailyTask = dailyTasks[index]
        guard dailyTask.isCompleted else { return nil }

        // 应用奖励到宠物 (需要访问Pet实例)
        // 这里只返回奖励,实际应用在调用处处理
        return dailyTask.reward
    }

    // 领取所有完成任务的奖励
    func claimAllRewards() -> [TaskReward] {
        let completedTasks = dailyTasks.filter { $0.isCompleted }
        let rewards = completedTasks.map { $0.reward }

        // 标记任务为已领取
        for index in dailyTasks.indices {
            if dailyTasks[index].isCompleted && !dailyTasks[index].isClaimed {
                dailyTasks[index].isClaimed = true
            }
        }

        saveData()
        return rewards
    }

    // 获取每日任务完成进度
    var completionProgress: Double {
        guard !dailyTasks.isEmpty else { return 0 }
        let completedCount = dailyTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(dailyTasks.count)
    }

    // 保存数据
    private func saveData() {
        let defaults = UserDefaults.standard

        // 保存日期
        defaults.set(lastResetDate, forKey: "dailyTask_lastReset")

        // 保存连续天数
        defaults.set(streak, forKey: "dailyTask_streak")
        defaults.set(allTimeCompleted, forKey: "dailyTask_allTimeCompleted")

        // 保存任务数据
        if let encoded = try? JSONEncoder().encode(dailyTasks) {
            defaults.set(encoded, forKey: "dailyTask_tasks")
        }
    }

    // 加载数据
    private func loadDailyTasks() {
        let defaults = UserDefaults.standard

        // 加载日期
        if let date = defaults.object(forKey: "dailyTask_lastReset") as? Date {
            lastResetDate = date
        }

        // 加载连续天数
        streak = defaults.integer(forKey: "dailyTask_streak")
        allTimeCompleted = defaults.integer(forKey: "dailyTask_allTimeCompleted")

        // 加载任务
        if let data = defaults.data(forKey: "dailyTask_tasks"),
           let decodedTasks = try? JSONDecoder().decode([DailyTask].self, from: data) {
            dailyTasks = decodedTasks
        } else {
            // 如果没有保存的任务,生成新的
            generateDailyTasks()
        }
    }

    // 手动刷新任务 (用于测试)
    func refreshTasks() {
        generateDailyTasks()
        saveData()
    }
}

// 每日任务视图
struct DailyTasksView: View {
    @ObservedObject var taskManager = DailyTaskManager.shared
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 20) {
            // 头部信息
            VStack(spacing: 12) {
                HStack {
                    Text("📋 每日任务")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    // 连续天数
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)

                        Text("\(taskManager.streak)天")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }

                // 进度条
                VStack(alignment: .leading, spacing: 8) {
                    Text("完成进度: \(Int(taskManager.completionProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: taskManager.completionProgress)
                        .accentColor(.blue)
                }
            }

            // 任务列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(taskManager.dailyTasks) { task in
                        DailyTaskCard(
                            task: task,
                            pet: pet,
                            onClaim: {
                                if let reward = taskManager.claimReward(for: task) {
                                    applyReward(reward)
                                }
                            }
                        )
                    }
                }
            }

            // 底部操作
            VStack(spacing: 12) {
                Text("总完成: \(taskManager.allTimeCompleted)天")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("刷新任务") {
                    taskManager.refreshTasks()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.background)
                .shadow(radius: 5)
        )
    }

    // 应用奖励
    private func applyReward(_ reward: TaskReward) {
        pet.experience += reward.experience
        pet.happiness = min(100, pet.happiness + reward.happiness)
        if let health = reward.health {
            pet.health = min(100, pet.health + health)
        }
        if let energy = reward.energy {
            pet.energy = min(100, max(0, pet.energy + energy))
        }
        pet.specialCurrency += reward.specialCurrency

        // 震动反馈
        HapticManager.shared.trigger(.medium)

        // 记录活动
        pet.logActivity(
            Activity(
                title: "领取任务奖励",
                icon: "gift.fill",
                color: CodableColor(from: Color.purple),
                date: Date(),
                value: reward.experience
            )
        )
    }
}

// 每日任务卡片
struct DailyTaskCard: View {
    let task: DailyTask
    let pet: Pet
    let onClaim: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(red: task.color.red/255, green: task.color.green/255, blue: task.color.blue/255).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: task.icon)
                    .foregroundColor(Color(red: task.color.red/255, green: task.color.green/255, blue: task.color.blue/255))
            }

            // 任务信息
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 进度条
                ProgressView(value: task.progress)
                    .accentColor(Color(red: task.color.red/255, green: task.color.green/255, blue: task.color.blue/255))
                    .frame(height: 4)

                Text("\(task.current)/\(task.target)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 奖励信息
            VStack(alignment: .trailing, spacing: 4) {
                if task.isCompleted {
                    Button(action: onClaim) {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                            Text("领取")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .disabled(false)
                } else {
                    Text("待完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 奖励预览
                HStack(spacing: 2) {
                    if task.reward.experience > 0 {
                        RewardIcon(type: "exp", value: task.reward.experience)
                    }
                    if task.reward.specialCurrency > 0 {
                        RewardIcon(type: "gem", value: task.reward.specialCurrency)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(task.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

// 奖励图标
struct RewardIcon: View {
    let type: String
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: type == "exp" ? "star.fill" : "diamond.fill")
                .font(.caption2)
            Text("\(value)")
                .font(.caption2)
        }
    }
}

// 预览
#Preview {
    DailyTasksView(pet: Pet())
        .padding()
        .background(Color.gray.opacity(0.1))
}
