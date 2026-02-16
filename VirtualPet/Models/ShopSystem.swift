//
//  ShopSystem.swift
//  VirtualPet
//
//  商店系统
// 食物商店和道具商店
//

import SwiftUI
import Combine

// 商品类型
enum ShopItemType: String, CaseIterable {
    case food = "食物"
    case item = "道具"
    case special = "特殊"

    var icon: String {
        switch self {
        case .food: return "leaf.fill"
        case .item: return "cube.box.fill"
        case .special: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .green
        case .item: return .blue
        case .special: return .purple
        }
    }
}

// 商店商品
struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let type: ShopItemType
    let icon: String
    let color: CodableColor
    let price: Int
    let description: String
    let effect: ItemEffect
    var isLimited: Bool
    var stock: Int?

    var isInStock: Bool {
        !isLimited || (stock ?? 0) > 0
    }
}

// 商品效果
struct ItemEffect: Codable {
    let hungerRestore: Int?
    let happinessRestore: Int?
    let healthRestore: Int?
    let energyRestore: Int?
    let experienceBonus: Double?
    let specialCurrency: Int?

    init(
        hungerRestore: Int? = nil,
        happinessRestore: Int? = nil,
        healthRestore: Int? = nil,
        energyRestore: Int? = nil,
        experienceBonus: Double? = nil,
        specialCurrency: Int? = nil
    ) {
        self.hungerRestore = hungerRestore
        self.happinessRestore = happinessRestore
        self.healthRestore = healthRestore
        self.energyRestore = energyRestore
        self.experienceBonus = experienceBonus
        self.specialCurrency = specialCurrency
    }
}

// 商店管理器
class ShopManager: ObservableObject {
    static let shared = ShopManager()

    @Published var playerCurrency: Int = 0 {
        didSet {
            saveData()
        }
    }

    @Published var foodItems: [ShopItem] = []
    @Published var itemItems: [ShopItem] = []
    @Published var specialItems: [ShopItem] = []

    private init() {
        loadShopItems()
        loadPlayerData()
    }

