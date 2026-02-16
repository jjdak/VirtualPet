//
//  AchievementUnlockView.swift
//  VirtualPet
//
//  成就解锁和追踪系统
//

import SwiftUI

struct AchievementUnlockView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    HStack {
                        Text("🏆 成就系统")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        // 解锁进度
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(pet.unlockedAchievements)/\(pet.achievements.count)")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("已解锁")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    // 成就分类
                    AchievementCategorySection(
                        title: "基础成就",
                        achievements: pet.achievements.filter { achievement in
                            achievement.title.contains("初次") ||
                            achievement.title.contains("美食家")
                        }
                    )

                    AchievementCategorySection(
                        title: "进阶成就",
                        achievements: pet.achievements.filter { achievement in
                            achievement.title.contains("快乐") ||
                            achievement.title.contains("健康")
                        }
                    )

                    AchievementCategorySection(
                        title: "关系成就",
                        achievements: pet.achievements.filter { achievement in
                            achievement.title.contains("亲密") ||
                            achievement.title.contains("灵魂")
                        }
                    )

                    AchievementCategorySection(
                        title: "成长成就",
                        achievements: pet.achievements.filter { achievement in
                            achievement.title.contains("成长") ||
                            achievement.title.contains("青春") ||
                            achievement.title.contains("成熟") ||
                            achievement.title.contains("传说")
                        }
                    )

                    AchievementCategorySection(
                        title: "特殊成就",
                        achievements: pet.achievements.filter { achievement in
                            achievement.title.contains("幸运") ||
                            achievement.title.contains("特殊")
                        }
                    )

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
        }
    }
}

// 成就分类区块
struct AchievementCategorySection: View {
    let title: String
    let achievements: [Achievement]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            if achievements.isEmpty {
                Text("暂无成就")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            } else {
                ForEach(achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }
}

// 成就行组件
struct AchievementRow: View {
    @ObservedObject var achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.unlocked ? .yellow : .gray)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 状态
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(achievement.unlocked ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(achievement.unlocked ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// 进化解锁视图
struct EvolutionUnlockView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    Text("🌟 进化系统")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 当前阶段
                    VStack(spacing: 16) {
                        Text("当前阶段")
                            .font(.headline)
                            .foregroundColor(.primary)

                        CurrentEvolutionCard(pet: pet)
                    }

                    // 进化路径选择
                    if pet.evolutionStage == .child && pet.evolutionPath == nil {
                        VStack(spacing: 16) {
                            Text("选择进化路径")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("不同的路径会带来不同的能力加成")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(EvolutionPath.allCases, id: \.self) { path in
                                EvolutionPathCard(
                                    path: path,
                                    pet: pet,
                                    action: {
                                        selectPath(path)
                                    }
                                )
                            }
                        }
                    }

                    // 进化阶段预览
                    VStack(spacing: 12) {
                        Text("进化路线")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(EvolutionStage.allCases, id: \.self) { stage in
                            EvolutionStageRow(
                                stage: stage,
                                currentStage: pet.evolutionStage,
                                petLevel: pet.level
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
        }
    }

    private func selectPath(_ path: EvolutionPath) {
        pet.setEvolutionPath(path)
        HapticManager.shared.trigger(.heavy)
        isPresented = false
    }
}

// 当前进化卡片
struct CurrentEvolutionCard: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 16) {
            // 宠物图标
            Text(pet.evolutionStage.rawValue)
                .font(.system(size: 80))

            // 阶段名称
            Text(pet.evolutionStage.rawValue)
                .font(.title2)
                .fontWeight(.bold)

            // 进化路径
            if let path = pet.evolutionPath {
                HStack(spacing: 8) {
                    Image(systemName: path.icon)
                        .foregroundColor(path.color)
                    Text(path.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 等级要求
            if pet.evolutionStage != .legendary {
                let nextStage = EvolutionStage.allCases[
                    min(EvolutionStage.allCases.count - 1,
                        EvolutionStage.allCases.firstIndex(of: pet.evolutionStage)! + 1)
                ]

                VStack(spacing: 8) {
                    Text("下个阶段: \(nextStage.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: Double(pet.level), total: Double(nextStage.requiredLevel))
                        .accentColor(.purple)

                    Text("Lv.\(pet.level)/\(nextStage.requiredLevel)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("已达到最终进化!")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

// 进化路径卡片
struct EvolutionPathCard: View {
    let path: EvolutionPath
    let pet: Pet
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(path.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: path.icon)
                        .font(.system(size: 30))
                        .foregroundColor(path.color)
                }

                // 名称
                Text(path.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                // 描述
                Text(path.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // 加成说明
                VStack(alignment: .leading, spacing: 4) {
                    Text("效果:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("• 各项能力提升")
                        .font(.caption2)
                        .foregroundColor(.primary)

                    Text("• 特殊加成")
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(path.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(path.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 进化阶段行
struct EvolutionStageRow: View {
    let stage: EvolutionStage
    let currentStage: EvolutionStage
    let petLevel: Int

    private var isReached: Bool {
        let stageIndex = EvolutionStage.allCases.firstIndex(of: stage) ?? 0
        let currentIndex = EvolutionStage.allCases.firstIndex(of: currentStage) ?? 0
        return stageIndex <= currentIndex
    }

    private var canEvolve: Bool {
        petLevel >= stage.requiredLevel && stage != currentStage
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Text(stage.rawValue)
                .font(.system(size: 40))
                .opacity(isReached ? 1.0 : 0.3)

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(stage.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isReached ? .primary : .secondary)

                Text("需要 Lv.\(stage.requiredLevel)")
                    .font(.caption)
                    .foregroundColor(canEvolve ? .green : .secondary)
            }

            Spacer()

            // 状态
            if isReached {
                if stage == currentStage {
                    Text("当前")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isReached ? Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

// 预览
#Preview("成就解锁") {
    AchievementUnlockView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}

#Preview("进化解锁") {
    EvolutionUnlockView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
