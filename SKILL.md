# VirtualPet Coding Patterns

This skill captures the coding patterns, conventions, and development practices observed in the VirtualPet iOS application repository.

## Repository Overview

**VirtualPet** is a modern iOS virtual pet application built with SwiftUI and Swift 5.0, featuring a comprehensive pet simulation system with mood tracking, achievements, level progression, and rich visual animations.

## Project Structure

```
VirtualPet/
├── VirtualPet.xcodeproj/          # Xcode project configuration
├── VirtualPet/
│   ├── VirtualPetApp.swift         # App entry point (minimal)
│   ├── ContentView.swift           # Main UI composition (2,170 lines)
│   ├── Pet.swift                   # Core business logic (1,488 lines)
│   └── Item.swift                  # Legacy placeholder
├── VirtualPetTests/                # Unit tests (placeholder)
└── VirtualPetUITests/              # UI tests (placeholder)

skills/virtual-pet/                # Skill generation system
├── skill.js                        # Node.js skill implementation
├── skill.py                       # Python skill implementation
├── skill.yaml                     # Skill configuration
├── templates/                     # Code templates
└── docs/                          # Documentation
```

## Coding Patterns

### 1. Architecture Patterns

**MVVM Architecture**
- **View Layer**: SwiftUI views using `@StateObject` and `@Binding`
- **ViewModel/Model**: `Pet` class inherits from `ObservableObject`
- **Data Flow**: One-way data binding with reactive updates
- **Decoupling**: Clear separation between UI and business logic

**Event-Driven Architecture**
- User interactions trigger `interact()` method
- Activities are logged with timestamps
- Achievement system checks on interactions
- Timer-based automatic stat decay

### 2. State Management

**SwiftUI Reactive State**
```swift
@Published var hunger: Int = 50
@Published var happiness: Int = 50
@Published var health: Int = 50
@Published var energy: Int = 50
@Published var level: Int = 1
@Published var experience: Int = 0
@Published var age: TimeInterval = 0
```

**Timer Management**
- Automatic stat decay using `Timer.publish`
- Cleanup in `onDisappear` to prevent memory leaks
- One-minute intervals for realistic pet simulation

### 3. Core Business Logic Patterns

**Pet Interaction System**
- Single `interact()` method handling all interaction types
- Stats are updated simultaneously with proper ranges (0-100)
- Experience calculation: `experience += 10 + level * 5`
- Level progression: `level * 100` experience per level

**Mood Calculation**
```swift
var mood: PetMood {
    let average = (hunger + happiness + health + energy) / 4
    switch average {
    case 80...100: return .happy
    case 60...79: return .normal
    case 40...59: return .hungry
    case 20...39: return .sad
    case 10...19: return .sick
    case 1...9: return .sleepy
    default: return .sad
    }
}
```

### 4. UI Composition Patterns

**Modular View Composition**
```swift
struct ContentView: View {
    @StateObject private var pet = Pet()

    var body: some View {
        VStack(spacing: 20) {
            PetHeaderView(pet: pet)
            PetDisplayView(pet: pet)
            StatusGridView(pet: pet)
            InteractionButtonsView(pet: pet)
            PetTypeSelector(pet: pet)
            QuickStatsView(pet: pet)
            ActivityLogView(pet: pet)
            AchievementsView(pet: pet)
        }
        .onAppear { pet.startTimer() }
        .onDisappear { pet.stopTimer() }
    }
}
```

**Conditional Styling**
- Dynamic background gradients based on mood
- Emoji-based pet representations
- Progress indicators with custom styling
- Conditional modifiers for different states

### 5. Data Persistence Patterns

**UserDefaults Integration**
```swift
private let defaults = UserDefaults.standard
private static let PetStatsKey = "PetStats"

struct PetStats: Codable {
    let hunger: Int
    let happiness: Int
    let health: Int
    let energy: Int
    let level: Int
    let experience: Int
    let age: TimeInterval
}

func save() {
    let stats = PetStats(hunger: hunger, happiness: happiness, ...)
    let data = try? JSONEncoder().encode(stats)
    defaults.set(data, forKey: Self.PetStatsKey)
}
```

### 6. Animation Patterns

**Spring Animations**
```swift
.animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: pet.hunger)
.transition(.scale.combined(with: .opacity))
```

**Particle Effects**
- Visual feedback for interactions
- Bounce animations on button presses
- Dynamic mood-based visual changes

### 7. Enum and Data Structure Patterns

**Custom Enum with Codable**
```swift
enum PetMood: String, CaseIterable, Codable {
    case happy = "开心"
    case normal = "正常"
    case hungry = "饥饿"
    case sad = "悲伤"
    case sick = "生病"
    case excited = "兴奋"
    case sleepy = "困倦"
}
```

