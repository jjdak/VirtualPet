//
//  PixelPetAvatarView.swift
//  VirtualPet
//
//  宠物形象视图 - 可爱像素风格 (8-bit)
//  Phase 1, Task 1.7 升级版本
//
//  实现内容:
//  - 像素艺术风格宠物形象
//  - 5种宠物类型像素化
//  - 7种心情像素表情
//  - 可爱的8-bit动画效果
//

import SwiftUI

struct PixelPetAvatarView: View {
    let petType: PetType
    let mood: PetMood
    let evolutionStage: EvolutionStage
    let isBlinking: Bool  // Phase 4: 外部眨眼状态

    @State private var bounceOffset: CGFloat = 0
    @State private var animationFrame = 0

    var body: some View {
        ZStack {
            // 像素网格容器
            PixelGrid(petType: petType, mood: mood, evolutionStage: evolutionStage)
                .frame(width: getPetSize(), height: getPetSize())
                .scaleEffect(1 + bounceOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceOffset)

            // Phase 4: 使用外部眨眼状态
            if isBlinking {
                PixelBlinkOverlay(petType: petType)
                    .frame(width: getPetSize(), height: getPetSize())
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func getPetSize() -> CGFloat {
        switch evolutionStage {
        case .egg: return 64
        case .baby: return 72
        case .child: return 80
        case .teen: return 88
        case .adult: return 96
        case .elder: return 92
        case .legendary: return 104
        }
    }

    private func startAnimations() {
        // 呼吸动画 (轻微弹跳)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            bounceOffset = 0.05
        }

        // Phase 4: 移除内部眨眼Timer,使用外部控制
        // 眨眼由 BreathAnimationManager 统一管理

        // 像素动画帧
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            animationFrame = (animationFrame + 1) % 2
        }
    }
}

// MARK: - 像素网格
struct PixelGrid: View {
    let petType: PetType
    let mood: PetMood
    let evolutionStage: EvolutionStage

