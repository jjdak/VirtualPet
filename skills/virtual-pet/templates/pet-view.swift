//
//  ContentView.swift
//  {{project_name}}
//
//  Created by VirtualPet Creator on {{current_date}}
//

import SwiftUI

// 确保类型可见
extension Pet {
    typealias Activity = VirtualPet.Activity
}

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var breathAnimation = true
    @State private var lastDecayTime = Date()
    @State private var timer: Timer? = nil
    @State private var petName = "我的宠物"
    @State private var showingActivityLog = false
    @State private var showingAchievements = false
    @State private var petBounce = false
    @State private var sparkleAnimation = false
    @State private var heartAnimation = false
    @State private var particleEffects: [Particle] = []
    @State private var selectedPetType: PetType = .{{pet_type}}

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 宠物信息头部
                    PetHeaderView(pet: pet)

                    // 宠物显示区域
                    PetDisplayView(
                        pet: pet,
                        breathAnimation: $breathAnimation,
                        petBounce: $petBounce,
                        sparkleAnimation: $sparkleAnimation,
                        heartAnimation: $heartAnimation,
                        particleEffects: $particleEffects
                    )

                    // 状态指标
                    StatusGridView(pet: pet)

                    // 操作按钮
                    InteractionButtonsView(
                        pet: pet,
                        petBounce: $petBounce,
                        sparkleAnimation: $sparkleAnimation,
                        heartAnimation: $heartAnimation,
                        particleEffects: $particleEffects
                    )

                    // 宠物选择器
                    PetTypeSelector(petType: $selectedPetType)

                    // 快速统计
                    QuickStatsView(pet: pet)
                }
                .padding()
            }
            .navigationTitle("虚拟宠物")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingActivityLog = true
                        }) {
                            Label("活动记录", systemImage: "clock.fill")
                        }
                        Button(action: {
                            showingAchievements = true
                        }) {
                            Label("成就", systemImage: "trophy.fill")
                        }
                        Button(action: {
                            resetPet()
                        }) {
                            Label("重置宠物", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingActivityLog) {
                ActivityLogView(pet: pet)
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView(pet: pet)
            }
            .onAppear {
                startDecayTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    func startDecayTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            pet.decay()
        }
    }

    func resetPet() {
        pet = Pet()
    }
}

// MARK: - View Components
struct PetHeaderView: View {
    let pet: Pet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(pet.petType.rawValue)")
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text("等级 \(pet.level)")
                        .font(.headline)
                    Text("\(pet.age)天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(pet.experience)/\(pet.level * 100)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text("\(pet.mood.rawValue)")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PetDisplayView: View {
    let pet: Pet
    @Binding var breathAnimation: Bool
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]

    var body: some View {
        ZStack {
            Circle()
                .fill(pet.petType.color.opacity(0.2))
                .frame(width: 200, height: 200)
                .scaleEffect(petBounce ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: petBounce)

            Text(pet.petType.rawValue)
                .font(.system(size: 80))

            // Mood indicator
            VStack {
                Spacer()
                HStack {
                    if heartAnimation {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .opacity(0.5)
                            .offset(y: -10)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: heartAnimation)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            petBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                petBounce = false
            }
        }
    }
}

struct StatusGridView: View {
    let pet: Pet

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            StatusIndicator(title: "饥饿", value: pet.hunger, color: .orange)
            StatusIndicator(title: "快乐", value: pet.happiness, color: .pink)
            StatusIndicator(title: "健康", value: pet.health, color: .green)
            StatusIndicator(title: "能量", value: pet.energy, color: .blue)
        }
    }
}

struct StatusIndicator: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct InteractionButtonsView: View {
    let pet: Pet
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                InteractionButton(
                    title: "喂养",
                    icon: "fork.knife",
                    color: .orange,
                    action: { interact(type: .feed) }
                )
                InteractionButton(
                    title: "玩耍",
                    icon: "gamecontroller",
                    color: .purple,
                    action: { interact(type: .play) }
                )
            }
            HStack(spacing: 15) {
                InteractionButton(
                    title: "清理",
                    icon: "sparkles",
                    color: .green,
                    action: { interact(type: .clean) }
                )
                InteractionButton(
                    title: "运动",
                    icon: "figure.walk",
                    color: .blue,
                    action: { interact(type: .exercise) }
                )
            }
            InteractionButton(
                title: "拥抱",
                icon: "heart.fill",
                color: .red,
                action: { interact(type: .cuddle) }
            )
        }
    }

    private func interact(type: Pet.InteractionType) {
        pet.interact(type: type)
        petBounce = true
        sparkleAnimation = type == .clean
        heartAnimation = type == .cuddle

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            petBounce = false
        }
    }
}

struct InteractionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

struct PetTypeSelector: View {
    @Binding var petType: PetType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择宠物类型")
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(PetType.allCases, id: \.self) { type in
                    Button(action: {
                        petType = type
                    }) {
                        Text(type.rawValue)
                            .font(.title)
                            .padding()
                            .background(petType == type ? Color.blue.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct QuickStatsView: View {
    let pet: Pet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("快速统计")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                QuickStatItem(title: "总互动", value: "\(pet.totalInteractions)")
                QuickStatItem(title: "解锁成就", value: "\(pet.unlockedAchievements)")
                QuickStatItem(title: "最高快乐", value: "\(pet.maxHappiness)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

struct ActivityLogView: View {
    let pet: Pet

    var body: some View {
        NavigationView {
            List(pet.activities.reversed()) { activity in
                HStack {
                    Image(systemName: activity.icon)
                        .foregroundColor(activity.color)
                    VStack(alignment: .leading) {
                        Text(activity.title)
                        Text(activity.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let value = activity.value {
                        Text("+\(value)")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("活动记录")
        }
    }
}

struct AchievementsView: View {
    let pet: Pet

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("成就 (\(pet.unlockedAchievements)/\(pet.achievements.count))")
                    .font(.headline)

                ForEach(pet.achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
            .padding()
            .navigationTitle("成就")
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .foregroundColor(achievement.unlocked ? .yellow : .gray)
            VStack(alignment: .leading) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Particle effect
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var color: Color
}

struct ParticleEffectView: View {
    @Binding var particles: [Particle]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .opacity(particle.opacity)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            particles.removeAll()
            for _ in 0..<20 {
                particles.append(Particle(
                    x: CGFloat.random(in: 0...200),
                    y: CGFloat.random(in: 0...200),
                    size: CGFloat.random(in: 2...6),
                    opacity: Double.random(in: 0.3...0.8),
                    color: [.yellow, .orange, .pink, .purple].randomElement() ?? .yellow
                ))
            }
        }
    }
}