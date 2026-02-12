//
//  StatusGridView.swift
//  VirtualPet
//
//  状态网格视图组件
//  以 2x2 网格显示 4 个状态项（饥饿度、快乐度、健康度、能量）
//

import SwiftUI

struct StatusGridView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 15) {
            Text("宠物状态")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                // 饥饿度
                StatusItem(
                    title: "饥饿度",
                    value: "\(pet.hunger)",
                    color: .orange,
                    icon: "flame.fill",
                    isCritical: pet.hunger >= 80
                )

                // 快乐度
                StatusItem(
                    title: "快乐度",
                    value: "\(pet.happiness)",
                    color: .blue,
                    icon: "face.smiling.fill",
                    isCritical: pet.happiness < 20
                )

                // 健康
                StatusItem(
                    title: "健康度",
                    value: "\(pet.health)",
                    color: .green,
                    icon: "heart.fill",
                    isCritical: pet.health < 30
                )

                // 能量
                StatusItem(
                    title: "能量",
                    value: "\(pet.energy)",
                    color: .purple,
                    icon: "bolt.fill",
                    isCritical: pet.energy < 20
                )
            }
        }
        .padding()
    }
}
