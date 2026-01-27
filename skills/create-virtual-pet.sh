#!/bin/bash

# Virtual Pet App Creator Script
# This script creates a complete virtual pet iOS app with all core features

set -e

# Configuration
PROJECT_NAME="VirtualPet"
PROJECT_DIR="$1/${PROJECT_NAME}"
BUNDLE_ID="com.example.${PROJECT_NAME,,}"
ORGANIZATION_NAME="VirtualPet Studio"
DEVELOPER_NAME="Developer"
DEPLOYMENT_TARGET="17.0"
SWIFT_VERSION="5.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Virtual Pet App Creator Script${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main script
main() {
    print_header

    # Check if Xcode command line tools are installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi

    # Check if project directory is provided
    if [ -z "$1" ]; then
        print_error "Please provide project directory path."
        echo "Usage: $0 <project_directory>"
        exit 1
    fi

    # Check if directory exists, if not create it
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"

    print_step "Creating Virtual Pet iOS project..."

    # Create Xcode project
    xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${PROJECT_NAME}" -template app \
        -deployment-target "$DEPLOYMENT_TARGET" \
        -create-info-plist \
        -useLegacyTemplate \
        -project-dir .

    if [ $? -ne 0 ]; then
        print_error "Failed to create Xcode project"
        exit 1
    fi

    print_step "Setting up project structure..."

    # Create source code directory
    mkdir -p "${PROJECT_NAME}"

    # Create all Swift source files
    create_swift_files

    # Create asset catalog
    create_assets

    # Create launch screen
    create_launch_screen

    # Update project file
    update_project_file

    print_step "Configuring project settings..."

    # Configure build settings
    configure_build_settings

    print_step "Adding unit test target..."

    # Add unit test target
    xcodebuild -project "${PROJECT_NAME}.xcodeproj" -target "${PROJECT_NAME}"Tests \
        -template unit_test_bundle \
        -deployment-target "$DEPLOYMENT_TARGET" \
        -create-info-plist \
        -project-dir .

    print_step "Adding UI test target..."

    # Add UI test target
    xcodebuild -project "${PROJECT_NAME}.xcodeproj" -target "${PROJECT_NAME}"UITests \
        -template ui_test_bundle \
        -deployment-target "$DEPLOYMENT_TARGET" \
        -create-info-plist \
        -project-dir .

    print_step "Generating project configuration..."

    # Generate Podfile (optional)
    create_podfile

    # Generate README
    create_readme

    print_info "Project created successfully at: ${PROJECT_DIR}"
    print_info "To run the project:"
    print_info "  cd ${PROJECT_DIR}"
    print_info "  open ${PROJECT_NAME}.xcodeproj"
    print_info "  or xcodebuild -project ${PROJECT_NAME}.xcodeproj -scheme ${PROJECT_NAME} build"
}

create_swift_files() {
    print_info "Creating Swift source files..."

    # VirtualPetApp.swift
    cat > "${PROJECT_NAME}/VirtualPetApp.swift" << 'EOF'
//
//  VirtualPetApp.swift
//  VirtualPet
//
//  Created by VirtualPet Creator on $(date +%Y/%m/%d)
//

import SwiftUI

@main
struct VirtualPetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

    # Pet.swift
    cat > "${PROJECT_NAME}/Pet.swift" << 'EOF'
import Foundation
import Combine
import SwiftUI

// 宠物心情枚举
enum PetMood: String, CaseIterable {
    case happy = "开心"
    case normal = "正常"
    case hungry = "饥饿"
    case sad = "伤心"
    case sick = "生病"
    case excited = "兴奋"
    case sleepy = "困倦"
}

// 宠物类型
enum PetType: String, CaseIterable {
    case cat = "🐱"
    case dog = "🐶"
    case rabbit = "🐰"
    case hamster = "🐹"
    case bird = "🐦"

    var color: Color {
        switch self {
        case .cat: return .orange
        case .dog: return .brown
        case .rabbit: return .pink
        case .hamster: return .yellow
        case .bird: return .blue
        }
    }
}

// 活动记录
struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let date: Date
    let value: Int?
}

// 状态记录
struct PetStatsRecord {
    let date: Date
    let hunger: Int
    let happiness: Int
    let health: Int
}

// 成就
class Achievement: ObservableObject, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let requirement: () -> Bool
    @Published var unlocked: Bool = false

    init(title: String, description: String, icon: String, requirement: @escaping () -> Bool) {
        self.title = title
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.unlocked = false
    }
}