    // 初始化商店物品
    private func loadShopItems() {
        // 食物商店
        foodItems = [
            ShopItem(
                name: "高级宠物粮",
                type: .food,
                icon: "star.fill",
                color: CodableColor(from: Color.yellow),
                price: 50,
                description: "美味又营养,快乐+25,饥饿-35",
                effect: ItemEffect(
                    hungerRestore: -35,
                    happinessRestore: 25,
                    experienceBonus: 1.2
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "健康食品",
                type: .food,
                icon: "heart.fill",
                color: CodableColor(from: Color.red),
                price: 45,
                description: "增强体质,健康+30",
                effect: ItemEffect(
                    hungerRestore: -15,
                    happinessRestore: nil,
                    healthRestore: 30,
                    energyRestore: nil,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "能量饮料",
                type: .food,
                icon: "bolt.fill",
                color: CodableColor(from: Color.blue),
                price: 40,
                description: "快速恢复,能量+40",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: nil,
                    healthRestore: nil,
                    energyRestore: 40,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "豪华套餐",
                type: .food,
                icon: "crown.fill",
                color: CodableColor(from: Color.purple),
                price: 100,
                description: "全面提升,所有属性+20",
                effect: ItemEffect(
                    hungerRestore: -20,
                    happinessRestore: 20,
                    healthRestore: 20,
                    energyRestore: 20,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: true,
                stock: 5
            )
        ]

        // 道具商店
        itemItems = [
            ShopItem(
                name: "经验药水",
                type: .item,
                icon: "flask.fill",
                color: CodableColor(from: Color.purple),
                price: 80,
                description: "立即获得100经验值",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: nil,
                    healthRestore: nil,
                    energyRestore: nil,
                    experienceBonus: 100.0,
                    specialCurrency: nil
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "快乐糖果",
                type: .item,
                icon: "candy.fill",
                color: CodableColor(from: Color.pink),
                price: 30,
                description: "恢复30点快乐值",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: 30,
                    healthRestore: nil,
                    energyRestore: nil,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "医疗包",
                type: .item,
                icon: "cross.case.fill",
                color: CodableColor(from: Color.red),
                price: 60,
                description: "治疗疾病,恢复50健康",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: nil,
                    healthRestore: 50,
                    energyRestore: nil,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: false,
                stock: nil
            ),
            ShopItem(
                name: "活力饮料",
                type: .item,
                icon: "bolt.circle.fill",
                color: CodableColor(from: Color.orange),
                price: 50,
                description: "恢复全部能量",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: nil,
                    healthRestore: nil,
                    energyRestore: 100,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: true,
                stock: 3
            )
        ]

        // 特殊商品
        specialItems = [
            ShopItem(
                name: "宠物装饰",
                type: .special,
                icon: "sparkles",
                color: CodableColor(from: Color.pink),
                price: 200,
                description: "可爱的装饰品,快乐+50",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: 50,
                    healthRestore: nil,
                    energyRestore: nil,
                    experienceBonus: nil,
                    specialCurrency: nil
                ),
                isLimited: true,
                stock: 10
            ),
            ShopItem(
                name: "技能书",
                type: .special,
                icon: "book.fill",
                color: CodableColor(from: Color.indigo),
                price: 150,
                description: "获得1个技能点",
                effect: ItemEffect(
                    hungerRestore: nil,
                    happinessRestore: nil,
                    healthRestore: nil,
                    energyRestore: nil,
                    experienceBonus: nil,
                    specialCurrency: 1
                ),
                isLimited: false,
                stock: nil
            )
        ]
    }

    // 购买物品
    func purchaseItem(_ item: ShopItem) -> Bool {
        guard playerCurrency >= item.price else {
            return false
        }

        guard item.isInStock else {
            return false
        }

        // 扣除货币
        playerCurrency -= item.price

        // 更新库存(如果是限量的)
        if let index = itemItems.firstIndex(where: { $0.id == item.id }) {
            if itemItems[index].isLimited {
                itemItems[index].stock = max(0, (itemItems[index].stock ?? 1) - 1)
            }
        }

        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
            if foodItems[index].isLimited {
                foodItems[index].stock = max(0, (foodItems[index].stock ?? 1) - 1)
            }
        }

        if let index = specialItems.firstIndex(where: { $0.id == item.id }) {
            if specialItems[index].isLimited {
                specialItems[index].stock = max(0, (specialItems[index].stock ?? 1) - 1)
            }
        }

        saveData()
        return true
    }

    // 使用物品
    func useItem(_ item: ShopItem, pet: Pet) -> Bool {
        // 应用物品效果到宠物
        if let hungerRestore = item.effect.hungerRestore {
            pet.hunger = max(0, min(100, pet.hunger + hungerRestore))
        }

        if let happinessRestore = item.effect.happinessRestore {
            pet.happiness = min(100, pet.happiness + happinessRestore)
        }

        if let healthRestore = item.effect.healthRestore {
            pet.health = min(100, pet.health + healthRestore)
        }

        if let energyRestore = item.effect.energyRestore {
            pet.energy = min(100, pet.energy + energyRestore)
        }

        if let expBonus = item.effect.experienceBonus {
            pet.experience += Int(Double(expBonus))
        }

        if let specialCurrency = item.effect.specialCurrency {
            pet.specialCurrency += specialCurrency
        }

        // 记录活动
        pet.logActivity(
            Activity(
                title: "使用\(item.type.rawValue): \(item.name)",
                icon: item.icon,
                color: CodableColor(from: Color(red: item.color.red/255, green: item.color.green/255, blue: item.color.blue/255)),
                date: Date(),
                value: item.price
            )
        )

        return true
    }

    // 保存数据
    private func saveData() {
        let defaults = UserDefaults.standard

        defaults.set(playerCurrency, forKey: "shop_currency")

        // 保存库存数据
        var foodStock: [String: Int] = [:]
        for (index, item) in foodItems.enumerated() {
            if item.isLimited, let stock = item.stock {
                foodStock["food_\(index)"] = stock
            }
        }
        defaults.set(foodStock as NSDictionary, forKey: "shop_foodStock")

        var itemStock: [String: Int] = [:]
        for (index, item) in itemItems.enumerated() {
            if item.isLimited, let stock = item.stock {
                itemStock["item_\(index)"] = stock
            }
        }
        defaults.set(itemStock as NSDictionary, forKey: "shop_itemStock")

        var specialStock: [String: Int] = [:]
        for (index, item) in specialItems.enumerated() {
            if item.isLimited, let stock = item.stock {
                specialStock["special_\(index)"] = stock
            }
        }
        defaults.set(specialStock as NSDictionary, forKey: "shop_specialStock")
    }

    // 加载玩家数据
    private func loadPlayerData() {
        let defaults = UserDefaults.standard
        playerCurrency = defaults.integer(forKey: "shop_currency")

        // 加载库存数据
        if let foodStock = defaults.object(forKey: "shop_foodStock") as? [String: Int] {
            for (key, stock) in foodStock {
                if key.hasPrefix("food_"), let index = Int(key.replacingOccurrences(of: "food_", with: "")), index < foodItems.count {
                    foodItems[index].stock = stock
                }
            }
        }

        if let itemStock = defaults.object(forKey: "shop_itemStock") as? [String: Int] {
            for (key, stock) in itemStock {
                if key.hasPrefix("item_"), let index = Int(key.replacingOccurrences(of: "item_", with: "")), index < itemItems.count {
                    itemItems[index].stock = stock
                }
            }
        }

        if let specialStock = defaults.object(forKey: "shop_specialStock") as? [String: Int] {
            for (key, stock) in specialStock {
                if key.hasPrefix("special_"), let index = Int(key.replacingOccurrences(of: "special_", with: "")), index < specialItems.count {
                    specialItems[index].stock = stock
                }
            }
        }
    }
}

// 商店视图
struct ShopView: View {
    @ObservedObject var shopManager = ShopManager.shared
    @ObservedObject var pet: Pet

