//
//  StatusItem.swift
//  VirtualPet
//
//  状态单项视图组件
//  显示单个状态条（饥饿度、快乐度、健康度、能量）
//

import SwiftUI

struct StatusItem: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    let isCritical: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))

            Text("\(value)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isCritical ? .red : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
