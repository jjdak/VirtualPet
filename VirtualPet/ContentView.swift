//
//  ContentView.swift
//  VirtualPet
//
//  Created by 冯卓 on 2026/1/26.
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
    @State private var selectedPetType: PetType = .cat

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

    // 重置宠物
    private func resetPet() {
        let resetPet = Pet()
        pet.hunger = resetPet.hunger
        pet.happiness = resetPet.happiness
        pet.health = resetPet.health
        pet.energy = resetPet.energy
        pet.age = resetPet.age
        pet.experience = resetPet.experience
        pet.level = resetPet.level
        pet.activities.removeAll()
        pet.statsHistory.removeAll()
        pet.achievements.forEach { $0.unlocked = false }
        pet.unlockedAchievements = 0
    }

    // 启动自动衰减定时器
    private func startDecayTimer() {
        checkDecay()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            pet.decay()
        }
    }

    // 检查是否需要衰减
    private func checkDecay() {
        // 此方法保留以保持兼容性
    }
}

// 粒子效果
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var animationProgress: Double
}

// 宠物信息头部
struct PetHeaderView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(pet.petType.rawValue)
                    .font(.system(size: 30))
                    .fontWeight(.bold)

                VStack(alignment: .leading) {
                    Text("Level \(pet.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("第 \(pet.age) 天")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("经验值")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ProgressView(value: Double(pet.experience), total: Double(pet.level * 100))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 100)

                    Text("\(pet.experience)/\(pet.level * 100)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemGray6))
                    .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }
}

// 宠物显示视图
struct PetDisplayView: View {
    @ObservedObject var pet: Pet
    @Binding var breathAnimation: Bool
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]

    var body: some View {
        ZStack {
            // 背景渐变基于心情
            RoundedRectangle(cornerRadius: 25)
                .fill(getMoodGradient())
                .shadow(color: getMoodShadowColor(), radius: 15, x: 0, y: 5)

            // 宠物表情
            Text(getPetExpression())
                .font(.system(size: 100))
                .scaleEffect(getPetScale())
                .rotationEffect(getPetRotation())
                .offset(y: petBounce ? -20 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: petBounce)

            // 粒子效果
            ForEach(particleEffects) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .animation(.easeOut, value: particle.animationProgress)
            }

            // 特殊效果
            if sparkleAnimation {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(.yellow)
                        .frame(width: 10, height: 10)
                        .opacity(sparkleAnimation ? 1.0 : 0.0)
                        .scaleEffect(sparkleAnimation ? 2.0 : 1.0)
                        .offset(
                            x: CGFloat.random(in: -50...50),
                            y: CGFloat.random(in: -50...50)
                        )
                        .animation(
                            .easeOut(duration: 1.0)
                                .delay(Double(index) * 0.1),
                            value: sparkleAnimation
                        )
                }
            }

            if heartAnimation {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .scaleEffect(petBounce ? 1.5 : 1.0)
                        .offset(
                            x: CGFloat.random(in: -30...30),
                            y: -CGFloat.random(in: 20...80)
                        )
                        .opacity(heartAnimation ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.2),
                            value: heartAnimation
                        )
                }
            }
        }
        .frame(height: 250)
        .padding()
    }

    private func getMoodGradient() -> LinearGradient {
        switch pet.mood {
        case .happy:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .excited:
            return LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [.gray, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sick:
            return LinearGradient(
                colors: [.red.opacity(0.3), .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hungry:
            return LinearGradient(
                colors: [.orange.opacity(0.5), .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleepy:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [pet.petType.color.opacity(0.2), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func getMoodShadowColor() -> Color {
        switch pet.mood {
        case .happy: return .yellow
        case .excited: return .pink
        case .sad: return .blue
        case .sick: return .red
        case .hungry: return .orange
        case .sleepy: return .purple
        default: return .gray
        }
    }

    private func getPetExpression() -> String {
        switch pet.petType {
        case .cat:
            switch pet.mood {
            case .happy: return "😸"
            case .sad: return "😿"
            case .sick: return "🙀"
            case .hungry: return "🙀"
            case .sleepy: return "😴"
            case .excited: return "😻"
            default: return "😺"
            }
        case .dog:
            switch pet.mood {
            case .happy: return "🐶"
            case .sad: return "😢"
            case .sick: return "🤒"
            case .hungry: return "🍖"
            case .sleepy: return "😴"
            case .excited: return "🎾"
            default: return "🐕"
            }
        case .rabbit:
            switch pet.mood {
            case .happy: return "🐰"
            case .sad: return "😔"
            case .sick: return "🤧"
            case .hungry: return "🥕"
            case .sleepy: return "😴"
            case .excited: return "🎉"
            default: return "🐇"
            }
        case .hamster:
            switch pet.mood {
            case .happy: return "🐹"
            case .sad: return "😞"
            case .sick: return "🤕"
            case .hungry: return "🌰"
            case .sleepy: return "😴"
            case .excited: return "🎊"
            default: return "🐭"
            }
        case .bird:
            switch pet.mood {
            case .happy: return "🐦"
            case .sad: return "😔"
            case .sick: return "🤧"
            case .hungry: return "🌽"
            case .sleepy: return "😴"
            case .excited: return "🎈"
            default: return "🐥"
            }
        }
    }

    private func getPetScale() -> CGFloat {
        switch pet.mood {
        case .excited: return 1.2
        case .happy: return 1.1
        case .sad: return 0.9
        case .sick: return 0.8
        case .sleepy: return 0.95
        default: return 1.0
        }
    }

    private func getPetRotation() -> Angle {
        switch pet.mood {
        case .sad: return Angle(degrees: -5)
        case .excited: return Angle(degrees: 5)
        case .sleepy: return Angle(degrees: 10)
        default: return Angle(degrees: 0)
        }
    }
}

// 状态网格视图
struct StatusGridView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 15) {
            Text("宠物状态")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                StatusItem(
                    title: "饥饿度",
                    value: pet.hunger,
                    color: .red,
                    icon: "fork.knife",
                    isCritical: pet.hunger > 80
                )

                StatusItem(
                    title: "快乐度",
                    value: pet.happiness,
                    color: .yellow,
                    icon: "heart.fill",
                    isCritical: pet.happiness < 20
                )

                StatusItem(
                    title: "健康度",
                    value: pet.health,
                    color: .green,
                    icon: "leaf.fill",
                    isCritical: pet.health < 30
                )

                StatusItem(
                    title: "能量",
                    value: pet.energy,
                    color: .blue,
                    icon: "bolt.fill",
                    isCritical: pet.energy < 20
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// 单个状态项
struct StatusItem: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    let isCritical: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))

            Text("\(value)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isCritical ? .red : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// 交互按钮视图
struct InteractionButtonsView: View {
    @ObservedObject var pet: Pet
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]

    var body: some View {
        VStack(spacing: 15) {
            Text("与宠物互动")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                InteractionButton(
                    title: "喂食",
                    color: .orange,
                    icon: "fork.knife",
                    action: {
                        pet.interact(type: .feed)
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            petBounce = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                petBounce = false
                            }
                        }
                        sparkleAnimation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            sparkleAnimation = false
                        }
                        addParticles(color: .orange, count: 5)
                    }
                )

                InteractionButton(
                    title: "玩耍",
                    color: .purple,
                    icon: "gamecontroller",
                    action: {
                        let result = pet.interact(type: .play)
                        if case .success = result {
                            animateInteraction()
                            heartAnimation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                heartAnimation = false
                            }
                            addParticles(color: .purple, count: 3)
                        }
                    }
                )

                InteractionButton(
                    title: "清理",
                    color: .green,
                    icon: "sparkles",
                    action: {
                        let result = pet.interact(type: .clean)
                        if case .success = result {
                            animateInteraction()
                            addParticles(color: .green, count: 4)
                        }
                    }
                )

                InteractionButton(
                    title: "运动",
                    color: .blue,
                    icon: "figure.walk",
                    action: {
                        let result = pet.interact(type: .exercise)
                        if case .success = result {
                            animateInteraction()
                            addParticles(color: .blue, count: 3)
                        }
                    }
                )

                InteractionButton(
                    title: "拥抱",
                    color: .red,
                    icon: "heart.fill",
                    action: {
                        let result = pet.interact(type: .cuddle)
                        if case .success = result {
                            animateInteraction()
                            heartAnimation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                heartAnimation = false
                            }
                            addParticles(color: .red, count: 6)
                        }
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func animateInteraction() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            petBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                petBounce = false
            }
        }
    }

    private func addParticles(color: Color, count: Int) {
        let newParticles = (0..<count).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 50...250),
                    y: CGFloat.random(in: 50...200)
                ),
                size: CGFloat.random(in: 5...15),
                color: color,
                opacity: 1.0,
                animationProgress: 0.0
            )
        }

        withAnimation(.easeOut(duration: 1.0)) {
            particleEffects.append(contentsOf: newParticles)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                particleEffects.removeAll()
            }
        }
    }
}

