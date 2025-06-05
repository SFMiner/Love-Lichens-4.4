````markdown
# Save/Load System Code Suggestions

This document provides concrete code implementations for the save/load system based on the audit and implementation plan. Each system needs `get_save_data()` and `load_save_data(data)` methods to integrate with the centralized save system.

## Overview

The save/load system follows this pattern:
1. Each system implements `get_save_data()` → returns Dictionary of its state
2. Each system implements `load_save_data(data)` → restores state from Dictionary
3. `GameState._collect_save_data()` calls all systems' `get_save_data()`
4. `GameState._apply_save_data()` calls all systems' `load_save_data()`

## 1. GameState (`game_state.gd`)

### Enhanced `_collect_save_data()` Method

**Location:** Replace existing `_collect_save_data()` method around line 400

**Purpose:** Coordinates saving data from all game systems into a unified structure

```gdscript
func _collect_save_data():
   var _fname = "_collect_save_data"
   if debug: print(script_name_tag(self, _fname) + "Collecting save data from all systems")
   
   # Update play time before saving
   if start_time > 0:
   	play_time += Time.get_unix_time_from_system() - start_time
   	start_time = Time.get_unix_time_from_system()
   
   var save_data = {
   	"save_format_version": 2,
   	"game_id": current_game_id,
   	"save_time": Time.get_unix_time_from_system(),
   	"play_time": play_time,
   	"game_data": game_data.duplicate(true),
   	"tags": tags.duplicate(true),
   	# Core GameState memory data
   	"discovered_memories": discovered_memories.duplicate(),
   	"memory_discovery_history": memory_discovery_history.duplicate(true),
   	"dialogue_mapping": dialogue_mapping.duplicate(true)
   }
   
   # Inventory System
   var inventory_system = get_node_or_null("/root/InventorySystem")
   if inventory_system and inventory_system.has_method("get_save_data"):
   	save_data["inventory_system"] = inventory_system.get_save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected inventory data")
   
   # Quest System  
   var quest_system = get_node_or_null("/root/QuestSystem")
   if quest_system and quest_system.has_method("get_save_data"):
   	save_data["quest_system"] = quest_system.get_save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected quest data")
   
   # Relationship System
   var relationship_system = get_node_or_null("/root/RelationshipSystem")
   if relationship_system and relationship_system.has_method("get_save_data"):
   	save_data["relationship_system"] = relationship_system.get_save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected relationship data")
   
   # Time System
   var time_system = get_node_or_null("/root/TimeSystem")
   if time_system and time_system.has_method("save_data"):
   	save_data["time_system"] = time_system.save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected time data")
   
   # Memory System
   var memory_system = get_node_or_null("/root/MemorySystem")
   if memory_system and memory_system.has_method("get_save_data"):
   	save_data["memory_system"] = memory_system.get_save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected memory system data")
   
   # Phone Apps (if phone scene exists)
   var phone_scene = get_node_or_null("/root/Game/PhoneCanvasLayer/PhoneSceneInstance")
   if not phone_scene:
   	phone_scene = get_node_or_null("/root/PhoneScene")
   if phone_scene and phone_scene.has_method("get_save_data"):
   	save_data["phone_apps"] = phone_scene.get_save_data()
   	if debug: print(script_name_tag(self, _fname) + "Collected phone app data")
   
   if debug: print(script_name_tag(self, _fname) + "Save data collection complete. Keys: ", save_data.keys())
   return save_data
````

### Enhanced `_apply_save_data()` Method

**Location:** Replace existing `_apply_save_data()` method around line 450

**Purpose:** Distributes loaded data to all game systems for restoration

gdscript

```gdscript
func _apply_save_data(save_data):
	var _fname = "_apply_save_data"
	if typeof(save_data) != TYPE_DICTIONARY:
		if debug: print(script_name_tag(self, _fname) + "ERROR: Save data is not a dictionary")
		return false
	
	if debug: print(script_name_tag(self, _fname) + "Applying save data to all systems")
	
	# Core GameState data
	if save_data.has("game_id"):
		current_game_id = save_data.game_id
	if save_data.has("play_time"):
		play_time = save_data.play_time
	if save_data.has("game_data"):
		game_data = save_data.game_data.duplicate(true)
	if save_data.has("tags"):
		tags = save_data.tags.duplicate(true)
	
	# GameState memory data
	if save_data.has("discovered_memories"):
		discovered_memories = save_data.discovered_memories.duplicate()
	if save_data.has("memory_discovery_history"):
		memory_discovery_history = save_data.memory_discovery_history.duplicate(true)
	if save_data.has("dialogue_mapping"):
		dialogue_mapping = save_data.dialogue_mapping.duplicate(true)
	
	# Inventory System
	if save_data.has("inventory_system"):
		var inventory_system = get_node_or_null("/root/InventorySystem")
		if inventory_system and inventory_system.has_method("load_save_data"):
			inventory_system.load_save_data(save_data.inventory_system)
			if debug: print(script_name_tag(self, _fname) + "Applied inventory data")
	
	# Quest System
	if save_data.has("quest_system"):
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system and quest_system.has_method("load_save_data"):
			quest_system.load_save_data(save_data.quest_system)
			if debug: print(script_name_tag(self, _fname) + "Applied quest data")
	
	# Relationship System
	if save_data.has("relationship_system"):
		var relationship_system = get_node_or_null("/root/RelationshipSystem")
		if relationship_system and relationship_system.has_method("load_save_data"):
			relationship_system.load_save_data(save_data.relationship_system)
			if debug: print(script_name_tag(self, _fname) + "Applied relationship data")
	
	# Time System
	if save_data.has("time_system"):
		var time_system = get_node_or_null("/root/TimeSystem")
		if time_system and time_system.has_method("load_data"):
			time_system.load_data(save_data.time_system)
			if debug: print(script_name_tag(self, _fname) + "Applied time data")
	
	# Memory System
	if save_data.has("memory_system"):
		var memory_system = get_node_or_null("/root/MemorySystem")
		if memory_system and memory_system.has_method("load_save_data"):
			memory_system.load_save_data(save_data.memory_system)
			if debug: print(script_name_tag(self, _fname) + "Applied memory system data")
	
	# Phone Apps
	if save_data.has("phone_apps"):
		var phone_scene = get_node_or_null("/root/Game/PhoneCanvasLayer/PhoneSceneInstance")
		if not phone_scene:
			phone_scene = get_node_or_null("/root/PhoneScene")
		if phone_scene and phone_scene.has_method("load_save_data"):
			phone_scene.load_save_data(save_data.phone_apps)
			if debug: print(script_name_tag(self, _fname) + "Applied phone app data")
	
	# Reset start time to now
	start_time = Time.get_unix_time_from_system()
	
	if debug: print(script_name_tag(self, _fname) + "Save data application complete")
	return true
