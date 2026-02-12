//
//  PetDisplayView.swift
//  VirtualPet
//
//  宠物主显示视图组件
// 包含：呼吸动画、表情系统、心情背景、进化装饰、粒子特效
//

import SwiftUI

struct PetDisplayView: View {
    @ObservedObject var pet: Pet
    @Binding var breathAnimation: Bool
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]
    @Binding var isAnimating: Bool
    @Binding var intimacyHeartPulse: Bool

    @State private var evolutionGlow = 0.0
    @State private var sparkleOffsets: [CGSize] = []
    @State private var heartOffsets: [CGSize] = []

    private let animationNamespace = Namespace()

    var body: some View {
        ZStack {
            // 背景渐变基于心情和进化阶段
            RoundedRectangle(cornerRadius: 25)
                .fill(getMoodGradient())
                .shadow(color: getMoodShadowColor(), radius: 15, x: 0, y: 5)
                .overlay(
                    // 进化光晕效果
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            getEvolutionGlowColor().opacity(evolutionGlow),
                            lineWidth: 4
                        )
                        .shadow(color: getEvolutionGlowColor().opacity(evolutionGlow), radius: 20)
                )

            // 进化阶段背景装饰
            if pet.evolutionStage != .egg {
                getEvolutionDecoration()
                    .opacity(0.3)
                    .scaleEffect(1.5)
            }

            // 宠物表情 - 优化的动画
            Text(getPetExpression())
                .font(.system(size: getPetSize()))
                .scaleEffect(getPetScale())
                .rotationEffect(getPetRotation())
                .offset(y: petBounce ? -20 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: petBounce)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            // 亲密度爱心装饰 - 使用预计算位置
            if pet.intimacy >= 50 {
                ForEach(0..<min(pet.intimacy / 25, 3), id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.caption)
                        .offset(
                            x: CGFloat(index - 1) * 40,
                            y: -80
                        )
                        .opacity(0.6)
                        .scaleEffect(1.0 + CGFloat(index) * 0.1)
                        .drawingGroup()
                }
            }

            // 进化路径图标
            if let path = pet.evolutionPath {
                ZStack {
                    Circle()
                        .fill(path.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: path.icon)
                        .foregroundColor(path.color)
                        .font(.title3)
                }
                .position(x: 280, y: 50)
            }

            // 粒子效果 - 使用drawingGroup优化
            ForEach(particleEffects) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(particle.position)
            }
            .drawingGroup()

            // 特殊效果 - 优化的动画实现
            if sparkleAnimation {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(.yellow)
                        .frame(width: 12, height: 12)
                        .offset(getSparkleOffset(for: index))
                        .opacity(sparkleAnimation ? 1.0 : 0.0)
                        .scaleEffect(sparkleAnimation ? 2.5 : 1.0)
                        .animation(
                            .easeOut(duration: 1.2)
                                .delay(Double(index) * 0.08),
                            value: sparkleAnimation
                        )
                }
            }

            if heartAnimation {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title)
                        .offset(getHeartOffset(for: index))
                        .scaleEffect(petBounce ? 1.8 : 1.0)
                        .opacity(heartAnimation ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 1.8)
                                .delay(Double(index) * 0.15),
                            value: heartAnimation
                        )
                }
            }
        }
        .frame(height: 280)
        .padding()
        .onAppear {
            startEvolutionGlow()
            initializeOffsets()
        }
        .onChange(of: sparkleAnimation) { oldValue, newValue in
            if newValue {
                initializeOffsets()
            }
        }
        .onChange(of: heartAnimation) { oldValue, newValue in
            if newValue {
                initializeOffsets()
            }
        }
    }

    private func initializeOffsets() {
        sparkleOffsets = (0..<8).map { _ in
            CGSize(width: CGFloat.random(in: -60...60), height: CGFloat.random(in: -60...60))
        }
        heartOffsets = (0..<5).map { _ in
            CGSize(width: CGFloat.random(in: -40...40), height: CGFloat.random(in: -30...100))
        }
    }

    private func getSparkleOffset(for index: Int) -> CGSize {
        guard index < sparkleOffsets.count else {
            return CGSize(width: CGFloat.random(in: -60...60), height: CGFloat.random(in: -60...60))
        }
        return sparkleOffsets[index]
    }

    private func getHeartOffset(for index: Int) -> CGSize {
        guard index < heartOffsets.count else {
            return CGSize(width: CGFloat.random(in: -40...40), height: CGFloat.random(in: -30...100))
        }
        return heartOffsets[index]
    }

    private func startEvolutionGlow() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            evolutionGlow = 0.8
        }
    }

    private func getEvolutionGlowColor() -> Color {
        switch pet.evolutionStage {
        case .egg: return .white
        case .baby: return .green
        case .child: return .blue
        case .teen: return .purple
        case .adult: return .orange
        case .elder: return .pink
        case .legendary: return .yellow
        }
    }

    private func getMoodGradient() -> LinearGradient {
        let baseColor = pet.petType.color

        switch pet.mood {
        case .happy:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .excited:
            return LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [.gray, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sick:
            return LinearGradient(
                colors: [.red.opacity(0.3), .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hungry:
            return LinearGradient(
                colors: [.orange.opacity(0.5), .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleepy:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [baseColor.opacity(0.2), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func getMoodShadowColor() -> Color {
        switch pet.mood {
        case .happy: return .yellow
        case .excited: return .pink
        case .sad: return .blue
        case .sick: return .red
        case .hungry: return .orange
        case .sleepy: return .purple
        default: return pet.petType.color
        }
    }

    private func getPetSize() -> CGFloat {
        let baseSize: CGFloat = 100
        let evolutionBonus = getEvolutionStageIndex() * 10
        let intimacyBonus = pet.intimacy >= 50 ? 10 : 0

        return baseSize + CGFloat(evolutionBonus + intimacyBonus)
    }

    private func getEvolutionStageIndex() -> Int {
        EvolutionStage.allCases.firstIndex(of: pet.evolutionStage) ?? 0
    }

    private func getEvolutionDecoration() -> some View {
        let stage = pet.evolutionStage

        switch stage {
        case .egg:
            return AnyView(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
            )
        case .baby:
            return AnyView(
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
            )
        case .child:
            return AnyView(
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
            )
        case .teen:
            return AnyView(
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                    .frame(width: 120, height: 120)
            )
        case .adult:
            return AnyView(
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 5)
                    .frame(width: 140, height: 140)
            )
        case .elder:
            return AnyView(
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 6)
                    .frame(width: 160, height: 160)
            )
        case .legendary:
            return AnyView(
                ZStack {
                    Circle()
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 7)
                        .frame(width: 180, height: 180)
                    Circle()
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 5)
                        .frame(width: 200, height: 200)
                }
            )
        }
    }

    private func getPetExpression() -> String {
        switch pet.petType {
        case .cat:
            switch pet.mood {
            case .happy: return "\u{1F600}"
            case .sad: return "\u{1F627}"
            case .sick: return "\u{1F640}"
            case .hungry: return "\u{1F640}"
            case .sleepy: return "\u{1F634}"
            case .excited: return "\u{1F643}"
            default: return "\u{1F642}"
            }
        case .dog:
            switch pet.mood {
            case .happy: return "\u{1F436}"
            case .sad: return "\u{1F622}"
            case .sick: return "\u{1F492}"
            case .hungry: return "\u{1F576}"
            case .sleepy: return "\u{1F634}"
            case .excited: return "\u{1F63E}"
            default: return "\u{1F435}"
            }
        case .rabbit:
            switch pet.mood {
            case .happy: return "\u{1F430}"
            case .sad: return "\u{1F614}"
            case .sick: return "\u{1F4A7}"
            case .hungry: return "\u{1F595}"
            case .sleepy: return "\u{1F634}"
            case .excited: return "\u{1F389}"
            default: return "\u{1F438}"
            }
        case .hamster:
            switch pet.mood {
            case .happy: return "\u{1F439}"
            case .sad: return "\u{1F63E}"
            case .sick: return "\u{1F495}"
            case .hungry: return "\u{1F4F0}"
            case .sleepy: return "\u{1F634}"
            case .excited: return "\u{1F3CE}"
            default: return "\u{1F43D}"
            }
        case .bird:
            switch pet.mood {
            case .happy: return "\u{1F426}"
            case .sad: return "\u{1F614}"
            case .sick: return "\u{1F4A7}"
            case .hungry: return "\u{1F52D}"
            case .sleepy: return "\u{1F634}"
            case .excited: return "\u{1F628}"
            default: return "\u{1F435}"
            }
        }
    }

    private func getPetScale() -> CGFloat {
        var scale: CGFloat = 1.0

        switch pet.mood {
        case .excited: scale = 1.2
        case .happy: scale = 1.1
        case .sad: scale = 0.9
        case .sick: scale = 0.8
        case .sleepy: scale = 0.95
        default: scale = 1.0
        }

        if pet.intimacy >= 80 {
            scale *= 1.05
        }

        return scale
    }

    private func getPetRotation() -> Angle {
        switch pet.mood {
        case .sad: return Angle(degrees: -5)
        case .excited: return Angle(degrees: 5)
        case .sleepy: return Angle(degrees: 10)
        default: return Angle(degrees: 0)
        }
    }
}
EOF
echo "✅ PetDisplayView.swift 创建完成 (~360 行)"