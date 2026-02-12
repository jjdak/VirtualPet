//
//  ActivityLogView.swift
//  VirtualPet
//
//  活动日志视图组件
//  显示宠物最近的互动记录，支持滚动查看
//

import SwiftUI

struct ActivityLogView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 0) {
            Text("活动记录")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(pet.activities.reversed(), id: \.id) { activity in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(activity.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                if let value = activity.value {
                                    Text(value.description)
                                        .font(.caption)
                                        .foregroundColor(activity.color.toColor())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(activity.color.toColor().opacity(0.15))
                                .shadow(color: activity.color.toColor().opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                }
            }
        }
        .padding()
    }
}

extension Color {
    func toColor() -> Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        default: return .primary
    }
}