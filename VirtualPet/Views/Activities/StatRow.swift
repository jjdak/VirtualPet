//
//  StatRow.swift
//  VirtualPet
//
//  统计行视图组件
//  水平排列多个统计项
//

import SwiftUI

struct StatRow: View {
    let title: String
    let values: [Any]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                ForEach(0..<values.count, id: \.self) { index in
                    if let value = values[index] as? CustomStringConvertible {
                        Text(value.description)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
    }
}