class Pet: ObservableObject {
    @Published var hunger: Int = 50 // 0-100
    @Published var happiness: Int = 50 // 0-100
    @Published var health: Int = 100 // 0-100
    @Published var energy: Int = 100 // 能量值
    @Published var age: Int = 0 // 年龄（天）
    @Published var experience: Int = 0 // 经验值
    @Published var level: Int = 1 // 等级
    @Published var lastFed = Date() // 上次喂食时间
    @Published var petType: PetType = .cat
    @Published var mood: PetMood = .normal
    @Published var totalInteractions: Int = 0
    @Published var maxHappiness: Int = 50
    @Published var careStreak: Int = 0
    @Published var unlockedAchievements: Int = 0
    @Published var activities: [Activity] = []
    @Published var statsHistory: [PetStatsRecord] = []
    @Published var achievements: [Achievement] = []

    // 辅助方法：确保值在有效范围内
    private func clampValue(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    // 初始化方法
    init(hunger: Int = 50, happiness: Int = 50, health: Int = 100) {
        self.hunger = clampValue(hunger)
        self.happiness = clampValue(happiness)
        self.health = clampValue(health)
        setupAchievements()
        updateMood()
    }

    // 设置成就
    private func setupAchievements() {
        let achievement1 = Achievement(
            title: "初次见面",
            description: "第一次与宠物互动",
            icon: "star.fill",
            requirement: { self.totalInteractions >= 1 }
        )

        let achievement2 = Achievement(
            title: "美食家",
            description: "喂养宠物10次",
            icon: "fork.knife",
            requirement: { self.feedCount >= 10 }
        )

        let achievement3 = Achievement(
            title: "快乐源泉",
            description: "让宠物快乐度达到100",
            icon: "heart.fill",
            requirement: { self.maxHappiness >= 100 }
        )

        let achievement4 = Achievement(
            title: "健康达人",
            description: "连续7天保持宠物健康度80+",
            icon: "leaf.fill",
            requirement: { self.healthStreak >= 7 }
        )

        achievements = [achievement1, achievement2, achievement3, achievement4]
    }

    // 互动类型
    enum InteractionType {
        case play, feed, clean, exercise, cuddle
    }

    // 喂养计数
    private var feedCount: Int {
        return activities.filter { $0.icon == "fork.knife" }.count
    }

    // 健康连续天数
    private var healthStreak: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return statsHistory.filter { record in
            record.date >= sevenDaysAgo && record.health >= 80
        }.count
    }

    // 更新宠物心情
    func updateMood() {
        if health < 30 {
            mood = .sick
        } else if hunger > 80 {
            mood = .hungry
        } else if energy < 20 {
            mood = .sleepy
        } else if happiness > 80 {
            mood = .happy
        } else if happiness < 20 {
            mood = .sad
        } else if happiness > 60 && energy > 50 {
            mood = .excited
        } else {
            mood = .normal
        }
    }

    // 记录活动
    func logActivity(_ activity: Activity) {
        activities.append(activity)
        if activities.count > 100 {
            activities.removeFirst()
        }

        // 更新最高快乐度
        if happiness > maxHappiness {
            maxHappiness = happiness
        }

        // 更新状态历史
        if activities.count % 10 == 0 {
            let record = PetStatsRecord(
                date: Date(),
                hunger: hunger,
                happiness: happiness,
                health: health
            )
            statsHistory.append(record)
        }

        // 检查成就
        checkAchievements()
    }

    // 检查成就
    func checkAchievements() {
        for achievement in achievements {
            if !achievement.unlocked && achievement.requirement() {
                achievement.unlocked = true
                unlockedAchievements += 1
                logActivity(
                    Activity(
                        title: "成就解锁：\(achievement.title)",
                        icon: "trophy.fill",
                        color: .yellow,
                        date: Date(),
                        value: nil
                    )
                )
            }
        }
    }

