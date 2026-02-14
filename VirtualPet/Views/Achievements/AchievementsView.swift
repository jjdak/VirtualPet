//
//  AchievementsView.swift
//  VirtualPet
//
//  成就系统视图组件
//  显示已解锁的成就列表
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var pet: Pet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("成就系统")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(pet.achievements) { achievement in
                            AchievementCard(achievement: achievement, unlocked: achievement.unlocked)
                        }
                    }
                    .padding()
                }

                Button("关闭") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom)
            }
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
                #else
                ToolbarItem(placement: .automatic) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color.purple.opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(unlocked ? .purple : .gray)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(unlocked ? Color.purple.opacity(0.05) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(unlocked ? Color.purple.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
