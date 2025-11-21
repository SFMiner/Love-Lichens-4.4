# Love & Lichens - Haiku 4.5 Implementation Task List
# Based on Improvement Plan Analysis

## OVERVIEW
This task list breaks down the improvements from the Improvement Plan into discrete tasks suitable for Claude Haiku 4.5 implementation. Each task includes clear instructions on whether extended thinking should be ON or OFF.

---

## PHASE 1: Navigation System Typo Fixes (High Priority - Immediate)
**Goal:** Fix all instances of "navigtion" typo to "navigation" in save_load_system.gd

### Task 1.1: Fix Navigation Manager Reference Typo
**Dependencies:** None  
**Extended thinking:** OFF  
**Reminder:** Before starting, ask the human: "Is extended thinking on? For this task, it should be OFF."

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Locate line that reads:
	```
	var navigation_manager = get_node_or_null("/root/NavigtionManager")
	```
3. Replace with:
	```
	var navigation_manager = get_node_or_null("/root/NavigationManager")
	```
4. Save the file

**Human Checkpoint:**
- [ ] File opens without errors
- [ ] Typo "NavigtionManager" changed to "NavigationManager"
- [ ] Code uses tabs for indentation
- [ ] Game runs without errors (F5)

### Task 1.2: Fix load_navigtion Method Name Typo
**Dependencies:** Task 1.1  
**Extended thinking:** OFF

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Locate the line that reads:
	```
	if navigation_manager and navigation_manager.has_method("load_navigtion"):
	```
3. Replace with:
	```
	if navigation_manager and navigation_manager.has_method("load_navigation"):
	```
4. Locate line that reads:
	```
	navigation_manager.load_navigation(save_data.navigation)
	```
5. Verify this line already has correct spelling (it does from the Improvement Plan example)
6. Save the file

**Human Checkpoint:**
- [ ] Method name changed from "load_navigtion" to "load_navigation"
- [ ] No new syntax errors introduced
- [ ] Game runs without errors (F5)

### Task 1.3: Fix "nvigation" Typo in Debug Print
**Dependencies:** Task 1.2  
**Extended thinking:** OFF

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Search for any debug print statements containing "nvigation" or "navigtion"
3. Locate line that likely reads:
	```
	if debug: print(GameState.script_name_tag(self) + "Restoring nvigation data...")
	```
4. Replace with:
	```
	if debug: print(GameState.script_name_tag(self) + "Restoring navigation data...")
	```
5. Save the file

**Human Checkpoint:**
- [ ] All navigation-related text now spelled correctly
- [ ] Debug messages display correctly when sys_debug enabled
- [ ] Save/load system works properly (test by saving and loading)

---

## PHASE 2: Property Checking Syntax Fixes (High Priority - Immediate)
**Goal:** Replace incorrect `object.has("property_name")` syntax with correct GDScript property checking

**⚠️ EXTENDED THINKING TRANSITION: Switch to ON**  
**Reminder:** Before starting Task 2.1, ask the human: "Is extended thinking on? For Phase 2 tasks, it should be ON to properly analyze code patterns."

### Task 2.1: Audit Codebase for Incorrect has() Usage
**Dependencies:** Phase 1 complete  
**Extended thinking:** ON  
**Reminder:** Before starting, ask the human: "Is extended thinking on? For this task, it should be ON."

**Implementation:**
1. Use bash to search for incorrect property checking patterns:
	```bash
	cd /mnt/project
	grep -r "\.has(" scripts/ --include="*.gd" | grep -v "\.has_method(" | grep -v "\.has_signal(" | grep -v "Dictionary" | grep -v "Array"
	```
2. Create a text file listing all findings:
	```bash
	cd /home/claude
	touch property_check_audit.txt
	```
3. For each finding, analyze:
	- Is it checking a property or a dictionary key?
	- What is the correct syntax replacement?
	- Document each case in property_check_audit.txt
4. Review findings with human before making changes

**Human Checkpoint:**
- [ ] Audit file created successfully
- [ ] All instances categorized correctly
- [ ] Human has reviewed the list before proceeding

### Task 2.2: Fix Property Checks in Save/Load System
**Dependencies:** Task 2.1  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Search for any pattern like `if save_data.has("property_name"):`
3. For each instance checking a Dictionary, verify it should stay as `.has()`
4. For each instance checking an Object property incorrectly:
	- Replace `if object.has("property_name"):` with `if "property_name" in object:`