    // 高级互动
    func interact(type: InteractionType) {
        switch type {
        case .play:
            happiness = clampValue(happiness + 15)
            energy = clampValue(energy - 10)
            experience += 5
            logActivity(
                Activity(
                    title: "玩耍",
                    icon: "gamecontroller",
                    color: .purple,
                    date: Date(),
                    value: 15
                )
            )
        case .feed:
            hunger = clampValue(hunger - 25)
            happiness = clampValue(happiness + 5)
            lastFed = Date()
            experience += 3
            logActivity(
                Activity(
                    title: "喂养",
                    icon: "fork.knife",
                    color: .orange,
                    date: Date(),
                    value: 25
                )
            )
        case .clean:
            health = clampValue(health + 15)
            happiness = clampValue(happiness + 5)
            experience += 2
            logActivity(
                Activity(
                    title: "清理",
                    icon: "sparkles",
                    color: .green,
                    date: Date(),
                    value: 15
                )
            )
        case .exercise:
            health = clampValue(health + 10)
            hunger = clampValue(hunger + 15)
            energy = clampValue(energy - 20)
            experience += 8
            logActivity(
                Activity(
                    title: "运动",
                    icon: "figure.walk",
                    color: .blue,
                    date: Date(),
                    value: 10
                )
            )
        case .cuddle:
            happiness = clampValue(happiness + 20)
            health = clampValue(health + 5)
            energy = clampValue(energy - 5)
            experience += 4
            logActivity(
                Activity(
                    title: "拥抱",
                    icon: "heart.fill",
                    color: .red,
                    date: Date(),
                    value: 20
                )
            )
        }

        totalInteractions += 1
        updateMood()
        checkLevelUp()
        saveData()
    }

    // 检查升级
    private func checkLevelUp() {
        let requiredExp = level * 100
        if experience >= requiredExp {
            level += 1
            experience = 0
            // 升级奖励
            health = min(100, health + 20)
            logActivity(
                Activity(
                    title: "升级到\(level)级！",
                    icon: "star.fill",
                    color: .yellow,
                    date: Date(),
                    value: nil
                )
            )
        }
    }

    // 自动衰减：每分钟饥饿度+1，快乐度-1，能量-2
    func decay() {
        hunger = clampValue(hunger + 1)
        happiness = clampValue(happiness - 1)
        energy = clampValue(energy - 2)
        age += 1
        updateMood()
        saveData()
    }

    // UserDefaults键名
    private let defaults = UserDefaults.standard
    private let hungerKey = "pet_hunger"
    private let happinessKey = "pet_happiness"
    private let healthKey = "pet_health"

    // 保存数据到UserDefaults
    func saveData() {
        defaults.set(hunger, forKey: hungerKey)
        defaults.set(happiness, forKey: happinessKey)
        defaults.set(health, forKey: healthKey)
    }

