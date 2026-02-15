//
//  FloatingTextView.swift
//  VirtualPet
//
//  数值飘字动画组件
//  用于显示互动时的数值变化 (如 +25 饥饿↓)
//

import SwiftUI

struct FloatingTextView: View {
    let text: String
    let color: Color
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 2)
            .offset(y: offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    offset = -60
                    opacity = 0
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.3
                }
            }
    }
}

// 预览
#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        FloatingTextView(
            text: "+25 饥饿↓",
            color: .orange
        )
    }
}