```

## 2. Inventory System (`inventory_system.gd`)

### Save/Load Methods

**Location:** Add these methods after the existing `clear_inventory()` method around line 380

**Purpose:** Preserves player inventory items, amounts, tags, and templates state

gdscript

```gdscript
# Save/Load System Integration
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"inventory": inventory.duplicate(true),
		"item_tags": item_tags.duplicate(true),
		"item_templates_loaded": item_templates_loaded
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected inventory data: ", inventory.size(), " items, ", item_tags.size(), " tag categories")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for inventory load")
		return false
	
	# Restore inventory items
	if data.has("inventory"):
		inventory = data.inventory.duplicate(true)
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", inventory.size(), " inventory items")
	
	# Restore item tags organization  
	if data.has("item_tags"):
		item_tags = data.item_tags.duplicate(true)
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", item_tags.size(), " item tag categories")
	
	# Restore template loading state
	if data.has("item_templates_loaded"):
		item_templates_loaded = data.item_templates_loaded
	
	# Emit signals for any items that were restored
	for item_id in inventory:
		var item_data = inventory[item_id]
		item_added.emit(item_id, item_data)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Inventory restoration complete")
	return true
```

## 3. Memory System (`memory_system.gd`)

### Save/Load Methods

**Location:** Add these methods after the existing utility functions around line 300

**Purpose:** Saves memory system state including examination history and current interaction target

gdscript

```gdscript
# Save/Load System Integration
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"examination_history": examination_history.duplicate(),
		"current_target": null  # Don't save node references, just reset
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected memory system data: ", examination_history.size(), " examination entries")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for memory system load")
		return false
	
	# Restore examination history
	if data.has("examination_history"):
		examination_history = data.examination_history.duplicate()
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", examination_history.size(), " examination history entries")
	
	# Reset current target (node references don't persist across saves)
	current_target = null
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory system restoration complete")
	return true
