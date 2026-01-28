# VirtualPet Skill Documentation

## Overview

The VirtualPet skill is a comprehensive tool for creating and managing virtual pet applications for iOS using SwiftUI. This skill provides a complete framework for building interactive virtual pet applications with features like pet care, achievements, animations, and data persistence.

## Installation

### Prerequisites
- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.0

### Setup
1. Clone the skill repository:
```bash
git clone https://github.com/virtualpet-studio/virtual-pet-skill.git
cd virtual-pet-skill
```

2. Make the skill executable:
```bash
chmod +x virtual-pet/skill.js
chmod +x virtual-pet/skill.py
```

## Quick Start

### Creating a New Project

Using JavaScript version:
```bash
node skills/virtual-pet/skill.js create --project-name MyPet --pet-type dog
```

Using Python version:
```bash
python skills/virtual-pet/skill.py create --project-name MyPet --pet-type dog
```

### Basic Usage

```bash
# List available skills
node skills/virtual-pet/skill.js list

# Create project with custom settings
node skills/virtual-pet/skill.js create \
  --project-name MyPet \
  --pet-type rabbit \
  --bundle-id com.mycompany.mypet \
  --deployment-target 17.0

# Add features to existing project
node skills/virtual-pet/skill.js add \
  --project-dir ./MyPet \
  --pet-type hamster

# Customize pet settings
node skills/virtual-pet/skill.js customize \
  --project-dir ./MyPet \
  --initial-stats hunger:30,happiness:70,health:80,energy:90
```

## Configuration

### Project Configuration

The VirtualPet skill supports various configuration options:

| Option | Description | Default |
|--------|-------------|---------|
| `--project-name` | Name of the iOS project | "VirtualPet" |
| `--pet-type` | Pet type: cat, dog, rabbit, hamster, bird | "cat" |
| `--bundle-id` | Bundle identifier for the app | "com.example.virtualpet" |
| `--deployment-target` | iOS deployment target | "17.0" |
| `--no-achievements` | Disable achievement system | false |
| `--no-animations` | Disable animations | false |
| `--no-persistence` | Disable data persistence | false |
| `--no-activity-log` | Disable activity logging | false |

### Pet Types

Available pet types with their colors:

- **cat (🐱)**: Orange
- **dog (🐶)**: Brown
- **rabbit (🐰)**: Pink
- **hamster (🐹)**: Yellow
- **bird (🐦)**: Blue

### Pet Statistics

All pet stats range from 0-100:

- **Hunger**: Decreases over time, increased by feeding
- **Happiness**: Increases with positive interactions, decreases over time
- **Health**: Affected by cleanliness and care
- **Energy**: Decreases with activities, recovers over time

## Commands

### Create Project

Creates a new VirtualPet iOS project.

```bash
node skills/virtual-pet/skill.js create [options]
```

Options:
- `--project-dir <path>`: Project directory (default: current directory)
- `--project-name <name>`: Project name (default: "VirtualPet")
- `--pet-type <type>`: Pet type (default: "cat")
- `--bundle-id <id>`: Bundle identifier (default: "com.example.virtualpet")
- `--deployment-target <version>`: iOS deployment target (default: "17.0")

### Add Features

Adds pet features to an existing project.

```bash
node skills/virtual-pet/skill.js add [options]
```

Options:
- `--project-dir <path>`: Project directory (default: current directory)
- `--pet-type <type>`: Pet type to set
- `--no-achievements`: Disable achievement system
- `--no-animations`: Disable animations

### Customize Pet

Customizes pet settings and behavior.

```bash
node skills/virtual-pet/skill.py customize [options]
```

Options:
- `--project-dir <path>`: Project directory (default: current directory)
- `--initial-stats`: Initial stats in format `hunger:30,happiness:70,health:80,energy:90`
- `--interaction-effects`: Custom interaction effects in format `play:happiness:15,energy:-10`

## Features

### Core Features

1. **Pet Management**
   - Multiple pet types with unique colors
   - Dynamic mood system based on stats
   - Level progression with experience points
   - Automatic stat decay over time

2. **Interaction System**
   - Feed: Decreases hunger, increases happiness
   - Play: Increases happiness, decreases energy
   - Clean: Increases health and happiness
   - Exercise: Increases health, decreases energy, increases hunger
   - Cuddle: Increases happiness and health, decreases energy

3. **Achievement System**
   - First interaction achievement
   - Foodie achievement (feed 10 times)
   - Happy pet achievement (max happiness)
   - Healthy pet achievement (7-day health streak)

4. **Data Persistence**
   - UserDefaults for pet stats
   - Activity history (last 100 activities)
   - Stats history for analytics
   - Achievement tracking

5. **Visual Features**
   - Smooth animations for interactions
   - Particle effects for visual feedback
   - Dynamic color changes based on pet type
   - Mood indicators and expressions

### Advanced Features

1. **Template System**
   - Code generation templates
   - Customizable pet models
   - Flexible view components
   - Asset catalog templates

2. **Configuration Management**
   - JSON and YAML configuration support
   - Default settings override
   - Custom parameter validation
   - Environment-specific configurations

3. **Extensibility**
   - Modular architecture
   - Custom interaction types
   - Additional achievement conditions
   - Custom visual effects

## File Structure

