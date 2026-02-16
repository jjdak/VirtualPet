//
//  SkillSystemView.swift
//  VirtualPet
//
//  技能系统UI
//  显示和管理宠物的技能
//

import SwiftUI

struct SkillSystemView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var selectedSkill: PetSkill?
    @State private var showDetail = false

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("⚡ 技能系统")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // 可用技能点
                    if pet.availableSkillPoints > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(pet.availableSkillPoints)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.3))
                        )
                    }
                }

                // 技能列表
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(PetSkill.allCases, id: \.self) { skill in
                            SkillCard(
                                skill: skill,
                                pet: pet,
                                action: {
                                    selectedSkill = skill
                                    showDetail = true
                                }
                            )
                        }
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
        .sheet(isPresented: $showDetail) {
            if let skill = selectedSkill {
                PetSkillDetailView(skill: skill, pet: pet, isPresented: $showDetail)
            }
        }
    }
}

// 技能卡片组件
struct SkillCard: View {
    let skill: PetSkill
    let pet: Pet
    let action: () -> Void

    private var currentLevel: Int {
        pet.unlockedSkills[skill] ?? 0
    }

    private var isUnlocked: Bool {
        currentLevel > 0
    }

    private var canLevelUp: Bool {
        pet.availableSkillPoints > 0 && currentLevel < skill.maxLevel
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 图标和等级
                ZStack {
                    Circle()
                        .fill(skill.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: skill.icon)
                        .font(.system(size: 28))
                        .foregroundColor(skill.color)

                    // 等级标记
                    if isUnlocked {
                        VStack {
                            HStack {
                                Spacer()
                                Text("Lv.\(currentLevel)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(skill.color)
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 60, height: 60)
                    }
                }

                // 名称
                Text(skill.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // 描述
                Text(skill.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // 进度条
                if isUnlocked {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(currentLevel), total: Double(skill.maxLevel))
                            .accentColor(skill.color)

                        Text("\(currentLevel)/\(skill.maxLevel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // 状态标签
                if isUnlocked {
                    if canLevelUp {
                        Text("可升级")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    } else if currentLevel >= skill.maxLevel {
                        Text("已满级")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(skill.color)
                            )
                    }
                } else {
                    Text("未解锁")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray)
                        )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? skill.color.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUnlocked ? skill.color.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 技能详情视图
struct PetSkillDetailView: View {
    let skill: PetSkill
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    private var currentLevel: Int {
        pet.unlockedSkills[skill] ?? 0
    }

    private var isUnlocked: Bool {
        currentLevel > 0
    }

    private var canUnlock: Bool {
        !isUnlocked && pet.availableSkillPoints > 0
    }

    private var canLevelUp: Bool {
        isUnlocked && pet.availableSkillPoints > 0 && currentLevel < skill.maxLevel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if !canUnlock && !canLevelUp {
                        isPresented = false
                    }
                }

            VStack(spacing: 24) {
                // 技能图标和信息
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(skill.color.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: skill.icon)
                            .font(.system(size: 50))
                            .foregroundColor(skill.color)
                    }

                    Text(skill.rawValue)
                        .font(.title)
                        .fontWeight(.bold)

                    if isUnlocked {
                        Text("Lv.\(currentLevel)/\(skill.maxLevel)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }

                // 当前效果
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前效果")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isUnlocked {
                        Text(skill.effect(at: currentLevel))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(skill.color.opacity(0.1))
                            )
                    } else {
                        Text("该技能尚未解锁")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }

                // 下级效果预览
                if isUnlocked && currentLevel < skill.maxLevel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("下级效果")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(skill.effect(at: currentLevel + 1))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                }

                // 操作按钮
                if canUnlock {
                    Button(action: {
                        unlockSkill()
                    }) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                            Text("解锁技能 (消耗1技能点)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(skill.color)
                        .cornerRadius(12)
                    }
                } else if canLevelUp {
                    Button(action: {
                        levelUpSkill()
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("升级技能 (消耗1技能点)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(skill.color)
                        .cornerRadius(12)
                    }
                } else if isUnlocked && currentLevel >= skill.maxLevel {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("已达到最大等级")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("技能点不足")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(12)
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

    private func unlockSkill() {
        if pet.learnSkill(skill) {
            HapticManager.shared.trigger(.heavy)

            // 发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: ["text": "✨ 技能解锁!", "color": skill.color]
            )
        }
    }

    private func levelUpSkill() {
        if pet.learnSkill(skill) {
            HapticManager.shared.trigger(.heavy)

            // 发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: ["text": "⬆️ 技能升级!", "color": skill.color]
            )
        }
    }
}

// 预览
#Preview {
    SkillSystemView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