5. Common locations to check:
	- Line with `if save_data.has("navigation")` - this is CORRECT (Dictionary check)
	- Line with `if save_data.has("quests")` - this is CORRECT (Dictionary check)
	- Any checks on system objects that aren't dictionaries
6. Save the file

**Human Checkpoint:**
- [ ] Dictionary checks remain using `.has()`
- [ ] Object property checks use `"property" in object` syntax
- [ ] Game runs without errors (F5)
- [ ] Save and load functionality works correctly

### Task 2.3: Fix Property Checks in Game Controller
**Dependencies:** Task 2.2  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/game_controller.gd`
2. Search for incorrect property checking patterns
3. Look for any lines like:
	```
	if some_object.has("property_name"):
	```
	where `some_object` is NOT a Dictionary or Array
4. Replace with correct syntax:
	```
	if "property_name" in some_object:
	```
5. For self-property checks in the same script:
	```
	if property_name:  # Direct check
	```
6. Save the file

**Human Checkpoint:**
- [ ] All property checks use correct syntax
- [ ] Game controller initializes correctly
- [ ] No runtime errors during gameplay

---

## PHASE 3: Signal Connection Safety (High Priority)
**Goal:** Add checks to prevent duplicate signal connections

### Task 3.1: Create Signal Connection Helper Function
**Dependencies:** Phase 2 complete  
**Extended thinking:** ON  
**Reminder:** Extended thinking should remain ON for Phase 3.

**Implementation:**
1. Open `res://scripts/autoload/game_state.gd`
2. Add a new static helper function at the end of the file:
	```gdscript
	# Safe signal connection helper
	static func safe_connect(signal_object: Object, signal_name: String, callable_target: Callable) -> bool:
		if not signal_object:
			push_warning("Cannot connect signal: signal_object is null")
			return false
		
		if not signal_object.has_signal(signal_name):
			push_warning("Signal does not exist: " + signal_name)
			return false
		
		var signal_ref = signal_object.get(signal_name)
		if signal_ref.is_connected(callable_target):
			# Already connected, skip
			return true
		
		signal_ref.connect(callable_target)
		return true
	```
3. Ensure proper tab indentation
4. Save the file

**Human Checkpoint:**
- [ ] Function added to game_state.gd
- [ ] Uses tabs for indentation
- [ ] No syntax errors (F6)

### Task 3.2: Apply Safe Connection in Memory System
**Dependencies:** Task 3.1  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/memory_system.gd` (or wherever memory system connections exist)
2. Find any lines that connect to signals, such as:
	```gdscript
	memory_system.memory_discovered.connect(_on_memory_discovered)
	```
3. Replace with safe connection:
	```gdscript
	GameState.safe_connect(memory_system, "memory_discovered", _on_memory_discovered)
	```
4. Apply to all signal connections in the file
5. Save the file

**Human Checkpoint:**
- [ ] All signal connections use safe_connect
- [ ] No duplicate connection warnings in console
- [ ] Memory system functions correctly

### Task 3.3: Apply Safe Connection in Game Controller
**Dependencies:** Task 3.2  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/game_controller.gd`
2. Locate the `_ready()` function
3. Find signal connections to TimeSystem:
	```gdscript
	time_system.day_changed.connect(_on_day_changed)
	time_system.time_of_day_changed.connect(_on_time_of_day_changed)
	```
4. Replace with safe connections:
	```gdscript
	GameState.safe_connect(time_system, "day_changed", _on_day_changed)
	GameState.safe_connect(time_system, "time_of_day_changed", _on_time_of_day_changed)
	```
5. Find any other signal connections in the file and apply safe_connect
6. Save the file

**Human Checkpoint:**
- [ ] All connections use safe_connect
- [ ] Game controller initializes without errors
- [ ] TimeSystem signals work correctly

---

## PHASE 4: Debug Print Standardization (Medium Priority)
**Goal:** Create centralized DebugManager for consistent debug output

**⚠️ EXTENDED THINKING REMAINS ON**

### Task 4.1: Create DebugManager Class
**Dependencies:** Phase 3 complete  
**Extended thinking:** ON

