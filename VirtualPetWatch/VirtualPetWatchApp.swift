import SwiftUI

@main
struct VirtualPetWatchApp: App {
    @StateObject private var companion = CompanionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(companion)
        }
    }
}