```

## 4. Quest System (`quest_system.gd`)

### Enhanced Save/Load Methods

**Location:** Replace existing `save_quests()` and `load_quests()` methods around line 700

**Purpose:** Preserves quest progress, objectives, visited areas, and area exploration data

gdscript

```gdscript
# Enhanced Save/Load System Integration  
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(true),
		"available_quests": available_quests.duplicate(true),
		"visited_areas": visited_areas.duplicate(true),
		"area_exploration": area_exploration.duplicate(true)
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected quest data: ", active_quests.size(), " active, ", completed_quests.size(), " completed, ", available_quests.size(), " available")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for quest system load")
		return false
	
	# Restore quest states
	if data.has("active_quests"):
		active_quests = data.active_quests.duplicate(true)
	if data.has("completed_quests"):
		completed_quests = data.completed_quests.duplicate(true)
	if data.has("available_quests"):
		available_quests = data.available_quests.duplicate(true)
	
	# Restore exploration progress
	if data.has("visited_areas"):
		visited_areas = data.visited_areas.duplicate(true)
	if data.has("area_exploration"):
		area_exploration = data.area_exploration.duplicate(true)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Quest system restoration complete: ", 
		active_quests.size(), " active quests, ", 
		completed_quests.size(), " completed quests, ",
		available_quests.size(), " available quests, ",
		visited_areas.size(), " visited areas")
	
	# Re-validate inventory-based objectives after loading
	call_deferred("check_inventory_against_tag_objectives")
	return true

# Legacy compatibility wrapper
func save_quests():
	return get_save_data()

# Legacy compatibility wrapper  
func load_quests(save_data):
	return load_save_data(save_data)
```

## 5. Relationship System (`relationship_system.gd`)

### Save/Load Methods

**Location:** Add these methods after the existing relationship management functions around line 150

**Purpose:** Preserves NPC relationship levels, affinity scores, key moments, and character flags

gdscript

```gdscript
# Save/Load System Integration
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"relationships": relationships.duplicate(true)
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected relationship data for ", relationships.size(), " characters")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for relationship system load")
		return false
	
	# Restore all relationship data
	if data.has("relationships"):
		relationships = data.relationships.duplicate(true)
		
		# Emit relationship change signals for any relationships that exist
		for character_id in relationships:
			var relationship = relationships[character_id]
			var level = relationship.get("level", RelationshipLevel.STRANGER)
			relationship_changed.emit(character_id, RelationshipLevel.STRANGER, level)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored relationships for ", relationships.size(), " characters")
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Relationship system restoration complete")
	return true
```

## 6. Time System (`time_system.gd`)

### Note on Existing Implementation

**Location:** The `time_system.gd` already has `save_data()` and `load_data()` methods

**Purpose:** These methods preserve day/month/year, time of day, and internal accumulator state

**Action Required:** No changes needed - the existing methods are compatible. Just ensure they're called from GameState (see GameState code above).

**Existing Methods:**

gdscript

```gdscript
# Already implemented correctly in time_system.gd
func save_data() -> Dictionary:
	return {
		"day": current_day,
		"month": current_month, 
		"year": current_year,
		"time_of_day": current_time_of_day,
		"accumulator": time_accumulator
	}

func load_data(data: Dictionary) -> void:
	if data.has("day"):
		current_day = data.day
	# ... rest of implementation already exists
```

## 7. Phone Apps (`PhoneScene.gd` or similar)

### Phone Scene Save/Load Methods

**Location:** Add to the main phone scene script (likely `res://scenes/ui/phone/PhoneScene.gd`)

**Purpose:** Preserves Discord messages, email conversations, journal entries, and app states

gdscript