**Implementation:**
1. Create new file: `res://scripts/autoload/debug_manager.gd`
2. Add the following code:
	```gdscript
	extends Node
	class_name DebugManager
	
	# Centralized debug printing system
	# Respects both global sys_debug and individual scr_debug settings
	
	# Print debug message if debugging is enabled
	static func print_debug(source: Object, method: String, message: String) -> void:
		var should_print = false
		
		# Check global debug setting
		if GameController.has("sys_debug") and GameController.sys_debug:
			should_print = true
		
		# Check script-level debug setting
		if source.get("scr_debug"):
			should_print = true
		
		if should_print:
			print(GameState.script_name_tag(source, method) + message)
	
	# Print warning (always shows)
	static func print_warning(source: Object, method: String, message: String) -> void:
		push_warning(GameState.script_name_tag(source, method) + message)
	
	# Print error (always shows)
	static func print_error(source: Object, method: String, message: String) -> void:
		push_error(GameState.script_name_tag(source, method) + message)
	```
3. Ensure tabs are used for indentation
4. Save the file
5. Open `res://project.godot`
6. Add DebugManager as an autoload (if not automatically detected as class_name)

**Human Checkpoint:**
- [ ] File created successfully
- [ ] Uses tabs for indentation
- [ ] No syntax errors (F6)
- [ ] DebugManager accessible globally

### Task 4.2: Update Save/Load System to Use DebugManager
**Dependencies:** Task 4.1  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Find all lines with pattern:
	```gdscript
	if debug: print(GameState.script_name_tag(self) + "message")
	```
3. Replace with:
	```gdscript
	DebugManager.print_debug(self, "_function_name", "message")
	```
4. For each function, use the actual function name in the method parameter
5. Example transformation:
	```gdscript
	# OLD:
	if debug: print(GameState.script_name_tag(self) + "Restoring navigation data...")
	
	# NEW:
	DebugManager.print_debug(self, "_apply_save_data", "Restoring navigation data...")
	```
6. Save the file

**Human Checkpoint:**
- [ ] All debug prints converted to DebugManager
- [ ] Function names accurately reflect location
- [ ] Debug output works when sys_debug enabled
- [ ] Save/load functionality unchanged

### Task 4.3: Update Inventory System to Use DebugManager
**Dependencies:** Task 4.2  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/inventory_system.gd`
2. Convert all debug print statements to use DebugManager.print_debug()
3. Follow same pattern as Task 4.2
4. Ensure method names are accurate for each function
5. Save the file

**Human Checkpoint:**
- [ ] All debug prints converted
- [ ] Inventory system functions correctly
- [ ] Debug output appears when enabled

---

## PHASE 5: Error Handling Improvements (Medium Priority)
**Goal:** Create standardized error handling system

### Task 5.1: Create ErrorHandler Class
**Dependencies:** Phase 4 complete  
**Extended thinking:** ON

**Implementation:**
1. Create new file: `res://scripts/tools/error_handler.gd`
2. Add the following code:
	```gdscript
	class_name ErrorHandler
	extends RefCounted
	
	# Standardized error handling for Love & Lichens
	
	enum ErrorLevel { INFO, WARNING, ERROR, CRITICAL }
	
	# Log an error with appropriate severity
	static func log_error(level: ErrorLevel, source: String, message: String) -> void:
		var prefix := ""
		match level:
			ErrorLevel.INFO:
				prefix = "[INFO]"
			ErrorLevel.WARNING:
				prefix = "[WARN]"
			ErrorLevel.ERROR:
				prefix = "[ERROR]"
			ErrorLevel.CRITICAL:
				prefix = "[CRITICAL]"
		
		var full_message := "%s %s: %s" % [prefix, source, message]
		
		match level:
			ErrorLevel.INFO:
				print(full_message)
			ErrorLevel.WARNING:
				push_warning(full_message)
			ErrorLevel.ERROR:
				push_error(full_message)
			ErrorLevel.CRITICAL:
				push_error(full_message)
				# Could trigger safe shutdown or recovery here
	
	# Validate that a node exists
	static func validate_node(node: Node, expected_path: String, source: String) -> bool:
		if not node:
			log_error(ErrorLevel.ERROR, source, "Node not found at path: " + expected_path)
			return false
		return true
	
	# Validate that an object has a required method
	static func validate_method(obj: Object, method_name: String, source: String) -> bool:
		if not obj:
			log_error(ErrorLevel.ERROR, source, "Cannot validate method on null object")
			return false
		if not obj.has_method(method_name):
			log_error(ErrorLevel.WARNING, source, "Object missing expected method: " + method_name)
			return false
		return true
	```
3. Ensure tabs are used for indentation
4. Save the file

