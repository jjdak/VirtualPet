# VirtualPet Skill Examples

## Overview

This document provides practical examples of using the VirtualPet skill for various scenarios. Examples cover JavaScript and Python implementations, from basic project creation to advanced customization.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Project Creation Examples](#project-creation-examples)
3. [Feature Addition Examples](#feature-addition-examples)
4. [Customization Examples](#customization-examples)
5. [Advanced Scenarios](#advanced-scenarios)
6. [Integration Examples](#integration-examples)

## Basic Usage

### Example 1: Listing Available Skills

**JavaScript:**
```bash
node skills/virtual-pet/skill.js list
```

**Python:**
```bash
python skills/virtual-pet/skill.py list
```

**Output:**
```
Available Skills:
================
virtual-pet v1.0.0
  Virtual pet management skill for creating and managing virtual pets in iOS applications
  by VirtualPet Studio
```

### Example 2: Show Help

**JavaScript:**
```bash
node skills/virtual-pet/skill.js help
```

**Python:**
```bash
python skills/virtual-pet/skill.py help
```

## Project Creation Examples

### Example 1: Basic Project Creation

Create a simple VirtualPet project with default settings.

```bash
# JavaScript version
node skills/virtual-pet/skill.js create

# Python version
python skills/virtual-pet/skill.py create
```

This creates a project named "VirtualPet" with a cat pet type.

### Example 2: Project with Custom Pet Type

Create a project with a dog pet type.

```bash
# JavaScript
node skills/virtual-pet/skill.js create --project-name DogPet --pet-type dog

# Python
python skills/virtual-pet/skill.py create --project-name DogPet --pet-type dog
```

### Example 3: Complete Project Configuration

Create a fully configured project with all options.

```bash
# JavaScript
node skills/virtual-pet/skill.js create \
  --project-name CompletePet \
  --pet-type rabbit \
  --bundle-id com.mycompany.completepet \
  --deployment-target 17.5 \
  --include-achievements \
  --include-animations \
  --include-data-persistence \
  --include-activity-log

# Python
python skills/virtual-pet/skill.py create \
  --project-name CompletePet \
  --pet-type rabbit \
  --bundle-id com.mycompany.completepet \
  --deployment-target 17.5 \
  --include-achievements \
  --include-animations \
  --include-data-persistence \
  --include-activity-log
```

### Example 4: Project Creation in Specific Directory

Create a project in a specific directory path.

```bash
# JavaScript
node skills/virtual-pet/skill.js create --project-dir ~/Projects --project-name MyHamsterPet --pet-type hamster

# Python
python skills/virtual-pet/skill.py create --project-dir ~/Projects --project-name MyHamsterPet --pet-type hamster
```

### Example 5: Minimal Configuration

Create a project with minimal features disabled.

```bash
# JavaScript
node skills/virtual-pet/skill.js create \
  --project-name MinimalPet \
  --pet-type bird \
  --no-achievements \
  --no-animations

# Python
python skills/virtual-pet/skill.py create \
  --project-name MinimalPet \
  --pet-type bird \
  --no-achievements \
  --no-animations
```

## Feature Addition Examples

### Example 1: Add Features to Existing Project

Add pet features to an existing project.

```bash
# JavaScript
node skills/virtual-pet/skill.js add \
  --project-dir ~/Projects/MyPet \
  --pet-type cat \
  --include-achievements

# Python
python skills/virtual-pet/skill.py add \
  --project-dir ~/Projects/MyPet \
  --pet-type cat \
  --include-achievements
```

### Example 2: Change Pet Type

Change the pet type of an existing project.

```bash
# JavaScript
node skills/virtual-pet/skill.js add \
  --project-dir ~/Projects/DogPet \
  --pet-type rabbit

# Python
python skills/virtual-pet/skill.py add \
  --project-dir ~/Projects/DogPet \
  --pet-type rabbit
```

### Example 3: Add Features without Achievements

Add features but disable the achievement system.

```bash
# JavaScript
node skills/virtual-pet/skill.js add \
  --project-dir ~/Projects/BirdPet \
  --no-achievements

# Python
python skills/virtual-pet/skill.py add \
  --project-dir ~/Projects/BirdPet \
  --no-achievements
```

## Customization Examples

### Example 1: Customize Initial Stats

Set custom initial pet statistics.

```bash
# Using Python for customization
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --initial-stats hunger:40,happiness:60,health:85,energy:75
```

This sets:
- Hunger: 40 (below average, pet will be hungry)
- Happiness: 60 (average)
- Health: 85 (good health)
- Energy: 75 (good energy)

### Example 2: Customize Interaction Effects

Modify how interactions affect pet stats.

```bash
# Python - Enhanced play interaction
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --interaction-effects play:happiness:25,energy:-5,experience:10

# Python - Balanced feeding
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --interaction-effects feed:hunger:-35,happiness:8,experience:5
```

### Example 3: Multiple Customizations

Combine initial stats and interaction effects.

```python
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --initial-stats hunger:30,happiness:50,health:90,energy:80 \
  --interaction-effects \
    play:happiness:20,energy:-5,experience:8 \
    feed:hunger:-30,happiness:10,experience:3 \
    clean:health:20,happiness:5,experience:2 \
    exercise:health:15,hunger:20,energy:-25,experience:12 \
    cuddle:happiness:30,health:10,energy:-10,experience:6
```

### Example 4: JavaScript Customization

Customize pet settings using JavaScript.

```javascript
// Create a custom pet configuration
const skill = require('./skill.js');

const customizations = {
  initialStats: {
    hunger: 25,
    happiness: 75,
    health: 95,
    energy: 85
  },
  interactionEffects: {
    play: {
      happiness: 30,
      energy: -3,
      experience: 15
    },
    feed: {
      hunger: -40,
      happiness: 15
    }
  }
};

skill.customizePet('./MyPet', customizations);
```

### Example 5: Gradual Customization

Apply customizations in stages.

```bash
# Step 1: Set initial poor health
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --initial-stats health:50

# Step 2: Add positive interactions
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --interaction-effects clean:health:30,happiness:10

# Step 3: Balance gameplay
python skills/virtual-pet/skill.py customize \
  --project-dir ~/Projects/MyPet \
  --interaction-effects exercise:health:20,hunger:25,energy:-30
```

## Advanced Scenarios

### Example 1: Create Multiple Projects with Different Pets

Create a collection of different pet projects.

```bash
# Create all pet types
for pet in cat dog rabbit hamster bird; do
  node skills/virtual-pet/skill.js create \
    --project-name ${pet}Pet \
    --pet-type ${pet} \
    --bundle-id com.mycompany.${pet}pet
done

# Or using Python
pets=("cat" "dog" "rabbit" "hamster" "bird")
for pet in "${pets[@]}"; do
  python skills/virtual-pet/skill.py create \
    --project-name ${pet}Pet \
    --pet-type ${pet} \
    --bundle-id com.mycompany.${pet}pet
done
```

### Example 2: Template-based Development

Create a template system for rapid prototyping.

```bash
# Create a template project
node skills/virtual-pet/skill.js create \
  --project-name PetTemplate \
  --pet-type cat \
  --no-achievements

# Customize the template
python skills/virtual-pet/skill.py customize \
  --project-dir ./PetTemplate \
  --initial-stats hunger:50,happiness:50,health:50,energy:50 \
  --interaction-effects \
    play:happiness:15,energy:-10,experience:5 \
    feed:hunger:-25,happiness:5,experience:3

# Copy template for new projects
cp -r PetTemplate/ ./NewPetProject
```

### Example 3: Multi-environment Setup

Setup different project configurations for different environments.

```bash
# Development environment - easier gameplay
node skills/virtual-pet/skill.js create \
  --project-name DevPet \
  --pet-type cat \
  --bundle-id com.company.devpet \
  --initial-stats hunger:80,happiness:80,health:100,energy:100

# Production environment - balanced gameplay
node skills/virtual-pet/skill.js create \
  --project-name ProdPet \
  --pet-type dog \
  --bundle-id com.company.prodpet \
  --initial-stats hunger:50,happiness:50,health:100,energy:100

# Testing environment - strict gameplay
node skills/virtual-pet/skill.js create \
  --project-name TestPet \
  --pet-type rabbit \
  --bundle-id com.company.testpet \
  --initial-stats hunger:30,happiness:30,health:80,energy:80
```

### Example 4: Custom Pet Behavior Mod

Create a mod with custom pet behavior.

```bash
# Create base project
node skills/virtual-pet/skill.js create \
  --project-name PetMod \
  --pet-type hamster

# Apply custom behavior
python skills/virtual-pet/skill.py customize \
  --project-dir ./PetMod \
  --initial-stats hunger:60,happiness:40,health:70,energy:90 \
  --interaction-effects \
    play:happiness:20,energy:-5,experience:10 \
    feed:hunger:-40,happiness:15,health:5,experience:5 \
    clean:health:25,happiness:10,energy:0,experience:3 \
    exercise:health:10,hunger:30,energy:-20,experience:15 \
    cuddle:happiness:35,health:15,energy:-5,experience:8
```

## Integration Examples

### Example 1: CI/CD Integration

Integrate VirtualPet creation into a CI/CD pipeline.

```yaml
# GitHub Actions example
name: Create VirtualPet Project

on:
  push:
    branches: [ main ]

jobs:
  create-project:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v2

    - name: Create VirtualPet project
      run: |
        python skills/virtual-pet/skill.py create \
          --project-name CI-Pet \
          --pet-type dog \
          --bundle-id com.company.cipet \
          --include-achievements \
          --include-animations

    - name: Verify project structure
      run: |
        ls -la CI-Pet/
        test -f CI-Pet/CI-Pet/Pet.swift
        test -f CI-Pet/CI-Pet/ContentView.swift
```

### Example 2: Build Script Integration

Create a build script that manages VirtualPet projects.

```bash
#!/bin/bash
# build-pet.sh

PROJECT_NAME=$1
PET_TYPE=${2:-cat}
BUNDLE_ID="com.mystudio.${PROJECT_NAME,,}"

echo "Building VirtualPet project: $PROJECT_NAME"

# Create project
python skills/virtual-pet/skill.py create \
  --project-name "$PROJECT_NAME" \
  --pet-type "$PET_TYPE" \
  --bundle-id "$BUNDLE_ID" \
  --include-achievements

# Build project
cd "$PROJECT_NAME"
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
  -scheme "$PROJECT_NAME" \
  -configuration Release \
  build

echo "Build complete: $PROJECT_NAME"
```

Usage:
```bash
./build-pet.sh MyApp dog
./build-pet.sh KittyApp cat
./build-pet.sh BirdApp bird
```

### Example 3: Plugin Integration

Integrate VirtualPet into an existing iOS app as a plugin.

```bash
# Create VirtualPet component
node skills/virtual-pet/skill.js create \
  --project-name VirtualPetPlugin \
  --pet-type cat \
  --bundle-id com.myapp.virtualpet \
  --no-achievements

# Copy plugin to main project
cp -r VirtualPetPlugin/VirtualPet ./MyApp/Plugins/

# Update Xcode project structure
# (Manual step needed to add files to Xcode)
```

### Example 4: Team Development Setup

Setup consistent development environment for the team.

```bash
# Create shared configuration
cat > pet-config.json << EOF
{
  "project_name": "TeamPet",
  "pet_type": "dog",
  "bundle_id": "com.team.pet",
  "deployment_target": "17.0",
  "include_achievements": true,
  "include_animations": true,
  "initial_stats": {
    "hunger": 50,
    "happiness": 50,
    "health": 100,
    "energy": 100
  }
}
EOF

# Create team project from config
python skills/virtual-pet/skill.py create \
  --project-name TeamPet \
  --pet-type dog \
  --bundle-id com.team.pet \
  --include-achievements \
  --include-animations

# Apply team customization
python skills/virtual-pet/skill.py customize \
  --project-dir ./TeamPet \
  --initial-stats hunger:50,happiness:50,health:100,energy:100
```

### Example 5: Asset Management Integration

Generate and manage assets for multiple pet types.

```bash
# Create projects for all pet types
for pet in cat dog rabbit hamster bird; do
  node skills/virtual-pet/script.js create \
    --project-name ${pet}PetAssets \
    --pet-type ${pet} \
    --bundle-id com.assets.${pet}pet

  # Generate custom assets for each pet
  mkdir -p ${pet}PetAssets/Assets.xcassets/${pet}Color.colorset
done

# Create asset manifest
cat > asset-manifest.json << EOF
{
  "pets": {
    "cat": {
      "color": "orange",
      "emoji": "🐱",
      "primary_color": "#FFA500"
    },
    "dog": {
      "color": "brown",
      "emoji": "🐶",
      "primary_color": "#8B4513"
    },
    "rabbit": {
      "color": "pink",
      "emoji": "🐰",
      "primary_color": "#FFC0CB"
    },
    "hamster": {
      "color": "yellow",
      "emoji": "🐹",
      "primary_color": "#FFD700"
    },
    "bird": {
      "color": "blue",
      "emoji": "🐦",
      "primary_color": "#4169E1"
    }
  }
}
EOF
```

## Testing Examples

### Example 1: Unit Testing Setup

Create test cases for pet behavior.

```swift
// PetTests.swift
import XCTest
@testable import VirtualPet

class PetTests: XCTestCase {

    var pet: Pet!

    override func setUp() {
        super.setUp()
        pet = Pet()
    }

    override func tearDown() {
        pet = nil
        super.tearDown()
    }

    func testFeed() {
        let initialHunger = pet.hunger
        pet.interact(type: .feed)

        XCTAssertLessThan(pet.hunger, initialHunger)
        XCTAssertGreaterThan(pet.happiness, 50)
    }

    func testPlay() {
        let initialEnergy = pet.energy
        pet.interact(type: .play)

        XCTAssertLessThan(pet.energy, initialEnergy)
        XCTAssertGreaterThan(pet.happiness, 50)
    }

    func testLevelUp() {
        // Add enough experience to level up
        pet.experience = pet.level * 100 - 1
        let initialLevel = pet.level
        pet.interact(type: .play)

        XCTAssertEqual(pet.level, initialLevel + 1)
        XCTAssertEqual(pet.experience, 0)
    }
}
```

### Example 2: UI Testing

Create UI tests for interaction buttons.

```swift
// VirtualPetUITests.swift
import XCTest

class VirtualPetUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testFeedButton() {
        let feedButton = app.buttons["喂养"]
        XCTAssertTrue(feedButton.exists)
        feedButton.tap()

        // Check that pet state changes
        let happinessLabel = app.staticTexts["快乐"]
        XCTAssertTrue(happinessLabel.exists)
    }

    func testPlayButton() {
        let playButton = app.buttons["玩耍"]
        XCTAssertTrue(playButton.exists)
        playButton.tap()

        // Check energy decreases
        let energyLabel = app.staticTexts["能量"]
        XCTAssertTrue(energyLabel.exists)
    }
}
```

## Performance Examples

### Example 1: Performance Testing

Test project creation performance.

```bash
#!/bin/bash
# performance-test.sh

echo "Starting performance test..."

# Time project creation
start_time=$(date +%s.%N)

node skills/virtual-pet/skill.js create \
  --project-name PerfTest \
  --pet-type cat \
  --no-achievements

end_time=$(date +%s.%N)

duration=$(echo "$end_time - $start_time" | bc)
echo "Project creation took: ${duration} seconds"

# Clean up
rm -rf PerfTest
```

### Example 2: Memory Usage Analysis

Analyze memory usage during pet interactions.

```swift
// MemoryUsageTest.swift
import XCTest
import SwiftUI

class MemoryUsageTest: XCTestCase {

    func testPetMemoryUsage() {
        let pet = Pet()
        let initialMemory = measureMemoryUsage {
            pet
        }

        // Perform many interactions
        for _ in 0...1000 {
            pet.interact(type: .play)
        }

        let finalMemory = measureMemoryUsage {
            pet
        }

        let memoryIncrease = finalMemory - initialMemory
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024) // Less than 10MB
    }

    private func measureMemoryUsage<T>(closure: () -> T) -> UInt64 {
        // Memory measurement implementation
        // This would use system APIs to measure memory usage
        return 0
    }
}
```

## Example Output

### Example 1: Successful Project Creation

```
Creating VirtualPet project: MyPet
Project directory: /Users/developer/MyPet
Pet type: dog
✅ VirtualPet project created successfully!

Next steps:
  cd /Users/developer/MyPet
  open MyPet.xcodeproj
  or xcodebuild -project MyPet.xcodeproj -scheme MyPet build
```

### Example 2: Customization Example

```
Customizing pet for: /Users/developer/MyPet
✅ Pet customized successfully
```

### Example 3: Error Handling

```
Error: Project directory already exists: /Users/developer/MyPet
```

## Best Practices

1. **Version Control**: Keep skill configurations in version control
2. **Environment Setup**: Use consistent development environments
3. **Testing**: Always test project creation and functionality
4. **Documentation**: Document custom pet behaviors and settings
5. **Backup**: Keep backups of original project files before customization

These examples provide a comprehensive guide for using the VirtualPet skill in various scenarios. Adapt them to your specific needs and development workflow.