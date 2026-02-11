import SwiftUI

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var selectedPetType: PetType = .cat
    @State private var showingActivityLog = false
    @State private var showingAchievements = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var timer: Timer? = nil

    var body: some View {
        NavigationView {
            MainContentView(
                pet: pet,
                selectedPetType: $selectedPetType,
                errorMessage: $errorMessage,
                showingError: $showingError,
                onReset: {
                    resetPet()
                }
            )
            .navigationTitle("虚拟宠物")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingActivityLog = true }) {
                            Label("活动记录", systemImage: "clock.fill")
                        }
                        Button(action: { showingAchievements = true }) {
                            Label("成就", systemImage: "trophy.fill")
                        }
                        Button(action: { resetPet() }) {
                            Label("重置宠物", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingActivityLog) {
                ActivityLogView(pet: pet)
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView(pet: pet)
            }
        }
        .onAppear {
            setupTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func resetPet() {
        pet.reset()
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            pet.decay()
        }
    }
}

struct MainContentView: View {
    @ObservedObject var pet: Pet
    @Binding var selectedPetType: PetType
    @Binding var errorMessage: String?
    @Binding var showingError: Bool
    let onReset: () -> Void
    
    @State private var petBounce = false
    @State private var sparkleAnimation = false
    @State private var heartAnimation = false
    @State private var particleEffects: [Particle] = []
    @State private var isAnimating = false
    @State private var intimacyHeartPulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PetHeaderView(pet: pet)
                
                PetDisplayView(
                    pet: pet,
                    breathAnimation: .constant(true),
                    petBounce: $petBounce,
                    sparkleAnimation: $sparkleAnimation,
                    heartAnimation: $heartAnimation,
                    particleEffects: $particleEffects
                )
                
                StatusGridView(pet: pet)
                
                InteractionButtonsView(
                    pet: pet,
                    petBounce: $petBounce,
                    sparkleAnimation: $sparkleAnimation,
                    heartAnimation: $heartAnimation,
                    particleEffects: $particleEffects,
                    isAnimating: $isAnimating,
                    errorMessage: $errorMessage,
                    showingError: $showingError,
                    intimacyHeartPulse: $intimacyHeartPulse
                )
                
                PetTypeSelector(petType: $selectedPetType)
                    .onChange(of: selectedPetType) { newValue in
                        pet.petType = newValue
                    }
                
                QuickStatsView(pet: pet)
            }
            .padding()
        }
        .overlay {
            ContentViewOverlays(pet: pet, intimacyHeartPulse: $intimacyHeartPulse, showingError: showingError, errorMessage: errorMessage, onDismissError: {
                withAnimation {
                    showingError = false
                    errorMessage = nil
                }
            }, onReset: onReset)
        }
    }
}

struct ContentViewOverlays: View {
    @ObservedObject var pet: Pet
    @Binding var intimacyHeartPulse: Bool
    var showingError: Bool
    var errorMessage: String?
    let onDismissError: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        ZStack {
            if showingError, let message = errorMessage {
                ErrorAlert(message: message, onDismiss: onDismissError)
            }
            
            if pet.intimacy > 0 && intimacyHeartPulse {
                IntimacyHeartAnimation()
            }
            
            if pet.isDead {
                DeathView(pet: pet, onRebirth: {
                    _ = pet.rebirth()
                    onReset()
                }, onReset: onReset)
            }
        }
    }
}

struct ErrorAlert: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: 20) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("提示")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                    }
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                }
                .padding(20)
                #if os(iOS)
                .background(Color(UIColor.systemBackground))
                #else
                .background(Color(nsColor: .textBackgroundColor))
                #endif
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 40)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: message)
    }
}

struct IntimacyHeartAnimation: View {
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2 - 50
            
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .stroke(Color.pink.opacity(0.6), lineWidth: 2)
                    .frame(width: 80 + CGFloat(index * 30), height: 80 + CGFloat(index * 30))
                    .position(x: centerX, y: centerY)
                    .opacity(0.6)
                    .scaleEffect(1.0 + CGFloat(index) * 0.2)
                    .animation(
                        .easeOut(duration: 1.2).delay(Double(index) * 0.15),
                        value: index
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// 粒子效果
struct Particle: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var animationProgress: Double
    
    static func == (lhs: Particle, rhs: Particle) -> Bool {
        lhs.id == rhs.id
    }
}

// 进化动画
struct EvolutionAnimation {
    let fromStage: EvolutionStage
    let toStage: EvolutionStage
    var progress: Double
    var particles: [EvolutionParticle]
    