**Human Checkpoint:**
- [ ] File created in correct directory
- [ ] Uses tabs for indentation
- [ ] No syntax errors (F6)
- [ ] Class accessible as ErrorHandler

### Task 5.2: Apply ErrorHandler to Save/Load System
**Dependencies:** Task 5.1  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Add ErrorHandler usage for file operations:
	```gdscript
	# In save_game() function, replace:
	if not file:
		if debug: print(GameState.script_name_tag(self) + "Failed to open save file: ", save_path)
		return false
	
	# With:
	if not file:
		ErrorHandler.log_error(ErrorHandler.ErrorLevel.ERROR, "SaveLoadSystem", "Failed to open save file: " + save_path)
		return false
	```
3. Add validation for system node access:
	```gdscript
	# Replace:
	var navigation_manager = get_node_or_null("/root/NavigationManager")
	if navigation_manager and save_data.has("navigation"):
	
	# With:
	var navigation_manager = get_node_or_null("/root/NavigationManager")
	if ErrorHandler.validate_node(navigation_manager, "/root/NavigationManager", "SaveLoadSystem") and save_data.has("navigation"):
	```
4. Apply similar patterns throughout the file
5. Save the file

**Human Checkpoint:**
- [ ] Error messages use ErrorHandler
- [ ] Validation functions used appropriately
- [ ] Save/load functionality works correctly
- [ ] Error messages are clear and informative

---

## PHASE 6: Input Action Validation (Lower Priority)
**Goal:** Ensure all required input actions are registered at startup

**⚠️ EXTENDED THINKING TRANSITION: Switch to OFF**  
**Reminder:** Before starting Task 6.1, ask the human: "Is extended thinking on? For Phase 6, it should be OFF for straightforward implementation."

### Task 6.1: Expand _ensure_input_actions() Function
**Dependencies:** Phase 5 complete  
**Extended thinking:** OFF  
**Reminder:** Before starting, ask the human: "Is extended thinking on? For this task, it should be OFF."

**Implementation:**
1. Open `res://scripts/autoload/game_controller.gd`
2. Locate the `_ensure_input_actions()` function
3. Add comprehensive action definitions after existing code:
	```gdscript
	func _ensure_input_actions():
		var _fname = "_ensure_input_actions"
		
		# Define all required actions with default keys
		var required_actions = {
			"interact": [KEY_E, KEY_SPACE],
			"ui_up": [KEY_W, KEY_UP],
			"ui_down": [KEY_S, KEY_DOWN],
			"ui_left": [KEY_A, KEY_LEFT],
			"ui_right": [KEY_D, KEY_RIGHT],
			"toggle_inventory": [KEY_I],
			"toggle_quest": [KEY_Q],
			"pause": [KEY_ESCAPE]
		}
		
		# Special actions with modifiers
		var save_action_keys = [KEY_S]
		var save_requires_ctrl = true
		
		# Process standard actions
		for action in required_actions:
			if not InputMap.has_action(action):
				InputMap.add_action(action)
				for key in required_actions[action]:
					var event = InputEventKey.new()
					event.keycode = key
					InputMap.action_add_event(action, event)
				if debug: print(GameState.script_name_tag(self, _fname) + "Added action: " + action)
		
		# Process save_game action with Ctrl modifier
		if not InputMap.has_action("save_game"):
			InputMap.add_action("save_game")
			for key in save_action_keys:
				var event = InputEventKey.new()
				event.keycode = key
				event.ctrl_pressed = save_requires_ctrl
				InputMap.action_add_event("save_game", event)
			if debug: print(GameState.script_name_tag(self, _fname) + "Added action: save_game (Ctrl+S)")
	```
4. Ensure tabs are used for indentation
5. Remove any duplicate code that's now covered by this function
6. Save the file

**Human Checkpoint:**
- [ ] Function includes all required actions
- [ ] All actions work in-game
- [ ] Ctrl+S saves the game
- [ ] No duplicate action errors in console

---

## PHASE 7: Resource Path Constants (Lower Priority)
**Goal:** Create centralized path management system

### Task 7.1: Create Paths Singleton
**Dependencies:** Phase 6 complete  
**Extended thinking:** OFF

