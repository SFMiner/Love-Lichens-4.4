# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Syntax Errors
- Other than speciifc data types like Dictionaries, there is no general method has() to check for properties. 
	- The proper syntax to look for a property in the same script (that is, self), is simply: 
		if property_name:
		- Example: to check if the current script's script_data poperty has a value, use:
			if script_data: 
	- To check in another object (an object with in the scirpt, or anotehr script), use:
		if "property_name" in object:
		- Example: to check if the object named my_variable has the peroperty _is_alive, use:
			if "_is_alive" in my_variable: 
- Ternary operators: condition ? value_if_true : value_if_false is NOT corerct gdscript syntax. Instead iuse:
	value = true_val if condition else false_val 
- NEVER check for a property within a script unless you know that it has been declared. Checking an undeclared property will cause an error

## Best Practices (Updated)

### Property Checking
- ✅ Use: `if "property_name" in object:` for object properties
- ✅ Use: `if property_name:` for self properties in same script
- ✅ Use: `if dict.has("key"):` for Dictionary keys
- ❌ Avoid: `if object.has("property_name"):` (doesn't exist in GDScript)

### Signal Connections
- ✅ Use: `GameState.safe_connect(signal_object, "signal_name", Callable(self, "method_name"))`
- This prevents duplicate connections and validates signals before connecting

### Debug Output
- ✅ Use: `DebugManager.print_debug(self, "_function_name", "message")`
- ✅ Use: `DebugManager.print_warning(self, "_function_name", "message")`
- ✅ Use: `DebugManager.print_error(self, "_function_name", "message")`
- This provides consistent, controllable debug output respecting both `sys_debug` and `scr_debug` settings

### Error Handling
- ✅ Use: `ErrorHandler.log_error(level, source, message)` for structured error logging
- ✅ Use: `ErrorHandler.validate_node(node, path, source)` to validate node existence
- ✅ Use: `ErrorHandler.validate_method(obj, method, source)` to validate methods
- Error levels: `ErrorLevel.INFO`, `ErrorLevel.WARNING`, `ErrorLevel.ERROR`, `ErrorLevel.CRITICAL`

### Path Management
- ✅ Use: `Paths.get_scene("scene_id")` instead of hardcoded paths
- ✅ Use: `Paths.get_ui("ui_id")` for UI scenes
- ✅ Use: `Paths.get_data_dir("type")` for data directories
- Prevents path duplication and makes it easier to refactor locations

### Null Safety
- ✅ Use: `GameState.safe_get_node(from_node, path)` for critical nodes (returns warning if not found)
- ✅ Use: `GameState.safe_call_method(node, method, args)` for safe method calls with array arguments
- ✅ Use: `GameState.node_has_method(node, method)` for validation before calling
- Example: `if GameState.node_has_method(quest_system, "get_all_quests"): save_data["quests"] = GameState.safe_call_method(quest_system, "get_all_quests")`

### Save Data Migration
- ✅ New saves should use: `"save_format_version": SaveDataMigrator.CURRENT_VERSION`
- ✅ Use: `SaveDataMigrator.migrate_save_data(data)` when loading old saves
- ✅ Use: `SaveDataMigrator.validate_save_data(data)` to ensure data integrity
- Current save format version: 2 (includes navigation fixes and pickup system data)

## Build/Run Commands
- Run game: Godot Editor → Play button or F5
- Export game: Godot Editor → Project → Export
- Test specific scene: Open a scene in editor and press F6

## Project Structure

### Key Directories
- **assets/**: Graphics, fonts, sprites, tilesets, and other visual resources
- **data/**: Contains JSON files for characters, dialogues, memories, quests, items
  - **data/dialogues/**: `.dialogue` files for character conversations and interactables
  - **data/memories/**: JSON files defining character memory chains
  - **data/characters/**: Character data in JSON format
  - **data/quests/**: Quest definitions
- **scripts/autoload/**: Contains all singleton systems that manage game functionality
- **scenes/world/locations/**: Main game areas with transitions
- **scenes/ui/**: User interface components including phone interface
- **addons/**: Third-party plugins including dialogue_manager and sound_manager

### Core Systems
- **Game Controller**: Central coordinator that manages scene transitions, pause functionality, and UI
- **Memory System**: Tracks character memories and story discoveries through observable features and triggers (note: memory_tag_registry feature remains in code but is not currently active)
- **Dialog System**: Handles character conversations with conditional responses based on player choices and character-specific font styling
- **Quest System**: Manages objectives, progress tracking, and rewards
- **Inventory System**: Item management with effect handling
- **Relationship System**: Tracks player standing with different characters
- **Time System**: Manages in-game time progression with day/night cycles
- **Save/Load System**: Persists game state between sessions with support for multiple save slots. Current;y saves current scene, inventory, 
- **Fast Travel System**: Allows player to move between unlocked locations
- **Character Data System**: Manages character information and fonts
- **Phone System**: Provides an in-game smartphone interface with apps for narrative content

## Coding Style Guidelines

### Naming Conventions
- Use snake_case for variables, functions, signals: `player_health`, `advance_turn()`
- Use PascalCase for classes and nodes: `InventorySystem`, `PlayerCombatant`
- Constants use UPPER_CASE or snake_case with `const` prefix: `sys_debug` or `TURNS_PER_DAY`
- Signals use descriptive verbs: `memory_discovered`, `turn_completed`

### Function Structure
- Order: properties → signals → constants → ready → public methods → private methods
- Tre first line of each function should be `var _fname = [function name]` so debug can output the script and funtion name for each line.
- Prefix private helper functions with underscore: `_load_memory_file()`
- Signal callbacks prefixed with `_on_`: `_on_memory_chain_completed()`

### Error Handling
- Use null checks with `get_node_or_null()` for node references
- Use `if debug: print()` for debug messages
- Employ push_error() for critical issues
- Use has_method() before calling optional methods

### Type Hints
- Add return type annotations: `func _ready() -> void:`
- Use explicit typing for collections: `var active_chains: Array[MemoryChain] = []`
- Document parameters in function comments

### Debug Practices
- Set a debug flag at class level: 
	- `const scr_debug: bool = true`
	- `var debug` 
	- first line of _ready function (after `var _fname = "_ready"`) is: 	`debug = scr_debug or GameController.sys_debug`
- Conditionally print debug info: `if debug: print(GameState.script_name_tag(self, _fname) + "Debug message")`
- Use await/yield for asynchronous operations

## Memory Management
- Free nodes with queue_free() rather than free() when removing
- Avoid circular references between autoloaded singletons

## Player Navigation System

The game supports both keyboard (WASD) navigation and click-to-navigate functionality:

### Player Navigation Components
- The player uses a `NavigationAgent2D` node for pathfinding
- `navigate_on_click` flag controls whether click-to-navigate is enabled
- Right-click on the map to navigate to that position
- Movement markers are instantiated from `res://scenes/world/movement_marker.tscn`

### Implementation Details
- Movement is interrupted by keyboard input (WASD keys) automatically
- Navigation requires scenes to have a `NavigationRegion2D` node with a valid navigation mesh
- The `is_navigating` flag controls navigation state
- Use `process_navigation(delta)` for handling navigation updates
- Direct navigation paths (`[target_position]`) work better than complex path calculation

### Debug Options
- Set `scr_debug = true` to enable navigation debugging
- Use `keyboard_override_timeout` to prevent unwanted keyboard interruptions
- The function `_check_navigation_region()` verifies navigation mesh validity

## Memory System

The game features an extensive memory system for character backstories and player discoveries:

- **Memory Triggers**: Events that unlock memories (look_at, item_acquired, location_visited, etc.)
- **Memory Chains**: Sequential memories that tell complete character stories
- **Observable Features**: Visual elements players can notice on characters
- **Tag System**: Centralized and simplified system that tracks player discoveries across the game
- Memory data stored in JSON format in `data/memories/` directory
- Integrates with dialogue for conditional options and quest objectives
- Memory tag registry system in `data/generated/memory_tag_registry.json`

## Scene Transitions

Scene transitions are handled through:

- `location_transition.gd` attached to Area2D nodes to create scene transitions
- `spawn_point.gd` script defines player spawn points in each scene
- GameController.change_location() preserves player state during transitions
- Fast travel can be implemented through dialogue using `fast_travel.dialogue` template (currently broken)
- Scene transition requires proper spawn point setup in both source and destination scenes

## Phone Interface

The game includes a phone interface with multiple apps:

- PhoneScene as main container with app loading functionality
- Supports multiple app types with different interfaces (messaging, social, email, etc.)
- Content tagged using the game's tag framework for filtering/unlocking
- Integrated with timestamp system for narrative flexibility
- Structured as a full-screen UI built around a base phone scene
- Basic phone system framework implemented and functioning
- Snake app fully implemented and working as a mini-game
- Other apps (messaging, social, email, etc.) still under development

## Debugging Features

- Memory system includes debug commands (memory_list, memory_set, memory_trigger)
- Scene transition debugging in GameController
- Most systems include debug flags (`scr_debug`, `sys_debug`)
- Quest debugging with `debug_complete_quest_objective`
- Improved debugging output with script and function names in debug messages

## Recent Updates (as of June 2025)

- Dialog system now correctly displays character-specific font styles
- Memory tag system fully operational with observable features working as expected
- Centralized and simplified tag system for better organization
- Basic phone interface framework functioning with Snake app playable
- Fixed dialogue option display issues and improved UI
