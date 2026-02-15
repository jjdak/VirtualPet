//
//  PetAvatarView.swift
//  VirtualPet
//
//  宠物形象视图 - SF Symbols + 自定义表情系统
//  Phase 1, Task 1.7 完整版本 (18小时实现)
//
//  实现内容:
//  - SF Symbols 基础图标
//  - 5种宠物类型可视化
//  - 7种心情表情系统
//  - 进化阶段动画
//

import SwiftUI

struct PetAvatarView: View {
    let petType: PetType
    let mood: PetMood
    let evolutionStage: EvolutionStage

    @State private var isBreathing = false
    @State private var moodAnimation: Double = 0

    var body: some View {
        ZStack {
            // 呼吸动画层
            Circle()
                .fill(getPetTypeColor().opacity(0.1))
                .frame(width: getPetSize() * 1.5, height: getPetSize() * 1.5)
                .scaleEffect(isBreathing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isBreathing)

            // 主宠物图标
            VStack(spacing: 0) {
                // 基础宠物图标
                getPetBaseIcon()
                    .frame(width: getPetSize(), height: getPetSize())

                // 自定义表情层
                getExpressionOverlay()
                    .frame(width: getPetSize(), height: getPetSize())
            }

            // 进化装饰
            if evolutionStage != .egg {
                getEvolutionDecorationView()
            }

            // 心情特效
            getMoodEffectsView()
        }
        .onAppear {
            isBreathing = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                moodAnimation = 1
            }
        }
    }

    // MARK: - 基础宠物图标 (SF Symbols)
    private func getPetBaseIcon() -> some View {
        let (iconName, iconScale): (String, CGFloat) = {
            switch petType {
            case .cat: return ("cat.fill", 0.7)
            case .dog: return ("dog.fill", 0.7)
            case .rabbit: return ("hare.fill", 0.7)
            case .bird: return ("bird.fill", 0.6)
            case .hamster: return ("circle.fill", 0.65)
            }
        }()

        return Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(getPetTypeColor())
            .scaleEffect(iconScale)
    }

    // MARK: - 自定义表情层
    private func getExpressionOverlay() -> some View {
        ZStack {
            // 眼睛层
            EyesView(mood: mood, petType: petType)
                .offset(y: -getPetSize() * 0.15)

            // 嘴巴层
            MouthView(mood: mood)
                .offset(y: getPetSize() * 0.1)

            // 特殊装饰
            getSpecialDecorationsView()
        }
    }

    // MARK: - 眼睛视图
    struct EyesView: View {
        let mood: PetMood
        let petType: PetType

        var body: some View {
            HStack(spacing: getEyeSpacing()) {
                LeftEyeView(mood: mood)
                RightEyeView(mood: mood)
            }
            .foregroundColor(.black)
        }

        private func getEyeSpacing() -> CGFloat {
            switch petType {
            case .bird, .hamster:
                return 15
            default:
                return 20
            }
        }
    }

    struct LeftEyeView: View {
        let mood: PetMood

        var body: some View {
            Group {
                switch mood {
                case .happy:
                    Capsule().frame(width: 12, height: 6)
                case .excited:
                    Image(systemName: "star.fill").font(.caption)
                case .sleepy:
                    Capsule().frame(width: 10, height: 3)
                case .sick:
                    Circle().frame(width: 8, height: 8)
                case .sad:
                    Ellipse().frame(width: 10, height: 12)
                case .hungry:
                    Circle().frame(width: 14, height: 14)
                case .normal:
                    Circle().frame(width: 12, height: 12)
                }
            }
        }
    }

    struct RightEyeView: View {
        let mood: PetMood

        var body: some View {
            Group {
                switch mood {
                case .happy:
                    Capsule().frame(width: 12, height: 6)
                case .excited:
                    Image(systemName: "star.fill").font(.caption)
                case .sleepy:
                    Capsule().frame(width: 10, height: 3)
                case .sick:
                    Circle().frame(width: 8, height: 8)
                case .sad:
                    Ellipse().frame(width: 10, height: 12)
                case .hungry:
                    Circle().frame(width: 14, height: 14)
                case .normal:
                    Circle().frame(width: 12, height: 12)
                }
            }
        }
    }

    // MARK: - 嘴巴视图
    struct MouthView: View {
        let mood: PetMood

        var body: some View {
            getMouthShape()
                .frame(width: 20, height: 15)
        }

        @ViewBuilder
        private func getMouthShape() -> some View {
            switch mood {
            case .happy:
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 15))
                    path.addQuadCurve(
                        to: CGPoint(x: 20, y: 15),
                        control: CGPoint(x: 10, y: 5)
                    )
                }
                .stroke(Color.black, lineWidth: 2.5)

            case .sad:
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 5))
                    path.addQuadCurve(
                        to: CGPoint(x: 20, y: 5),
                        control: CGPoint(x: 10, y: 15)
                    )
                }
                .stroke(Color.black, lineWidth: 2.5)

            case .hungry:
                Ellipse()
                    .strokeBorder(Color.black, lineWidth: 2.5)
                    .frame(width: 15, height: 10)

            case .excited:
                Ellipse()
                    .strokeBorder(Color.black, lineWidth: 2.5)
                    .frame(width: 20, height: 12)

            case .sleepy:
                Circle()
                    .strokeBorder(Color.black, lineWidth: 2.5)
                    .frame(width: 8, height: 8)

            case .sick:
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 10))
                    path.addCurve(
                        to: CGPoint(x: 10, y: 5),
                        control1: CGPoint(x: 3, y: 10),
                        control2: CGPoint(x: 7, y: 5)
                    )
                    path.addCurve(
                        to: CGPoint(x: 20, y: 10),
                        control1: CGPoint(x: 13, y: 5),
                        control2: CGPoint(x: 17, y: 10)
                    )
                }
                .stroke(Color.black, lineWidth: 2.5)

            case .normal:
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 15, height: 2)
            }
        }
    }

    // MARK: - 特殊装饰
    private func getSpecialDecorationsView() -> some View {
        VStack {
            Spacer()

            switch mood {
            case .sick:
                HStack {
                    Spacer()
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .offset(x: -15, y: -20)
                }

            case .happy:
                if moodAnimation > 0.5 {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .offset(x: -20, y: -10)
                            .opacity(moodAnimation)

                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .offset(x: 20, y: -15)
                            .opacity(moodAnimation)
                    }
                }

            case .hungry:
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.6))
                        .offset(x: 12, y: 5)
                    Spacer()
                }

            default:
                EmptyView()
            }
        }
        .frame(height: getPetSize())
    }

    // MARK: - 心情特效
    private func getMoodEffectsView() -> some View {
        let effectSize = getPetSize() * 1.8

        return Group {
            switch mood {
            case .excited:
                ForEach(0..<4) { index in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi / 2 + moodAnimation * 2)) * effectSize / 2,
                            y: CGFloat(sin(Double(index) * .pi / 2 + moodAnimation * 2)) * effectSize / 2
                        )
                        .rotationEffect(.degrees(moodAnimation * 360))
                }

            case .happy:
                if moodAnimation > 0.3 {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.purple.opacity(0.5))
                        .offset(y: -effectSize / 2 * moodAnimation)
                        .opacity(moodAnimation)
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - 进化装饰
    private func getEvolutionDecorationView() -> some View {
        let decorationSize = getPetSize() * 1.6
        let color = getEvolutionColor()

        return ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: decorationSize, height: decorationSize)
                .scaleEffect(isBreathing ? 1.05 : 0.95)

            if evolutionStage == .legendary {
                ForEach(0..<8) { index in
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(color)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi / 4)) * decorationSize / 2,
                            y: CGFloat(sin(Double(index) * .pi / 4)) * decorationSize / 2
                        )
                        .rotationEffect(.degrees(moodAnimation * 360))
                }
            } else if evolutionStage == .adult || evolutionStage == .elder {
                ForEach(0..<4) { index in
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundColor(color)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi / 2)) * decorationSize / 2.2,
                            y: CGFloat(sin(Double(index) * .pi / 2)) * decorationSize / 2.2
                        )
                }
            }
        }
    }

    // MARK: - 宠物大小（基于进化阶段）
    private func getPetSize() -> CGFloat {
        switch evolutionStage {
        case .egg: return 60
        case .baby: return 70
        case .child: return 80
        case .teen: return 90
        case .adult: return 100
        case .elder: return 95
        case .legendary: return 110
        }
    }

    // MARK: - 宠物类型颜色
    private func getPetTypeColor() -> Color {
        switch petType {
        case .cat: return .orange
        case .dog: return .blue
        case .rabbit: return .pink
        case .bird: return .green
        case .hamster: return .yellow
        }
    }

    // MARK: - 进化颜色
    private func getEvolutionColor() -> Color {
        switch evolutionStage {
        case .egg: return .white
        case .baby: return .green
        case .child: return .blue
        case .teen: return .purple
        case .adult: return .orange
        case .elder: return .pink
        case .legendary: return .yellow
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 30) {
        VStack(spacing: 10) {
            Text("不同宠物类型")
                .font(.headline)
            HStack(spacing: 20) {
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child)
                PetAvatarView(petType: .dog, mood: .normal, evolutionStage: .adult)
                PetAvatarView(petType: .rabbit, mood: .excited, evolutionStage: .teen)
                PetAvatarView(petType: .bird, mood: .happy, evolutionStage: .child)
                PetAvatarView(petType: .hamster, mood: .normal, evolutionStage: .baby)
            }
        }

        VStack(spacing: 10) {
            Text("不同心情状态")
                .font(.headline)
            HStack(spacing: 15) {
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .sad, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .sick, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .excited, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .hungry, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .sleepy, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .normal, evolutionStage: .adult)
            }
        }

        VStack(spacing: 10) {
            Text("进化阶段")
                .font(.headline)
            HStack(spacing: 12) {
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .egg)
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .baby)
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child)
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .teen)
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult)
                PetAvatarView(petType: .cat, mood: .happy, evolutionStage: .legendary)
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
