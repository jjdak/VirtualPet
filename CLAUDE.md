# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VirtualPet is a modern iOS virtual pet application built with SwiftUI and Swift 5.0. The app features a comprehensive pet simulation system with mood tracking, achievements, level progression, and rich visual animations.

## Build and Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build

# Run on simulator
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build

# Run on device (replace with actual device ID)
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### Testing
```bash
# Run unit tests via Xcode
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'

# Run UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

### Linting
```bash
# SwiftLint (if available)
swiftlint lint --strict

# Build-time syntax checking
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug build
```

## Architecture Overview

### Core Components

**Pet.swift** - Central business logic and data model (~1,500 lines)
- Main `Pet` class inheriting from `ObservableObject`
- Manages all pet state: hunger, happiness, health, energy, age, experience, level
- Handles interactions (play, feed, clean, exercise, cuddle)
- Implements automatic stat decay every minute
- Achievement system with 4 predefined achievements
- Data persistence via UserDefaults

**Advanced Systems**:
- **Evolution System**: 7 stages (egg, baby, child, teen, adult, elder, legendary) with 5 evolutionary paths (balanced, strong, happy, healthy, mysterious)
- **Life Cycle**: Aging, death, and rebirth mechanics
- **Trait System**: 12 unlockable traits affecting gameplay (e.g., disease resistance, training efficiency)
- **Random Events**: Dynamic events affecting pet stats (finding items, weather changes, dreams)
- **Intimacy System**: Relationship building with pet through interactions

**Item.swift** - SwiftData model for item system (minimal implementation)

**ContentView.swift** - Main UI composition (~2,200 lines)
- Modular SwiftUI view composed of multiple sub-views:
  - `PetHeaderView`: Pet info display (type, level, age, experience)
  - `PetDisplayView`: Animated pet display with mood-based styling
  - `StatusGridView`: 4 status indicators (hunger, happiness, health, energy)
  - `InteractionButtonsView`: 5 interaction buttons with animations
  - `EvolutionInfoView`: Evolution stage and path display
  - `TraitManagementView`: Trait unlock and management interface
  - `RandomEventView`: Random event display and handling
  - `IntimacyView`: Intimacy level and relationship status
  - `PetTypeSelector`: Pet type switching
  - `QuickStatsView`: Summary statistics
  - `ActivityLogView`: Interaction history
  - `AchievementsView`: Achievement display

**VirtualPetApp.swift** - App entry point
- Standard SwiftUI `@main` app structure
- Simple `WindowGroup` containing `ContentView`

### Key Design Patterns

**MVVM Architecture**:
- View (ContentView) binds to ViewModel/Model (Pet)
- `@StateObject` for Pet instance in ContentView
- `@Published` properties in Pet for reactive updates

**State Management**:
- SwiftUI's reactive state management
- `UserDefaults` for simple persistence
- Timer-based automatic stat decay

**Event-Driven Architecture**:
- User interactions trigger `interact()` method
- Activities are logged with timestamps
- Achievement system checks on interactions

### Core Game Mechanics

**Stat System**:
- All stats range from 0-100
- Automatic decay: hunger +1, happiness -1, energy -2 per minute
- Interactions affect multiple stats simultaneously

**Mood Calculation**:
- 7 mood states based on stat thresholds
- Dynamic mood updates after each interaction
- Visual feedback through UI changes

**Progression System**:
- Experience points from interactions
- Level up every `level * 100` experience
- Level bonuses: +20 health

**Evolution Mechanics**:
- 7 evolution stages: egg → baby → child → teen → adult → elder → legendary
- 5 evolutionary paths with different stat bonuses:
  - Balanced: All stats +5
  - Strong: Health +15, Energy +10
  - Happy: Happiness +15, Hunger -5
  - Healthy: Health +20
  - Mysterious: Random stat bonuses
- Evolution requirements: minimum level + experience for each stage

**Life Cycle**:
- Pet ages over time (every 100 interactions = 1 year)
- Death occurs when health reaches 0 or age exceeds limit
- Rebirth preserves traits and achievements
- Inheritance system for reborn pets

**Trait System**:
- 12 unlockable traits with unique gameplay effects
- Traits unlock at specific levels/achievements
- Examples: Disease Resistance (health decay reduced), Training Efficiency (more XP), Lucky Charm (better random events)
- Active traits can be equipped for gameplay bonuses

**Random Events**:
- Dynamic events occur periodically (finding items, weather changes, dreams)
- Events affect stats and provide gameplay variety
- Visual feedback through event animations and UI

**Intimacy System**:
- Relationship level tracked through positive interactions
- Higher intimacy unlocks special interactions and bonuses
- Affects random event outcomes and evolution choices

**Achievements**:
- 4 predefined achievements with different unlock conditions
- Activity logging for achievement unlocks
- Achievement progress tracking

### Data Structures

**PetMood Enum**: 7 mood states (happy, normal, hungry, sad, sick, excited, sleepy)
**PetType Enum**: 5 pet types with associated colors
**EvolutionStage Enum**: 7 stages (egg, baby, child, teen, adult, elder, legendary)
**EvolutionPath Enum**: 5 paths (balanced, strong, happy, healthy, mysterious)
**Trait Enum**: 12 traits with gameplay modifiers (stored in Pet class)
**Activity**: Interaction history with timestamps and values
**PetStatsRecord**: Historical stat tracking for analytics
**Achievement**: Achievement system with unlock conditions
**RandomEvent**: Dynamic event data with stat effects and display information

### Visual Features

**Animations**:
- Spring-based animations for interactions
- Particle effects for visual feedback (using drawingGroup for performance)
- Bounce animations on interactions
- Dynamic background gradients based on mood
- Evolution animations with particle effects
- Random event animations with visual feedback
- Mood-based pet emoji scaling and rotation

**UI Components**:
- Modular view composition
- Conditional styling based on pet state
- Custom progress indicators
- Activity log and achievement sheets
- Evolution stage indicators
- Trait selection interface
- Intimacy level display

### Testing Structure

**VirtualPetTests**: Swift Testing framework placeholder
**VirtualPetUITests**: XCTest framework with launch performance test
Currently contains only placeholder implementations

### Project Configuration

- **iOS Deployment Target**: 26.2
- **Swift Version**: 5.0
- **Architecture**: Standard Xcode project structure
- **Dependencies**: No external dependencies (uses native Apple frameworks)
- **Data Persistence**: UserDefaults for core stats, JSON encoding for activity history
- **Build Configuration**: Standard Debug/Release configurations
- **Platforms**: iOS 26.2, macOS 26.1, visionOS 26.2

### Development Notes

- The app uses modern SwiftUI features with minimal UIKit usage
- All pet state is managed through the `Pet` class (~1,500 lines of business logic)
- Timer cleanup is handled in `onDisappear`
- Activity history is limited to last 100 entries for performance
- Stats history is recorded every 10 activities
- Chinese language interface with emoji-based pet types
- **Performance optimizations**: drawingGroup for particle effects, lazy loading for history views
- **Extensibility**: Enum-based systems for easy addition of new moods, types, traits, and events
- **Codable conformance**: All custom types support JSON serialization for persistence