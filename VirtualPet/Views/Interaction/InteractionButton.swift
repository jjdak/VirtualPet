//
//  InteractionButton.swift
//  VirtualPet
//
//  交互按钮组件
//  显示单个互动按钮，包含图标和标题
//

import SwiftUI

struct InteractionButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