**Implementation:**
1. Create new file: `res://scripts/autoload/paths.gd`
2. Add the following code:
	```gdscript
	extends Node
	
	# Centralized path constants for Love & Lichens
	# Prevents hardcoded paths throughout the codebase
	
	const SCENES = {
		"main_menu": "res://scenes/main_menu.tscn",
		"game": "res://scenes/game.tscn",
		"dorm_room": "res://scenes/world/locations/dorm_room.tscn",
		"campus_quad": "res://scenes/world/locations/campus_quad.tscn",
		"campus_path": "res://scenes/world/locations/campus_path.tscn",
		"science_building": "res://scenes/world/locations/science_building.tscn",
		"library": "res://scenes/world/locations/library.tscn",
		"greenhouse": "res://scenes/world/locations/greenhouse.tscn"
	}
	
	const UI = {
		"inventory_panel": "res://scenes/ui/inventory_panel.tscn",
		"quest_panel": "res://scenes/ui/quest_panel.tscn",
		"pause_menu": "res://scenes/ui/pause_menu.tscn",
		"dialogue_balloon": "res://scenes/ui/dialogue_balloon.tscn"
	}
	
	const DATA = {
		"items": "res://data/items/",
		"quests": "res://data/quests/",
		"dialogues": "res://data/dialogues/",
		"memories": "res://data/memories/",
		"characters": "res://data/characters/"
	}
	
	const SCRIPTS = {
		"player": "res://scripts/world/player.gd",
		"npc": "res://scripts/world/npc.gd"
	}
	
	# Helper function to get scene path
	static func get_scene(scene_id: String) -> String:
		if SCENES.has(scene_id):
			return SCENES[scene_id]
		push_warning("Unknown scene ID: " + scene_id)
		return ""
	
	# Helper function to get UI path
	static func get_ui(ui_id: String) -> String:
		if UI.has(ui_id):
			return UI[ui_id]
		push_warning("Unknown UI ID: " + ui_id)
		return ""
	
	# Helper function to get data directory
	static func get_data_dir(data_type: String) -> String:
		if DATA.has(data_type):
			return DATA[data_type]
		push_warning("Unknown data type: " + data_type)
		return ""
	```
3. Ensure tabs are used for indentation
4. Save the file
5. Add as autoload in project settings if needed

**Human Checkpoint:**
- [ ] File created successfully
- [ ] All current scene paths included
- [ ] Paths singleton accessible globally
- [ ] No syntax errors (F6)

### Task 7.2: Update Game Controller to Use Paths
**Dependencies:** Task 7.1  
**Extended thinking:** OFF

**Implementation:**
1. Open `res://scripts/autoload/game_controller.gd`
2. Find hardcoded scene paths like:
	```gdscript
	change_scene("res://scenes/main_menu.tscn")
	```
3. Replace with:
	```gdscript
	change_scene(Paths.get_scene("main_menu"))
	```
4. Find UI path references like:
	```gdscript
	if ResourceLoader.exists("res://scenes/ui/pause_menu.tscn"):
		pause_menu_scene = load("res://scenes/ui/pause_menu.tscn")
	```
5. Replace with:
	```gdscript
	var pause_path = Paths.get_ui("pause_menu")
	if ResourceLoader.exists(pause_path):
		pause_menu_scene = load(pause_path)
	```
6. Apply throughout the file
7. Save the file

**Human Checkpoint:**
- [ ] All hardcoded paths replaced
- [ ] Scene transitions work correctly
- [ ] UI panels load properly
- [ ] No errors in console

---

## PHASE 8: Null Safety Helpers (Lower Priority)
**Goal:** Create helper functions for safe node access

### Task 8.1: Add Null Safety Functions to GameState
**Dependencies:** Phase 7 complete  
**Extended thinking:** OFF

**Implementation:**
1. Open `res://scripts/autoload/game_state.gd`
2. Add these helper functions at the end of the file:
	```gdscript
	# ==========================================
	# NULL SAFETY HELPERS
	# ==========================================
	
	# Safely get a node with warning if not found
	static func safe_get_node(from_node: Node, path: String) -> Node:
		var node = from_node.get_node_or_null(path)
		if not node:
			push_warning("Node not found at path: " + path)
		return node
	
	# Safely call a method on a node
	static func safe_call_method(node: Node, method: String, args: Array = []):
		if not node:
			push_warning("Cannot call method on null node: " + method)
			return null
		if not node.has_method(method):
			push_warning("Node missing method: " + method)
			return null
		return node.callv(method, args)
	
	# Check if node exists and has method
	static func node_has_method(node: Node, method: String) -> bool:
		if not node:
			return false
		return node.has_method(method)
	```
