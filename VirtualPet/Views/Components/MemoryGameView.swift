//
//  MemoryGameView.swift
//  VirtualPet
//
//  记忆卡片游戏
//  翻牌配对,锻炼记忆力
//

import SwiftUI

// 卡片数据
struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
    var isFlipped = false
    var isMatched = false
}

// 记忆游戏视图
struct MemoryGameView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var cards: [MemoryCard] = []
    @State private var flippedCards: [MemoryCard] = []
    @State private var matchedPairs = 0
    @State private var moves = 0
    @State private var gameTimer: Timer?
    @State private var remainingTime = 60.0
    @State private var showResult = false
    @State private var finalScore = 0
    @State private var isProcessing = false

    private let pairsCount = 8 // 8对卡片
    private let emojis = ["🐶", "🐱", "🐼", "🦊", "🐨", "🐯", "🦁", "🐮"]

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 顶部栏
                HStack {
                    Button("退出") {
                        endGame()
                        isPresented = false
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Text("记忆卡片")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption)
                            Text("\(moves)")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding()

                // 倒计时
                if !showResult {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(remainingTime < 10 ? .red : .white)
                        Text("\(Int(remainingTime))秒")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(remainingTime < 10 ? .red : .white)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                }

                // 进度
                if !showResult {
                    Text("已配对: \(matchedPairs)/\(pairsCount)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                Spacer()

                // 游戏区域
                if showResult {
                    MemoryGameResultView(
                        score: finalScore,
                        moves: moves,
                        timeRemaining: remainingTime,
                        onRestart: {
                            resetGame()
                        },
                        onExit: {
                            isPresented = false
                        }
                    )
                } else {
                    // 卡片网格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(cards.indices, id: \.self) { index in
                            CardView(
                                card: cards[index],
                                action: {
                                    flipCard(at: index)
                                }
                            )
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
        }
    }

    // 开始游戏
    private func startGame() {
        resetGame()

        // 创建卡片对
        var cardPairs: [MemoryCard] = []
        for emoji in emojis.prefix(pairsCount) {
            cardPairs.append(MemoryCard(emoji: emoji))
            cardPairs.append(MemoryCard(emoji: emoji))
        }

        // 随机打乱
        cards = cardPairs.shuffled()

        // 启动倒计时
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            remainingTime -= 1

            if remainingTime <= 0 {
                endGame()
            }
        }
    }

    // 重置游戏
    private func resetGame() {
        cards = []
        flippedCards = []
        matchedPairs = 0
        moves = 0
        remainingTime = 60.0
        showResult = false
        isProcessing = false
    }

    // 翻牌
    private func flipCard(at index: Int) {
        guard !isProcessing else { return }
        guard index < cards.count else { return }

        let card = cards[index]

        // 跳过已翻开的或已匹配的卡片
        guard !card.isFlipped && !card.isMatched else { return }

        // 翻开卡片
        cards[index].isFlipped = true
        flippedCards.append(cards[index])

        // 检查是否翻了两张
        if flippedCards.count == 2 {
            moves += 1
            isProcessing = true

            // 检查是否匹配
            if flippedCards[0].emoji == flippedCards[1].emoji {
                // 匹配成功
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let firstIndex = cards.firstIndex(where: { $0.id == flippedCards[0].id }) {
                        cards[firstIndex].isMatched = true
                    }
                    if let secondIndex = cards.firstIndex(where: { $0.id == flippedCards[1].id }) {
                        cards[secondIndex].isMatched = true
                    }

                    matchedPairs += 1
                    flippedCards = []
                    isProcessing = false

                    // 检查是否全部匹配
                    if matchedPairs == pairsCount {
                        endGame()
                    }

                    // 触觉反馈
                    HapticManager.shared.trigger(.light)
                }
            } else {
                // 匹配失败
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let firstIndex = cards.firstIndex(where: { $0.id == flippedCards[0].id }) {
                        cards[firstIndex].isFlipped = false
                    }
                    if let secondIndex = cards.firstIndex(where: { $0.id == flippedCards[1].id }) {
                        cards[secondIndex].isFlipped = false
                    }

                    flippedCards = []
                    isProcessing = false
                }
            }
        }
    }

    // 结束游戏
    private func endGame() {
        gameTimer?.invalidate()
        showResult = true

        // 计算分数
        let timeBonus = Int(remainingTime) * 2
        let movePenalty = max(0, (moves - pairsCount) * 5)
        let matchBonus = matchedPairs * 50

        finalScore = max(0, matchBonus + timeBonus - movePenalty)

        // 应用奖励到宠物
        applyReward()
    }

    // 应用奖励
    private func applyReward() {
        let experience = finalScore
        let happiness = min(100, pet.happiness + matchedPairs * 5)

        pet.experience += experience
        pet.happiness = happiness

        // 震动反馈
        HapticManager.shared.trigger(.medium)

        // 记录活动
        pet.logActivity(
            Activity(
                title: "记忆卡片游戏",
                icon: "brain.head.profile",
                color: CodableColor(from: Color.purple),
                date: Date(),
                value: experience
            )
        )

        // 更新每日任务
        DailyTaskManager.shared.updateTask(type: .miniGame)
    }
}

// 卡片视图
struct CardView: View {
    let card: MemoryCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if card.isFlipped || card.isMatched {
                    // 正面
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(card.isMatched ? Color.green : Color.purple, lineWidth: 2)
                        )

                    Text(card.emoji)
                        .font(.system(size: 40))
                } else {
                    // 背面
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )

                    Image(systemName: "questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 70, height: 90)
            .rotation3DEffect(
                card.isFlipped || card.isMatched ? .degrees(180) : .degrees(0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(card.isMatched)
    }
}

// 结果视图
struct MemoryGameResultView: View {
    let score: Int
    let moves: Int
    let timeRemaining: Double
    let onRestart: () -> Void
    let onExit: () -> Void

    var grade: String {
        if score >= 300 { return "S" }
        if score >= 250 { return "A" }
        if score >= 200 { return "B" }
        if score >= 150 { return "C" }
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
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(moves)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("步数")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(Int(timeRemaining))s")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("剩余")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
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
                    .background(Color.blue)
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
    MemoryGameView(pet: Pet(), isPresented: .constant(true))
}
