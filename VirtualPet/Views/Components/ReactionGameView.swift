//
//  ReactionGameView.swift
//  VirtualPet
//
//  反应测试游戏
//  快速点击目标,锻炼反应速度
//

import SwiftUI

// 目标点
struct TargetPoint: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let lifetime: TimeInterval
    let createdAt: Date
    var isHit = false

    var isExpired: Bool {
        Date().timeIntervalSince(createdAt) > lifetime
    }

    var remainingProgress: Double {
        let elapsed = Date().timeIntervalSince(createdAt)
        return max(0, 1 - (elapsed / lifetime))
    }
}

// 反应游戏视图
struct ReactionGameView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var targets: [TargetPoint] = []
    @State private var gameTimer: Timer?
    @State private var targetSpawner: Timer?
    @State private var remainingTime = 30.0
    @State private var showResult = false
    @State private var finalScore = 0
    @State private var hits = 0
    @State private var misses = 0
    @State private var combo = 0
    @State private var maxCombo = 0
    @State private var gameAreaSize: CGSize = .zero

    private let gameDuration: TimeInterval = 30.0
    private let baseSpawnInterval: TimeInterval = 1.0

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button("退出") {
                        endGame()
                        isPresented = false
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Text("反应测试")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(finalScore)")
                                .font(.caption)
                        }
                        .foregroundColor(.white)

                        if combo > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                Text("x\(combo)")
                                    .font(.caption)
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()

                // 倒计时和统计
                if !showResult {
                    HStack(spacing: 16) {
                        // 倒计时
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(Int(remainingTime))s")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )

                        // 命中/失误
                        HStack(spacing: 8) {
                            Label("\(hits)", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)

                            Label("\(misses)", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // 游戏区域
                if showResult {
                    ReactionGameResultView(
                        score: finalScore,
                        hits: hits,
                        misses: misses,
                        maxCombo: maxCombo,
                        accuracy: accuracy,
                        onRestart: {
                            resetGame()
                        },
                        onExit: {
                            isPresented = false
                        }
                    )
                } else {
                    GeometryReader { geometry in
                        ZStack {
                            // 目标点
                            ForEach(targets) { target in
                                TargetView(target: target) {
                                    hitTarget(target)
                                }
                            }
                        }
                        .onAppear {
                            gameAreaSize = geometry.size
                        }
                        .onChange(of: geometry.size) { oldValue, newValue in
                            gameAreaSize = newValue
                        }
                    }
                    .padding()
                }

                Spacer()
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            gameTimer?.invalidate()
            targetSpawner?.invalidate()
        }
    }

    private var accuracy: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total)
    }

    // 开始游戏
    private func startGame() {
        resetGame()

        // 启动倒计时
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            remainingTime -= 0.1

            // 清理过期目标
            targets.removeAll { target in
                if target.isExpired && !target.isHit {
                    misses += 1
                    combo = 0
                    return true
                }
                return false
            }

            if remainingTime <= 0 {
                endGame()
            }
        }

        // 启动目标生成器
        targetSpawner = Timer.scheduledTimer(withTimeInterval: baseSpawnInterval, repeats: true) { _ in
            spawnTarget()
        }
    }

    // 重置游戏
    private func resetGame() {
        targets = []
        remainingTime = gameDuration
        showResult = false
        finalScore = 0
        hits = 0
        misses = 0
        combo = 0
        maxCombo = 0
    }

    // 生成目标
    private func spawnTarget() {
        guard remainingTime > 0 else { return }

        // 随机位置 (避免边缘)
        let padding: CGFloat = 50
        let maxX = max(100, gameAreaSize.width - padding * 2)
        let maxY = max(100, gameAreaSize.height - padding * 2)

        let x = CGFloat.random(in: padding...(padding + maxX))
        let y = CGFloat.random(in: padding...(padding + maxY))

        // 随机大小
        let size = CGFloat.random(in: 40...70)

        // 存在时间 (越小存续越短)
        let lifetime = TimeInterval.random(in: 1.5...3.0)

        let target = TargetPoint(
            position: CGPoint(x: x, y: y),
            size: size,
            lifetime: lifetime,
            createdAt: Date()
        )

        targets.append(target)

        // 限制同时存在的目标数量
        if targets.count > 5 {
            targets.removeFirst()
        }
    }

    // 击中目标
    private func hitTarget(_ target: TargetPoint) {
        guard let index = targets.firstIndex(where: { $0.id == target.id }) else { return }
        guard !targets[index].isHit else { return }

        targets[index].isHit = true
        targets.remove(at: index)

        hits += 1
        combo += 1
        maxCombo = max(maxCombo, combo)

        // 计算得分 (combo加成)
        let comboBonus = Double(combo) * 0.5
        let baseScore = 10
        finalScore += Int(round(Double(baseScore) * (1.0 + comboBonus)))

        // 触觉反馈
        HapticManager.shared.trigger(.light)
    }

    // 结束游戏
    private func endGame() {
        gameTimer?.invalidate()
        targetSpawner?.invalidate()
        showResult = true

        // 应用奖励到宠物
        applyReward()
    }

    // 应用奖励
    private func applyReward() {
        let experience = finalScore
        let happiness = min(100, pet.happiness + hits * 3)
        let energy = max(0, pet.energy - 10) // 消耗能量

        pet.experience += experience
        pet.happiness = happiness
        pet.energy = energy

        // 震动反馈
        HapticManager.shared.trigger(.medium)

        // 记录活动
        pet.logActivity(
            Activity(
                title: "反应测试游戏",
                icon: "bolt.circle.fill",
                color: CodableColor(from: Color.orange),
                date: Date(),
                value: Int(exactly: experience)
            )
        )

        // 更新每日任务
        DailyTaskManager.shared.updateTask(type: .miniGame)
    }
}

