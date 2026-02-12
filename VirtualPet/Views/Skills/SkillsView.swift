//
//  SkillsView.swift
//  VirtualPet
//
//  技能系统视图组件
//  显示技能点、技能列表和总技能等级
//

import SwiftUI

struct SkillsView: View {
    @ObservedObject var pet: Pet
    @State private var showingSkillDetails: PetSkill?

    var body: some View {
        VStack(spacing: 12) {
            Text("宠物技能")
                .font(.headline)
                .foregroundColor(.secondary)

            // 技能点显示
            HStack {
                Text("技能点：")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("\(pet.availableSkillPoints)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Spacer()

                Button(action: {
                    pet.earnSkillPoints()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            Divider()

            // 技能列表
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(PetSkill.allCases, id: \.self) { skill in
                        SkillRow(
                            skill: skill,
                            currentLevel: pet.unlockedSkills[skill] ?? 0,
                            canLearn: pet.canLearnSkill(skill),
                            onLearn: {
                                _ = pet.learnSkill(skill)
                            },
                            onTapDetails: {
                                showingSkillDetails = skill
                            }
                        )
                    }
                }
            }

            Divider()

            // 总技能等级
            HStack {
                Text("总技能等级：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(pet.getTotalSkillLevel())")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .font(.caption)
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.yellow.opacity(0.15))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .sheet(item: $showingSkillDetails) { skill in
                SkillDetailView(skill: skill, pet: pet)
            }
    }
}
