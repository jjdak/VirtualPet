//
//  BreathAnimationManager.swift
//  VirtualPet
//
//  宠物呼吸动画管理系统
//  Phase 4 - 单机向养成深化 (任务1: 呼吸待机动画)
//

import SwiftUI
import Combine

/// 呼吸动画参数配置
struct BreathAnimationConfig {
    /// 呼吸周期 (秒)
    let duration: Double
    /// 缩放范围 (最小值, 最大值)
    let scaleRange: ClosedRange<Double>
    /// 浮动范围 (最小值, 最大值)
    let verticalOffsetRange: ClosedRange<Double>
    /// 水平摆动范围 (角度)
    let rotationRange: ClosedRange<Double>
    /// 是否有尾巴摆动
    let hasTailWag: Bool
    /// 尾巴摆动速度
    let tailWagSpeed: Double

    /// 默认配置 (猫咪)
    static let `default` = BreathAnimationConfig(
        duration: 2.0,
        scaleRange: 0.95...1.05,
        verticalOffsetRange: -3.0...3.0,
        rotationRange: -1.0...1.0,
        hasTailWag: true,
        tailWagSpeed: 0.8
    )

    /// 活泼型 (狗狗、兔子)
    static let energetic = BreathAnimationConfig(
        duration: 1.5,
        scaleRange: 0.93...1.07,
        verticalOffsetRange: -5.0...5.0,
        rotationRange: -2.0...2.0,
        hasTailWag: true,
        tailWagSpeed: 0.5
    )

    /// 安静型 (仓鼠、小鸟)
    static let calm = BreathAnimationConfig(
        duration: 2.5,
        scaleRange: 0.97...1.03,
        verticalOffsetRange: -2.0...2.0,
        rotationRange: -0.5...0.5,
        hasTailWag: false,
        tailWagSpeed: 1.2
    )

    /// 困倦型 (睡觉状态)
    static let sleepy = BreathAnimationConfig(
        duration: 3.0,
        scaleRange: 0.92...1.08,  // 增大幅度
        verticalOffsetRange: -3.0...3.0,  // 增加浮动
        rotationRange: -1.0...1.0,  // 添加轻微旋转
        hasTailWag: false,
        tailWagSpeed: 2.0
    )

    /// 兴奋型 (兴奋状态)
    static let excited = BreathAnimationConfig(
        duration: 1.0,
        scaleRange: 0.90...1.10,
        verticalOffsetRange: -8.0...8.0,
        rotationRange: -3.0...3.0,
        hasTailWag: true,
        tailWagSpeed: 0.3
    )
}

/// 呼吸动画管理器
class BreathAnimationManager: ObservableObject {
    static let shared = BreathAnimationManager()

    // MARK: - 发布的动画状态

    /// 当前呼吸缩放比例
    @Published var breathScale: Double = 1.0
    /// 当前垂直偏移
    @Published var verticalOffset: Double = 0.0
    /// 当前旋转角度
    @Published var rotationAngle: Double = 0.0
    /// 尾巴摆动角度
    @Published var tailWagAngle: Double = 0.0
    /// 眨眼状态 (true = 闭眼)
    @Published var isBlinking: Bool = false

    // MARK: - 私有状态

    private var animationTimer: Timer?
    private var blinkTimer: Timer?
    private var currentConfig: BreathAnimationConfig = .default
    private var breathPhase: Double = 0.0  // 0.0 到 1.0 表示一个呼吸周期
    private var tailWagPhase: Double = 0.0

    private init() {
        startBreathAnimation()
        startBlinkAnimation()
    }

    // MARK: - 公开方法

    /// 根据宠物类型和心情设置动画配置
    func configureAnimation(petType: String, mood: String) {
        currentConfig = getConfig(petType: petType, mood: mood)
    }

