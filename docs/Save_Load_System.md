# Save & Load System Documentation

The Save & Load System in Love & Lichens provides persistence for game state across multiple save slots, allowing players to save their progress and return to it later.

## Architecture Overview

The save/load functionality is implemented through a multi-layered approach:

1. **SaveLoadSystem** - Primary autoload singleton that handles file operations
2. **GameState** - Coordinates game data collection and application
3. **GameController** - Exposes save/load methods to the UI and handles input shortcuts
4. **UI Components** - Pause menu and main menu provide user interfaces for save/load operations

## Core Components

### SaveLoadSystem (scripts/autoload/save_load_system.gd)

The primary autoload singleton responsible for:
- Managing file operations (read/write JSON)
- Maintaining save slots (up to 5 slots)
- Collecting and applying game state data from various systems
- Emitting signals when games are saved or loaded

#### Key Properties

- `SAVE_FOLDER = "user://saves/"` - Directory for save files
- `SAVE_EXTENSION = ".json"` - File format for saves
- `MAX_SAVE_SLOTS = 5` - Maximum number of save slots
- `current_save_slot` - Tracks the currently loaded save slot

#### Key Methods

- `save_game(slot)` - Saves game to the specified slot
- `load_game(slot)` - Loads game from the specified slot
- `get_save_info(slot)` - Returns metadata about a save slot
- `get_all_save_slots_info()` - Returns info about all save slots
- `delete_save(slot)` - Deletes a save in the specified slot

### GameState (scripts/autoload/game_state.gd)

Coordinates save data collection and application:
- Centralizes game state data collection
- Integrates with memory system for saving character memories
- Tracks play time and game metadata

#### Key Methods

- `save_game(slot)` - Collects data and delegates to SaveLoadSystem
- `load_game(slot)` - Delegates to SaveLoadSystem and emits signals
- `_collect_save_data()` - Gathers state from various game systems
- `_apply_save_data(save_data)` - Applies loaded data to game systems

### GameController (scripts/autoload/game_controller.gd)

Exposes save/load functionality to the UI and implements shortcut keys:
- Keyboard shortcuts for quick saves (Ctrl+S)
- Integration with pause menu for save/load UI
- Coordinates scene changes during load operations

#### Key Methods

- `save_game(slot)` - Public method called by UI
- `load_game(slot)` - Public method called by UI
- `quick_save()` - Saves to slot 0 and shows notification
- `_on_save_game(slot)` - Signal handler from pause menu
- `_on_load_game(slot)` - Signal handler from pause menu

## Saved Data

The system should saves the following data:

- **Basic Metadata**
  - Save date and time (implemented)
  - Play time (not implemented)
  - Current location (implemented)

- **Player State**
  - Position coordinates (implemented)
  - Last movement direction  (implemented)
  - Current animation (looks like it's implemented,but it might be just that _idle is the default. lowest riority)

- **Game Systems**
  - Inventory items  (not implements. high priority)
  - Memory tags and discovered memories (not implements. high priority)
  - Character relationships (not implemented; relationships system unfinished but data structures shoul dbe available)
  - Active quests and objectives (not implemented; quest system unfinished but data structures shoul dbe available)
  - Dialog history (not implemented; dialog history current;y operated on memory_tags, not actually ttracing choices)
  - Time system state (Not sure if impeented)

## Save File Format

Save files are stored as JSON with the following structure:

```json
{
  "save_format_version": 1,
  "save_date": "YYYY-MM-DD HH:MM:SS",
  "play_time": 0,
  "player_name": "Adam Major",
  "current_location": "campus_quad",
  "current_scene_path": "res://scenes/world/locations/campus_quad.tscn",
  "inventory": [...],
  "relationships": {...},
  "quests": [...],
  "dialog_seen": [...],
  "current_dialog": "character_id",
  "player_position": {"x": 0, "y": 0},
  "player_direction": {"x": 0, "y": 0},
  "player_animation": "idle",
  "tags": {...},
  "discovered_memories": [...],
  "memory_discovery_history": [...],
  "dialogue_mapping": {...},
  "time_system": {...}
}
```

## UI Integration

### Pause Menu

The pause menu (scripts/ui/pause_menu.gd) provides a user interface for:
- Selecting save slots
- Viewing save metadata (date, location)
- Confirming save/load operations

### Main Menu

The main menu allows players to:
- Start a new game
- Continue from the most recent save
- Load a specific save slot

## Usage

### For Players

- **Quick Save**: Press Ctrl+S during gameplay
- **Save Game**: Open pause menu (Esc) and select "Save Game"
- **Load Game**: Open pause menu (Esc) and select "Load Game"

### For Developers

To integrate with the save system, ensure your system:

1. Implements a method to collect its state (e.g., `get_all_items()`)
2. Implements a method to apply saved state (e.g., `load_quests()`)
3. Is referenced in the `_collect_save_data()` and `_apply_save_data()` methods

Example integration:

```gdscript
# In your system class
func get_save_data():
	return {
		"system_state": current_state,
		"other_data": important_values
	}

func load_save_data(data):
	if data.has("system_state"):
		current_state = data.system_state
	if data.has("other_data"):
		important_values = data.other_data
```

Then ensure SaveLoadSystem includes your system:

```gdscript
# In _collect_save_data()
var my_system = get_node_or_null("/root/MySystem")
if my_system and my_system.has_method("get_save_data"):
	save_data["my_system"] = my_system.get_save_data()

# In _apply_save_data()
var my_system = get_node_or_null("/root/MySystem")
if my_system and save_data.has("my_system") and my_system.has_method("load_save_data"):
	my_system.load_save_data(save_data.my_system)
```

## Debug Features

When `scr_debug` or `sys_debug` is enabled:
- Detailed logging of save/load operations
- Error reporting for file operations
- Player position and scene loading diagnostics
