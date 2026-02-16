//
//  CleaningMiniGameView.swift
//  VirtualPet
//
//  清洁小游戏
//  擦拭脏污,提升清洁度
//

import SwiftUI

struct CleaningMiniGameView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var dirtSpots: [DirtSpot] = []
    @State private var cleanedCount = 0
    @State private var gameTimer: Timer?
    @State private var remainingTime = 10.0
    @State private var showResult = false
    @State private var finalScore = 0
    @State private var gameGrade = ""

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.1)],
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

                    Text("清洁大作战")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                        Text("\(cleanedCount)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                // 倒计时
                if !showResult {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(remainingTime < 3 ? .red : .white)
                        Text(String(format: "%.1f秒", remainingTime))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(remainingTime < 3 ? .red : .white)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                }

                Spacer()

                // 游戏区域
                if showResult {
                    CleaningGameResultView(
                        score: finalScore,
                        grade: gameGrade,
                        onRestart: {
                            resetGame()
                        },
                        onExit: {
                            isPresented = false
                        }
                    )
                } else {
                    ZStack {
                        // 宠物显示 (简化版)
                        VStack(spacing: 20) {
                            Text(pet.petType.rawValue)
                                .font(.system(size: 80))

                            if pet.cleanliness < 30 {
                                Text("😰 好脏...")
                                    .font(.title2)
                            } else if pet.cleanliness < 60 {
                                Text("😐 还需要清洁")
                                    .font(.title2)
                            } else {
                                Text("😊 干净了!")
                                    .font(.title2)
                            }
                        }

                        // 脏污点
                        ForEach(dirtSpots) { spot in
                            if !spot.isCleaned {
                                DirtSpotView(spot: spot) {
                                    cleanSpot(spot)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        // 生成脏污点
        for _ in 0..<8 {
            dirtSpots.append(DirtSpot())
        }

        // 启动倒计时
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            remainingTime -= 0.1

            if remainingTime <= 0 {
                endGame()
            }
        }
    }

    // 清洁脏污点
    private func cleanSpot(_ spot: DirtSpot) {
        if let index = dirtSpots.firstIndex(where: { $0.id == spot.id }) {
            dirtSpots[index].isCleaned = true
            cleanedCount += 1

            // 震动反馈
            HapticManager.shared.trigger(.light)

            // 连击系统
            ComboSystem.shared.incrementCombo()

            // 检查是否全部清洁
            if cleanedCount >= dirtSpots.count {
                endGame()
            }
        }
    }

    // 结束游戏
    private func endGame() {
        gameTimer?.invalidate()

        // 计算得分
        let baseScore = cleanedCount * 10
        let timeBonus = Int(remainingTime) * 5
        finalScore = baseScore + timeBonus

        // 计算评级
        if cleanedCount == dirtSpots.count {
            gameGrade = "S"
        } else if cleanedCount >= Int(Double(dirtSpots.count) * 0.8) {
            gameGrade = "A"
        } else if cleanedCount >= Int(Double(dirtSpots.count) * 0.6) {
            gameGrade = "B"
        } else if cleanedCount >= Int(Double(dirtSpots.count) * 0.4) {
            gameGrade = "C"
        } else {
            gameGrade = "D"
        }

        // 应用清洁效果到宠物
        let cleanlinessBonus = cleanedCount * 10
        pet.cleanliness = min(100, pet.cleanliness + cleanlinessBonus)
        pet.health = min(100, pet.health + cleanedCount * 2)
        pet.happiness = min(100, pet.happiness + cleanedCount * 3)
        pet.experience += cleanedCount * 3

        // 记录活动
        pet.logActivity(
            Activity(
                title: "清洁完成！\(gameGrade)级",
                icon: "sparkles",
                color: CodableColor(from: .cyan),
                date: Date(),
                value: finalScore
            )
        )

        // 震动反馈
        if gameGrade == "S" || gameGrade == "A" {
            HapticManager.shared.trigger(.heavy)
        } else {
            HapticManager.shared.trigger(.medium)
        }

        showResult = true
    }

    // 重置游戏
    private func resetGame() {
        dirtSpots = []
        cleanedCount = 0
        remainingTime = 10.0
        showResult = false
        finalScore = 0
        gameGrade = ""
    }
}

// 脏污点数据模型
struct DirtSpot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    var isCleaned: Bool = false

    init() {
        // 随机位置 (在屏幕范围内)
        self.x = CGFloat.random(in: 50...300)
        self.y = CGFloat.random(in: 200...700)
    }
}

// 脏污点视图
struct DirtSpotView: View {
    let spot: DirtSpot
    let action: () -> Void

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                action()
            }
        }) {
            ZStack {
                // 污渍
                Circle()
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .blur(radius: 2)

                // 纹理
                Image(systemName: "period")
                    .font(.system(size: 8))
                    .foregroundColor(.brown)
                    .offset(x: -5, y: -5)

                Image(systemName: "period")
                    .font(.system(size: 6))
                    .foregroundColor(.brown)
                    .offset(x: 8, y: 3)
            }
            .scaleEffect(scale)
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: spot.x, y: spot.y)
    }
}

// 清洁游戏结果视图
struct CleaningGameResultView: View {
    let score: Int
    let grade: String
    let onRestart: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // 评级
            Text(grade)
                .font(.system(size: 80, weight: .heavy))
                .foregroundColor(gradeColor)

            // 标题
            Text(resultTitle)
                .font(.title)
                .fontWeight(.bold)

            // 得分
            Text("得分: \(score)")
                .font(.title2)
                .foregroundColor(.secondary)

            // 按钮
            HStack(spacing: 16) {
                Button(action: onRestart) {
                    Text("再来一次")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cyan)
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

    var gradeColor: Color {
        switch grade {
        case "S": return .yellow
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        default: return .red
        }
    }

    var resultTitle: String {
        switch grade {
        case "S": return "完美清洁！✨"
        case "A": return "干得漂亮！👍"
        case "B": return "还不错 😊"
        case "C": return "继续加油 💪"
        default: return "需要努力 😅"
        }
    }
}

// 预览
#Preview {
    CleaningMiniGameView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
