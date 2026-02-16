//
//  SocialSystem.swift
//  VirtualPet
//
//  社交系统
//  好友管理、访问、互动
//

import SwiftUI
import Combine

// 好友数据
struct Friend: Identifiable, Codable {
    let id: UUID
    let name: String
    let petTypeString: String
    let petLevel: Int
    let lastVisit: Date?
    var intimacy: Int // 亲密度 0-100

    var displayName: String {
        name.isEmpty ? "匿名玩家" : name
    }

    var petType: PetType {
        PetType(rawValue: petTypeString) ?? .cat
    }

    var petEmoji: String {
        petType.rawValue
    }

    // 自定义编码以处理PetType
    enum CodingKeys: String, CodingKey {
        case id, name, petTypeString, petLevel, lastVisit, intimacy
    }

    init(id: UUID, name: String, petType: PetType, petLevel: Int, lastVisit: Date?, intimacy: Int) {
        self.id = id
        self.name = name
        self.petTypeString = petType.rawValue
        self.petLevel = petLevel
        self.lastVisit = lastVisit
        self.intimacy = intimacy
    }
}

// 社交互动类型
enum SocialInteractionType: String, CaseIterable {
    case visit = "访问"
    case gift = "送礼"
    case play = "玩耍"
    case message = "留言"

    var icon: String {
        switch self {
        case .visit: return "house.fill"
        case .gift: return "gift.fill"
        case .play: return "gamecontroller.fill"
        case .message: return "message.fill"
        }
    }

    var color: Color {
        switch self {
        case .visit: return .blue
        case .gift: return .pink
        case .play: return .green
        case .message: return .purple
        }
    }

    var description: String {
        switch self {
        case .visit: return "访问好友的宠物"
        case .gift: return "赠送礼物增加亲密度"
        case .play: return "与好友宠物玩耍"
        case .message: return "给好友留言"
        }
    }
}

// 好友管理器
class SocialManager: ObservableObject {
    static let shared = SocialManager()

    @Published var friends: [Friend] = []
    @Published var friendRequests: [Friend] = [] // 待处理的好友请求
    @Published var receivedGifts: [String: Int] = [:] // 收到的礼物 [friendId: amount]

    private init() {
        loadFriends()
    }

    // MARK: - 好友管理

    // 添加好友
    func addFriend(name: String, petType: PetType, petLevel: Int) -> Friend {
        let friend = Friend(
            id: UUID(),
            name: name,
            petType: petType,
            petLevel: petLevel,
            lastVisit: nil as Date?,
            intimacy: 0
        )

        friends.append(friend)
        saveFriends()

        return friend
    }

