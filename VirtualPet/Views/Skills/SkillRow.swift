//
//  SkillRow.swift
//  VirtualPet
//
//  技能行组件
//

import SwiftUI

struct SkillRow: View {
    let skill: PetSkill
    let currentLevel: Int
    let canLearn: Bool
    let onLearn: () -> Void
    let onTapDetails: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: skill.icon)
                .font(.title2)
                .foregroundColor(skill.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Lv. \(currentLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onLearn) {
                Text(canLearn ? "学习" : "满级")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(canLearn ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(canLearn ? Color.blue : Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canLearn)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .onTapGesture {
            onTapDetails()
        }
    }
}

struct SkillDetailView: View {
    let skill: PetSkill
    @ObservedObject var pet: Pet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(skill.color.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: skill.icon)
                            .font(.system(size: 40))
                            .foregroundColor(skill.color)
                    }

                    Text(skill.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Lv. \(pet.unlockedSkills[skill] ?? 0)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("技能描述")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(skill.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        Divider()

                        Text("技能效果")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(skill.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("Lv. \(pet.unlockedSkills[skill] ?? 0): \(skill.effect(at: pet.unlockedSkills[skill] ?? 0))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                Spacer()

                Button("关闭") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}
