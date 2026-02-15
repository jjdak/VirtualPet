//
//  AudioManager.swift
//  VirtualPet
//
//  音效管理器 - 统一管理游戏音效
//  Phase 1, Task 1.4 - 基础框架
//

import AVFoundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// 音效管理器单例
class AudioManager {
    static let shared = AudioManager()

    // 音效播放器池
    private var soundPlayers: [String: AVAudioPlayer] = [:]

    // 背景音乐播放器
    private var backgroundMusicPlayer: AVAudioPlayer?

    // 设置
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("soundVolume") var soundVolume: Double = 0.7

    private init() {
        setupAudioSession()
    }

    // MARK: - 音频会话设置
    private func setupAudioSession() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default
            )
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - 音效播放
    /// 播放音效
    func playSound(_ soundName: SoundName) {
        guard soundEnabled else { return }

        // 使用震动反馈模拟音效（临时方案）
        #if os(iOS)
        switch soundName {
        case .feed:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .play:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .clean:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .exercise:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .cuddle:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .levelUp:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .achievement:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        default:
            break
        }
        #endif

        // TODO: 实际音效播放
        // playActualSound(soundName)
    }

    /// 播放实际音效文件（未来实现）
    private func playActualSound(_ soundName: SoundName) {
        // 未来的音效播放实现
        // 1. 准备音效文件
        // 2. 创建 AVAudioPlayer
        // 3. 设置音量
        // 4. 播放音效
    }

    // MARK: - 背景音乐
    /// 播放背景音乐
    func playBackgroundMusic() {
        // TODO: 实现背景音乐播放
        // 1. 准备背景音乐文件
        // 2. 创建播放器
        // 3. 设置循环播放
        // 4. 淡入淡出
    }

    /// 停止背景音乐
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }

    // MARK: - 音量控制
    /// 设置音量
    func setVolume(_ volume: Double) {
        soundVolume = volume
        backgroundMusicPlayer?.volume = Float(volume)
    }
}

// MARK: - 音效名称枚举
enum SoundName: String {
    // 互动音效
    case feed = "feed"
    case play = "play"
    case clean = "clean"
    case exercise = "exercise"
    case cuddle = "cuddle"

    // 特殊音效
    case levelUp = "level_up"
    case achievement = "achievement"
    case evolution = "evolution"

    // 状态音效
    case hungry = "hungry"
    case sick = "sick"
    case happy = "happy"
    case sad = "sad"
}

// MARK: - 音效资源管理
extension AudioManager {
    /// 获取音效文件名
    private func getSoundFileName(_ soundName: SoundName) -> String {
        return soundName.rawValue
    }

    /// 预加载音效（未来优化）
    func preloadSounds() {
        // TODO: 预加载常用音效到内存
        // 可以使用 AVAssetResourceLoader
    }
}

// MARK: - 音效播放辅助
extension AudioManager {
    /// 测试音效
    func testSound() {
        playSound(.feed)
    }
}