// 目标视图
struct TargetView: View {
    let target: TargetPoint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // 外圈倒计时指示器
                Circle()
                    .stroke(
                        Color.orange.opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: target.size, height: target.size)

                Circle()
                    .trim(from: 0, to: target.remainingProgress)
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: target.size, height: target.size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: target.remainingProgress)

                // 目标圆圈
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: target.size * 0.7, height: target.size * 0.7)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )

                Image(systemName: "scope")
                    .font(.system(size: target.size * 0.3))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .position(target.position)
    }
}

// 结果视图
struct ReactionGameResultView: View {
    let score: Int
    let hits: Int
    let misses: Int
    let maxCombo: Int
    let accuracy: Double
    let onRestart: () -> Void
    let onExit: () -> Void

    var grade: String {
        if accuracy >= 0.9 && score >= 500 { return "S" }
        if accuracy >= 0.8 && score >= 400 { return "A" }
        if accuracy >= 0.7 && score >= 300 { return "B" }
        if accuracy >= 0.6 { return "C" }
        return "D"
    }

    var gradeColor: Color {
        switch grade {
        case "S": return .yellow
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        default: return .gray
        }
    }

    var accuracyText: String {
        String(format: "%.1f%%", accuracy * 100)
    }

    var body: some View {
        VStack(spacing: 24) {
            // 等级
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Text(grade)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(gradeColor)
            }

            // 分数
            VStack(spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("总分")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            // 统计
            VStack(spacing: 12) {
                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Text("\(hits)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("命中")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(misses)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("失误")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("x\(maxCombo)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("最大连击")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                HStack {
                    Text("准确率")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text(accuracyText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(accuracy >= 0.7 ? .green : .orange)
                }
            }

            // 按钮
            VStack(spacing: 12) {
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再来一局")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(12)
                }

                Button(action: onExit) {
                    Text("退出")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// 预览
#Preview {
    ReactionGameView(pet: Pet(), isPresented: .constant(true))
}