    init(from: EvolutionStage, to: EvolutionStage) {
        self.fromStage = from
        self.toStage = to
        self.progress = 0.0
        self.particles = []
    }
}

struct EvolutionParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// 随机事件动画
struct RandomEventAnimation {
    let title: String
    let icon: String
    let color: Color
    var showProgress: Double
    var particles: [EventParticle]
    
    init(title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
        self.showProgress = 0.0
        self.particles = []
    }
}

struct EventParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var scale: CGFloat
}

// 宠物信息头部
struct PetHeaderView: View {
    @ObservedObject var pet: Pet
    @State private var showingEvolutionPathSelection = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(pet.petType.rawValue)
                        .font(.system(size: 28))
                    
                    Text(getEvolutionEmoji())
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Lv.\(pet.level)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if pet.evolutionStage != .egg {
                            Text("• \(pet.evolutionStage.rawValue)")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }

                    Text("第 \(pet.age) 天")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("经验")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("\(pet.experience)/\(pet.level * 100)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("亲密度")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("\(pet.intimacy)/100")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                    }
                    
                    ProgressView(value: Double(pet.experience), total: Double(pet.level * 100))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 120)
                    
                    if pet.intimacy > 0 {
                        ProgressView(value: Double(pet.intimacy), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                            .frame(width: 120)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            if pet.evolutionStage == .child && pet.evolutionPath == nil {
                Button(action: {
                    showingEvolutionPathSelection = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        Text("选择进化路径")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.blue, lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingEvolutionPathSelection) {
                    EvolutionPathSelectionView(pet: pet, isPresented: $showingEvolutionPathSelection)
                }
            }
        }
    }
    
    private func getEvolutionEmoji() -> String {
        switch pet.evolutionStage {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teen: return "🐥"
        case .adult: return "🐓"
        case .elder: return "🦄"
        case .legendary: return "🌟"
        }
    }
}

// 进化路径选择视图
struct EvolutionPathSelectionView: View {
    @ObservedObject var pet: Pet
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Text("选择进化路径")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("不同的路径会影响宠物的成长方式和特殊能力")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(EvolutionPath.allCases, id: \.self) { path in
                            EvolutionPathCard(
                                path: path,
                                isSelected: pet.evolutionPath == path,
                                onTap: {
                                    pet.setEvolutionPath(path)
                                    withAnimation {
                                        isPresented = false
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Button("暂不选择") {
                    withAnimation {
                        isPresented = false
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("关闭") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
                #endif
            }
        }
    }
}

// 进化路径卡片
struct EvolutionPathCard: View {
    let path: EvolutionPath
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(getPathColor().opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: path.icon)
                        .font(.title2)
                        .foregroundColor(getPathColor())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(path.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPathColor() -> Color {
        switch path {
        case .balanced: return .blue
        case .strong: return .orange
        case .happy: return .pink
        case .healthy: return .green
        case .mysterious: return .purple
        }
    }
}

// 宠物显示视图 - 优化版本
struct PetDisplayView: View {
    @ObservedObject var pet: Pet
    @Binding var breathAnimation: Bool
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]
    
    @State private var evolutionGlow = 0.0
    @State private var sparkleOffsets: [CGSize] = []
    @State private var heartOffsets: [CGSize] = []
    
    private let animationNamespace = Namespace()

    var body: some View {
        ZStack {
            // 背景渐变基于心情和进化阶段
            RoundedRectangle(cornerRadius: 25)
                .fill(getMoodGradient())
                .shadow(color: getMoodShadowColor(), radius: 15, x: 0, y: 5)
                .overlay(
                    // 进化光晕效果 - 使用优化的动画
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            getEvolutionGlowColor().opacity(evolutionGlow),
                            lineWidth: 4
                        )
                        .shadow(color: getEvolutionGlowColor().opacity(evolutionGlow), radius: 20)
                )

            // 进化阶段背景装饰
            if pet.evolutionStage != .egg {
                getEvolutionDecoration()
                    .opacity(0.3)
                    .scaleEffect(1.5)
            }

            // 宠物表情 - 优化动画
            Text(getPetExpression())
                .font(.system(size: getPetSize()))
                .scaleEffect(getPetScale())
                .rotationEffect(getPetRotation())
                .offset(y: petBounce ? -20 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: petBounce)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            // 亲密度爱心装饰 - 使用预计算位置
            if pet.intimacy >= 50 {
                ForEach(0..<min(pet.intimacy / 25, 3), id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.caption)
                        .offset(
                            x: CGFloat(index - 1) * 40,
                            y: -80
                        )
                        .opacity(0.6)
                        .scaleEffect(1.0 + CGFloat(index) * 0.1)
                        .drawingGroup() // 优化渲染性能
                }
            }

            // 进化路径图标
            if let path = pet.evolutionPath {
                ZStack {
                    Circle()
                        .fill(path.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: path.icon)
                        .foregroundColor(path.color)
                        .font(.title3)
                }
                .position(x: 280, y: 50)
            }

            // 粒子效果 - 使用drawingGroup优化
            ForEach(particleEffects) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(particle.position)
            }
            .drawingGroup()

            // 特殊效果 - 优化的动画实现
            if sparkleAnimation {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(.yellow)
                        .frame(width: 12, height: 12)
                        .offset(getSparkleOffset(for: index))
                        .opacity(sparkleAnimation ? 1.0 : 0.0)
                        .scaleEffect(sparkleAnimation ? 2.5 : 1.0)
                        .animation(
                            .easeOut(duration: 1.2)
                                .delay(Double(index) * 0.08),
                            value: sparkleAnimation
                        )
                }
            }

            if heartAnimation {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title)
                        .offset(getHeartOffset(for: index))
                        .scaleEffect(petBounce ? 1.8 : 1.0)
                        .opacity(heartAnimation ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 1.8)
                                .delay(Double(index) * 0.15),
                            value: heartAnimation
                        )
                }
            }
        }
        .frame(height: 280)
        .padding()
        .onAppear {
            startEvolutionGlow()
            initializeOffsets()
        }
        .onChange(of: sparkleAnimation) { oldValue, newValue in
            if newValue {
                initializeOffsets()
            }
        }
        .onChange(of: heartAnimation) { oldValue, newValue in
            if newValue {
                initializeOffsets()
            }
        }
    }
    
    private func initializeOffsets() {
        sparkleOffsets = (0..<8).map { _ in
            CGSize(width: CGFloat.random(in: -60...60), height: CGFloat.random(in: -60...60))
        }
        heartOffsets = (0..<5).map { _ in
            CGSize(width: CGFloat.random(in: -40...40), height: -CGFloat.random(in: 30...100))
        }
    }
    
    private func getSparkleOffset(for index: Int) -> CGSize {
        guard index < sparkleOffsets.count else {
            return CGSize(width: CGFloat.random(in: -60...60), height: CGFloat.random(in: -60...60))
        }
        return sparkleOffsets[index]
    }
    
    private func getHeartOffset(for index: Int) -> CGSize {
        guard index < heartOffsets.count else {
            return CGSize(width: CGFloat.random(in: -40...40), height: -CGFloat.random(in: 30...100))
        }
        return heartOffsets[index]
    }
    
    private func startEvolutionGlow() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            evolutionGlow = 0.8
        }
    }
    
    private func getEvolutionGlowColor() -> Color {
        switch pet.evolutionStage {
        case .egg: return .white
        case .baby: return .green
        case .child: return .blue
        case .teen: return .purple
        case .adult: return .orange
        case .elder: return .pink
        case .legendary: return .yellow
        }
    }

    private func getMoodGradient() -> LinearGradient {
        let baseColor = pet.petType.color
        
        switch pet.mood {
        case .happy:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .excited:
            return LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [.gray, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sick:
            return LinearGradient(
                colors: [.red.opacity(0.3), .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hungry:
            return LinearGradient(
                colors: [.orange.opacity(0.5), .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleepy:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [baseColor.opacity(0.2), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func getMoodShadowColor() -> Color {
        switch pet.mood {
        case .happy: return .yellow
        case .excited: return .pink
        case .sad: return .blue
        case .sick: return .red
        case .hungry: return .orange
        case .sleepy: return .purple
        default: return pet.petType.color
        }
    }
    
    private func getPetSize() -> CGFloat {
        let baseSize: CGFloat = 100
        let evolutionBonus = getEvolutionStageIndex() * 10
        let intimacyBonus = pet.intimacy >= 50 ? 10 : 0
        
        return baseSize + CGFloat(evolutionBonus + intimacyBonus)
    }
    
    private func getEvolutionStageIndex() -> Int {
        EvolutionStage.allCases.firstIndex(of: pet.evolutionStage) ?? 0
    }
    
    private func getEvolutionDecoration() -> some View {
        let stage = pet.evolutionStage
        
        switch stage {
        case .egg:
            return AnyView(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
            )
        case .baby:
            return AnyView(
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
            )
        case .child:
            return AnyView(
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
            )
        case .teen:
            return AnyView(
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                    .frame(width: 120, height: 120)
            )
        case .adult:
            return AnyView(
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 5)
                    .frame(width: 140, height: 140)
            )
        case .elder:
            return AnyView(
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 6)
                    .frame(width: 160, height: 160)
            )
        case .legendary:
            return AnyView(
                ZStack {
                    Circle()
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 7)
                        .frame(width: 180, height: 180)
                    Circle()
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 5)
                        .frame(width: 200, height: 200)
                }
            )
        }
    }

    private func getPetExpression() -> String {
        switch pet.petType {
        case .cat:
            switch pet.mood {
            case .happy: return "😸"
            case .sad: return "😿"
            case .sick: return "🙀"
            case .hungry: return "🙀"
            case .sleepy: return "😴"
            case .excited: return "😻"
            default: return "😺"
            }
        case .dog:
            switch pet.mood {
            case .happy: return "🐶"
            case .sad: return "😢"
            case .sick: return "🤒"
            case .hungry: return "🍖"
            case .sleepy: return "😴"
            case .excited: return "🎾"
            default: return "🐕"
            }
        case .rabbit:
            switch pet.mood {
            case .happy: return "🐰"
            case .sad: return "😔"
            case .sick: return "🤧"
            case .hungry: return "🥕"
            case .sleepy: return "😴"
            case .excited: return "🎉"
            default: return "🐇"
            }
        case .hamster:
            switch pet.mood {
            case .happy: return "🐹"
            case .sad: return "😞"
            case .sick: return "🤕"
            case .hungry: return "🌰"
            case .sleepy: return "😴"
            case .excited: return "🎊"
            default: return "🐭"
            }
        case .bird:
            switch pet.mood {
            case .happy: return "🐦"
            case .sad: return "😔"
            case .sick: return "🤧"
            case .hungry: return "🌽"
            case .sleepy: return "😴"
            case .excited: return "🎈"
            default: return "🐥"
            }
        }
    }

    private func getPetScale() -> CGFloat {
        var scale: CGFloat = 1.0
        
        switch pet.mood {
        case .excited: scale = 1.2
        case .happy: scale = 1.1
        case .sad: scale = 0.9
        case .sick: scale = 0.8
        case .sleepy: scale = 0.95
        default: scale = 1.0
        }
        
        if pet.intimacy >= 80 {
            scale *= 1.05
        }
        
        return scale
    }

    private func getPetRotation() -> Angle {
        switch pet.mood {
        case .sad: return Angle(degrees: -5)
        case .excited: return Angle(degrees: 5)
        case .sleepy: return Angle(degrees: 10)
        default: return Angle(degrees: 0)
        }
    }
}

// 状态网格视图
struct StatusGridView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 15) {
            Text("宠物状态")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                StatusItem(
                    title: "饥饿度",
                    value: pet.hunger,
                    color: .red,
                    icon: "fork.knife",
                    isCritical: pet.hunger > 80
                )

                StatusItem(
                    title: "快乐度",
                    value: pet.happiness,
                    color: .yellow,
                    icon: "heart.fill",
                    isCritical: pet.happiness < 20
                )

                StatusItem(
                    title: "健康度",
                    value: pet.health,
                    color: .green,
                    icon: "leaf.fill",
                    isCritical: pet.health < 30
                )

                StatusItem(
                    title: "能量",
                    value: pet.energy,
                    color: .blue,
                    icon: "bolt.fill",
                    isCritical: pet.energy < 20
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// 单个状态项
struct StatusItem: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    let isCritical: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))

            Text("\(value)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isCritical ? .red : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// 交互按钮视图
struct InteractionButtonsView: View {
    @ObservedObject var pet: Pet
    @Binding var petBounce: Bool
    @Binding var sparkleAnimation: Bool
    @Binding var heartAnimation: Bool
    @Binding var particleEffects: [Particle]
    @Binding var isAnimating: Bool
    @Binding var errorMessage: String?
    @Binding var showingError: Bool
    @Binding var intimacyHeartPulse: Bool

    var body: some View {
        VStack(spacing: 15) {
            Text("与宠物互动")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                InteractionButton(
                    title: "喂食",
                    color: .orange,
                    icon: "fork.knife",
                    action: { handleInteraction(.feed, animation: .sparkle) }
                )

                InteractionButton(
                    title: "玩耍",
                    color: .purple,
                    icon: "gamecontroller",
                    action: { handleInteraction(.play, animation: .heart) }
                )

                InteractionButton(
                    title: "清理",
                    color: .green,
                    icon: "sparkles",
                    action: { handleInteraction(.clean, animation: .bounce) }
                )

                InteractionButton(
                    title: "运动",
                    color: .blue,
                    icon: "figure.walk",
                    action: { handleInteraction(.exercise, animation: .bounce) }
                )

                InteractionButton(
                    title: "拥抱",
                    color: .red,
                    icon: "heart.fill",
                    action: { handleInteraction(.cuddle, animation: .heart) }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    // 动画类型
    enum AnimationType {
        case bounce, sparkle, heart
    }

    // 处理交互 - 统一处理逻辑
    private func handleInteraction(_ type: Pet.InteractionType, animation: AnimationType) {
        guard !isAnimating else { return }
        isAnimating = true

        let result = pet.interact(type: type)
        handleInteractionResult(result, animation: animation, interactionType: type)
    }

    // 处理交互结果
    private func handleInteractionResult(_ result: Pet.InteractionResult, animation: AnimationType, interactionType: Pet.InteractionType) {
        switch result {
        case .success(_):
            applyAnimation(animation, for: interactionType)
            checkIntimacyMilestone()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        case .failure(let message), .warning(let message):
            showError(message)
            isAnimating = false
        }
    }

    // 应用动画效果（根据交互类型确定颜色）
    private func applyAnimation(_ type: AnimationType, for interactionType: Pet.InteractionType) {
        let particleColor = getParticleColor(for: interactionType)
        let particleCount = getParticleCount(for: interactionType)

        switch type {
        case .bounce:
            animateBounce()
        case .sparkle:
            animateBounce()
            sparkleAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                sparkleAnimation = false
            }
            addParticles(color: particleColor, count: particleCount)
        case .heart:
            animateBounce()
            heartAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                heartAnimation = false
            }
            addParticles(color: particleColor, count: particleCount)
        }
    }

    // 获取粒子颜色
    private func getParticleColor(for type: Pet.InteractionType) -> Color {
        switch type {
        case .feed: return .orange
        case .play: return .purple
        case .clean: return .green
        case .exercise: return .blue
        case .cuddle: return .red
        case .train: return .orange
        case .discipline: return .gray
        case .praise: return .yellow
        case .study: return .indigo
        }
    }

    // 获取粒子数量
    private func getParticleCount(for type: Pet.InteractionType) -> Int {
        switch type {
        case .feed: return 5
        case .play: return 3
        case .clean: return 4
        case .exercise: return 3
        case .cuddle: return 6
        case .train: return 4
        case .discipline: return 2
        case .praise: return 5
        case .study: return 3
        }
    }

    // 弹跳动画
    private func animateBounce() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            petBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                petBounce = false
            }
        }
    }

    // 检查亲密度里程碑
    private func checkIntimacyMilestone() {
        if pet.intimacy > 0 && pet.intimacy % 10 == 0 {
            withAnimation {
                intimacyHeartPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    intimacyHeartPulse = false
                }
            }
        }
    }

    // 显示错误消息
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingError = false
            errorMessage = nil
        }
    }

    private func addParticles(color: Color, count: Int) {
        let newParticles = (0..<count).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 50...250),
                    y: CGFloat.random(in: 50...200)
                ),
                size: CGFloat.random(in: 5...15),
                color: color,
                opacity: 1.0,
                animationProgress: 0.0
            )
        }

        withAnimation(.easeOut(duration: 1.0)) {
            particleEffects.append(contentsOf: newParticles)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                particleEffects.removeAll()
            }
        }
    }
}

