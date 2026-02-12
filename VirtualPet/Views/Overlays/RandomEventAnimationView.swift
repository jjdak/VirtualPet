//
//  RandomEventAnimationView.swift
//  VirtualPet
//
//  随机事件动画视图组件
//  显示随机发生的游戏事件（如发现物品、天气变化等）
//

import SwiftUI

struct RandomEventAnimationView: View {
    @ObservedObject var pet: Pet
    @State private var showEvent = false
    @State private var eventText = ""
    @State private var eventIcon = ""

    var body: some View {
        if showEvent {
            VStack(spacing: 12) {
                Text(eventIcon)
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(.purple.opacity(0.2))
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 10)

                Text(eventText)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            }
            .frame(maxWidth: 300)
            .padding(40)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                // 模拟随机事件触发
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring()) {
                        showEvent = true
                        eventText = "获得神秘礼物！"
                        eventIcon = "🎁"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.spring()) {
                            showEvent = false
                        }
                    }
                }
            }
        }
    }
}