```gdscript
# Save/Load System Integration for Phone Apps
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"phone_apps": {}
	}
	
	# Discord App Data
	var discord_app = get_node_or_null("DiscordApp")
	if discord_app and discord_app.has_method("get_save_data"):
		save_data.phone_apps["discord"] = discord_app.get_save_data()
	elif discord_app:
		# Fallback for basic Discord data
		save_data.phone_apps["discord"] = {
			"messages": discord_app.get("messages", []),
			"channels": discord_app.get("channels", {}),
			"read_status": discord_app.get("read_status", {}),
			"current_channel": discord_app.get("current_channel", "")
		}
	
	# Email App Data
	var email_app = get_node_or_null("EmailApp")
	if email_app and email_app.has_method("get_save_data"):
		save_data.phone_apps["email"] = email_app.get_save_data()
	elif email_app:
		# Fallback for basic email data
		save_data.phone_apps["email"] = {
			"inbox": email_app.get("inbox", []),
			"sent": email_app.get("sent", []),
			"drafts": email_app.get("drafts", []),
			"read_emails": email_app.get("read_emails", [])
		}
	
	# Journal App Data
	var journal_app = get_node_or_null("JournalApp")
	if journal_app and journal_app.has_method("get_save_data"):
		save_data.phone_apps["journal"] = journal_app.get_save_data()
	elif journal_app:
		# Fallback for basic journal data
		save_data.phone_apps["journal"] = {
			"entries": journal_app.get("entries", []),
			"categories": journal_app.get("categories", []),
			"bookmarks": journal_app.get("bookmarks", []),
			"last_entry_date": journal_app.get("last_entry_date", "")
		}
	
	# Phone UI state
	save_data["phone_ui"] = {
		"current_app": get("current_app", ""),
		"notifications": get("notifications", []),
		"app_settings": get("app_settings", {})
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected phone app data")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for phone apps load")
		return false
	
	# Restore Discord App
	if data.has("phone_apps") and data.phone_apps.has("discord"):
		var discord_app = get_node_or_null("DiscordApp")
		if discord_app and discord_app.has_method("load_save_data"):
			discord_app.load_save_data(data.phone_apps.discord)
		elif discord_app:
			# Fallback restoration
			var discord_data = data.phone_apps.discord
			if discord_data.has("messages") and discord_app.has_method("set"):
				discord_app.set("messages", discord_data.messages)
			# ... additional fallback restoration
	
	# Restore Email App
	if data.has("phone_apps") and data.phone_apps.has("email"):
		var email_app = get_node_or_null("EmailApp")
		if email_app and email_app.has_method("load_save_data"):
			email_app.load_save_data(data.phone_apps.email)
		# ... fallback restoration similar to Discord
	
	# Restore Journal App
	if data.has("phone_apps") and data.phone_apps.has("journal"):
		var journal_app = get_node_or_null("JournalApp")
		if journal_app and journal_app.has_method("load_save_data"):
			journal_app.load_save_data(data.phone_apps.journal)
		# ... fallback restoration similar to Discord
	
	# Restore Phone UI state
	if data.has("phone_ui"):
		var ui_data = data.phone_ui
		if ui_data.has("current_app"):
			set("current_app", ui_data.current_app)
		if ui_data.has("notifications"):
			set("notifications", ui_data.notifications)
		if ui_data.has("app_settings"):
			set("app_settings", ui_data.app_settings)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Phone apps restoration complete")
	return true
```

### Individual Phone App Save/Load (Discord Example)

**Location:** Add to individual app scripts (e.g., `DiscordApp.gd`)

**Purpose:** Each app manages its own specific data format and state

gdscript

```gdscript
# Discord App Save/Load Methods
func get_save_data():
	var _fname = "get_save_data"
	return {
		"messages": messages.duplicate(true),
		"channels": channels.duplicate(true),
		"read_status": read_status.duplicate(true),
		"current_channel": current_channel,
		"notification_settings": notification_settings.duplicate(true),
		"user_status": user_status
	}

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	if data.has("messages"):
		messages = data.messages.duplicate(true)
	if data.has("channels"):
		channels = data.channels.duplicate(true)
	if data.has("read_status"):
		read_status = data.read_status.duplicate(true)
	if data.has("current_channel"):
		current_channel = data.current_channel
	if data.has("notification_settings"):
		notification_settings = data.notification_settings.duplicate(true)
	if data.has("user_status"):
		user_status = data.user_status
	
	# Refresh UI after loading
	call_deferred("refresh_message_display")
	return true
```

## Sample JSON Save Structure

Here's what the complete save file should look like:

json

