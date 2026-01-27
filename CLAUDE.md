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
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Run on device (replace with actual device ID)
xcodebuild -project VirtualPet.xcodeproj -scheme VirtualPet -configuration Release -destination 'platform=iOS,name=Your iPhone' build
```

### Testing
```bash
# Run unit tests
swift test

# Run unit tests via Xcode
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run UI tests
xcodebuild test -project VirtualPet.xcodeproj -scheme VirtualPet -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
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

**Pet.swift** - Central business logic and data model
- Main `Pet` class inheriting from `ObservableObject`
- Manages all pet state: hunger, happiness, health, energy, age, experience, level
- Handles interactions (play, feed, clean, exercise, cuddle)
- Implements automatic stat decay every minute
- Achievement system with 4 predefined achievements
- Data persistence via UserDefaults

**ContentView.swift** - Main UI composition
- Modular SwiftUI view composed of multiple sub-views:
  - `PetHeaderView`: Pet info display (type, level, age, experience)
  - `PetDisplayView`: Animated pet display with mood-based styling
  - `StatusGridView`: 4 status indicators (hunger, happiness, health, energy)
  - `InteractionButtonsView`: 5 interaction buttons with animations
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

**Achievements**:
- 4 predefined achievements with different unlock conditions
- Activity logging for achievement unlocks
- Achievement progress tracking

### Data Structures

**PetMood Enum**: 7 mood states (happy, normal, hungry, sad, sick, excited, sleepy)
**PetType Enum**: 5 pet types with associated colors
**Activity**: Interaction history with timestamps and values
**PetStatsRecord**: Historical stat tracking for analytics
**Achievement**: Achievement system with unlock conditions

### Visual Features

**Animations**:
- Spring-based animations for interactions
- Particle effects for visual feedback
- Bounce animations on interactions
- Dynamic background gradients based on mood

**UI Components**:
- Modular view composition
- Conditional styling based on pet state
- Custom progress indicators
- Activity log and achievement sheets

### Testing Structure

**VirtualPetTests**: Swift Testing framework placeholder
**VirtualPetUITests**: XCTest framework with launch performance test
Currently contains only placeholder implementations

### Project Configuration

- **iOS Deployment Target**: 26.2 (iOS 26.2)
- **Swift Version**: 5.0
- **Architecture**: Standard Xcode project structure
- **Dependencies**: No external dependencies (uses native Apple frameworks)
- **Data Persistence**: UserDefaults for core stats
- **Build Configuration**: Standard Debug/Release configurations

### Development Notes

- The app uses modern SwiftUI features with minimal UIKit usage
- All pet state is managed through the `Pet` class
- Timer cleanup is handled in `onDisappear`
- Activity history is limited to last 100 entries for performance
- Stats history is recorded every 10 activities
- Chinese language interface with emoji-based pet types