    /// 开始呼吸动画
    func startBreathAnimation() {
        // 停止现有计时器
        stopBreathAnimation()

        // 创建新计时器 (60fps)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateBreathState()
        }
    }

    /// 停止呼吸动画
    func stopBreathAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    /// 开始眨眼动画
    func startBlinkAnimation() {
        stopBlinkAnimation()

        // 随机眨眼间隔 (3-5秒)
        scheduleNextBlink()
    }

    /// 停止眨眼动画
    func stopBlinkAnimation() {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    // MARK: - 私有方法

    private func getConfig(petType: String, mood: String) -> BreathAnimationConfig {
        // 首先根据心情调整
        switch mood {
        case "困倦", "生病":
            return .sleepy
        case "兴奋":
            return .excited
        case "开心":
            return petType == "狗狗" || petType == "兔子" ? .energetic : .default
        case "伤心":
            return BreathAnimationConfig(
                duration: 2.5,
                scaleRange: 0.94...1.04,  // 增大幅度
                verticalOffsetRange: -3.0...0.0,  // 下垂更明显
                rotationRange: -2.0...0.0,  // 增加旋转
                hasTailWag: false,
                tailWagSpeed: 1.5
            )
        default:
            break
        }

        // 然后根据宠物类型调整
        switch petType {
        case "狗狗", "兔子":
            return .energetic
        case "仓鼠", "小鸟":
            return .calm
        case "猫咪":
            return .default
        default:
            return .default
        }
    }

    private func updateBreathState() {
        // 更新呼吸相位
        let phaseIncrement = 1.0 / (currentConfig.duration * 60.0)
        breathPhase = (breathPhase + phaseIncrement).truncatingRemainder(dividingBy: 1.0)

        // 使用正弦波创建平滑的呼吸效果
        let breathValue = sin(breathPhase * 2.0 * .pi)  // -1 到 1

        // 计算缩放 (0.95 到 1.05)
        let normalizedBreath = (breathValue + 1.0) / 2.0  // 0 到 1
        let scaleRange = currentConfig.scaleRange
        breathScale = scaleRange.lowerBound + normalizedBreath * (scaleRange.upperBound - scaleRange.lowerBound)

        // 计算垂直偏移
        let offsetRange = currentConfig.verticalOffsetRange
        verticalOffset = offsetRange.lowerBound + normalizedBreath * (offsetRange.upperBound - offsetRange.lowerBound)

        // 计算旋转角度
        let rotationRange = currentConfig.rotationRange
        rotationAngle = rotationRange.lowerBound + normalizedBreath * (rotationRange.upperBound - rotationRange.lowerBound)

        // 更新尾巴摆动
        if currentConfig.hasTailWag {
            updateTailWag()
        }
    }

    private func updateTailWag() {
        let tailIncrement = 1.0 / (currentConfig.tailWagSpeed * 60.0)
        tailWagPhase = (tailWagPhase + tailIncrement).truncatingRemainder(dividingBy: 1.0)

        // 尾巴摆动使用更快的频率
        let tailValue = sin(tailWagPhase * 2.0 * .pi * 2)  // 两倍频率
        tailWagAngle = tailValue * 15.0  // ±15度
    }

    private func scheduleNextBlink() {
        // 随机间隔 3-5 秒
        let randomInterval = TimeInterval.random(in: 3.0...5.0)

        blinkTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { [weak self] _ in
            self?.performBlink()
        }
    }

    private func performBlink() {
        // 闭眼
        withAnimation(.easeInOut(duration: 0.1)) {
            isBlinking = true
        }

        // 睁眼
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isBlinking = false
            }
        }

        // 安排下一次眨眼
        scheduleNextBlink()
    }

    deinit {
        stopBreathAnimation()
        stopBlinkAnimation()
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// 应用呼吸动画效果
    func breathAnimation(
        scale: Double,
        offset: Double,
        rotation: Double
    ) -> some View {
        self
            .scaleEffect(scale)
            .offset(y: offset)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - 预览辅助

#if DEBUG
struct BreathAnimationPreview: View {
    @StateObject private var animator = BreathAnimationManager.shared

    var body: some View {
        VStack(spacing: 30) {
            Text("🐱")
                .font(.system(size: 80))
                .breathAnimation(
                    scale: animator.breathScale,
                    offset: animator.verticalOffset,
                    rotation: animator.rotationAngle
                )

            VStack(spacing: 10) {
                Text("呼吸缩放: \(animator.breathScale, specifier: "%.2f")")
                Text("垂直偏移: \(animator.verticalOffset, specifier: "%.1f")")
                Text("旋转角度: \(animator.rotationAngle, specifier: "%.1f")°")
                Text("眨眼状态: \(animator.isBlinking ? "闭眼" : "睁眼")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .onAppear {
            animator.configureAnimation(petType: "猫咪", mood: "开心")
        }
    }
}
#endif
