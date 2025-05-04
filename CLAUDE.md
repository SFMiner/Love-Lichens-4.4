# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Run game: Godot Editor → Play button or F5
- Export game: Godot Editor → Project → Export
- Test specific scene: Open a scene in editor and press F6

## Coding Style Guidelines

### Naming Conventions
- Use snake_case for variables, functions, signals: `player_health`, `advance_turn()`
- Use PascalCase for classes and nodes: `InventorySystem`, `PlayerCombatant`
- Constants use UPPER_CASE or snake_case with `const` prefix: `sys_debug` or `TURNS_PER_DAY`
- Signals use descriptive verbs: `memory_discovered`, `turn_completed`

### Function Structure
- Order: properties → signals → constants → ready → public methods → private methods
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
- Set a debug flag at class level: `const scr_debug: bool = true`
- Conditionally print debug info: `if debug: print("Debug message")`
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