    // 删除好友
    func removeFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        saveFriends()
    }

    // 更新好友信息
    func updateFriend(_ friend: Friend) {
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index] = friend
            saveFriends()
        }
    }

    // 增加亲密度
    func increaseIntimacy(for friend: Friend, by amount: Int) {
        guard let index = friends.firstIndex(where: { $0.id == friend.id }) else { return }

        var updatedFriend = friend
        updatedFriend.intimacy = min(100, updatedFriend.intimacy + amount)
        friends[index] = updatedFriend
        saveFriends()
    }

    // 更新访问时间
    func updateLastVisit(for friend: Friend) {
        guard let index = friends.firstIndex(where: { $0.id == friend.id }) else { return }

        var updatedFriend = friend
        updatedFriend = Friend(
            id: friend.id,
            name: friend.name,
            petType: friend.petType,
            petLevel: friend.petLevel,
            lastVisit: Date(),
            intimacy: friend.intimacy
        )
        friends[index] = updatedFriend
        saveFriends()
    }

    // MARK: - 好友请求

    // 发送好友请求
    func sendFriendRequest(to name: String, petType: PetType, petLevel: Int) {
        let request = Friend(
            id: UUID(),
            name: name,
            petType: petType,
            petLevel: petLevel,
            lastVisit: nil as Date?,
            intimacy: 0
        )

        friendRequests.append(request)
        saveFriends()
    }

    // 接受好友请求
    func acceptFriendRequest(_ request: Friend) {
        friendRequests.removeAll { $0.id == request.id }
        friends.append(request)
        saveFriends()
    }

    // 拒绝好友请求
    func rejectFriendRequest(_ request: Friend) {
        friendRequests.removeAll { $0.id == request.id }
        saveFriends()
    }

    // MARK: - 社交互动

    // 访问好友
    func visitFriend(_ friend: Friend) -> Bool {
        // 检查是否可以访问 (简单的冷却时间: 1小时)
        if let lastVisit = friend.lastVisit,
           Date().timeIntervalSince(lastVisit) < 3600 {
            return false
        }

        updateLastVisit(for: friend)
        increaseIntimacy(for: friend, by: 5)

        return true
    }

    // 赠送礼物
    func sendGift(to friend: Friend, amount: Int = 10) -> Bool {
        // 检查是否有足够的货币
        let currency = ShopManager.shared.playerCurrency
        let cost = amount * 2 // 每份礼物花费2钻石

        guard currency >= cost else { return false }

        // 扣除货币
        ShopManager.shared.playerCurrency -= cost

        // 增加亲密度
        increaseIntimacy(for: friend, by: amount)

        return true
    }

    // 接收礼物
    func receiveGift(from friendId: String, amount: Int) {
        receivedGifts[friendId] = (receivedGifts[friendId] ?? 0) + amount
        ShopManager.shared.playerCurrency += amount
        saveFriends()
    }

    // 清空已接收的礼物
    func clearReceivedGifts() {
        receivedGifts.removeAll()
        saveFriends()
    }

    // MARK: - 数据持久化

    // 保存好友数据
    private func saveFriends() {
        let defaults = UserDefaults.standard

        if let encoded = try? JSONEncoder().encode(friends) {
            defaults.set(encoded, forKey: "social_friends")
        }

        if let requestsEncoded = try? JSONEncoder().encode(friendRequests) {
            defaults.set(requestsEncoded, forKey: "social_requests")
        }

        defaults.set(receivedGifts as NSDictionary, forKey: "social_gifts")
    }

    // 加载好友数据
    private func loadFriends() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: "social_friends"),
           let decodedFriends = try? JSONDecoder().decode([Friend].self, from: data) {
            friends = decodedFriends
        }

        if let data = defaults.data(forKey: "social_requests"),
           let decodedRequests = try? JSONDecoder().decode([Friend].self, from: data) {
            friendRequests = decodedRequests
        }

        if let gifts = defaults.object(forKey: "social_gifts") as? [String: Int] {
            receivedGifts = gifts
        }
    }

    // MARK: - 辅助方法

    // 获取好友数量
    var friendCount: Int {
        friends.count
    }

    // 获取亲密度等级
    func getIntimacyLevel(for friend: Friend) -> String {
        switch friend.intimacy {
        case 0..<20: return "陌生人"
        case 20..<40: return "认识"
        case 40..<60: return "朋友"
        case 60..<80: return "好友"
        case 80..<100: return "挚友"
        case 100: return "死党"
        default: return "陌生人"
        }
    }

    // 搜索好友
    func searchFriends(query: String) -> [Friend] {
        guard !query.isEmpty else { return friends }

        return friends.filter { friend in
            friend.name.localizedCaseInsensitiveContains(query)
        }
    }

    // 获取亲密好友
    func getCloseFriends(threshold: Int = 60) -> [Friend] {
        friends.filter { $0.intimacy >= threshold }
            .sorted { $0.intimacy > $1.intimacy }
    }
}

// 社交主视图
struct SocialView: View {
    @ObservedObject var socialManager = SocialManager.shared
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool

    @State private var selectedTab: SocialTab = .friends
    @State private var showingAddFriend = false
    @State private var selectedFriend: Friend?
    @State private var showingFriendDetail = false

