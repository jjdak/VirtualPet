//
//  PetAvatarView.swift
//  VirtualPet
//
//  宠物形象视图 - 使用 Emoji + 心情修饰符
//  Phase 1, Task 1.7 快速原型 (2小时版本)
//

import SwiftUI

struct PetAvatarView: View {
    let petType: PetType
    let mood: PetMood
    let evolutionStage: EvolutionStage

    var body: some View {
        ZStack {
            // 基础宠物 Emoji
            Text(getPetEmoji())
                .font(.system(size: getPetSize()))

            // 心情修饰符层
            if let moodModifier = getMoodModifier() {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(moodModifier)
                            .font(.caption)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 2)
                            )
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, 20)
                }
            }

            // 进化装饰
            if evolutionStage != .egg {
                getEvolutionDecoration()
                    .opacity(0.6)
            }
        }
    }

    // MARK: - 基础宠物 Emoji
    private func getPetEmoji() -> String {
        switch petType {
        case .cat:
            return "🐱"
        case .dog:
            return "🐶"
        case .rabbit:
            return "🐰"
        case .bird:
            return "🐦"
        case .hamster:
            return "🐹"
        }
    }

    // MARK: - 宠物大小（基于进化阶段）
    private func getPetSize() -> CGFloat {
        switch evolutionStage {
        case .egg:
            return 60
        case .baby:
            return 70
        case .child:
            return 80
        case .teen:
            return 90
        case .adult:
            return 100
        case .elder:
            return 95
        case .legendary:
            return 110
        }
    }

    // MARK: - 心情修饰符
    private func getMoodModifier() -> String? {
        switch mood {
        case .happy:
            return "😊"
        case .sad:
            return "😢"
        case .sick:
            return "🤒"
        case .hungry:
            return "😋"
        case .sleepy:
            return "😴"
        case .excited:
            return "🤩"
        case .normal:
            return nil
        }
    }

    // MARK: - 进化装饰
    @ViewBuilder
    private func getEvolutionDecoration() -> some View {
        let color = getEvolutionColor()

        ZStack {
            // 光环
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 2)
                .frame(width: 130, height: 130)

            // 星星装饰（高阶段）
            if evolutionStage == .legendary {
                ForEach(0..<4) { index in
                    Text("⭐")
                        .font(.caption)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi / 2) * 70),
                            y: CGFloat(sin(Double(index) * .pi / 2) * 70)
                        )
                }
            } else if evolutionStage == .adult || evolutionStage == .elder {
                ForEach(0..<2) { index in
                    Text("✨")
                        .font(.caption2)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi) * 60),
                            y: CGFloat(sin(Double(index) * .pi) * 60)
                        )
                }
            }
        }
    }

    // MARK: - 进化颜色
    private func getEvolutionColor() -> Color {
        switch evolutionStage {
        case .egg:
            return .white
        case .baby:
            return .green
        case .child:
            return .blue
        case .teen:
            return .purple
        case .adult:
            return .orange
        case .elder:
            return .pink
        case .legendary:
            return .yellow
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 30) {
        // 不同类型
        HStack(spacing: 20) {
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child)
            PetAvatarView(petType: .dog, mood: .excited, evolutionStage: .adult)
            PetAvatarView(petType: .rabbit, mood: .normal, evolutionStage: .teen)
        }

        // 不同心情
        HStack(spacing: 20) {
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult)
            PetAvatarView(petType: .cat, mood: .sad, evolutionStage: .adult)
            PetAvatarView(petType: .cat, mood: .sick, evolutionStage: .adult)
            PetAvatarView(petType: .cat, mood: .excited, evolutionStage: .adult)
        }

        // 不同进化阶段
        HStack(spacing: 15) {
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .egg)
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .baby)
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child)
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult)
            PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .legendary)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
