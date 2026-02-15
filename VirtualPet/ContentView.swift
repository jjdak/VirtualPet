//
//  ContentView.swift
//  VirtualPet
//
//  主视图 - 手表风格简化布局
//  Phase 1, UI 优化
//
//  设计理念:
//  - 宠物作为视觉焦点，占据屏幕 60%
//  - 简化的控制按钮
//  - 清晰的状态指示器
//  - 类似 Apple Watch 的圆形/圆角界面
//

import SwiftUI

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var showingActivityLog = false
    @State private var showingAchievements = false
    @State private var showingHelp = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var timer: Timer? = nil
    @State private var selectedTab = 0 // 0: 宠物, 1: 状态, 2: 活动
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部：宠物信息 (简化版)
                TopBarView(pet: pet)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                Spacer()

                // 中部：大型宠物展示区域
                PetDisplaySection(pet: pet)
                    .frame(maxHeight: .infinity)

                Spacer()

                // 底部：标签页控制
                if selectedTab == 0 {
                    WatchInteractionButtonsView(pet: pet)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                } else if selectedTab == 1 {
                    StatusGridView(pet: pet)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                } else {
                    QuickStatsView(pet: pet)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                // 底部导航栏
                BottomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 10)
            }

            // 菜单按钮
            VStack {
                HStack {
                    Spacer()
                    MenuButton {
                        Button("活动记录") { showingActivityLog = true }
                        Button("成就") { showingAchievements = true }
                        Button("帮助") { showingHelp = true }
                        Button("设置") { showingSettings = true }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingActivityLog) {
            ActivityLogView(pet: pet)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(pet: pet)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
        .alert("错误", isPresented: $showingError, presenting: errorMessage) { _ in
            Button("确定") { }
        }
        .onAppear {
            setupTimer()
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            pet.updateMood()
        }
    }

    private func resetPet() {
        let defaultPet = Pet()
        pet.happiness = defaultPet.happiness
        pet.hunger = defaultPet.hunger
        pet.health = defaultPet.health
        pet.energy = defaultPet.energy
        pet.level = defaultPet.level
        pet.experience = defaultPet.experience
        pet.age = defaultPet.age
        pet.mood = defaultPet.mood
        pet.evolutionStage = defaultPet.evolutionStage
        pet.evolutionPath = defaultPet.evolutionPath
        pet.totalInteractions = defaultPet.totalInteractions
        pet.maxHappiness = defaultPet.maxHappiness
        pet.unlockedAchievements = defaultPet.unlockedAchievements
        pet.activities = defaultPet.activities
        pet.intimacy = defaultPet.intimacy
        pet.luckyEvents = defaultPet.luckyEvents
        pet.specialMoments = defaultPet.specialMoments
        pet.cleanliness = defaultPet.cleanliness
        pet.trainingLevel = defaultPet.trainingLevel
        pet.isAsleep = defaultPet.isAsleep
        pet.sleepTime = defaultPet.sleepTime
        pet.saveData()
    }
}

// MARK: - 顶部信息栏
struct TopBarView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // 等级
                    Label("\(pet.level)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    // 年龄
                    Text("\(pet.age)岁")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 心情指示器 (小图标)
            Image(systemName: getMoodIcon())
                .font(.title3)
                .foregroundColor(getMoodColor())
        }
    }

    private func getMoodIcon() -> String {
        switch pet.mood {
        case .happy: return "face.smiling.fill"
        case .sad: return "face.dashed.fill"
        case .sick: return "thermometer"
        case .hungry: return "fork.knife"
        case .sleepy: return "moon.zzz.fill"
        case .excited: return "star.fill"
        case .normal: return "face.smile"
        }
    }

    private func getMoodColor() -> Color {
        switch pet.mood {
        case .happy: return .yellow
        case .sad: return .blue
        case .sick: return .red
        case .hungry: return .orange
        case .sleepy: return .purple
        case .excited: return .pink
        case .normal: return .green
        }
    }
}

// MARK: - 宠物展示区域 (手表风格)
struct PetDisplaySection: View {
    @ObservedObject var pet: Pet

    var body: some View {
        ZStack {
            // 圆形背景容器 (类似手表表盘)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.gray.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .overlay(
                    Circle()
                        .stroke(
                            getMoodColor().opacity(0.3),
                            lineWidth: 3
                        )
                )
                .frame(width: 320, height: 320)

            // 宠物形象 (放大)
            PixelPetAvatarView(
                petType: pet.petType,
                mood: pet.mood,
                evolutionStage: pet.evolutionStage
            )
            .frame(width: 200, height: 200)
            .scaleEffect(1.8) // 放大 1.8 倍

            // 简化的状态指示器 (小圆点)
            VStack {
                Spacer()

                HStack(spacing: 30) {
                    // 饥饿度
                    VStack(spacing: 4) {
                        Circle()
                            .fill(pet.hunger > 30 ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text("饥饿")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // 快乐度
                    VStack(spacing: 4) {
                        Circle()
                            .fill(pet.happiness > 30 ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text("快乐")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // 健康度
                    VStack(spacing: 4) {
                        Circle()
                            .fill(pet.health > 30 ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text("健康")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // 能量
                    VStack(spacing: 4) {
                        Circle()
                            .fill(pet.energy > 30 ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text("能量")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer().frame(height: 20)
            }
        }
    }

    private func getMoodColor() -> Color {
        switch pet.mood {
        case .happy: return .yellow
        case .sad: return .blue
        case .sick: return .red
        case .hungry: return .orange
        case .sleepy: return .purple
        case .excited: return .pink
        case .normal: return .green
        }
    }
}

// MARK: - 底部标签栏
struct BottomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                icon: "pawprint.fill",
                label: "互动",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            TabButton(
                icon: "chart.bar.fill",
                label: "状态",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            TabButton(
                icon: "clock.fill",
                label: "活动",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 标签按钮
struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 简化的互动按钮包装器
struct WatchInteractionButtonsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 12) {
            // 主要互动按钮 (大按钮)
            HStack(spacing: 12) {
                WatchInteractionButton(
                    icon: "fork.knife",
                    label: "喂食",
                    color: .orange
                ) {
                    _ = pet.interact(type: .feed)
                }

                WatchInteractionButton(
                    icon: "figure.run",
                    label: "玩耍",
                    color: .blue
                ) {
                    _ = pet.interact(type: .play)
                }

                WatchInteractionButton(
                    icon: "sparkles",
                    label: "清洁",
                    color: .cyan
                ) {
                    _ = pet.interact(type: .clean)
                }
            }

            // 次要互动按钮 (小按钮)
            HStack(spacing: 12) {
                WatchInteractionButton(
                    icon: "figure.walk",
                    label: "运动",
                    color: .green
                ) {
                    _ = pet.interact(type: .exercise)
                }

                WatchInteractionButton(
                    icon: "heart.fill",
                    label: "拥抱",
                    color: .pink
                ) {
                    _ = pet.interact(type: .cuddle)
                }
            }
        }
    }
}

// MARK: - 手表风格互动按钮组件
struct WatchInteractionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: isPressed ? 8 : 4, x: 0, y: isPressed ? 4 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 菜单按钮 (简化版)
struct MenuButton<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
                .padding(8)
                .background(Circle().fill(Color.white.opacity(0.8)))
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