3. Ensure tabs are used for indentation
4. Save the file

**Human Checkpoint:**
- [ ] Functions added successfully
- [ ] Uses tabs for indentation
- [ ] No syntax errors (F6)
- [ ] Functions accessible as GameState.safe_get_node(), etc.

### Task 8.2: Apply Null Safety to Save/Load System
**Dependencies:** Task 8.1  
**Extended thinking:** OFF

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. Find patterns like:
	```gdscript
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
	```
3. Consider if warning is appropriate, then optionally replace with:
	```gdscript
	var inventory_system = GameState.safe_get_node(get_tree().root, "/root/InventorySystem")
	if inventory_system:
	```
4. Find patterns like:
	```gdscript
	if inventory_system and inventory_system.has_method("get_save_data"):
		save_data["inventory"] = inventory_system.get_save_data()
	```
5. Replace with:
	```gdscript
	if GameState.node_has_method(inventory_system, "get_save_data"):
		save_data["inventory"] = GameState.safe_call_method(inventory_system, "get_save_data")
	```
6. Apply judiciously - not all cases need the extra safety
7. Save the file

**Human Checkpoint:**
- [ ] Critical node accesses use safe functions
- [ ] Appropriate warnings appear when nodes missing
- [ ] Save/load functionality unchanged
- [ ] No performance issues

---

## PHASE 9: Save Data Migration System (Medium-Long Term)
**Goal:** Implement versioned save data with migration support

**⚠️ EXTENDED THINKING TRANSITION: Switch to ON**  
**Reminder:** Before starting Task 9.1, ask the human: "Is extended thinking on? For Phase 9, it should be ON for proper architectural design."

### Task 9.1: Create SaveDataMigrator Class
**Dependencies:** Phase 8 complete  
**Extended thinking:** ON  
**Reminder:** Before starting, ask the human: "Is extended thinking on? For this task, it should be ON."

**Implementation:**
1. Create new file: `res://scripts/tools/save_data_migrator.gd`
2. Add the following code:
	```gdscript
	class_name SaveDataMigrator
	extends RefCounted
	
	# Save data migration system for Love & Lichens
	# Handles converting old save formats to current version
	
	const CURRENT_VERSION = 2
	
	# Migrate save data from any version to current
	static func migrate_save_data(data: Dictionary) -> Dictionary:
		if not data.has("save_format_version"):
			# Version 1 didn't have version field
			data["save_format_version"] = 1
		
		var version = data.get("save_format_version", 1)
		
		# Apply migrations sequentially
		while version < CURRENT_VERSION:
			data = _migrate_to_next_version(data, version)
			version += 1
			data["save_format_version"] = version
		
		return data
	
	# Migrate from one version to the next
	static func _migrate_to_next_version(data: Dictionary, from_version: int) -> Dictionary:
		match from_version:
			1:
				return _migrate_v1_to_v2(data)
			# Add more migrations as needed
			_:
				push_warning("Unknown save version: " + str(from_version))
				return data
	
	# Migrate from version 1 to version 2
	static func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
		# Fix the navigation typo issue
		if data.has("navigtion"):
			data["navigation"] = data["navigtion"]
			data.erase("navigtion")
		
		# Add any new required fields
		if not data.has("play_time"):
			data["play_time"] = 0
		
		# Add pickup system data if missing
		if not data.has("pickup_system"):
			data["pickup_system"] = {}
		
		return data
	
	# Validate save data structure
	static func validate_save_data(data: Dictionary) -> bool:
		# Check for required fields
		var required_fields = ["save_format_version", "save_date"]
		for field in required_fields:
			if not data.has(field):
				push_error("Save data missing required field: " + field)
				return false
		
		return true
	```
3. Ensure tabs are used for indentation
4. Save the file

**Human Checkpoint:**
- [ ] File created successfully
- [ ] Migration logic sound
- [ ] Uses tabs for indentation
- [ ] No syntax errors (F6)

### Task 9.2: Integrate Migrator into Save/Load System
**Dependencies:** Task 9.1  
**Extended thinking:** ON

**Implementation:**
1. Open `res://scripts/autoload/save_load_system.gd`
2. In the `load_game()` function, after parsing JSON and before applying data:
	```gdscript
	# After:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		if debug: print(GameState.script_name_tag(self) + "Failed to parse save data")
		return false
	
	var save_data = json.data
	
	# Add:
	# Migrate save data if needed
	if save_data is Dictionary:
		save_data = SaveDataMigrator.migrate_save_data(save_data)
		if not SaveDataMigrator.validate_save_data(save_data):
			ErrorHandler.log_error(ErrorHandler.ErrorLevel.ERROR, "SaveLoadSystem", "Save data validation failed")
			return false
	```