    @State private var selectedTab: ShopItemType = .food

    var body: some View {
        VStack(spacing: 20) {
            // 头部
            VStack(spacing: 12) {
                HStack {
                    Text("🛍️ 宠物商店")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    // 货币显示
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.cyan)

                        Text("\(shopManager.playerCurrency)")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.2))
                    )
                }

                // 标签页
                Picker("商店类型", selection: $selectedTab) {
                    ForEach(ShopItemType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 商品列表
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(itemsForSelectedTab) { item in
                        ShopItemCard(
                            item: item,
                            canAfford: shopManager.playerCurrency >= item.price,
                            onPurchase: {
                                purchaseItem(item)
                            },
                            onUse: {
                                useShopItem(item)
                            }
                        )
                    }
                }
            }

            // 底部提示
            Text("提示: 点击购买直接使用,物品效果立即生效")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.background)
                .shadow(radius: 5)
        )
    }

    private var itemsForSelectedTab: [ShopItem] {
        switch selectedTab {
        case .food:
            return shopManager.foodItems
        case .item:
            return shopManager.itemItems
        case .special:
            return shopManager.specialItems
        }
    }

    // 购买物品
    private func purchaseItem(_ item: ShopItem) {
        if shopManager.purchaseItem(item) {
            HapticManager.shared.trigger(.medium)

            // 自动使用物品
            shopManager.useItem(item, pet: pet)

            // 发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: [
                    "text": "-\(item.price) 💎",
                    "color": Color.cyan
                ]
            )
        } else {
            // 货币不足提示
            HapticManager.shared.trigger(.notification)

            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: [
                    "text": "💎 货币不足",
                    "color": Color.red
                ]
            )
        }
    }

    // 使用物品(从商店购买后自动调用)
    private func useShopItem(_ item: ShopItem) {
        if shopManager.useItem(item, pet: pet) {
            // 显示使用效果
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFloatingText"),
                object: nil,
                userInfo: [
                    "text": "✨ 使用\(item.name)",
                    "color": Color.purple
                ]
            )

            // 发送表情
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowEmoji"),
                object: nil,
                userInfo: ["emoji": "✨"]
            )
        }
    }
}

// 商店物品卡片
struct ShopItemCard: View {
    let item: ShopItem
    let canAfford: Bool
    let onPurchase: () -> Void
    let onUse: () -> Void

    var body: some View {
        Button(action: {
            if canAfford {
                onPurchase()
            }
        }) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color(red: item.color.red/255, green: item.color.green/255, blue: item.color.blue/255).opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: item.color.red/255, green: item.color.green/255, blue: item.color.blue/255))
                }

                // 名称
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // 描述
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // 价格
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill")
                        .font(.caption2)
                        .foregroundColor(.cyan)

                    Text("\(item.price)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(canAfford ? .cyan : .red)
                }

                // 库存提示
                if item.isLimited {
                    HStack(spacing: 4) {
                        Image(systemName: "cube.box")
                            .font(.caption2)
                            .foregroundColor(.orange)

                        Text("剩余: \(item.stock ?? 0)")
                            .font(.caption2)
                            .foregroundColor(item.stock ?? 0 > 0 ? .primary : .red)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canAfford ? Color.cyan.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canAfford ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canAfford)
    }
}

// 预览
#Preview {
    ShopView(pet: Pet())
        .padding()
        .background(Color.gray.opacity(0.1))
}
