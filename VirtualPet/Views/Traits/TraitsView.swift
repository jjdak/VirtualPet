//
//  TraitsView.swift
//  VirtualPet
//
//  宠物特质系统视图组件
//  显示已解锁的特质卡片列表
//

import SwiftUI
import SwiftUI
import VirtualPet

struct TraitsView: View {
    let traits: [Trait]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("已解锁特质")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(traits, id: \.self) { trait in
                            TraitCard(trait: trait)
                        }
                    }
                }

                Button("关闭") {
                    dismiss()
                }
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

struct TraitCard: View {
    let trait: Trait

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(trait.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(trait.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("等级 \(trait.level)")
                        .font(.title2)
                        .foregroundColor(trait.color)

                    if trait.unlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(trait.color.opacity(0.1))
                    .shadow(color: trait.color.opacity(0.3), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(trait.color, lineWidth: 1)
            )
    }
}
