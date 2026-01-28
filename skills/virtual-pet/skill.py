#!/usr/bin/env python3
"""
VirtualPet Skill - Python Implementation
This script provides command-line interface for managing virtual pet projects
"""

import os
import sys
import json
import shutil
import argparse
from pathlib import Path
from datetime import datetime


class VirtualPetSkill:
    def __init__(self):
        self.skill_config = None
        self.project_dir = os.getcwd()

    def load_config(self, config_path):
        """Load skill configuration from JSON or YAML file"""
        config_path = Path(config_path)

        # Try JSON first
        if config_path.exists():
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    self.skill_config = json.load(f)
                return self.skill_config
            except json.JSONDecodeError as e:
                print(f"Error loading JSON config: {e}")

        # Try YAML
        yaml_path = config_path.with_suffix('.yaml')
        if yaml_path.exists():
            try:
                with open(yaml_path, 'r', encoding='utf-8') as f:
                    self.skill_config = self.parse_simple_yaml(f.read())
                return self.skill_config
            except Exception as e:
                print(f"Error loading YAML config: {e}")

        raise FileNotFoundError("Skill configuration not found")

    def list_skills(self):
        """List available skills"""
        skills_dir = Path(__file__).parent.parent
        skills = []

        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir() and (skill_dir / 'skill.json').exists():
                config_path = skill_dir / 'skill.json'
                try:
                    config = self.load_config(config_path)
                    skills.append({
                        'name': config.get('name', 'Unknown'),
                        'version': config.get('version', '0.0.0'),
                        'description': config.get('description', 'No description'),
                        'author': config.get('author', 'Unknown')
                    })
                except Exception as e:
                    print(f"Error loading skill config for {skill_dir.name}: {e}")

        print("Available Skills:")
        print("================")
        for skill in skills:
            print(f"{skill['name']} v{skill['version']}")
            print(f"  {skill['description']}")
            print(f"  by {skill['author']}")
            print()

        return skills

    def create_project(self, **kwargs):
        """Create a new VirtualPet project"""
        options = {
            'project_dir': self.project_dir,
            'project_name': 'VirtualPet',
            'pet_type': 'cat',
            'bundle_id': 'com.example.virtualpet',
            'deployment_target': '17.0',
            'include_achievements': True,
            'include_animations': True,
            'include_data_persistence': True,
            'include_activity_log': True,
            **kwargs
        }

        project_path = Path(options['project_dir']) / options['project_name']

        print(f"Creating VirtualPet project: {options['project_name']}")
        print(f"Project directory: {project_path}")
        print(f"Pet type: {options['pet_type']}")

        # Check if project directory exists
        if project_path.exists():
            print(f"Project directory already exists: {project_path}")
            return False

        # Create project directory
        project_path.mkdir(parents=True, exist_ok=True)

        # Generate project files
        self.generate_project_files(options)

        # Generate Xcode project
        self.generate_xcode_project(options)

        print(f"✅ VirtualPet project created successfully!")
        print()
        print("Next steps:")
        print(f"  cd {project_path}")
        print(f"  open {options['project_name']}.xcodeproj")
        print(f"  or xcodebuild -project {options['project_name']}.xcodeproj -scheme {options['project_name']} build")

        return True

    def generate_project_files(self, options):
        """Generate project files"""
        source_path = Path(__file__).parent.parent.parent / 'VirtualPet'

        # Copy source files
        if source_path.exists():
            self.copy_directory(source_path, Path(options['project_dir']) / options['project_name'])

        # Update pet type in Pet.swift
        pet_file_path = Path(options['project_dir']) / options['project_name'] / 'Pet.swift'
        if pet_file_path.exists():
            with open(pet_file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Replace default pet type
            content = content.replace('petType: PetType = .cat', f'petType: PetType = .{options["pet_type"]}')

            with open(pet_file_path, 'w', encoding='utf-8') as f:
                f.write(content)

    def generate_xcode_project(self, options):
        """Generate Xcode project using the existing script"""
        script_path = Path(__file__).parent / 'create-virtual-pet.sh'
        if script_path.exists():
            import subprocess
            project_path = Path(options['project_dir']) / options['project_name']
            command = f'bash "{script_path}" "{project_path}"'
            result = subprocess.run(command, shell=True, capture_output=True, text=True)

            if result.returncode != 0:
                print(f"Error running project creator script: {result.stderr}")
            else:
                print(result.stdout)

    def add_pet_feature(self, project_path, **kwargs):
        """Add pet features to existing project"""
        project_path = Path(project_path)
        print(f"Adding pet features to: {project_path}")

        # Check if it's a valid project
        if not (project_path / 'Pet.swift').exists():
            print("Not a valid VirtualPet project")
            return False

        # Add or update pet features based on options
        if 'pet_type' in kwargs:
            self.update_pet_type(project_path, kwargs['pet_type'])

        if kwargs.get('include_achievements', True):
            self.add_achievement_system(project_path)

        if kwargs.get('include_animations', True):
            self.add_animations(project_path)

        print("✅ Pet features added successfully")
        return True

    def customize_pet(self, project_path, customizations=None):
        """Customize pet settings"""
        project_path = Path(project_path)
        print(f"Customizing pet for: {project_path}")

        pet_file_path = project_path / 'Pet.swift'
        if not pet_file_path.exists():
            print("Pet.swift not found")
            return False

        with open(pet_file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Apply customizations
        if customizations and 'initial_stats' in customizations:
            stats = customizations['initial_stats']
            init_params = []

            if 'hunger' in stats:
                init_params.append(f"hunger={stats['hunger']}")
            else:
                init_params.append("hunger=50")

            if 'happiness' in stats:
                init_params.append(f"happiness={stats['happiness']}")
            else:
                init_params.append("happiness=50")

            if 'health' in stats:
                init_params.append(f"health={stats['health']}")
            else:
                init_params.append("health=100")

            if 'energy' in stats:
                init_params.append(f"energy={stats['energy']}")
            else:
                init_params.append("energy=100")

            # Update init method
            content = content.replace(
                'init(hunger: Int = 50, happiness: Int = 50, health: Int = 100)',
                f'init({" , ".join(init_params)})'
            )

        # Update interaction effects
        if customizations and 'interaction_effects' in customizations:
            for interaction, effects in customizations['interaction_effects'].items():
                effect_statements = []

                if 'hunger' in effects:
                    change = effects['hunger']
                    op = '+' if change > 0 else ''
                    effect_statements.append(f"hunger = clampValue(hunger {op} {change})")

                if 'happiness' in effects:
                    change = effects['happiness']
                    op = '+' if change > 0 else ''
                    effect_statements.append(f"happiness = clampValue(happiness {op} {change})")

                if 'health' in effects:
                    change = effects['health']
                    op = '+' if change > 0 else ''
                    effect_statements.append(f"health = clampValue(health {op} {change})")

                if 'energy' in effects:
                    change = effects['energy']
                    op = '+' if change > 0 else ''
                    effect_statements.append(f"energy = clampValue(energy {op} {change})")

                if 'experience' in effects:
                    effect_statements.append(f"experience += {effects['experience']}")

                if effect_statements:
                    effect_block = "{\n        " + "\n        ".join(effect_statements) + "\n        }"
                    content = content.replace(
                        f'case .{interaction}: {{',
                        f'case .{interaction}: {effect_block}'
                    )

        with open(pet_file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print("✅ Pet customized successfully")
        return True

    def copy_directory(self, src, dest):
        """Copy directory recursively"""
        if not dest.exists():
            dest.mkdir(parents=True, exist_ok=True)

        for item in src.iterdir():
            src_item = src / item
            dest_item = dest / item

            if src_item.is_dir():
                self.copy_directory(src_item, dest_item)
            else:
                shutil.copy2(src_item, dest_item)

    def parse_simple_yaml(self, yaml_content):
        """Simple YAML parser for basic key-value pairs"""
        config = {}
        lines = yaml_content.split('\n')

        for line in lines:
            trimmed = line.strip()
            if trimmed and not trimmed.startswith('#'):
                colon_index = trimmed.find(':')
                if colon_index > 0:
                    key = trimmed[:colon_index].strip()
                    value = trimmed[colon_index + 1:].strip()

                    # Remove quotes if present
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]

                    # Parse values
                    if value.lower() == 'true':
                        config[key] = True
                    elif value.lower() == 'false':
                        config[key] = False
                    elif value.isdigit():
                        config[key] = int(value)
                    elif '.' in value and value.replace('.', '').isdigit():
                        config[key] = float(value)
                    else:
                        config[key] = value

        return config

    def show_help(self):
        """Show help message"""
        help_text = """
VirtualPet Skill - Virtual Pet Management Tool

Usage: python skill.py [command] [options]

Commands:
  help                    Show this help message
  list                    List available skills
  create [options]         Create a new VirtualPet project
  add [options]           Add pet features to existing project
  customize [options]     Customize pet settings

Options:
  --project-dir <path>    Project directory (default: current directory)
  --project-name <name>   Project name (default: VirtualPet)
  --pet-type <type>       Pet type: cat, dog, rabbit, hamster, bird
  --bundle-id <id>        Bundle identifier (default: com.example.virtualpet)
  --deployment-target <version> iOS deployment target (default: 17.0)
  --no-achievements       Disable achievement system
  --no-animations          Disable animations
  --no-persistence        Disable data persistence
  --no-activity-log       Disable activity logging

Examples:
  python skill.py create --project-name MyPet
  python skill.py create --pet-type dog --bundle-id com.mycompany.mypet
  python skill.py add --project-dir ./MyPet --pet-type rabbit
  python skill.py customize --project-dir ./MyPet --initial-stats hunger:30,happiness:70
"""
        print(help_text)


def main():
    """Command line interface"""
    skill = VirtualPetSkill()
    parser = argparse.ArgumentParser(description='VirtualPet Skill - Virtual Pet Management Tool')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # Help command
    parser_help = subparsers.add_parser('help', help='Show help message')

    # List command
    parser_list = subparsers.add_parser('list', help='List available skills')

    # Create command
    parser_create = subparsers.add_parser('create', help='Create a new VirtualPet project')
    parser_create.add_argument('--project-dir', help='Project directory')
    parser_create.add_argument('--project-name', default='VirtualPet', help='Project name')
    parser_create.add_argument('--pet-type', default='cat', choices=['cat', 'dog', 'rabbit', 'hamster', 'bird'], help='Pet type')
    parser_create.add_argument('--bundle-id', default='com.example.virtualpet', help='Bundle identifier')
    parser_create.add_argument('--deployment-target', default='17.0', help='iOS deployment target')
    parser_create.add_argument('--no-achievements', action='store_true', help='Disable achievement system')
    parser_create.add_argument('--no-animations', action='store_true', help='Disable animations')
    parser_create.add_argument('--no-persistence', action='store_true', help='Disable data persistence')
    parser_create.add_argument('--no-activity-log', action='store_true', help='Disable activity logging')

    # Add command
    parser_add = subparsers.add_parser('add', help='Add pet features to existing project')
    parser_add.add_argument('--project-dir', default=os.getcwd(), help='Project directory')
    parser_add.add_argument('--pet-type', choices=['cat', 'dog', 'rabbit', 'hamster', 'bird'], help='Pet type')
    parser_add.add_argument('--no-achievements', action='store_true', help='Disable achievement system')
    parser_add.add_argument('--no-animations', action='store_true', help='Disable animations')

    # Customize command
    parser_customize = subparsers.add_parser('customize', help='Customize pet settings')
    parser_customize.add_argument('--project-dir', default=os.getcwd(), help='Project directory')
    parser_customize.add_argument('--initial-stats', help='Initial stats in format hunger:30,happiness:70,health:80,energy:90')
    parser_customize.add_argument('--interaction-effects', help='Interaction effects in format play:happiness:15,energy:-10')

    # Parse arguments
    args = parser.parse_args()

    if args.command is None or args.command == 'help':
        skill.show_help()
        return

    # Execute command
    try:
        if args.command == 'list':
            skill.list_skills()
        elif args.command == 'create':
            options = {
                'project_dir': args.project_dir,
                'project_name': args.project_name,
                'pet_type': args.pet_type,
                'bundle_id': args.bundle_id,
                'deployment_target': args.deployment_target,
                'include_achievements': not args.no_achievements,
                'include_animations': not args.no_animations,
                'include_data_persistence': not args.no_persistence,
                'include_activity_log': not args.no_activity_log
            }
            skill.create_project(**options)
        elif args.command == 'add':
            options = {
                'project_dir': args.project_dir,
                'pet_type': args.pet_type,
                'include_achievements': not args.no_achievements,
                'include_animations': not args.no_animations
            }
            skill.add_pet_feature(args.project_dir, **options)
        elif args.command == 'customize':
            customizations = {}
            if args.initial_stats:
                stats = {}
                for stat in args.initial_stats.split(','):
                    key, value = stat.split(':')
                    stats[key] = int(value)
                customizations['initial_stats'] = stats

            if args.interaction_effects:
                effects = {}
                for effect in args.interaction_effects.split(','):
                    interaction, *rest = effect.split(':')
                    effect_values = {}
                    for stat_value in rest:
                        stat, value = stat_value.split(':')
                        effect_values[stat] = int(value)
                    effects[interaction] = effect_values
                customizations['interaction_effects'] = effects

            skill.customize_pet(args.project_dir, customizations)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()