Generated project structure:

```
{{project_name}}/
├── {{project_name}}/               # Main app source code
│   ├── {{project_name}}App.swift   # App entry point
│   ├── ContentView.swift           # Main UI view
│   ├── Pet.swift                   # Core pet model and logic
│   └── Item.swift                  # SwiftData model
├── {{project_name}}Tests/           # Unit tests
├── {{project_name}}UITests/         # UI tests
├── Assets.xcassets/                 # App assets
│   ├── AppIcon.appiconset/
│   ├── AccentColor.colorset/
│   └── Contents.json
├── Info.plist                       # App configuration
└── README.md                        # Project documentation
```

## API Reference

### Pet Class

The main class for managing virtual pet state and behavior.

#### Properties

```swift
@Published var hunger: Int        // 0-100, decreases over time
@Published var happiness: Int     // 0-100, affected by interactions
@Published var health: Int       // 0-100, affected by care
@Published var energy: Int       // 0-100, decreases with activities
@Published var age: Int          // Pet age in days
@Published var experience: Int  // Experience points
@Published var level: Int        // Current level
@Published var mood: PetMood     // Current mood state
@Published var petType: PetType  // Type of pet
// ... more properties
```

#### Methods

```swift
// Initialize pet with custom stats
init(hunger: Int = 50, happiness: Int = 50, health: Int = 100, energy: Int = 100)

// Interact with pet
func interact(type: InteractionType)

// Update pet mood
func updateMood()

// Check for level up
func checkLevelUp()

// Automatic stat decay
func decay()

// Save data to UserDefaults
func saveData()

// Load data from UserDefaults
static func loadData() -> Pet
```

### Interaction Types

```swift
enum InteractionType {
    case play     // Play with pet
    case feed     // Feed pet
    case clean    // Clean pet
    case exercise // Exercise with pet
    case cuddle   // Cuddle pet
}
```

### Pet Types

```swift
enum PetType: String, CaseIterable {
    case cat = "🐱"      // Orange color
    case dog = "🐶"      // Brown color
    case rabbit = "🐰"   // Pink color
    case hamster = "🐹" // Yellow color
    case bird = "🐦"    // Blue color
}
```

### Pet Moods

```swift
enum PetMood: String, CaseIterable {
    case happy = "开心"     // High happiness
    case normal = "正常"    // Balanced stats
    case hungry = "饥饿"    // High hunger
    case sad = "伤心"      // Low happiness
    case sick = "生病"     // Low health
    case excited = "兴奋"   // High happiness and energy
    case sleepy = "困倦"   // Low energy
}
```

## Examples

### Example 1: Basic Project Creation

```bash
# Create a basic VirtualPet project
node skills/virtual-pet/skill.js create --project-name MyPet

# Create with dog pet type
node skills/virtual-pet/skill.js create --project-name DogPet --pet-type dog

# Create with custom bundle identifier
node skills/virtual-pet/skill.js create \
  --project-name CompanyPet \
  --bundle-id com.mycompany.virtualpet \
  --deployment-target 17.5
```

### Example 2: Customizing Pet Settings

```python
# Using Python to customize initial stats
python skills/virtual-pet/skill.py customize \
  --project-dir ./MyPet \
  --initial-stats hunger:40,happiness:60,health:85,energy:75

# Using Python to customize interaction effects
python skills/virtual-pet/skill.py customize \
  --project-dir ./MyPet \
  --interaction-effects play:happiness:20,energy:-5,feed:hunger:-30,happiness:10
```

### Example 3: Adding Features to Existing Project

```javascript
// Add features with JavaScript
node skills/virtual-pet/skill.js add \
  --project-dir ./ExistingApp \
  --pet-type rabbit \
  --no-achievements
```

## Troubleshooting

### Common Issues

1. **Xcode Project Creation Fails**
   - Ensure Xcode command line tools are installed
   - Check write permissions in project directory
   - Verify deployment target compatibility

2. **Build Errors**
   - Check iOS deployment target in Xcode
   - Verify Swift version compatibility
   - Ensure all required frameworks are linked

3. **Pet Data Not Persisting**
   - Check UserDefaults access permissions
   - Verify correct key names in Pet class
   - Test on actual device if issues persist on simulator

### Debug Tips

1. Enable logging in skill scripts:
```javascript
// Add before running commands
process.env.DEBUG = 'virtual-pet:*';
```

2. Check generated files:
```bash
ls -la {{project_name}}/
cat {{project_name}}/Pet.swift | head -20
```

3. Test with minimal configuration:
```bash
node skills/virtual-pet/skill.js create --project-name TestPet --no-achievements
```

## Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

### Code Style

- Follow Swift coding conventions
- Use meaningful variable names
- Add comments for complex logic
- Include unit tests for new features

### Bug Reports

When reporting bugs, please include:
1. Skill version
2. Command used
3. Error message
4. Steps to reproduce
5. Expected vs actual behavior

## License

This skill is licensed under the MIT License. See LICENSE file for details.

## Support

- GitHub Issues: https://github.com/virtualpet-studio/virtual-pet-skill/issues
- Documentation: https://virtualpet.studio/docs
- Email: support@virtualpet.studio

---

For more information and updates, visit the [VirtualPet Studio website](https://virtualpet.studio).