    // 从UserDefaults加载数据
    static func loadData() -> Pet {
        let defaults = UserDefaults.standard
        let hunger = defaults.integer(forKey: "pet_hunger")
        let happiness = defaults.integer(forKey: "pet_happiness")
        let health = defaults.integer(forKey: "pet_health")

        // 如果是第一次加载，使用默认值
        if hunger == 0 && happiness == 0 && health == 0 {
            return Pet()
        }

        return Pet(hunger: hunger, happiness: happiness, health: health)
    }
}
EOF

    # ContentView.swift (simplified version)
    cat > "${PROJECT_NAME}/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var lastDecayTime = Date()
    @State private var timer: Timer? = nil
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
                VStack(spacing: 20) {
                    // 宠物信息头部
                    PetHeaderView(pet: pet)

                    // 宠物显示区域
                    PetDisplayView(
                        pet: pet,
                        petBounce: $petBounce,
                        sparkleAnimation: $sparkleAnimation,
                        heartAnimation: $heartAnimation
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
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool

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
EOF

    # Item.swift
    cat > "${PROJECT_NAME}/Item.swift" << 'EOF'
//
//  Item.swift
//  VirtualPet
//
//  Created by VirtualPet Creator on $(date +%Y/%m/%d)
//

import Foundation
import SwiftUI

struct Item: Identifiable {
    let id = UUID()
    let timestamp: Date
}
EOF
}

create_assets() {
    print_info "Creating asset catalog..."

    mkdir -p "${PROJECT_NAME}/Assets.xcassets/AppIcon.appiconset"
    mkdir -p "${PROJECT_NAME}/Assets.xcassets/Colors.colorset"

    # Create basic app icon
    cat > "${PROJECT_NAME}/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "1x"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "2x"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "3x"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "1x"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "2x"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "3x"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "1x"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "2x"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "3x"
    },
    {
      "idiom" : "iphone",
      "size" : "76x76",
      "scale" : "1x"
    },
    {
      "idiom" : "iphone",
      "size" : "76x76",
      "scale" : "2x"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "1x"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "2x"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "1x"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "2x"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "1x"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "2x"
    },
    {
      "idiom" : "ipad",
      "size" : "76x76",
      "scale" : "1x"
    },
    {
      "idiom" : "ipad",
      "size" : "76x76",
      "scale" : "2x"
    },
    {
      "idiom" : "ipad",
      "size" : "83.5x83.5",
      "scale" : "2x"
    },
    {
      "idiom" : "ios-marketing",
      "size" : "1024x1024",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    # Create color set
    cat > "${PROJECT_NAME}/Assets.xcassets/Colors.colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.584",
          "red" : "1.000"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
}

create_launch_screen() {
    print_info "Creating launch screen..."

    mkdir -p "${PROJECT_NAME}/Base.lproj"

    # Create LaunchScreen.storyboard
    cat > "${PROJECT_NAME}/Base.lproj/LaunchScreen.storyboard" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21507" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21505"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                        <userDefinedRuntimeAttributes>
                            <userDefinedRuntimeAttribute type="string" key="petType" value="🐱"/>
                        </userDefinedRuntimeAttributes>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
EOF
}

update_project_file() {
    print_info "Updating project file..."

    # This would normally be done by xcodebuild, but we'll add some additional configuration
    # For now, the project file is created by xcodebuild
}

configure_build_settings() {
    print_info "Configuring build settings..."

    # Update Info.plist
    cat > "${PROJECT_NAME}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF
}

create_podfile() {
    print_info "Creating Podfile..."

    cat > "Podfile" << EOF
# VirtualPet App Podfile
# Uncomment this line to define a global platform for your project
# platform :ios, '$DEPLOYMENT_TARGET'

target '$PROJECT_NAME' do
  # Comment this line if you're not using Swift and you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VirtualPet
  # Add your pod dependencies here

  target '$PROJECT_NAMETests' do
    inherit! :search_paths
    # Pods for testing
  end

  target '$PROJECT_NAMEUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
EOF
}

create_readme() {
    print_info "Creating README..."

    cat > "README.md" << EOF
# VirtualPet iOS App

A modern virtual pet application built with SwiftUI and Swift 5.0.

## Features

- **5 Pet Types**: Choose from cat 🐱, dog 🐶, rabbit 🐰, hamster 🐹, or bird 🐦
- **Interactive Gameplay**: Play, feed, clean, exercise, and cuddle with your pet
- **Dynamic Mood System**: Pet mood changes based on hunger, happiness, health, and energy
- **Level Progression**: Earn experience points and level up your pet
- **Achievement System**: Unlock achievements for various milestones
- **Persistent Data**: Pet state is saved and restored between app launches
- **Rich Animations**: Smooth animations and visual feedback for interactions
- **Activity Log**: Track all interactions and events

## Game Mechanics

### Pet Stats
- **Hunger**: Decreases over time, can be increased by feeding
- **Happiness**: Increases with positive interactions, decreases over time
- **Health**: Affected by cleanliness and care
- **Energy**: Decreases with activities, recovers over time

### Automatic Decay
Pet stats automatically decrease every minute:
- Hunger: +1
- Happiness: -1
- Energy: -2

### Level System
- Gain experience points from interactions
- Level up requires `current_level * 100` experience
- Level up grants +20 health bonus

### Achievements
1. **初次见面**: First interaction
2. **美食家**: Feed 10 times
3. **快乐源泉**: Max happiness (100)
4. **健康达人**: 7 consecutive days with 80+ health

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.0

## Installation

### Using Xcode
1. Open the project in Xcode
2. Build and run the app

### Using Command Line
\`\`\`bash
# Build the project
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet build

# Run on simulator
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
\`\`\`

## Project Structure

\`\`\`
VirtualPet/
├── VirtualPet/                    # Main app source code
│   ├── VirtualPetApp.swift       # App entry point
│   ├── ContentView.swift         # Main UI view
│   ├── Pet.swift                 # Core pet model and logic
│   └── Item.swift                # SwiftData model
├── VirtualPetTests/              # Unit tests
├── VirtualPetUITests/            # UI tests
└── Assets.xcassets/              # App assets
\`\`\`

## Architecture

The app follows MVVM architecture:
- **View**: SwiftUI views (ContentView)
- **ViewModel/Model**: Pet class managing state and logic
- **Persistence**: UserDefaults for data persistence

## Development

### Running Tests
\`\`\`bash
# Unit tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' only-testing:VirtualPetTests

# UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' only-testing:VirtualPetUITests
\`\`\`

### Building
\`\`\`bash
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release build
\`\`\`

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Contact

Created by VirtualPet Creator
$(date +%Y/%m/%d)
EOF
}

# Execute main function
main "$@"