    var body: some View {
        Canvas { context, size in
            let pixelSize = size.width / 16
            let pixels = getPetPixels()

            for (index, color) in pixels.enumerated() {
                if color != .clear {
                    let x = CGFloat(index % 16) * pixelSize
                    let y = CGFloat(index / 16) * pixelSize
                    let rect = CGRect(x: x, y: y, width: pixelSize, height: pixelSize)

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }

    private func getPetPixels() -> [Color] {
        var basePixels = getBasePetPixels()
        let expressionPixels = getExpressionPixels()

        // 叠加表情
        for i in 0..<min(basePixels.count, expressionPixels.count) {
            if expressionPixels[i] != .clear {
                basePixels[i] = expressionPixels[i]
            }
        }

        return basePixels
    }

    // MARK: - 基础宠物像素
    private func getBasePetPixels() -> [Color] {
        let petColor = getPetColor()
        let secondaryColor = getSecondaryColor()

        switch petType {
        case .cat:
            return CatPixels.getBasePixels(color: petColor, secondary: secondaryColor)
        case .dog:
            return DogPixels.getBasePixels(color: petColor, secondary: secondaryColor)
        case .rabbit:
            return RabbitPixels.getBasePixels(color: petColor, secondary: secondaryColor)
        case .bird:
            return BirdPixels.getBasePixels(color: petColor, secondary: secondaryColor)
        case .hamster:
            return HamsterPixels.getBasePixels(color: petColor, secondary: secondaryColor)
        }
    }

    // MARK: - 表情像素
    private func getExpressionPixels() -> [Color] {
        switch mood {
        case .happy:
            return HappyExpression.getPixels()
        case .sad:
            return SadExpression.getPixels()
        case .sick:
            return SickExpression.getPixels()
        case .hungry:
            return HungryExpression.getPixels()
        case .sleepy:
            return SleepyExpression.getPixels()
        case .excited:
            return ExcitedExpression.getPixels()
        case .normal:
            return NormalExpression.getPixels()
        }
    }

    private func getPetColor() -> Color {
        switch petType {
        case .cat: return Color(red: 1.0, green: 0.6, blue: 0.4) // 橙色
        case .dog: return Color(red: 0.5, green: 0.6, blue: 0.8) // 蓝灰色
        case .rabbit: return Color(red: 1.0, green: 0.8, blue: 0.9) // 粉色
        case .bird: return Color(red: 0.6, green: 0.8, blue: 0.5) // 绿色
        case .hamster: return Color(red: 1.0, green: 0.9, blue: 0.4) // 黄色
        }
    }

    private func getSecondaryColor() -> Color {
        switch petType {
        case .cat: return Color(red: 0.9, green: 0.5, blue: 0.3)
        case .dog: return Color(red: 0.4, green: 0.5, blue: 0.7)
        case .rabbit: return Color(red: 0.9, green: 0.7, blue: 0.8)
        case .bird: return Color(red: 0.5, green: 0.7, blue: 0.4)
        case .hamster: return Color(red: 0.9, green: 0.8, blue: 0.3)
        }
    }
}

// MARK: - 眨眼覆盖层
struct PixelBlinkOverlay: View {
    let petType: PetType

    var body: some View {
        Canvas { context, size in
            let pixelSize = size.width / 16
            let blinkPixels = getBlinkPixels()

            for (index, color) in blinkPixels.enumerated() {
                if color != .clear {
                    let x = CGFloat(index % 16) * pixelSize
                    let y = CGFloat(index / 16) * pixelSize
                    let rect = CGRect(x: x, y: y, width: pixelSize, height: pixelSize)

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }

    private func getBlinkPixels() -> [Color] {
        // 闭眼像素 (两条横线)
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼闭眼
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor

        // 右眼闭眼
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor

        return pixels
    }
}

// MARK: - 像素数据 (16x16 网格 = 256 像素点)
enum CatPixels {
    static func getBasePixels(color: Color, secondary: Color) -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)

        // 耳朵 (左)
        pixels[1 * 16 + 3] = color
        pixels[1 * 16 + 4] = color
        pixels[2 * 16 + 2] = color
        pixels[2 * 16 + 3] = secondary

        // 耳朵 (右)
        pixels[1 * 16 + 11] = color
        pixels[1 * 16 + 12] = color
        pixels[2 * 16 + 12] = color
        pixels[2 * 16 + 13] = secondary

        // 头部轮廓
        for y in 3..<10 {
            for x in 3..<13 {
                pixels[y * 16 + x] = color
            }
        }

        // 面部中心 (较浅)
        for y in 4..<8 {
            for x in 4..<12 {
                pixels[y * 16 + x] = secondary
            }
        }

        // 身体
        for y in 10..<13 {
            for x in 5..<11 {
                pixels[y * 16 + x] = color
            }
        }

        // 尾巴
        pixels[11 * 16 + 3] = color
        pixels[11 * 16 + 4] = color

        return pixels
    }
}

enum DogPixels {
    static func getBasePixels(color: Color, secondary: Color) -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)

        // 耳朵 (垂耳)
        for y in 2..<6 {
            pixels[y * 16 + 2] = color
            pixels[y * 16 + 13] = color
        }

        // 头部
        for y in 3..<10 {
            for x in 3..<13 {
                pixels[y * 16 + x] = color
            }
        }

        // 面部
        for y in 4..<8 {
            for x in 4..<12 {
                pixels[y * 16 + x] = secondary
            }
        }

        // 身体
        for y in 10..<13 {
            for x in 5..<11 {
                pixels[y * 16 + x] = color
            }
        }

        // 鼻子区域
        pixels[7 * 16 + 7] = Color(red: 0.3, green: 0.2, blue: 0.2)
        pixels[7 * 16 + 8] = Color(red: 0.3, green: 0.2, blue: 0.2)

        return pixels
    }
}

enum RabbitPixels {
    static func getBasePixels(color: Color, secondary: Color) -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)

        // 长耳朵 (左)
        for y in 0..<4 {
            pixels[y * 16 + 4] = color
            if y < 3 {
                pixels[y * 16 + 5] = secondary
            }
        }

        // 长耳朵 (右)
        for y in 0..<4 {
            pixels[y * 16 + 10] = color
            if y < 3 {
                pixels[y * 16 + 11] = secondary
            }
        }

        // 头部 (圆形)
        for y in 4..<9 {
            for x in 4..<12 {
                pixels[y * 16 + x] = color
            }
        }

        // 面部
        for y in 5..<8 {
            for x in 5..<11 {
                pixels[y * 16 + x] = secondary
            }
        }

        // 身体
        for y in 9..<12 {
            for x in 5..<11 {
                pixels[y * 16 + x] = color
            }
        }

        return pixels
    }
}

enum BirdPixels {
    static func getBasePixels(color: Color, secondary: Color) -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)