3. In `_collect_save_data()`, ensure version is set:
	```gdscript
	var save_data = {
		"save_format_version": SaveDataMigrator.CURRENT_VERSION,
		"save_date": date_string,
		# ... rest of data
	}
	```
4. Save the file

**Human Checkpoint:**
- [ ] Migrator integrated into load process
- [ ] Version set correctly on save
- [ ] Old saves load correctly (if you have v1 saves)
- [ ] New saves work properly
- [ ] Migration warnings appear appropriately

---

## PHASE 10: Documentation and Cleanup
**Goal:** Document changes and verify all improvements

**⚠️ EXTENDED THINKING: OFF**  
**Reminder:** Before starting Task 10.1, ask the human: "Is extended thinking on? For Phase 10, it should be OFF for straightforward documentation."

### Task 10.1: Update CLAUDE.md with New Patterns
**Dependencies:** All previous phases  
**Extended thinking:** OFF  
**Reminder:** Before starting, ask the human: "Is extended thinking on? For this task, it should be OFF."

**Implementation:**
1. Open `CLAUDE.md` in project root
2. Add new section after "Common Syntax Errors":
	```markdown
	## Best Practices (Updated)
	
	### Property Checking
	- ✅ Use: `if "property_name" in object:` for object properties
	- ✅ Use: `if property_name:` for self properties in same script  
	- ✅ Use: `if dict.has("key"):` for Dictionary keys
	- ❌ Avoid: `if object.has("property_name"):` (doesn't exist in GDScript)
	
	### Signal Connections
	- ✅ Use: `GameState.safe_connect(signal_object, "signal_name", callable)`
	- This prevents duplicate connections and validates signals
	
	### Debug Output
	- ✅ Use: `DebugManager.print_debug(self, "_function_name", "message")`
	- ✅ Use: `DebugManager.print_warning(self, "_function_name", "message")`
	- ✅ Use: `DebugManager.print_error(self, "_function_name", "message")`
	- This provides consistent, controllable debug output
	
	### Error Handling
	- ✅ Use: `ErrorHandler.log_error(level, source, message)`
	- ✅ Use: `ErrorHandler.validate_node(node, path, source)`
	- ✅ Use: `ErrorHandler.validate_method(obj, method, source)`
	
	### Path Management
	- ✅ Use: `Paths.get_scene("scene_id")` instead of hardcoded paths
	- ✅ Use: `Paths.get_ui("ui_id")` for UI scenes
	- ✅ Use: `Paths.get_data_dir("type")` for data directories
	
	### Null Safety
	- ✅ Use: `GameState.safe_get_node(from_node, path)` for critical nodes
	- ✅ Use: `GameState.safe_call_method(node, method, args)` for method calls
	- ✅ Use: `GameState.node_has_method(node, method)` for validation
	```
3. Save the file

**Human Checkpoint:**
- [ ] CLAUDE.md updated with new patterns
- [ ] Examples are clear and correct
- [ ] Formatting matches existing style

### Task 10.2: Create Implementation Summary Document
**Dependencies:** Task 10.1  
**Extended thinking:** OFF