    enum SocialTab: String, CaseIterable {
        case friends = "好友"
        case requests = "请求"
        case gifts = "礼物"
    }

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("👥 社交中心")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // 好友数量
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("\(socialManager.friendCount)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.3))
                    )
                }

                // 标签页
                Picker("社交类型", selection: $selectedTab) {
                    ForEach(SocialTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                // 内容区域
                ScrollView {
                    switch selectedTab {
                    case .friends:
                        FriendsListView(
                            friends: socialManager.friends,
                            onAddFriend: {
                                showingAddFriend = true
                            },
                            onSelectFriend: { friend in
                                selectedFriend = friend
                                showingFriendDetail = true
                            }
                        )
                    case .requests:
                        FriendRequestsView(
                            requests: socialManager.friendRequests
                        )
                    case .gifts:
                        GiftsView(
                            receivedGifts: socialManager.receivedGifts
                        )
                    }
                }

                // 关闭按钮
                Button(action: {
                    isPresented = false
                }) {
                    Text("关闭")
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
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView(isPresented: $showingAddFriend)
        }
        .sheet(isPresented: $showingFriendDetail) {
            if let friend = selectedFriend {
                FriendDetailView(friend: friend, isPresented: $showingFriendDetail)
            }
        }
    }
}

// 好友列表视图
struct FriendsListView: View {
    let friends: [Friend]
    let onAddFriend: () -> Void
    let onSelectFriend: (Friend) -> Void

