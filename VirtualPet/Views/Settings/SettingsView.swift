//
//  SettingsView.swift
//  VirtualPet
//
//  设置页面 - 音效、震动、自动存档等配置
//  Phase 1, Task 1.5
//

import SwiftUI
#if os(iOS)
import UserNotifications
import UIKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("soundVolume") private var soundVolume: Double = 0.7
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval: Double = 300
    @AppStorage("notificationEnabled") private var notificationEnabled = false

    private let saveIntervals: [Double] = [60, 180, 300, 600] // 秒
    private let saveIntervalLabels: [String] = ["1分钟", "3分钟", "5分钟", "10分钟"]

    var body: some View {
        NavigationView {
            List {
                // 音效设置
                Section {
                    Toggle("音效", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _ in
                            if soundEnabled {
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            }
                        }

                    if soundEnabled {
                        HStack {
                            Text("音量")
                            Spacer()
                            Text("\(Int(soundVolume * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $soundVolume, in: 0...1, step: 0.1)
                            .onChange(of: soundVolume) { _ in
                                playTestSound()
                            }
                    }
                } header: {
                    Text("音效设置")
                }

                // 震动反馈
                Section {
                    Toggle("震动反馈", isOn: $hapticFeedbackEnabled)
                        .onChange(of: hapticFeedbackEnabled) { _ in
                            if hapticFeedbackEnabled {
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            }
                        }

                    if hapticFeedbackEnabled {
                        Button("测试震动") {
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            #endif
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("反馈设置")
                }

                // 自动存档
                Section {
                    Picker("自动存档频率", selection: $autoSaveInterval) {
                        ForEach(0..<saveIntervals.count, id: \.self) { index in
                            Text(saveIntervalLabels[index])
                                .tag(saveIntervals[index])
                        }
                    }
                    .onChange(of: autoSaveInterval) { _ in
                        // 更新自动存档定时器
                        NotificationCenter.default.post(
                            name: Notification.Name("AutoSaveIntervalChanged"),
                            object: autoSaveInterval
                        )
                    }

                    HStack {
                        Text("下次自动存档")
                        Spacer()
                        Text(getNextAutoSaveTime())
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("存档设置")
                } footer: {
                    Text("游戏会自动保存，确保不会丢失进度")
                }

                // 通知设置
                Section {
                    Toggle("推送通知", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }

                    if notificationEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("通知类型")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.blue)
                                Text("宠物状态提醒")
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.orange)
                                Text("每日任务提醒")
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("特殊事件通知")
                                Spacer()
                            }
                        }
                        .font(.caption)
                    }
                } header: {
                    Text("通知设置")
                } footer: {
                    Text("开启后会在重要事件时推送通知")
                }

                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("v0.6.0-alpha")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/jjdak/VirtualPet")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("查看 GitHub 仓库")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.blue)
                    }

                    Button("清除缓存") {
                        clearCache()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 辅助方法

    private func playTestSound() {
        guard soundEnabled else { return }
        // 这里可以播放测试音效
        // 暂时使用震动反馈模拟
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func requestNotificationPermission() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已授予")
            } else {
                print("通知权限被拒绝")
                DispatchQueue.main.async {
                    notificationEnabled = false
                }
            }
        }
        #endif
    }

    private func getNextAutoSaveTime() -> String {
        let interval = Int(autoSaveInterval)
        let now = Date()
        let nextSave = Calendar.current.date(byAdding: .second, value: interval, to: now) ?? now

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: nextSave, relativeTo: now)
    }

    private func clearCache() {
        // 清除缓存逻辑
        UserDefaults.standard.synchronize()
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

#Preview {
    SettingsView()
}