        // 身体 (椭圆形)
        for y in 4..<10 {
            for x in 4..<12 {
                if y == 4 || y == 9 {
                    if x > 4 && x < 12 {
                        pixels[y * 16 + x] = color
                    }
                } else {
                    pixels[y * 16 + x] = color
                }
            }
        }

        // 腹部
        for y in 5..<9 {
            for x in 6..<10 {
                pixels[y * 16 + x] = secondary
            }
        }

        // 翅膀 (左)
        pixels[6 * 16 + 2] = color
        pixels[6 * 16 + 3] = color
        pixels[7 * 16 + 2] = color

        // 翅膀 (右)
        pixels[6 * 16 + 12] = color
        pixels[6 * 16 + 13] = color
        pixels[7 * 16 + 13] = color

        // 嘴巴
        pixels[6 * 16 + 12] = Color.orange

        return pixels
    }
}

enum HamsterPixels {
    static func getBasePixels(color: Color, secondary: Color) -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)

        // 身体 (圆形)
        for y in 4..<10 {
            for x in 4..<12 {
                pixels[y * 16 + x] = color
            }
        }

        // 腹部
        for y in 5..<9 {
            for x in 5..<11 {
                pixels[y * 16 + x] = secondary
            }
        }

        // 耳朵 (左上)
        pixels[3 * 16 + 5] = color
        pixels[3 * 16 + 6] = secondary

        // 耳朵 (右上)
        pixels[3 * 16 + 9] = color
        pixels[3 * 16 + 10] = secondary

        // 腮红 (左)
        pixels[6 * 16 + 4] = Color(red: 1.0, green: 0.7, blue: 0.7).opacity(0.6)

        // 腮红 (右)
        pixels[6 * 16 + 11] = Color(red: 1.0, green: 0.7, blue: 0.7).opacity(0.6)

        return pixels
    }
}

// MARK: - 表情像素
enum NormalExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor
        pixels[6 * 16 + 5] = eyeColor
        pixels[6 * 16 + 6] = eyeColor

        // 右眼
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor
        pixels[6 * 16 + 9] = eyeColor
        pixels[6 * 16 + 10] = eyeColor

        // 嘴巴 (点)
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor

        return pixels
    }
}

enum HappyExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼 (笑眼 - 弧形)
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor

        // 右眼
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor

        // 嘴巴 (微笑)
        pixels[8 * 16 + 6] = eyeColor
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor
        pixels[8 * 16 + 9] = eyeColor
        pixels[9 * 16 + 5] = eyeColor
        pixels[9 * 16 + 10] = eyeColor

        return pixels
    }
}

enum SadExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor
        pixels[6 * 16 + 5] = eyeColor
        pixels[6 * 16 + 6] = eyeColor

        // 右眼
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor
        pixels[6 * 16 + 9] = eyeColor
        pixels[6 * 16 + 10] = eyeColor

        // 泪滴
        pixels[7 * 16 + 4] = Color.blue
        pixels[7 * 16 + 11] = Color.blue

        // 嘴巴 (悲伤)
        pixels[9 * 16 + 6] = eyeColor
        pixels[9 * 16 + 7] = eyeColor
        pixels[9 * 16 + 8] = eyeColor
        pixels[9 * 16 + 9] = eyeColor
        pixels[8 * 16 + 5] = eyeColor
        pixels[8 * 16 + 10] = eyeColor

        return pixels
    }
}

enum ExcitedExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼 (星星眼 - 简化为亮点)
        pixels[5 * 16 + 5] = Color.yellow
        pixels[5 * 16 + 6] = eyeColor
        pixels[6 * 16 + 5] = eyeColor
        pixels[6 * 16 + 6] = Color.yellow

        // 右眼
        pixels[5 * 16 + 9] = Color.yellow
        pixels[5 * 16 + 10] = eyeColor
        pixels[6 * 16 + 9] = eyeColor
        pixels[6 * 16 + 10] = Color.yellow

        // 嘴巴 (大张)
        pixels[8 * 16 + 5] = eyeColor
        pixels[8 * 16 + 6] = eyeColor
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor
        pixels[8 * 16 + 9] = eyeColor
        pixels[8 * 16 + 10] = eyeColor
        pixels[8 * 16 + 11] = eyeColor

        // 兴奋红晕
        pixels[4 * 16 + 3] = Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.5)
        pixels[4 * 16 + 12] = Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.5)

        return pixels
    }
}

