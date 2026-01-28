#!/bin/bash

# VirtualPet Skill Usage Example Script
# This script demonstrates how to use the VirtualPet skill system

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  VirtualPet Skill Usage Example${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main script
main() {
    print_header

    # Ensure we're in the project directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"

    print_step "1. Listing available skills"
    node virtual-pet/skill.js list
    echo

    print_step "2. Creating basic VirtualPet project"
    node virtual-pet/skill.js create --project-name MyPet --pet-type cat
    echo

    print_step "3. Creating dog VirtualPet project"
    node virtual-pet/skill.js create --project-name DogPet --pet-type dog --bundle-id com.mycompany.dogpet
    echo

    print_step "4. Creating project with custom settings"
    node virtual-pet/skill.js create \
        --project-name CompletePet \
        --pet-type rabbit \
        --bundle-id com.mycompany.completepet \
        --deployment-target 17.5 \
        --include-achievements \
        --include-animations \
        --include-data-persistence \
        --include-activity-log
    echo

    print_step "5. Adding features to existing project"
    node virtual-pet/skill.js add \
        --project-dir ./DogPet \
        --pet-type hamster \
        --include-achievements
    echo

    print_step "6. Customizing pet settings"
    python virtual-pet/skill.py customize \
        --project-dir ./MyPet \
        --initial-stats hunger:40,happiness:70,health:85,energy:90
    echo

    print_step "7. Customizing interaction effects"
    python virtual-pet/skill.py customize \
        --project-dir ./MyPet \
        --interaction-effects \
            play:happiness:25,energy:-5,experience:10 \
            feed:hunger:-35,happiness:12,experience:5
    echo

    print_step "8. Testing Python version"
    python virtual-pet/skill.py list
    echo

    print_step "9. Creating minimal project"
    node virtual-pet/skill.js create \
        --project-name MinimalPet \
        --pet-type bird \
        --no-achievements \
        --no-animations
    echo

    print_success "All examples completed successfully!"
    echo
    print_info "Created projects:"
    echo "  - MyPet (cat with custom stats)"
    echo "  - DogPet (dog with features)"
    echo "  - CompletePet (rabbit with full features)"
    echo "  - MinimalPet (bird with minimal features)"
    echo
    print_info "To explore the created projects:"
    echo "  cd MyPet && open MyPet.xcodeproj"
    echo "  cd DogPet && open DogPet.xcodeproj"
    echo "  cd CompletePet && open CompletePet.xcodeproj"
    echo "  cd MinimalPet && open MinimalPet.xcodeproj"
}

# Run main function
main "$@"