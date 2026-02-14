//
//  TraitsView.swift
//  VirtualPet
//
//  宠物特质系统视图组件
//  显示已解锁的特质卡片列表
//

import SwiftUI

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
                    .padding()
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

struct TraitCard: View {
    let trait: Trait

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: trait.icon)
                    .font(.title2)
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(trait.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(trait.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}