enum SickExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼 (小)
        pixels[5 * 16 + 5] = eyeColor
        pixels[6 * 16 + 5] = eyeColor

        // 右眼 (小)
        pixels[5 * 16 + 10] = eyeColor
        pixels[6 * 16 + 10] = eyeColor

        // 发汗 (汗滴)
        pixels[3 * 16 + 3] = Color.blue.opacity(0.7)
        pixels[4 * 16 + 2] = Color.blue.opacity(0.7)

        // 嘴巴 (波浪)
        pixels[8 * 16 + 6] = eyeColor
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor
        pixels[8 * 16 + 9] = eyeColor

        // 脸色发青
        pixels[4 * 16 + 6] = Color.green.opacity(0.2)
        pixels[4 * 16 + 7] = Color.green.opacity(0.2)
        pixels[4 * 16 + 8] = Color.green.opacity(0.2)
        pixels[4 * 16 + 9] = Color.green.opacity(0.2)

        return pixels
    }
}

enum HungryExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼 (大)
        pixels[4 * 16 + 5] = eyeColor
        pixels[4 * 16 + 6] = eyeColor
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor
        pixels[6 * 16 + 5] = eyeColor
        pixels[6 * 16 + 6] = eyeColor

        // 右眼
        pixels[4 * 16 + 9] = eyeColor
        pixels[4 * 16 + 10] = eyeColor
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor
        pixels[6 * 16 + 9] = eyeColor
        pixels[6 * 16 + 10] = eyeColor

        // 嘴巴 (张嘴)
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor
        pixels[9 * 16 + 6] = eyeColor
        pixels[9 * 16 + 7] = Color(red: 0.8, green: 0.6, blue: 0.4)
        pixels[9 * 16 + 8] = Color(red: 0.8, green: 0.6, blue: 0.4)
        pixels[9 * 16 + 9] = eyeColor

        // 流口水
        pixels[10 * 16 + 7] = Color.blue.opacity(0.6)
        pixels[10 * 16 + 8] = Color.blue.opacity(0.6)

        return pixels
    }
}

enum SleepyExpression {
    static func getPixels() -> [Color] {
        var pixels = Array(repeating: Color.clear, count: 256)
        let eyeColor = Color.black

        // 左眼 (闭眼 - 横线)
        pixels[5 * 16 + 5] = eyeColor
        pixels[5 * 16 + 6] = eyeColor

        // 右眼
        pixels[5 * 16 + 9] = eyeColor
        pixels[5 * 16 + 10] = eyeColor

        // 嘴巴 (小圆)
        pixels[8 * 16 + 7] = eyeColor
        pixels[8 * 16 + 8] = eyeColor

        // 呼噜气泡
        pixels[2 * 16 + 12] = Color.blue.opacity(0.4)
        pixels[1 * 16 + 13] = Color.blue.opacity(0.3)

        // Zzz (简单表示)
        pixels[0 * 16 + 14] = Color.gray

        return pixels
    }
}

// MARK: - 预览
#Preview("像素风格宠物") {
    VStack(spacing: 30) {
        // 不同宠物类型
        VStack(spacing: 10) {
            Text("可爱像素宠物")
                .font(.headline)
            HStack(spacing: 20) {
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child, isBlinking: false)
                PixelPetAvatarView(petType: .dog, mood: .normal, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .rabbit, mood: .excited, evolutionStage: .teen, isBlinking: false)
                PixelPetAvatarView(petType: .bird, mood: .happy, evolutionStage: .child, isBlinking: false)
                PixelPetAvatarView(petType: .hamster, mood: .normal, evolutionStage: .baby, isBlinking: false)
            }
        }

        // 不同心情
        VStack(spacing: 10) {
            Text("不同心情")
                .font(.headline)
            HStack(spacing: 15) {
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .sad, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .sick, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .excited, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .hungry, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .sleepy, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .normal, evolutionStage: .adult, isBlinking: false)
            }
        }

        // 进化阶段
        VStack(spacing: 10) {
            Text("进化阶段")
                .font(.headline)
            HStack(spacing: 12) {
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .egg, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .baby, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .child, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .adult, isBlinking: false)
                PixelPetAvatarView(petType: .cat, mood: .happy, evolutionStage: .legendary, isBlinking: false)
            }
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
