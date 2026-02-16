//
//  MiniGameHubView.swift
//  VirtualPet
//
//  小游戏中心
//  提供多种小游戏选择和入口
//

import SwiftUI

struct MiniGameHubView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool
    @State private var selectedGame: MiniGameType?
    @State private var showingGame = false

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                // 标题
                Text("🎮 小游戏中心")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // 小游戏列表
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(MiniGameType.allCases, id: \.self) { game in
                        MiniGameCard(
                            game: game,
                            pet: pet,
                            isOnCooldown: pet.isMiniGameOnCooldown(game),
                            cooldownRemaining: pet.getMiniGameCooldownRemaining(game),
                            action: {
                                selectedGame = game
                                showingGame = true
                            }
                        )
                    }
                }

                // 关闭按钮
                Button(action: {
                    isPresented = false
                }) {
                    Text("关闭")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.background)
                    .shadow(radius: 20)
            )
            .padding(40)
        }
        .sheet(isPresented: $showingGame) {
            if let game = selectedGame {
                MiniGameView(gameType: game, pet: pet, isPresented: $showingGame)
            }
        }
    }
}

// 小游戏卡片组件
struct MiniGameCard: View {
    let game: MiniGameType
    let pet: Pet
    let isOnCooldown: Bool
    let cooldownRemaining: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(game.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: game.icon)
                        .font(.system(size: 28))
                        .foregroundColor(game.color)
                }

                // 名称
                Text(game.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                // 描述
                Text(game.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // 冷却状态
                if isOnCooldown {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(cooldownRemaining)
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("可游玩")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isOnCooldown ? Color.gray.opacity(0.3) : game.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isOnCooldown ? Color.gray.opacity(0.3) : game.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isOnCooldown)
    }
}

