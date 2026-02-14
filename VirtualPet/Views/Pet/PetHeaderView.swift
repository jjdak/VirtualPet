//
//  PetHeaderView.swift
//  VirtualPet
//
//  宠物信息头部视图组件
//  显示宠物类型、等级、年龄、经验、亲密度等基础信息
//

import SwiftUI

struct PetHeaderView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(pet.petType.rawValue)
                    .font(.system(size: 28))

                Text(getEvolutionEmoji())
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Lv.\(pet.level)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    if pet.evolutionStage != .egg {
                        Text("• \(pet.evolutionStage.rawValue)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }

                Text("第 \(pet.age) 天")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("经验")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(pet.experience)/\(pet.level * 100)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("亲密度")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(pet.intimacy)/100")
                            .font(.caption2)
                            .foregroundColor(.pink)
                    }
                }

                ProgressView(value: Double(pet.experience), total: Double(pet.level * 100))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 120)

                if pet.intimacy > 0 {
                    ProgressView(value: Double(pet.intimacy), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                        .frame(width: 120)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private func getEvolutionEmoji() -> String {
        switch pet.evolutionStage {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teen: return "🐥"
        case .adult: return "🐓"
        case .elder: return "🦄"
        case .legendary: return "🌟"
        }
    }
}
