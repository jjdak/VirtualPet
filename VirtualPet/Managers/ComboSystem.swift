//
//  ComboSystem.swift
//  VirtualPet
//
//  连击系统
//  追踪连续互动并提供倍率奖励
//

import SwiftUI
import Combine

class ComboSystem: ObservableObject {
    static let shared = ComboSystem()

    @Published var currentCombo: Int = 0
    @Published var maxCombo: Int = 0
    @Published var showCombo: Bool = false

    private var comboTimer: Timer?
    private let comboTimeout: TimeInterval = 3.0 // 3秒无操作重置

    private init() {
        // 私有初始化,确保单例
    }

    // 增加连击
    func incrementCombo() {
        currentCombo += 1
        maxCombo = max(maxCombo, currentCombo)
        showCombo = true

        // 触发震动反馈
        HapticManager.shared.triggerCombo(currentCombo)

        // 重置定时器
        comboTimer?.invalidate()
        comboTimer = Timer.scheduledTimer(
            withTimeInterval: comboTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.resetCombo()
        }

        // 每5连击显示特殊提示
        if currentCombo % 5 == 0 {
            notifyComboMilestone(currentCombo)
        }
    }

    // 重置连击
    func resetCombo() {
        currentCombo = 0
        showCombo = false
        comboTimer?.invalidate()
    }

    // 获取连击倍率
    var comboMultiplier: Float {
        return 1.0 + (Float(currentCombo) * 0.1) // 每连击+10%
    }

    // 连击里程碑通知
    private func notifyComboMilestone(_ combo: Int) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ComboMilestone"),
            object: combo
        )
    }
}

// 连击显示视图组件
struct ComboIndicator: View {
    @ObservedObject var comboSystem = ComboSystem.shared

    var body: some View {
        Group {
            if comboSystem.showCombo && comboSystem.currentCombo > 1 {
                VStack(spacing: 4) {
                    Text("\(comboSystem.currentCombo)x")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 10)

                    Text("COMBO!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.7))
                )
                .transition(.opacity)
            }
        }
    }
}

// 预览
#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        ComboIndicator()
    }
}