// 小游戏视图
struct MiniGameView: View {
    let gameType: MiniGameType
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var gameScore = 0
    @State private var gameResult: MiniGameResult?
    @State private var showingResult = false

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [gameType.color.opacity(0.3), gameType.color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 顶部栏
                HStack {
                    Button("退出") {
                        isPresented = false
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Text(gameType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Text("得分: \(gameScore)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()

                Spacer()

                // 游戏内容
                if showingResult, let result = gameResult {
                    GameResultView(
                        result: result,
                        gameType: gameType,
                        onRestart: {
                            showingResult = false
                            gameScore = 0
                        },
                        onExit: {
                            isPresented = false
                        }
                    )
                } else {
                    gameContent
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var gameContent: some View {
        switch gameType {
        case .feedingFrenzy:
            BallTossGame(score: $gameScore) { finalScore in
                finishGame(score: finalScore)
            }
        case .memoryCards:
            MemoryGameView(pet: pet, isPresented: $isPresented)
        case .catchToys:
            TappingGame(score: $gameScore) { finalScore in
                finishGame(score: finalScore)
            }
        case .reactionTest:
            ReactionGameView(pet: pet, isPresented: $isPresented)
        case .cleaningGame:
            CleaningMiniGameView(pet: pet, isPresented: $isPresented)
        }
    }

    private func finishGame(score: Int) {
        // 调用 Pet 的迷你游戏逻辑
        let result = pet.playMiniGame(gameType)

        // 更新显示的分数
        gameScore = score
        gameResult = result
        showingResult = true

        // 震动反馈
        if result.success {
            HapticManager.shared.trigger(.heavy)
        } else {
            HapticManager.shared.trigger(.medium)
        }
    }
}

// 游戏结果视图
struct GameResultView: View {
    let result: MiniGameResult
    let gameType: MiniGameType
    let onRestart: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // 结果图标
            Image(systemName: result.success ? "trophy.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(result.success ? .yellow : .red)

            // 结果标题
            Text(result.success ? "🎉 胜利！" : "😢 失败")
                .font(.title)
                .fontWeight(.bold)

            // 分数
            Text("得分: \(result.score)")
                .font(.title2)
                .foregroundColor(.secondary)

            // 奖励
            VStack(spacing: 8) {
                RewardItem(icon: "star.fill", label: "经验", value: "+\(result.rewards.experience)")
                RewardItem(icon: "heart.fill", label: "快乐", value: "+\(result.rewards.happiness)")
                RewardItem(icon: "bolt.fill", label: "能量", value: "+\(result.rewards.energy)")
                RewardItem(icon: "diamond.fill", label: "钻石", value: "+\(result.rewards.specialCurrency)")
            }

            // 消息
            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            // 按钮
            HStack(spacing: 16) {
                Button(action: onRestart) {
                    Text("再来一次")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(gameType.color)
                        .cornerRadius(12)
                }

                Button(action: onExit) {
                    Text("退出")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(12)
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.background)
                .shadow(radius: 20)
        )
        .padding(40)
    }
}

// 奖励项组件
struct RewardItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)

            Text(label)
                .font(.body)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(.horizontal)
    }
}

// MARK: - 简化版小游戏 (作为占位符)

// 扔球游戏 (反应速度)
struct BallTossGame: View {
    @Binding var score: Int
    let onComplete: (Int) -> Void

    @State private var showBall = false
    @State private var tapCount = 0
    @State private var gameTimer: Timer?

    var body: some View {
        VStack(spacing: 40) {
            Text("点击出现的球!")
                .font(.title2)

            ZStack {
                if showBall {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .onTapGesture {
                            tapCount += 1
                            score += 10
                            showBall = false

                            if tapCount >= 5 {
                                endGame()
                            }
                        }
                        .transition(.scale)
                }
            }
            .frame(width: 200, height: 200)

            Text("进度: \(tapCount)/5")
                .font(.headline)
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            gameTimer?.invalidate()
        }
    }

    private func startGame() {
        tapCount = 0
        score = 0

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation {
                showBall = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showBall = false
                }
            }
        }
    }

    private func endGame() {
        gameTimer?.invalidate()
        onComplete(score)
    }
}

// 简单反应游戏
struct SimpleReactionGame: View {
    @Binding var score: Int
    let onComplete: (Int) -> Void

    @State private var targetColor: Color = .red
    @State private var options: [Color] = []
    @State private var round = 0

    var body: some View {
        VStack(spacing: 40) {
            Text("点击正确的颜色!")
                .font(.title2)

            Circle()
                .fill(targetColor)
                .frame(width: 100, height: 100)

            HStack(spacing: 20) {
                ForEach(options, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                        .onTapGesture {
                            if color == targetColor {
                                score += 20
                            }

                            nextRound()
                        }
                }
            }
        }
        .onAppear {
            startGame()
        }
    }

    private func startGame() {
        round = 0
        score = 0
        nextRound()
    }

    private func nextRound() {
        round += 1

        if round > 3 {
            onComplete(score)
            return
        }

        let colors: [Color] = [.red, .blue, .green, .yellow]
        targetColor = colors.randomElement() ?? .red

        var tempOptions = [targetColor]
        tempOptions.append(contentsOf: colors.shuffled().filter { $0 != targetColor }.prefix(2))
        options = tempOptions.shuffled()
    }
}

// 连点游戏
struct TappingGame: View {
    @Binding var score: Int
    let onComplete: (Int) -> Void

    @State private var remainingTime = 5.0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 40) {
            Text("快速点击!")
                .font(.title2)

            Text(String(format: "%.1f秒", remainingTime))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(remainingTime < 2 ? .red : .primary)

            Button(action: {
                score += 5
            }) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 100, height: 100)
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startGame() {
        remainingTime = 5.0
        score = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            remainingTime -= 0.1

            if remainingTime <= 0 {
                timer?.invalidate()
                onComplete(score)
            }
        }
    }
}

// 预览
#Preview {
    MiniGameHubView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
