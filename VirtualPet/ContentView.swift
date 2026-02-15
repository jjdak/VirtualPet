import SwiftUI

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var showingActivityLog = false
    @State private var showingAchievements = false
    @State private var showingHelp = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var timer: Timer? = nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationView {
            MainContentView(
                pet: pet,
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
                        Divider()
                        Button(action: { showingHelp = true }) {
                            Label("帮助", systemImage: "questionmark.circle")
                        }
                        Button(action: { showingSettings = true }) {
                            Label("设置", systemImage: "gearshape.fill")
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
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding)
            }
        }
        .onAppear {
            setupTimer()
            // 检查是否需要显示新手引导
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func resetPet() {
        let defaultPet = Pet()
        pet.happiness = defaultPet.happiness
        pet.hunger = defaultPet.hunger
        pet.health = defaultPet.health
        pet.energy = defaultPet.energy
        pet.level = defaultPet.level
        pet.experience = defaultPet.experience
        pet.age = defaultPet.age
        pet.mood = defaultPet.mood
        pet.evolutionStage = defaultPet.evolutionStage
        pet.evolutionPath = defaultPet.evolutionPath
        pet.totalInteractions = defaultPet.totalInteractions
        pet.maxHappiness = defaultPet.maxHappiness
        pet.unlockedAchievements = defaultPet.unlockedAchievements
        pet.activities = defaultPet.activities
        pet.intimacy = defaultPet.intimacy
        pet.luckyEvents = defaultPet.luckyEvents
        pet.specialMoments = defaultPet.specialMoments
        pet.cleanliness = defaultPet.cleanliness
        pet.trainingLevel = defaultPet.trainingLevel
        pet.isAsleep = defaultPet.isAsleep
        pet.sleepTime = defaultPet.sleepTime
        pet.generation = defaultPet.generation
        pet.lifeStage = defaultPet.lifeStage
        pet.isDead = defaultPet.isDead
        pet.deathCause = defaultPet.deathCause
        pet.birthDate = defaultPet.birthDate
        pet.lifeSpan = defaultPet.lifeSpan
        pet.daysUntilDeath = defaultPet.daysUntilDeath
        pet.inheritedTraits = defaultPet.inheritedTraits
        pet.unlockedTraits = defaultPet.unlockedTraits
        pet.legendaryCount = defaultPet.legendaryCount
        pet.feedCount = defaultPet.feedCount
        pet.playCount = defaultPet.playCount
        pet.hugCount = defaultPet.hugCount
        pet.cleanCount = defaultPet.cleanCount
        pet.trainCount = defaultPet.trainCount
        pet.medicalCount = defaultPet.medicalCount
        pet.personality = defaultPet.personality
        pet.favoriteFood = defaultPet.favoriteFood
        pet.favoriteActivity = defaultPet.favoriteActivity
        pet.saveData()
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            pet.decay()
        }
    }
}

struct MainContentView: View {
    @ObservedObject var pet: Pet
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
                    particleEffects: $particleEffects,
                    isAnimating: $isAnimating,
                    intimacyHeartPulse: $intimacyHeartPulse
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
                
                PetTypeSelector(pet: pet)
                
                QuickStatsView(pet: pet)
            }
            .padding()
        }
        .overlay {
            ContentViewOverlays(
                pet: pet,
                errorMessage: $errorMessage,
                showingError: $showingError,
                intimacyHeartPulse: $intimacyHeartPulse,
                onDismissError: {
                    withAnimation {
                        showingError = false
                        errorMessage = nil
                    }
                },
                onRebirth: {
                    _ = pet.rebirth()
                    onReset()
                },
                onReset: onReset
            )
        }
    }
}

struct Particle: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var animationProgress: Double
}

#Preview {
    ContentView()
}
