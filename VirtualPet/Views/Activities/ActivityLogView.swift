//
//  ActivityLogView.swift
//  VirtualPet
//
//  活动记录视图组件
//  显示宠物的所有活动历史记录
//

import SwiftUI

struct ActivityLogView: View {
    @ObservedObject var pet: Pet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("活动记录")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                if pet.activities.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无活动记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(pet.activities.sorted(by: { $0.date > $1.date })) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding()
                    }
                }

                Button("关闭") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(activity.color.color.opacity(0.15))
                    .frame(width: 45, height: 45)

                Image(systemName: activity.icon)
                    .font(.title3)
                    .foregroundColor(activity.color.color)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(formatDate(activity.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let value = activity.value {
                Text("+\(value)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