```json
{
  "save_format_version": 2,
  "save_time": 1703123456.789,
  "play_time": 1234.5,
  "game_id": "game_1703123456_7890",
  "game_data": {
	"player_name": "Adam Major",
	"current_location": "campus_quad",
	"current_scene_path": "res://scenes/world/locations/campus_quad.tscn",
	"player_position": {"x": 1730.0, "y": 800.0},
	"player_direction": {"x": 0.0, "y": 1.0},
	"current_day": 5,
	"current_turn": 3,
	"turns_per_day": 8
  },
  "tags": {
	"intro_completed": true,
	"poison_necklace_seen": true,
	"erik_gummies_seen": false
  },
  "discovered_memories": ["poison_necklace_seen", "intro_memory"],
  "memory_discovery_history": [
	{
	  "memory_tag": "poison_necklace_seen",
	  "description": "Noticed Poison's mysterious necklace",
	  "discovery_method": "look_at",
	  "character_id": "poison",
	  "location": "campus_quad",
	  "timestamp": 1703123400.0,
	  "game_day": 5
	}
  ],
  "dialogue_mapping": {
	"poison_necklace_seen": {
	  "character_id": "poison",
	  "dialogue_title": "necklace_conversation"
	}
  },
  "inventory_system": {
	"inventory": {
	  "common_lichen1": {"amount": 3, "category": 0},
	  "energy_drink": {"amount": 1, "category": 2}
	},
	"item_tags": {
	  "lichen": ["common_lichen1"],
	  "consumable": ["energy_drink"]
	},
	"item_templates_loaded": true
  },
  "quest_system": {
	"active_quests": {
	  "intro_quest": {
		"id": "intro_quest",
		"title": "Welcome to Campus",
		"objectives": [
		  {"type": "visit", "target": "campus_quad", "completed": true},
		  {"type": "talk", "target": "professor_moss", "completed": false}
		],
		"completed": false
	  }
	},
	"completed_quests": {},
	"available_quests": {},
	"visited_areas": {
	  "campus_quad": true,
	  "library": false
	},
	"area_exploration": {
	  "campus_quad": {
		"visited_areas": ["center", "north_path", "library_entrance"]
	  }
	}
  },
  "relationship_system": {
	"relationships": {
	  "professor_moss": {
		"name": "Professor Moss",
		"level": 1,
		"affinity": 15,
		"key_moments": ["first_meeting"],
		"flags": {"introduced": true}
	  },
	  "poison": {
		"name": "Poison",
		"level": 0,
		"affinity": 5,
		"key_moments": [],
		"flags": {}
	  }
	}
  },
  "time_system": {
	"day": 5,
	"month": 1,
	"year": 1,
	"time_of_day": 2,
	"accumulator": 45.2
  },
  "memory_system": {
	"examination_history": [
	  {"target": "poison", "feature": "necklace", "timestamp": 1703123400.0}
	],
	"current_target": null
  },
  "phone_apps": {
	"phone_apps": {
	  "discord": {
		"messages": [
		  {
			"channel": "general",
			"author": "Erik",
			"content": "Anyone seen my gummies?",
			"timestamp": 1703123000,
			"read": true
		  }
		],
		"channels": {
		  "general": {"name": "General", "unread_count": 0},
		  "study_group": {"name": "Study Group", "unread_count": 2}
		},
		"read_status": {"general": 1703123000},
		"current_channel": "general"
	  },
	  "email": {
		"inbox": [
		  {
			"from": "registrar@university.edu",
			"subject": "Class Schedule Reminder",
			"body": "Don't forget about your morning lecture...",
			"timestamp": 1703120000,
			"read": true
		  }
		],
		"sent": [],
		"drafts": []
	  },
	  "journal": {
		"entries": [
		  {
			"title": "First Day Thoughts",
			"content": "Campus is bigger than I expected...",
			"timestamp": 1703100000,
			"category": "personal"
		  }
		],
		"categories": ["personal", "academic", "memories"],
		"bookmarks": []
	  }
	},
	"phone_ui": {
	  "current_app": "",
	  "notifications": [],
	  "app_settings": {}
	}
  }
}
```

## Implementation Notes

1. **Error Handling:** All methods include type checking and graceful failure modes
2. **Debug Output:** Consistent debug logging following the `GameState.script_name_tag()` pattern
3. **Deep Copying:** Uses `.duplicate(true)` to avoid reference issues
4. **Backward Compatibility:** Maintains existing method names where possible
5. **Deferred Calls:** Uses `call_deferred()` for UI updates that need to happen after scene loading
6. **Signal Emission:** Restores signals and UI state after loading data

The Claude Code agent should prioritize implementing these methods in the order listed, testing each system individually before moving to the next one.
