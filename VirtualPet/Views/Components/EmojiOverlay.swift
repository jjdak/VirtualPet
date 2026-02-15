//
//  EmojiOverlay.swift
//  VirtualPet
//
//  表情浮层组件
//  用于显示互动时的表情反馈 (如 😋😊🤤)
//

import SwiftUI

struct EmojiOverlay: View {
    let emoji: String
    @Binding var show: Bool
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(emoji)
            .font(.system(size: 80))
            .scaleEffect(scale)
            .opacity(show ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: show)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: scale)
            .onChange(of: show) { oldValue, newValue in
                if newValue {
                    // 显示时放大
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.5
                    }
                } else {
                    // 隐藏时缩小
                    withAnimation {
                        scale = 0.5
                    }
                }
            }
    }
}

// 预览
#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        EmojiOverlay(
            emoji: "😋",
            show: .constant(true)
        )
    }
}