// 交互按钮
struct InteractionButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 宠物类型选择器
struct PetTypeSelector: View {
    @Binding var petType: PetType

    var body: some View {
        VStack(spacing: 10) {
            Text("选择宠物类型")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(PetType.allCases, id: \.self) { type in
                    Button(role: .none, action: {
                        petType = type
                    }) {
                        VStack {
                            Text(type.rawValue)
                                .font(.system(size: 30))
                            Text(type.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(petType == type ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// 快速统计视图
struct QuickStatsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 12) {
            Text("宠物档案")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                HStack(spacing: 15) {
                    StatItem(title: "总互动", value: pet.totalInteractions, color: .blue)
                    StatItem(title: "最高快乐", value: pet.maxHappiness, color: .yellow)
                    StatItem(title: "成就数", value: pet.unlockedAchievements, color: .purple)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                HStack(spacing: 15) {
                    StatItem(title: "亲密度", value: pet.intimacy, color: .pink, suffix: "/100")
                    StatItem(title: "幸运事件", value: pet.luckyEvents, color: .orange)
                    StatItem(title: "特殊时刻", value: pet.specialMoments, color: .green)
                }
                
                if pet.evolutionStage != .egg {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("进化阶段")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Text(getEvolutionEmoji(pet.evolutionStage))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pet.evolutionStage.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    if let nextStage = getNextEvolutionStage() {
                                        Text("下一级：\(nextStage.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("进化路径")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let path = pet.evolutionPath {
                                HStack(spacing: 4) {
                                    Image(systemName: path.icon)
                                        .foregroundColor(getPathColor(path))
                                    Text(path.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            } else {
                                Text("未选择")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                if pet.evolutionStage != .legendary {
                    let currentLevelIndex = EvolutionStage.allCases.firstIndex(of: pet.evolutionStage) ?? 0
                    let nextLevel = EvolutionStage.allCases[currentLevelIndex + 1]
                    let progress = pet.level >= nextLevel.requiredLevel ? 1.0 : Double(pet.level) / Double(nextLevel.requiredLevel)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("进化进度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(pet.level)/\(nextLevel.requiredLevel)级")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .scaleEffect(y: 1.5)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getEvolutionEmoji(_ stage: EvolutionStage) -> String {
        switch stage {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teen: return "🐥"
        case .adult: return "🐓"
        case .elder: return "🦄"
        case .legendary: return "🌟"
        }
    }
    
    private func getNextEvolutionStage() -> EvolutionStage? {
        guard let currentIndex = EvolutionStage.allCases.firstIndex(of: pet.evolutionStage) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < EvolutionStage.allCases.count ? EvolutionStage.allCases[nextIndex] : nil
    }
    
    private func getPathColor(_ path: EvolutionPath) -> Color {
        switch path {
        case .balanced: return .blue
        case .strong: return .orange
        case .happy: return .pink
        case .healthy: return .green
        case .mysterious: return .purple
        }
    }
}

// 统计项
struct StatItem: View {
    let title: String
    let value: Int
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)\(suffix)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// 活动记录视图
struct ActivityLogView: View {
    @ObservedObject var pet: Pet
    @State private var showingAllActivities = false

    var filteredActivities: [Activity] {
        showingAllActivities ? pet.activities : Array(pet.activities.reversed().prefix(10))
    }

    var body: some View {
        NavigationView {
            List {
                Section("最近活动") {
                    ForEach(filteredActivities) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activity.icon)
                                .foregroundColor(activity.color.color)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(activity.date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let value = activity.value {
                                Text("+\(value)")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                        .frame(minHeight: 56)
                        .padding(.vertical, 2)
                    }
                }

                Section("统计") {
                    StatRow(title: "总互动次数", value: pet.totalInteractions)
                    StatRow(title: "最高快乐度", value: pet.maxHappiness)
                    StatRow(title: "当前等级", value: pet.level)
                    StatRow(title: "获得成就数", value: pet.unlockedAchievements)
                    StatRow(title: "宠物年龄", value: pet.age)
                }
            }
            .listStyle(.inset)
            .navigationTitle("活动记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(showingAllActivities ? "显示最近" : "显示全部") {
                        showingAllActivities.toggle()
                    }
                    .font(.body)
                }
            }
        }
    }
}

// 成就视图
struct AchievementsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        NavigationView {
            List {
                Section("已解锁成就 (\(pet.unlockedAchievements)/\(pet.achievements.count))") {
                    ForEach(pet.achievements) { achievement in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(achievement.unlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: achievement.icon)
                                    .foregroundColor(achievement.unlocked ? .yellow : .gray)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Text(achievement.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if achievement.unlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            } else {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                            }
                        }
                        .frame(minHeight: 60)
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("成就")
        }
    }
}

// 统计行
struct StatRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

// 进化动画视图
struct EvolutionAnimationView: View {
    @State var animation: EvolutionAnimation
    let onComplete: () -> Void
    @State private var particles: [EvolutionParticle] = []
    @State private var screenSize: CGSize = CGSize(width: 400, height: 800)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 进化阶段展示
                    VStack(spacing: 20) {
                        Text("进化！")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animation.progress < 0.5 ? 1.0 : 1.2)
                            .animation(.easeInOut(duration: 0.5), value: animation.progress)
                        
                        HStack(spacing: 40) {
                            Text(getStageEmoji(animation.fromStage))
                                .font(.system(size: 80))
                                .opacity(animation.progress < 0.5 ? 1.0 : 0.0)
                                .scaleEffect(animation.progress < 0.5 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.5), value: animation.progress)
                            
                            Text("→")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .opacity(animation.progress > 0.3 && animation.progress < 0.7 ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.2), value: animation.progress)
                            
                            Text(getStageEmoji(animation.toStage))
                                .font(.system(size: 100))
                                .opacity(animation.progress > 0.5 ? 1.0 : 0.0)
                                .scaleEffect(animation.progress > 0.5 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.5), value: animation.progress)
                        }
                        
                        Text("\(animation.fromStage.rawValue) → \(animation.toStage.rawValue)")
                            .font(.title2)
                            .foregroundColor(.white)
                            .opacity(animation.progress > 0.5 ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.5).delay(0.3), value: animation.progress)
                    }
                    
                    // 进化粒子效果
                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .opacity(particle.opacity)
                                .position(particle.position)
                        }
                    }
                    .frame(height: 200)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            screenSize = CGSize(width: 400, height: 800)
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 生成粒子
        for _ in 0..<30 {
            particles.append(EvolutionParticle(
                position: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2),
                velocity: CGVector(dx: CGFloat.random(in: -3...3), dy: CGFloat.random(in: -3...3)),
                size: CGFloat.random(in: 5...15),
                color: [.yellow, .orange, .purple, .pink, .blue].randomElement() ?? .yellow,
                opacity: 1.0
            ))
        }
        
        // 动画进度
        withAnimation(.easeInOut(duration: 2.0)) {
            animation.progress = 1.0
        }
        
        // 粒子动画
        withAnimation(.easeOut(duration: 2.0)) {
            for index in particles.indices {
                particles[index].position.x += CGFloat.random(in: -200...200)
                particles[index].position.y += CGFloat.random(in: -200...200)
                particles[index].opacity = 0.0
            }
        }
        
        // 完成回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }
    
    private func getStageEmoji(_ stage: EvolutionStage) -> String {
        switch stage {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teen: return "🐥"
        case .adult: return "🐓"
        case .elder: return "🦄"
        case .legendary: return "🌟"
        }
    }
}

// 随机事件动画视图
struct RandomEventAnimationView: View {
    @State var animation: RandomEventAnimation
    let onComplete: () -> Void
    @State private var particles: [EventParticle] = []
    @State private var screenSize: CGSize = CGSize(width: 400, height: 800)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(animation.color.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(animation.showProgress)
                                .animation(.easeInOut(duration: 0.6), value: animation.showProgress)
                            
                            Circle()
                                .fill(animation.color.opacity(0.1))
                                .frame(width: 150, height: 150)
                                .scaleEffect(animation.showProgress * 1.2)
                                .animation(.easeInOut(duration: 0.6).delay(0.1), value: animation.showProgress)
                            
                            Image(systemName: animation.icon)
                                .font(.system(size: 50))
                                .foregroundColor(animation.color)
                                .scaleEffect(animation.showProgress)
                                .rotationEffect(.degrees(animation.showProgress * 360))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animation.showProgress)
                        }
                        
                        Text(animation.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(animation.showProgress)
                            .animation(.easeIn(duration: 0.5).delay(0.3), value: animation.showProgress)
                    }
                    
                    // 事件粒子效果
                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .opacity(particle.opacity)
                                .scaleEffect(particle.scale)
                                .position(particle.position)
                        }
                    }
                    .frame(height: 150)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            screenSize = CGSize(width: 400, height: 800)
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 生成粒子
        for _ in 0..<20 {
            particles.append(EventParticle(
                position: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2),
                size: CGFloat.random(in: 3...10),
                color: animation.color,
                opacity: 1.0,
                scale: 1.0
            ))
        }
        
