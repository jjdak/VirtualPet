//
//  StatItem.swift
//  VirtualPet
//
//  统计项视图组件（与 StatusItem 不同，用于快速统计区域）
//

import SwiftUI

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}
