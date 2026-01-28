# VirtualPet Skill API Reference

## Overview

The VirtualPet skill provides a comprehensive API for creating and managing virtual pet applications. This document covers the complete API reference for the skill implementation in JavaScript, Python, and Swift.

## Table of Contents

1. [JavaScript API](#javascript-api)
2. [Python API](#python-api)
3. [Swift API](#swift-api)
4. [Configuration API](#configuration-api)
5. [Template API](#template-api)
6. [Error Handling](#error-handling)

## JavaScript API

### VirtualPetSkill Class

The main class for managing virtual pet projects.

```javascript
const VirtualPetSkill = require('./skill.js');
const skill = new VirtualPetSkill();
```

#### Constructor

```javascript
new VirtualPetSkill()
```

Creates a new VirtualPetSkill instance with default settings.

#### Methods

##### `loadConfig(configPath)`

Load skill configuration from JSON or YAML file.

```javascript
try {
  const config = skill.loadConfig('./skill.json');
  console.log('Skill loaded:', config.name);
} catch (error) {
  console.error('Failed to load skill:', error.message);
}
```

**Parameters:**
- `configPath` (string): Path to configuration file

**Returns:** Object - Parsed configuration

**Throws:** Error if configuration file not found or invalid

##### `listSkills()`

List all available skills in the skills directory.

```javascript
const skills = skill.listSkills();
console.log('Available skills:', skills);
```

**Returns:** Array of skill objects

**Example Output:**
```javascript
[
  {
    name: "virtual-pet",
    version: "1.0.0",
    description: "Virtual pet management skill...",
    author: "VirtualPet Studio"
  }
]
```

##### `createProject(options)`

Create a new VirtualPet iOS project.

```javascript
const result = skill.createProject({
  projectDir: './my-projects',
  projectName: 'MyPet',
  petType: 'dog',
  bundleId: 'com.mycompany.mypet',
  deploymentTarget: '17.0',
  includeAchievements: true,
  includeAnimations: true,
  includeDataPersistence: true,
  includeActivityLog: true
});
```

**Parameters:**
- `options` (object): Project configuration options

**Options:**
- `projectDir` (string): Project directory path
- `projectName` (string): Name of the project
- `petType` (string): Pet type ('cat', 'dog', 'rabbit', 'hamster', 'bird')
- `bundleId` (string): Bundle identifier
- `deploymentTarget` (string): iOS deployment target
- `includeAchievements` (boolean): Include achievement system
- `includeAnimations` (boolean): Include animations
- `includeDataPersistence` (boolean): Include data persistence
- `includeActivityLog` (boolean): Include activity logging

**Returns:** boolean - True if project created successfully

##### `addPetFeature(projectPath, options)`

Add pet features to an existing project.

```javascript
const result = skill.addPetFeature('./MyPet', {
  petType: 'rabbit',
  includeAchievements: true,
  includeAnimations: true
});
```

**Parameters:**
- `projectPath` (string): Path to existing project
- `options` (object): Feature configuration options

**Options:**
- `petType` (string): Pet type to set
- `includeAchievements` (boolean): Enable achievement system
- `includeAnimations` (boolean): Enable animations

**Returns:** boolean - True if features added successfully

##### `customizePet(projectPath, customizations)`

Customize pet settings and behavior.

```javascript
const result = skill.customizePet('./MyPet', {
  initialStats: {
    hunger: 30,
    happiness: 70,
    health: 80,
    energy: 90
  },
  interactionEffects: {
    play: {
      happiness: 20,
      energy: -5
    },
    feed: {
      hunger: -30,
      happiness: 10
    }
  }
});
```

**Parameters:**
- `projectPath` (string): Path to project
- `customizations` (object): Customization options

**Options:**
- `initialStats` (object): Initial stat values
- `interactionEffects` (object): Custom interaction effects

**Returns:** boolean - True if customization applied successfully

##### `copyDirectory(src, dest)`

Copy a directory recursively.

```javascript
skill.copyDirectory('./templates', './project/templates');
```

**Parameters:**
- `src` (string): Source directory path
- `dest` (string): Destination directory path

##### `showHelp()`

Display help information and usage examples.

```javascript
skill.showHelp();
```

## Python API

### VirtualPetSkill Class

The Python implementation of the VirtualPet skill.

```python
from skill import VirtualPetSkill
skill = VirtualPetSkill()
```

#### Methods

##### `load_config(config_path)`

Load skill configuration from JSON or YAML file.

```python
try:
    config = skill.load_config('./skill.json')
    print(f'Skill loaded: {config["name"]}')
except Exception as e:
    print(f'Failed to load skill: {e}')
```

**Parameters:**
- `config_path` (str): Path to configuration file

**Returns:** dict - Parsed configuration

**Raises:** FileNotFoundError if configuration file not found

##### `list_skills()`

List all available skills.

```python
skills = skill.list_skills()
for skill_info in skills:
    print(f'{skill_info["name"]} v{skill_info["version"]}')
```

**Returns:** List of skill dictionaries

##### `create_project(**kwargs)`

Create a new VirtualPet project.

```python
success = skill.create_project(
    project_dir='./my-projects',
    project_name='MyPet',
    pet_type='dog',
    bundle_id='com.mycompany.mypet',
    deployment_target='17.0',
    include_achievements=True,
    include_animations=True,
    include_data_persistence=True,
    include_activity_log=True
)
```

**Parameters:**
- `project_dir` (str): Project directory path
- `project_name` (str): Project name
- `pet_type` (str): Pet type ('cat', 'dog', 'rabbit', 'hamster', 'bird')
- `bundle_id` (str): Bundle identifier
- `deployment_target` (str): iOS deployment target
- `include_achievements` (bool): Include achievement system
- `include_animations` (bool): Include animations
- `include_data_persistence` (bool): Include data persistence
- `include_activity_log` (bool): Include activity logging

**Returns:** bool - True if project created successfully

##### `add_pet_feature(project_path, **kwargs)`

Add features to existing project.

```python
success = skill.add_pet_feature(
    './MyPet',
    pet_type='rabbit',
    include_achievements=True,
    include_animations=True
)
```

**Parameters:**
- `project_path` (str): Path to existing project
- `pet_type` (str): Pet type to set
- `include_achievements` (bool): Enable achievement system
- `include_animations` (bool): Enable animations

**Returns:** bool - True if features added successfully

##### `customize_pet(project_path, customizations)`

Customize pet settings.

```python
customizations = {
    'initial_stats': {
        'hunger': 30,
        'happiness': 70,
        'health': 80,
        'energy': 90
    },
    'interaction_effects': {
        'play': {
            'happiness': 20,
            'energy': -5
        },
        'feed': {
            'hunger': -30,
            'happiness': 10
        }
    }
}

success = skill.customize_pet('./MyPet', customizations)
```

**Parameters:**
- `project_path` (str): Path to project
- `customizations` (dict): Customization options

**Returns:** bool - True if customization applied successfully

##### `copy_directory(src, dest)`

Copy directory recursively.

```python
skill.copy_directory('./templates', './project/templates')
```

**Parameters:**
- `src` (Path or str): Source directory
- `dest` (Path or str): Destination directory

## Swift API

### Pet Class

The core Swift class for managing virtual pets.

#### Properties

```swift
class Pet: ObservableObject {
    @Published var hunger: Int = 50           // 0-100
    @Published var happiness: Int = 50       // 0-100
    @Published var health: Int = 100          // 0-100
    @Published var energy: Int = 100          // 0-100
    @Published var age: Int = 0             // Days
    @Published var experience: Int = 0       // Experience points
    @Published var level: Int = 1            // Current level
    @Published var mood: PetMood = .normal   // Current mood
    @Published var petType: PetType = .cat  // Pet type
    @Published var activities: [Activity] = []  // Activity history
    @Published var achievements: [Achievement] = []  // Achievements

    // Computed properties
    var maxHappiness: Int = 50              // Maximum happiness reached
    var totalInteractions: Int = 0          // Total interactions
    var unlockedAchievements: Int = 0      // Unlocked achievements count
}
```

#### Initialization

```swift
// Default initialization
let pet = Pet()

// Custom stats initialization
let customPet = Pet(
    hunger: 30,
    happiness: 70,
    health: 80,
    energy: 90
)
```

#### Methods

##### `interact(type:)`

Interact with the pet.

```swift
pet.interact(type: .play)     // Play with pet
pet.interact(type: .feed)     // Feed pet
pet.interact(type: .clean)    // Clean pet
pet.interact(type: .exercise) // Exercise with pet
pet.interact(type: .cuddle)   // Cuddle pet
```

**Parameters:**
- `type` (`InteractionType`): Type of interaction

**Effects:**
- Each interaction affects multiple stats
- Experience points are earned
- Activities are logged
- Mood is updated
- Level up check performed

##### `updateMood()`

Update pet mood based on current stats.

```swift
pet.updateMood()
```

**Mood Logic:**
- Sick: Health < 30
- Hungry: Hunger > 80
- Sleepy: Energy < 20
- Happy: Happiness > 80
- Sad: Happiness < 20
- Excited: Happiness > 60 && Energy > 50
- Normal: Default mood

##### `decay()`

Perform automatic stat decay.

```swift
pet.decay()
```

**Effects:**
- Hunger: +1
- Happiness: -1
- Energy: -2
- Age: +1 day

##### `saveData()`

Save pet data to UserDefaults.

```swift
pet.saveData()
```

**Saved Data:**
- Hunger value
- Happiness value
- Health value
- Energy value

##### `loadData() -> Pet`

Load pet data from UserDefaults.

```swift
let pet = Pet.loadData()
```

**Returns:** Pet instance with loaded data or default values

#### Enums

##### `InteractionType`

```swift
enum InteractionType {
    case play   // Play with pet
    case feed   // Feed pet
    case clean  // Clean pet
    case exercise // Exercise with pet
    case cuddle // Cuddle pet
}
```

##### `PetType`

```swift
enum PetType: String, CaseIterable {
    case cat = "🐱"      // Orange color
    case dog = "🐶"      // Brown color
    case rabbit = "🐰"   // Pink color
    case hamster = "🐹" // Yellow color
    case bird = "🐦"    // Blue color
}
```

##### `PetMood`

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

#### Data Structures

##### `Activity`

```swift
struct Activity: Identifiable {
    let id = UUID()
    let title: String          // Activity title
    let icon: String          // SF Symbol icon name
    let color: Color          // Activity color
    let date: Date            // Activity timestamp
    let value: Int?           // Stat change value (optional)
}
```

##### `PetStatsRecord`

```swift
struct PetStatsRecord {
    let date: Date        // Record timestamp
    let hunger: Int       // Hunger value
    let happiness: Int    // Happiness value
    let health: Int       // Health value
}
```

##### `Achievement`

```swift
class Achievement: ObservableObject, Identifiable {
    let id = UUID()
    let title: String               // Achievement title
    let description: String         // Achievement description
    let icon: String                // SF Symbol icon name
    let requirement: () -> Bool      // Requirement function
    @Published var unlocked: Bool = false  // Unlock status
}
```

## Configuration API

### JSON Configuration Format

```json
{
  "name": "virtual-pet",
  "version": "1.0.0",
  "description": "Virtual pet management skill",
  "author": "VirtualPet Studio",
  "language": ["swift"],
  "target_platform": ["ios"],
  "parameters": {
    "required": [],
    "optional": [
      {
        "name": "pet_type",
        "type": "string",
        "description": "Type of pet",
        "default": "cat",
        "options": ["cat", "dog", "rabbit", "hamster", "bird"]
      }
    ]
  },
  "capabilities": {
    "project_generation": true,
    "code_generation": true,
    "file_generation": true
  }
}
```

### YAML Configuration Format

```yaml
name: virtual-pet
version: "1.0.0"
description: Virtual pet management skill
author: VirtualPet Studio
language: [swift]
target_platform: [ios]
parameters:
  optional:
    - name: pet_type
      type: string
      description: Type of pet
      default: cat
      options: [cat, dog, rabbit, hamster, bird]
capabilities:
  project_generation: true
  code_generation: true
  file_generation: true
```

### Configuration Parameters

#### Global Parameters

- `name`: Skill name (string)
- `version`: Skill version (string)
- `description`: Skill description (string)
- `author`: Skill author (string)
- `language`: Programming languages (array)
- `target_platform`: Target platforms (array)
- `dependencies`: Skill dependencies (array)

#### Project Parameters

- `project_name`: Project name (string)
- `pet_type`: Pet type selection (string)
- `bundle_id`: App bundle identifier (string)
- `deployment_target`: iOS version (string)
- `include_achievements`: Enable achievements (boolean)
- `include_animations`: Enable animations (boolean)
- `include_data_persistence`: Enable persistence (boolean)
- `include_activity_log`: Enable logging (boolean)

## Template API

### Template Variables

Templates support the following variables:

- `{{project_name}}`: Project name
- `{{pet_type}}`: Pet type
- `{{current_date}}`: Current date
- `{{initial_hunger}}`: Initial hunger value
- `{{initial_happiness}}`: Initial happiness value
- `{{initial_health}}`: Initial health value
- `{{initial_energy}}`: Initial energy value
- `{{initial_experience}}`: Initial experience value
- `{{initial_level}}`: Initial level

### Template Processing

The skill engine processes templates using variable substitution:

```javascript
const template = `
// File: {{project_name}}.swift
// Created: {{current_date}}
class {{project_name}} {
    let petType = PetType.{{pet_type}};
}
`;

const processed = skill.processTemplate(template, {
    project_name: 'MyPet',
    pet_type: 'dog',
    current_date: new Date().toISOString()
});
```

## Error Handling

### JavaScript Errors

```javascript
try {
    const result = skill.createProject(options);
} catch (error) {
    if (error.message.includes('not found')) {
        console.error('Configuration file missing');
    } else if (error.message.includes('permission denied')) {
        console.error('Permission denied');
    } else {
        console.error('Unknown error:', error.message);
    }
}
```

### Python Errors

```python
try:
    success = skill.create_project(**options)
except FileNotFoundError as e:
    print(f'File not found: {e}')
except PermissionError as e:
    print(f'Permission denied: {e}')
except Exception as e:
    print(f'Error: {e}')
```

### Common Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| E_CONFIG_NOT_FOUND | Configuration file not found | Check file path and permissions |
| E_INVALID_CONFIG | Invalid configuration format | Validate JSON/YAML syntax |
| E_PROJECT_EXISTS | Project directory already exists | Choose different project name |
| E_PERMISSION_DENIED | Permission denied | Check write permissions |
| E_XCODE_NOT_FOUND | Xcode command line tools not found | Install Xcode command line tools |
| E_INVALID_PET_TYPE | Invalid pet type | Use valid pet type from options |

### Error Recovery

The skill implements error recovery mechanisms:

1. **Rollback**: If project creation fails, partial files are cleaned up
2. **Validation**: Input parameters are validated before processing
3. **Graceful Degradation**: Optional features can be disabled if unavailable

## API Versioning

### Version History

| Version | Changes | Date |
|---------|---------|------|
| 1.0.0 | Initial API release | 2024-01-01 |

### Backward Compatibility

- API is designed for backward compatibility
- New parameters are optional
- Existing functionality remains unchanged

### Future Considerations

- Template system may be extended with conditional logic
- Additional pet types and interaction types planned
- Android platform support in future versions

## Performance Considerations

### Memory Usage

- Pet state uses minimal memory
- Activity history is limited to 100 entries
- Stats history is recorded every 10 activities

### Performance Optimization

- Timer-based operations use efficient scheduling
- File operations are batched when possible
- UI updates use SwiftUI's reactive system

### Resource Management

- Timer resources are properly cleaned up
- File handles are closed after operations
- Memory is freed when appropriate