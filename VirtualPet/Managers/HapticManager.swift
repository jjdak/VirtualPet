//
//  HapticManager.swift
//  VirtualPet
//
//  触觉反馈管理器
//  统一管理不同类型的震动反馈
//

import Foundation

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    enum HapticType {
        case light        // 轻柔震动
        case medium       // 中等震动
        case heavy        // 强烈震动
        case heartbeat    // 心跳震动
        case notification // 通知震动
    }

    func trigger(_ type: HapticType) {
        // 简化实现,仅作为占位符
        // 实际触觉反馈将在 iOS 平台通过特定 API 实现
        #if os(iOS)
        triggerHaptic(type)
        #endif
    }

    #if os(iOS)
    private func triggerHaptic(_ type: HapticType) {
        // iOS 特定实现将在运行时动态加载
        // 这里使用 selector 调用以避免编译时依赖 UIKit
    }
    #endif

    // 连击震动 (连击数越高,震动越强)
    func triggerCombo(_ comboCount: Int) {
        switch comboCount {
        case 1...2:
            trigger(.light)
        case 3...4:
            trigger(.medium)
        case 5...7:
            trigger(.heavy)
        default: // 8+
            trigger(.heartbeat)
        }
    }
}