// 交互按钮
struct InteractionButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 宠物类型选择器
struct PetTypeSelector: View {
    @Binding var petType: PetType

    var body: some View {
        VStack(spacing: 10) {
            Text("选择宠物类型")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(PetType.allCases, id: \.self) { type in
                    Button(role: .none, action: {
                        petType = type
                    }) {
                        VStack {
                            Text(type.rawValue)
                                .font(.system(size: 30))
                            Text(type.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(petType == type ? type.color.opacity(0.2) : Color(.systemGray5))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// 快速统计视图
struct QuickStatsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 10) {
            Text("快速统计")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                StatItem(title: "总互动", value: pet.totalInteractions)
                StatItem(title: "最高快乐", value: pet.maxHappiness)
                StatItem(title: "成就数", value: pet.unlockedAchievements)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// 统计项
struct StatItem: View {
    let title: String
    let value: Int

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 活动记录视图
struct ActivityLogView: View {
    @ObservedObject var pet: Pet
    @State private var showingAllActivities = false

    var filteredActivities: [Activity] {
        showingAllActivities ? pet.activities : Array(pet.activities.reversed().prefix(10))
    }

    var body: some View {
        NavigationView {
            List {
                Section("最近活动") {
                    ForEach(filteredActivities) { activity in
                        HStack {
                            Image(systemName: activity.icon)
                                .foregroundColor(activity.color)
                            VStack(alignment: .leading) {
                                Text(activity.title)
                                Text(activity.date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if let value = activity.value {
                                Text("+\(value)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("统计") {
                    StatRow(title: "总互动次数", value: pet.totalInteractions)
                    StatRow(title: "最高快乐度", value: pet.maxHappiness)
                    StatRow(title: "当前等级", value: pet.level)
                    StatRow(title: "获得成就数", value: pet.unlockedAchievements)
                    StatRow(title: "宠物年龄", value: pet.age)
                }
            }
            .navigationTitle("活动记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingAllActivities ? "显示最近" : "显示全部") {
                        showingAllActivities.toggle()
                    }
                }
            }
        }
    }
}

// 成就视图
struct AchievementsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        NavigationView {
            List {
                Section("已解锁成就 (\(pet.unlockedAchievements)/\(pet.achievements.count))") {
                    ForEach(pet.achievements) { achievement in
                        HStack {
                            Image(systemName: achievement.icon)
                                .foregroundColor(achievement.unlocked ? .yellow : .gray)
                                .font(.title2)

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
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("成就")
        }
    }
}

// 统计行
struct StatRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    ContentView()
}