**Type-Safe Configuration**
```swift
struct PetType: CaseIterable {
    case dog, cat, rabbit, hamster, bird

    var emoji: String {
        switch self {
        case .dog: return "🐶"
        case .cat: return "🐱"
        case .rabbit: return "🐰"
        case .hamster: return "🐹"
        case .bird: return "🐦"
        }
    }
}
```

## Git Commit Patterns

### Commit Message Format
- **Simple, descriptive messages**: "runable demo.", "fix.", "add."
- **No conventional commit prefixes** (feat:, fix:, etc.)
- **Direct action descriptions** rather than explanations
- **Occasional punctuation** (commits with periods at the end)

### Commit Frequency
- **High initial activity**: 10 commits in first 3 days
- **Recent development**: Active commits on Feb 9-10, 2026
- **Sustained effort**: Regular commits over 15-day period

### File Change Patterns
- **Core files changed together**: `ContentView.swift` and `Pet.swift` always modified together
- **Large commits**: Up to 1,317 insertions in single commit
- **User state files**: Frequent `.DS_Store` and `.xcuserstate` changes
- **Skill development**: Large commit adding skills directory (5,594 insertions)

### Branch Strategy
- **Single main branch**: No feature branches or pull requests
- **Direct commits**: All changes made directly to main
- **No merge conflicts**: Linear commit history

## Testing Patterns

### Current Testing Structure
- **Placeholder tests**: Basic XCTest structure with minimal implementation
- **Launch performance test**: `VirtualPetUITestsLaunchTests`
- **No unit test coverage**: Test files contain only boilerplate

### Testing Gaps
- **No unit tests** for core Pet class logic
- **No integration tests** for UI interactions
- **No automated UI tests** for user flows
- **No performance testing** for timer-based operations

## Build and Development Patterns

### Xcode Configuration
- **iOS Deployment Target**: 26.2 (very latest)
- **Swift Version**: 5.0
- **Standard schemes**: Debug/Release configurations
- **Universal deployment**: iOS, macOS, visionOS

### Development Commands
```bash
# Build pattern
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# Simulator pattern
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build

# Testing pattern
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

## Code Quality Patterns

### File Size Guidelines
- **Core files**: 1,488-2,170 lines (larger than ideal)
- **Target size**: Should be under 800 lines per file
- **Refactoring needed**: Split large files into logical modules

### Naming Conventions
- **Descriptive names**: `PetMood`, `InteractionButtonsView`
- **Swift UI patterns**: `ContentView`, `VirtualPetApp`
- **Clear separation**: Business logic vs UI logic

### Error Handling
- **Graceful degradation**: Stats clamped to 0-100 range
- **User-friendly messages**: Chinese interface with emoji
- **No crash-prone operations**: Safe dictionary access, optional binding

## Performance Patterns

### Memory Management
- **Timer cleanup**: Proper `onDisappear` cleanup
- **State management**: SwiftUI's automatic memory handling
- **No retained cycles**: Weak/unowned where appropriate

### UI Performance
- **Efficient re-rendering**: SwiftUI's view diffing
- **Lazy loading**: Not yet implemented
- **Image caching**: Basic Assets.xcassets usage

## Internationalization Patterns

### Language Support
- **Primary language**: Chinese (Simplified)
- **Emoji-based UI**: Cross-cultural visual elements
- **Localized strings**: Hardcoded strings, no localization system

## Best Practices Observed

### Strengths
1. **Modern SwiftUI patterns** - Uses latest iOS features
2. **Clean separation** - Clear MVVM architecture
3. **Comprehensive features** - Rich pet simulation system
4. **Responsive design** - Real-time stat updates
5. **Achievement system** - Engaging progression mechanics

### Areas for Improvement
1. **Testing coverage** - No meaningful tests implemented
2. **File organization** - Large files could be modularized
3. **Documentation** - Limited inline code comments
4. **Code review** - No pull request process
5. **CI/CD** - No automated testing/deployment

## Code Generation Patterns

### Template-based Development
- **Skill system**: Comprehensive code generation tools
- **Parameterized templates**: Customizable pet types and features
- **Multi-language support**: JavaScript, Python, YAML skill definitions
- **Project scaffolding**: Complete iOS project generation

### Template Structure
```swift
// Consistent template patterns
enum PetMood: CaseIterable { ... }
enum PetType: CaseIterable { ... }
class Pet: ObservableObject { ... }
struct ContentView: View { ... }
```

## Conclusion

The VirtualPet project demonstrates strong SwiftUI development practices with a well-structured MVVM architecture. The codebase shows attention to user experience with rich animations and comprehensive game mechanics. However, there are opportunities to improve testing coverage, file organization, and development workflow practices. The skill generation system indicates a sophisticated approach to code reuse and project scaffolding.

This repository serves as an excellent example of modern iOS development with SwiftUI, particularly for educational purposes and as a foundation for more complex iOS applications.