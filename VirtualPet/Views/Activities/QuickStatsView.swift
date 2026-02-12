//
//  QuickStatsView.swift
//  VirtualPet
//
//  快速统计视图组件
//  显示宠物的核心统计数据（总互动次数、最高快乐值、成就数等）
//

import SwiftUI

struct QuickStatsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 12) {
            Text("宠物档案")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                HStack(spacing: 15) {
                    StatItem(title: "总互动", value: "\(pet.totalInteractions)", color: .blue)

                    StatItem(title: "最高快乐", value: "\(pet.maxHappiness)", color: .yellow)
                }

                HStack(spacing: 15) {
                    StatItem(title: "成就数", value: "\(pet.unlockedAchievements)", color: .purple)

                    StatItem(title: "亲密度", value: pet.intimacy, color: .pink, suffix: "/100")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }
}