    var body: some View {
        if friends.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 12) {
                ForEach(friends) { friend in
                    FriendCard(
                        friend: friend,
                        action: {
                            onSelectFriend(friend)
                        }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("还没有好友")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("添加好友开始社交吧!")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onAddFriend) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("添加好友")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// 好友卡片
struct FriendCard: View {
    let friend: Friend
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 宠物图标
                ZStack {
                    Circle()
                        .fill(friend.petType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(friend.petEmoji)
                        .font(.system(size: 30))
                }

                // 好友信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("Lv.\(friend.petLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(SocialManager.shared.getIntimacyLevel(for: friend))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    // 亲密度进度条
                    ProgressView(value: Double(friend.intimacy), total: 100)
                        .accentColor(.pink)
                        .frame(height: 3)
                }

                Spacer()

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 好友请求视图
struct FriendRequestsView: View {
    let requests: [Friend]

    var body: some View {
        if requests.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 12) {
                ForEach(requests) { request in
                    FriendRequestCard(request: request)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("暂无好友请求")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("等待其他玩家添加你吧!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// 好友请求卡片
struct FriendRequestCard: View {
    let request: Friend

    var body: some View {
        HStack(spacing: 12) {
            // 宠物图标
            ZStack {
                Circle()
                    .fill(request.petType.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(request.petEmoji)
                    .font(.system(size: 30))
            }

            // 好友信息
            VStack(alignment: .leading, spacing: 4) {
                Text(request.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Lv.\(request.petLevel) \(request.petType.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮
            HStack(spacing: 8) {
                Button(action: {
                    SocialManager.shared.rejectFriendRequest(request)
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                }

                Button(action: {
                    SocialManager.shared.acceptFriendRequest(request)
                }) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// 礼物视图
struct GiftsView: View {
    let receivedGifts: [String: Int]

    var body: some View {
        let totalGifts = receivedGifts.values.reduce(0, +)

        if totalGifts == 0 {
            emptyState
        } else {
            VStack(spacing: 16) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)

                Text("收到 \(totalGifts) 份礼物!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(receivedGifts.count) 位好友赠送了礼物")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("全部领取") {
                    SocialManager.shared.clearReceivedGifts()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.pink)
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("暂无礼物")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("等待好友送你礼物吧!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// 添加好友视图
struct AddFriendView: View {
    @Binding var isPresented: Bool
    @State private var friendName = ""
    @State private var selectedPetType: PetType = .cat
    @State private var showingResult = false
    @State private var resultMessage = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                Text("添加好友")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // 输入好友名字
                VStack(alignment: .leading, spacing: 8) {
                    Text("好友名字")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    TextField("输入好友的名字", text: $friendName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(Color.white)
                }

                // 选择宠物类型(模拟)
                VStack(alignment: .leading, spacing: 8) {
                    Text("好友的宠物类型")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Picker("宠物类型", selection: $selectedPetType) {
                        ForEach(PetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 发送请求按钮
                Button(action: sendFriendRequest) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("发送好友请求")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(friendName.isEmpty)

                // 结果提示
                if showingResult {
                    Text(resultMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.5))
                        )
                }

                Button("关闭") {
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(12)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.background)
                    .shadow(radius: 20)
            )
            .padding(40)
        }
    }

    private func sendFriendRequest() {
        // 模拟发送好友请求
        SocialManager.shared.sendFriendRequest(
            to: friendName,
            petType: selectedPetType,
            petLevel: Int.random(in: 1...20)
        )

        resultMessage = "好友请求已发送!"
        showingResult = true
        friendName = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingResult = false
            isPresented = false
        }
    }
}

// 好友详情视图
struct FriendDetailView: View {
    let friend: Friend
    @Binding var isPresented: Bool

    @State private var selectedAction: SocialInteractionType?
    @State private var showingActionSheet = false

    var intimacyLevel: String {
        SocialManager.shared.getIntimacyLevel(for: friend)
    }

    var canVisit: Bool {
        guard let lastVisit = friend.lastVisit else { return true }
        return Date().timeIntervalSince(lastVisit) >= 3600
    }

    var nextVisitTime: String? {
        guard let lastVisit = friend.lastVisit else { return nil }
        let elapsed = Date().timeIntervalSince(lastVisit)
        guard elapsed < 3600 else { return nil }

        let remaining = 3600 - elapsed
        if remaining < 60 {
            return "\(Int(remaining))秒后"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))分钟后"
        }
        return nil
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                // 宠物图标和信息
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(friend.petType.color.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Text(friend.petEmoji)
                            .font(.system(size: 60))
                    }

                    Text(friend.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Text("Lv.\(friend.petLevel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(intimacyLevel)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                // 亲密度
                VStack(alignment: .leading, spacing: 8) {
                    Text("亲密度")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ProgressView(value: Double(friend.intimacy), total: 100)
                        .accentColor(.pink)

                    HStack {
                        Text("\(friend.intimacy)/100")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if let nextTime = nextVisitTime {
                            Text(nextTime)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.pink.opacity(0.1))
                )

                // 互动选项
                VStack(spacing: 12) {
                    Text("互动选项")
                        .font(.headline)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(SocialInteractionType.allCases, id: \.self) { action in
                            SocialActionButton(
                                action: action,
                                friend: friend,
                                canPerform: canPerformAction(action),
                                onSelect: {
                                    performAction(action)
                                }
                            )
                        }
                    }
                }

                // 关闭按钮
                Button(action: {
                    isPresented = false
                }) {
                    Text("关闭")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.background)
                    .shadow(radius: 20)
            )
            .padding(40)
        }
    }

    private func canPerformAction(_ action: SocialInteractionType) -> Bool {
        switch action {
        case .visit:
            return canVisit
        case .gift, .play, .message:
            return true
        }
    }

    private func performAction(_ action: SocialInteractionType) {
        switch action {
        case .visit:
            if SocialManager.shared.visitFriend(friend) {
                HapticManager.shared.trigger(.medium)
                // 访问成功反馈
            }
        case .gift:
            if SocialManager.shared.sendGift(to: friend) {
                HapticManager.shared.trigger(.medium)
                // 送礼成功反馈
            }
        case .play:
            // 玩耍互动
            SocialManager.shared.increaseIntimacy(for: friend, by: 3)
            HapticManager.shared.trigger(.light)
        case .message:
            // 留言功能(简化版)
            SocialManager.shared.increaseIntimacy(for: friend, by: 2)
            HapticManager.shared.trigger(.light)
        }

        isPresented = false
    }
}

// 社交操作按钮
struct SocialActionButton: View {
    let action: SocialInteractionType
    let friend: Friend
    let canPerform: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: action.icon)
                        .foregroundColor(action.color)
                }

                Text(action.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)

                if !canPerform {
                    Text("冷却中")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .opacity(canPerform ? 1.0 : 0.5)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canPerform)
    }
}

// 预览
#Preview {
    SocialView(pet: Pet(), isPresented: .constant(true))
}
