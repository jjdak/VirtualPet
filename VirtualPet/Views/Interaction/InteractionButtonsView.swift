//
//  InteractionButtonsView.swift
//  VirtualPet
//
// 互动按钮视图组件
// 包含 5 个主要互动按钮（喂食、玩耍、清理、运动、拥抱）
// 处理动画效果、粒子系统和错误处理
//

import SwiftUI

struct InteractionButtonsView: View {
    @ObservedObject var pet: Pet
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]
    @Binding var isAnimating: Bool
    @Binding var errorMessage: String?
    @Binding var showingError: Bool
    @Binding var intimacyHeartPulse: Bool

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
                    action: { handleInteraction(.feed, animation: .sparkle) }
                )

                InteractionButton(
                    title: "玩耍",
                    color: .purple,
                    icon: "gamecontroller",
                    action: { handleInteraction(.play, animation: .heart) }
                )

                InteractionButton(
                    title: "清理",
                    color: .green,
                    icon: "sparkles",
                    action: { handleInteraction(.clean, animation: .bounce) }
                )

                InteractionButton(
                    title: "运动",
                    color: .blue,
                    icon: "figure.walk",
                    action: { handleInteraction(.exercise, animation: .bounce) }
                )

                InteractionButton(
                    title: "拥抱",
                    color: .red,
                    icon: "heart.fill",
                    action: { handleInteraction(.cuddle, animation: .heart) }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - 动画类型
    enum AnimationType {
        case bounce, sparkle, heart
    }

    // MARK: - 处理交互 - 统一处理逻辑
    private func handleInteraction(_ type: Pet.InteractionType, animation: AnimationType) {
        guard !isAnimating else { return }
        isAnimating = true

        let result = pet.interact(type: type)
        handleInteractionResult(result, animation: animation, interactionType: type)
    }

    // MARK: - 处理交互结果
    private func handleInteractionResult(_ result: Pet.InteractionResult, animation: AnimationType, interactionType: Pet.InteractionType) {
        switch result {
        case .success(_):
            applyAnimation(animation, for: interactionType)
            checkIntimacyMilestone()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        case .failure(let message), .warning(let message):
            showError(message)
            isAnimating = false
        }
    }

    // MARK: - 应用动画效果
    private func applyAnimation(_ type: AnimationType, for interactionType: Pet.InteractionType) {
        let particleColor = getParticleColor(for: interactionType)
        let particleCount = getParticleCount(for: interactionType)

        switch type {
        case .bounce:
            animateBounce()
        case .sparkle:
            animateBounce()
            sparkleAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                sparkleAnimation = false
            }
        case .heart:
            animateBounce()
            heartAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                heartAnimation = false
            }
            addParticles(color: particleColor, count: particleCount)
        }
    }

    // MARK: - 获取粒子颜色
    private func getParticleColor(for type: Pet.InteractionType) -> Color {
        switch type {
        case .feed: return .orange
        case .play: return .purple
        case .clean: return .green
        case .exercise: return .blue
        case .cuddle: return .red
        case .train: return .orange
        case .discipline: return .gray
        case .praise: return .yellow
        case .study: return .indigo
        }
    }

    // MARK: - 获取粒子数量
    private func getParticleCount(for type: Pet.InteractionType) -> Int {
        switch type {
        case .feed: return 5
        case .play: return 3
        case .clean: return 4
        case .exercise: return 3
        case .cuddle: return 6
        case .train: return 4
        case .discipline: return 2
        case .praise: return 5
        case .study: return 3
        }
    }

    // MARK: - 弹跳动画
    private func animateBounce() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            petBounce = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    petBounce = false
                }
            }
        }
    }

    // MARK: - 检查亲密度里程碑
    private func checkIntimacyMilestone() {
        if pet.intimacy > 0 && pet.intimacy % 10 == 0 {
            withAnimation {
                intimacyHeartPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    intimacyHeartPulse = false
                }
            }
        }
    }

    // MARK: - 显示错误消息
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingError = false
            errorMessage = nil
        }
    }

    // MARK: - 粒子系统
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
EOF
echo "✅ InteractionButtonsView.swift 创建完成 (~800 行)"