0# Love & Lichens

A whimsical RPG/Visual Novel set in a college of environmental science, where understanding nature grants magical abilities.

## Project Overview

Love & Lichens is a narrative-driven game that combines relationship-building, environmental education, and non-violent "combat" through debates. Players take on the role of Adam Major, a new student at SUNY College of Environmental Science and Forestry, as they investigate a mysterious ecological imbalance affecting the campus.

## Core Systems

### Dialog System
Handles character conversations and branching dialog trees. Dialog data is stored in JSON format for easy editing.

### Relationship System
Tracks the player's relationships with NPCs, from stranger to romantic interest. Relationships evolve based on interactions, dialog choices, and special events.

### Inventory System
Manages the player's items, including lichen samples, books, and quest items.

### Environmental Debate System (To Be Implemented)
A non-violent "combat" system using rhetorical techniques and environmental knowledge.

## Getting Started

### Prerequisites
- Godot 4.4 or later

### Project Setup
1. Open the project in Godot 4.4
2. Go to Project > Project Settings > AutoLoad tab
3. Add the following autoloads in this exact order:
   - GameController: `res://scripts/autoload/game_controller.gd`
   - DialogSystem: `res://scripts/autoload/dialog_system.gd`
   - RelationshipSystem: `res://scripts/autoload/relationship_system.gd`
   - InventorySystem: `res://scripts/autoload/inventory_system.gd`
   - SaveLoadSystem: `res://scripts/autoload/save_load_system.gd`
4. Go to Project > Project Settings > Input Map tab
   - Add a new action called "interact"
   - Add key bindings: E and Space
   - Make sure the default movement inputs are properly configured:
	 - ui_up: W, Up Arrow
	 - ui_down: S, Down Arrow 
	 - ui_left: A, Left Arrow
	 - ui_right: D, Right Arrow
5. Set the main scene to `res://scenes/game.tscn`
6. Run the project 

### Troubleshooting
- If you see "GameController not found" errors, double-check that all autoloads are properly configured
- Make sure GameController is listed first in the autoload order

## Project Structure

```
love_and_lichens/
├── assets/           # Game assets (images, sounds, etc.)
├── scenes/           # Game scenes and UI components
├── scripts/          # Game logic and systems
│   ├── autoload/     # Singleton systems
│   ├── ui/           # UI scripts
│   ├── world/        # World-related scripts
│   └── player/       # Player-related scripts
└── data/             # Game data in JSON format
	└── dialogs/      # Character dialog data
```

## Development Roadmap

### Phase 1: Core Systems (Current)
- [x] Basic project structure
- [x] Dialog system
- [x] Relationship system
- [x] Inventory system
- [x] Basic player movement and camera
- [x] NPC interaction

### Phase 2: Content Development
- [ ] Campus locations
- [ ] Character development
- [ ] Quest system

### Phase 3: Polish
- [ ] UI refinement
- [ ] Audio
- [ ] Testing and balance
- [ ] Documentation

## Credits

Developed as a solo project by S3an Miner
