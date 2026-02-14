//
//  DeathView.swift
//  VirtualPet
//
//  宠物死亡视图组件
//  当宠物死亡时显示的界面
//

import SwiftUI

struct DeathView: View {
    @ObservedObject var pet: Pet
    let onRebirth: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("🪦")
                .font(.system(size: 80))
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.gray, .black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                )
                .scaleEffect(1.2)

            Text("宠物离开了...")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("它在你的照顾下度过了快乐的一生")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("等级: \(pet.level)")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Text("存活时间: \(pet.age) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("传奇宠物: \(pet.legendaryCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRebirth) {
                Label("迎接新生命", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .background(
                        Capsule()
                            .fill(.blue)
                    )
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), .black.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
    }
}