**Implementation:**
1. Create file: `res://docs/Implementation_Summary.md`
2. Document what was changed:
	```markdown
	# Implementation Summary - Improvement Plan
	
	## Completed Improvements
	
	### Phase 1: Navigation System Typo Fixes ✅
	- Fixed "NavigtionManager" → "NavigationManager"
	- Fixed "load_navigtion" → "load_navigation"
	- Fixed debug message typos
	
	### Phase 2: Property Checking Syntax Fixes ✅
	- Replaced incorrect `object.has("property")` with `"property" in object`
	- Updated save_load_system.gd
	- Updated game_controller.gd
	
	### Phase 3: Signal Connection Safety ✅
	- Created `GameState.safe_connect()` helper function
	- Applied to memory_system connections
	- Applied to game_controller connections
	
	### Phase 4: Debug Print Standardization ✅
	- Created DebugManager class
	- Updated save_load_system.gd to use DebugManager
	- Updated inventory_system.gd to use DebugManager
	
	### Phase 5: Error Handling Improvements ✅
	- Created ErrorHandler class with severity levels
	- Added validation helper functions
	- Applied to save_load_system.gd
	
	### Phase 6: Input Action Validation ✅
	- Expanded _ensure_input_actions() function
	- Added all required actions
	- Added save_game action with Ctrl modifier
	
	### Phase 7: Resource Path Constants ✅
	- Created Paths singleton
	- Added scene, UI, and data path constants
	- Updated game_controller.gd to use Paths
	
	### Phase 8: Null Safety Helpers ✅
	- Added safe_get_node() to GameState
	- Added safe_call_method() to GameState
	- Added node_has_method() to GameState
	- Applied to save_load_system.gd
	
	### Phase 9: Save Data Migration System ✅
	- Created SaveDataMigrator class
	- Implemented v1 to v2 migration
	- Integrated into save/load process
	
	### Phase 10: Documentation ✅
	- Updated CLAUDE.md with new patterns
	- Created this summary document
	
	## Files Modified
	1. scripts/autoload/save_load_system.gd
	2. scripts/autoload/game_controller.gd
	3. scripts/autoload/game_state.gd
	4. scripts/autoload/inventory_system.gd
	5. scripts/autoload/memory_system.gd
	6. CLAUDE.md
	
	## Files Created
	1. scripts/autoload/debug_manager.gd
	2. scripts/tools/error_handler.gd
	3. scripts/autoload/paths.gd
	4. scripts/tools/save_data_migrator.gd
	5. docs/Implementation_Summary.md
	
	## Next Steps (Future Improvements)
	These items were in the Improvement Plan but deferred for later:
	- Memory System Refactoring (create MemoryRegistry resource)
	- Inventory System Architecture (component-based system)
	- Additional migration versions as needed
	```
3. Save the file

**Human Checkpoint:**
- [ ] Summary document created
- [ ] All changes documented
- [ ] Files lists are complete and accurate

### Task 10.3: Final Testing and Verification
**Dependencies:** Task 10.2  
**Extended thinking:** OFF

**Implementation:**
1. Run the game (F5) and verify:
	- Game starts without errors
	- Main menu loads
	- New game starts correctly
	- Save game works (Ctrl+S)
	- Load game works
	- Inventory system functions
	- Quest system functions
	- All UI elements work
2. Test with debug enabled:
	- Set `sys_debug = true` in game_controller.gd
	- Verify debug output uses DebugManager
	- Verify error messages are clear
3. Test save migration:
	- If old save files exist, verify they load
	- Verify new saves have correct version
4. Create test report file: `res://docs/Test_Results.md`
5. Document any issues found

**Human Checkpoint:**
- [ ] All core functionality works
- [ ] No new errors introduced
- [ ] Debug output clean and useful
- [ ] Save/load works correctly
- [ ] Test report created

---

## COMPLETION CHECKLIST

### High Priority (Must Complete)
- [ ] Phase 1: Navigation typos fixed
- [ ] Phase 2: Property checking syntax corrected
- [ ] Phase 3: Signal connection safety added
- [ ] Phase 4: Debug print standardization

### Medium Priority (Should Complete)
- [ ] Phase 5: Error handling improvements
- [ ] Phase 9: Save data migration system

### Lower Priority (Nice to Have)
- [ ] Phase 6: Input action validation
- [ ] Phase 7: Resource path constants
- [ ] Phase 8: Null safety helpers
- [ ] Phase 10: Documentation and cleanup

### Verification
- [ ] All modified files use tabs for indentation
- [ ] No syntax errors (F6 test on each file)
- [ ] Game runs without runtime errors (F5)
- [ ] Save/load functionality works
- [ ] All new classes properly documented
- [ ] CLAUDE.md updated with new patterns

---

## NOTES FOR HAIKU
- Always ask human about extended thinking setting before starting each task
- Use tabs for indentation, never spaces
- Test after each phase is complete
- If a task seems too complex, break it into smaller subtasks
- Document any issues or questions for the human
- Verify existing functionality isn't broken before moving to next phase

## ESTIMATED COMPLETION TIME
- Phase 1-2: Quick (simple replacements)
- Phase 3-5: Medium (new classes and integration)
- Phase 6-8: Quick-Medium (helper functions)
- Phase 9: Medium (architectural change)
- Phase 10: Quick (documentation)

Total: Approximately 10-15 tasks per session, completing full implementation over 2-3 sessions.
