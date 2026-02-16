//
//  FoodSelectionView.swift
//  VirtualPet
//
//  食物选择界面
//  提供不同类型食物的选择,每种食物有不同的效果
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Theme colors
struct Theme {
    static var background: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

struct FoodSelectionView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool
    @State private var selectedFood: FoodType?
    @State private var showCriticalEffect = false

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // 食物选择卡片
            VStack(spacing: 20) {
                Text("选择食物")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(FoodType.allCases, id: \.self) { food in
                        FoodCard(
                            food: food,
                            isFavorite: food == pet.favoriteFood,
                            action: {
                                selectedFood = food
                                feedPet(food: food)
                            }
                        )
                    }
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.background)
                    .shadow(radius: 20)
            )
            .padding(40)

            // 暴击效果
            if showCriticalEffect {
                CriticalHitOverlay()
            }
        }
    }

    // 喂食逻辑
    private func feedPet(food: FoodType) {
        // 基础营养值
        var nutritionValue = food.nutritionValue
        var experienceBonus = food.experienceBonus

        // 检查是否是喜爱食物
        let isFavorite = food == pet.favoriteFood
        if isFavorite {
            nutritionValue = Int(Double(nutritionValue) * 1.5) // 1.5倍效果
            experienceBonus = Int(Double(experienceBonus) * 2.0) // 2倍经验
        }

        // 检查暴击 (10% 概率)
        let isCriticalHit = Double.random(in: 0...1) < 0.1
        if isCriticalHit {
            nutritionValue = Int(Double(nutritionValue) * 2.0)
            experienceBonus = Int(Double(experienceBonus) * 2.0)
            showCriticalEffect = true

            // 发送暴击通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: ["text": "🎯 美食暴击！", "color": Color.orange]
            )

            HapticManager.shared.trigger(.heavy)
        }

        // 应用效果
        pet.hunger = max(0, pet.hunger - nutritionValue)
        pet.happiness = min(100, pet.happiness + (isFavorite ? 10 : 5))
        pet.experience += experienceBonus
        pet.feedCount += 1
        pet.lastFed = Date()

        // 记录活动
        let favoriteText = isFavorite ? " ❤️" : ""
        let criticalText = isCriticalHit ? " ✨" : ""
        pet.logActivity(
            Activity(
                title: "\(food.rawValue)\(favoriteText)\(criticalText)",
                icon: food.icon,
                color: CodableColor(from: isCriticalHit ? .orange : food.color),
                date: Date(),
                value: nutritionValue
            )
        )

        // 连击系统
        ComboSystem.shared.incrementCombo()

        // 发送飘字通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFloatingText"),
            object: nil,
            userInfo: [
                "text": "+\(nutritionValue) 饱腹↓",
                "color": isCriticalHit ? Color.orange : Color.green
            ]
        )

        // 发送表情通知
        let emojis = ["😋", "😊", "🤤", "😄"]
        let randomEmoji = emojis.randomElement() ?? "😋"
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEmoji"),
            object: nil,
            userInfo: ["emoji": randomEmoji]
        )

        // 震动反馈
        HapticManager.shared.trigger(.medium)

        // 延迟关闭界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// 食物卡片组件
struct FoodCard: View {
    let food: FoodType
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(food.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: food.icon)
                        .font(.system(size: 24))
                        .foregroundColor(food.color)

                    // 喜爱标记
                    if isFavorite {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }

                Text(food.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 8))
                        Text("×\(food.nutritionValue)")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("+\(food.experienceBonus)XP")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFavorite ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFavorite ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 暴击特效组件
struct CriticalHitOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)

            Text("暴击！")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.5
                rotation = 15
            }

            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
        }
    }
}

// Color extension for FoodType
extension FoodType {
    var color: Color {
        switch self {
        case .regular: return .green
        case .delicious: return .orange
        case .healthy: return .blue
        case .premium: return .purple
        case .special: return .pink
        }
    }
}

// 预览
#Preview {
    FoodSelectionView(
        pet: Pet(),
        isPresented: .constant(true)
    )
}