        // 显示动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animation.showProgress = 1.0
        }
        
        // 粒子扩散
        withAnimation(.easeOut(duration: 1.5)) {
            for index in particles.indices {
                let angle = Double(index) * (2 * .pi / Double(particles.count))
                let distance: CGFloat = 150
                particles[index].position.x += CGFloat(cos(angle) * distance)
                particles[index].position.y += CGFloat(sin(angle) * distance)
                particles[index].opacity = 0.0
                particles[index].scale = 0.0
            }
        }
        
        // 完成回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }
}

#Preview {
    ContentView()
}

// 死亡界面
struct DeathView: View {
    @ObservedObject var pet: Pet
    let onRebirth: () -> Void
    let onReset: () -> Void
    
    @State private var showingTraits = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 死亡原因图标
                ZStack {
                    Circle()
                        .fill(pet.deathCause?.color.opacity(0.2) ?? .gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: pet.deathCause?.icon ?? "heart.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(pet.deathCause?.color ?? .gray)
                }
                
                // 死亡信息
                VStack(spacing: 15) {
                    Text(pet.deathCause == .oldAge ? "寿终正寝" : "宠物离开了")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("死因：\(pet.deathCause?.rawValue ?? "未知")")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if pet.deathCause == .oldAge {
                        Text("感谢你的细心照料！")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                
                // 生命统计
                VStack(spacing: 10) {
                    StatRow(title: "生存天数", value: pet.age)
                    StatRow(title: "第 \(pet.generation) 代", value: 0)
                    StatRow(title: "最终等级", value: pet.level)
                    StatRow(title: "进化阶段", value: EvolutionStage.allCases.firstIndex(of: pet.evolutionStage) ?? 0)
                    StatRow(title: "最终亲密度", value: pet.intimacy)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                )
                
                // 传承特质
                if !pet.unlockedTraits.isEmpty {
                    VStack(spacing: 10) {
                        Button(action: {
                            showingTraits.toggle()
                        }) {
                            HStack {
                                Text("已解锁 \(pet.unlockedTraits.count) 个特质")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.3))
                    )
                }
                
                // 操作按钮
                VStack(spacing: 15) {
                    if pet.deathCause == .oldAge {
                        Button(action: onRebirth) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white)
                                Text("培养下一代")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: onReset) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("重新开始")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingTraits) {
            TraitsView(traits: pet.unlockedTraits)
        }
    }
}

// 特质展示视图
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

// 特质卡片
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