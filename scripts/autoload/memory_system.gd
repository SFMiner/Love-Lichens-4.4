extends Node

# Signals for other systems
signal memory_discovered(memory_tag: String, description: String)
signal memory_chain_completed(character_id: String, chain_id: String)
signal dialogue_option_unlocked(character_id: String, dialogue_title: String, memory_tag: String)

signal quest_unlocked_by_memory(quest_id: String, memory_tag: String)

# Memory trigger types
enum TriggerType {
	LOOK_AT,
	ITEM_ACQUIRED,
	LOCATION_VISITED,
	DIALOGUE_CHOICE,
	QUEST_COMPLETED,
	CHARACTER_RELATIONSHIP,
	TIME_PASSED,
	ITEM_USED,
	NPC_TALKED_TO
}

const scr_debug : bool = true
var debug

var current_target = null
var examination_history: Array = []

func _ready():
	var _fname = "ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory System initialized")
	
	# Wait for GameState to load memory data
	if GameState.has_signal("memory_data_loaded"):
		if not GameState.memory_data_loaded.is_connected(_on_memory_data_ready):
			GameState.memory_data_loaded.connect(_on_memory_data_ready)
	else:
		# If signal doesn't exist, just proceed
		call_deferred("_on_memory_data_ready")
	
	_connect_to_other_systems()



func _on_memory_data_ready():
	var _fname = "_on_memory_data_ready"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory system ready - GameState has loaded all memory definitions")
	
	# Debug check what memories are available
	if debug:
		print(GameState.script_name_tag(self, _fname) + "MEMORY SYSTEM: Checking available memories")
		for trigger_type in range(9):
			var memories = GameState.get_memories_for_trigger(trigger_type, "test")
			print(GameState.script_name_tag(self, _fname) + "  Trigger type ", trigger_type, " has memories defined: ", memories.size() > 0)
			
func _connect_to_other_systems():
	var _fname = "_connect_to_other_systems"
	# Connect to inventory for item acquisitions
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system and inventory_system.has_signal("item_added"):
		inventory_system.item_added.connect(_on_item_acquired)
	
	# Connect to dialog system for dialogue choices
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		if dialog_system.has_signal("dialog_ended"):
			dialog_system.dialog_ended.connect(_on_dialog_ended)
		if dialog_system.has_signal("memory_unlocked"):
			dialog_system.memory_unlocked.connect(_on_memory_unlocked)

# Main API - now just queries GameState and triggers discoveries
func trigger_item_acquired(item_id: String) -> bool:
	var _fname = "trigger_item_acquired"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Item acquired ", item_id)
	
	# Validate item exists
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		var item_template = inventory_system.get_item_template(item_id)
		if not item_template:
			if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Memory trigger for non-existent item: ", item_id)
			return false
	
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.ITEM_ACQUIRED, item_id)
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "item_acquired", item_id)
			triggered_any = true
	
	return triggered_any

func trigger_npc_talked_to(npc_id: String) -> bool:
	var _fname = "trigger_npc_talked_to"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Talked to NPC ", npc_id)
	
	# Try both the exact ID and lowercase version
	var ids_to_try = [npc_id, npc_id.to_lower()]
	var triggered_any = false
	
	for id in ids_to_try:
		var matching_memories = GameState.get_memories_for_trigger(TriggerType.NPC_TALKED_TO, id)
		
		for memory_data in matching_memories:
			if _check_memory_conditions(memory_data):
				_process_memory_unlock(memory_data, "npc_interaction", id)
				triggered_any = true
	
	return triggered_any

func trigger_location_visited(location_id: String) -> bool:
	var _fname = "trigger_location_visited"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Location visited ", location_id)
	
	# VALIDATION: Check if location exists (basic scene file check)
	var location_path = "res://scenes/world/locations/" + location_id + ".tscn"
	if not ResourceLoader.exists(location_path):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Memory trigger for non-existent location: ", location_id, " (", location_path, ")")
		# Don't return false here - location might be an area within a scene, not a full scene
	
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.LOCATION_VISITED, location_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for location: ", location_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "location_visit", location_id)
			triggered_any = true
	
	return triggered_any

func trigger_look_at(target_id: String) -> bool:
	var _fname = "trigger_look_at"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Look at ", target_id)
	
	# Get memories from GameState
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.LOOK_AT, target_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for looking at: ", target_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "look_at", target_id)
			triggered_any = true
	
	return triggered_any

# Add other trigger functions following the same pattern...

# VALIDATION: Helper functions to verify IDs exist in their respective systems
func _validate_item_id(item_id: String) -> bool:
	var _fname = "_validate_item_id"
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		var item_template = inventory_system.get_item_template(item_id)
		return item_template != null
	
	if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Cannot validate item_id - InventorySystem not found")
	return true  # Assume valid if system not available

func _validate_character_id(character_id: String) -> bool:
	var _fname = "_validate_character_id"
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var character_data = character_loader.get_character(character_id)
		return character_data != null
	
	if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Cannot validate character_id - CharacterDataLoader not found")
	return true  # Assume valid if system not available

func _validate_location_id(location_id: String) -> bool:
	var _fname = "_validate_location_id"
	# Check if it's a scene file
	var location_path = "res://scenes/world/locations/" + location_id + ".tscn"
	if ResourceLoader.exists(location_path):
		return true
	
	# Could also be an area within a scene, so don't be too strict
	if debug: print(GameState.script_name_tag(self, _fname) + "INFO: Location ", location_id, " not found as scene file, might be area ID")
	return true

func _validate_quest_id(quest_id: String) -> bool:
	var _fname = "_validate_quest_id"
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		return quest_system.get_quest(quest_id) != null
	
	if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Cannot validate quest_id - QuestSystem not found")
	return true


func trigger_quest_completed(quest_id: String) -> bool:
	var _fname = "trigger_quest_completed"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Quest completed ", quest_id)
	
	# VALIDATION: Check if quest exists
	if not _validate_quest_id(quest_id):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Memory trigger for non-existent quest: ", quest_id)
		return false
	
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.QUEST_COMPLETED, quest_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for quest completion: ", quest_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "quest_completed", quest_id)
			triggered_any = true
	
	return triggered_any

func trigger_dialogue_choice(choice_id: String) -> bool:
	var _fname = "trigger_dialogue_choice"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Dialogue choice ", choice_id)
	
	# Note: Dialogue choices are dynamic, so no validation here
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.DIALOGUE_CHOICE, choice_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for dialogue choice: ", choice_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "dialogue_choice", choice_id)
			triggered_any = true
	
	return triggered_any

func trigger_item_used(item_id: String) -> bool:
	var _fname = "trigger_item_used"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Item used ", item_id)
	
	# VALIDATION: Check if item exists
	if not _validate_item_id(item_id):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Memory trigger for non-existent item usage: ", item_id)
		return false
	
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.ITEM_USED, item_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for item usage: ", item_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "item_used", item_id)
			triggered_any = true
	
	return triggered_any

func trigger_character_relationship(character_id: String) -> bool:
	var _fname = "trigger_character_relationship"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Character relationship change ", character_id)
	
	# VALIDATION: Check if character exists
	if not _validate_character_id(character_id):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Memory trigger for non-existent character relationship: ", character_id)
		return false
	
	var matching_memories = GameState.get_memories_for_trigger(TriggerType.CHARACTER_RELATIONSHIP, character_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for character relationship: ", character_id)
		return false
	
	var triggered_any = false
	for memory_data in matching_memories:
		if _check_memory_conditions(memory_data):
			_process_memory_unlock(memory_data, "relationship_change", character_id)
			triggered_any = true
	
	return triggered_any

func _check_memory_conditions(memory_data: Dictionary) -> bool:
	var _fname = "_check_memory_conditions"
	var unlock_tag = memory_data.get("unlock_tag", "")
	
	# Check if already discovered
	if GameState.has_discovered_memory(unlock_tag):
		return false
	
	# Check condition tags
	var condition_tags = memory_data.get("condition_tags", [])
	for condition_tag in condition_tags:
		if not GameState.has_tag(condition_tag):
			if debug: print(GameState.script_name_tag(self, _fname) + "Memory condition not met: ", condition_tag)
			return false
	
	return true

func _process_memory_unlock(memory_data: Dictionary, discovery_method: String, trigger_target: String):
	var _fname = "_process_memory_unlock"
	var unlock_tag = memory_data.get("unlock_tag", "")
	var description = memory_data.get("description", "")
	var character_id = memory_data.get("character_id", "")
	var dialogue_title = memory_data.get("dialogue_title", "")
	
	# Let GameState handle the discovery
	if GameState.discover_memory(unlock_tag, description, discovery_method, character_id):
		# Newly discovered
		memory_discovered.emit(unlock_tag, description)
		
		# Check for dialogue unlocks
		if not dialogue_title.is_empty() and not character_id.is_empty():
			dialogue_option_unlocked.emit(character_id, dialogue_title, unlock_tag)
			if debug: print(GameState.script_name_tag(self, _fname) + "Unlocked dialogue option: ", character_id, " -> ", dialogue_title)
		
		# Show notification
		var notification_system = get_node_or_null("/root/NotificationSystem")
		if notification_system and notification_system.has_method("show_notification"):
			notification_system.show_notification(description)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Memory discovered: ", unlock_tag, " - ", description)

func _check_memory_consequences(memory_data: Dictionary, character_id: String):
	var _fname = "_check_memory_consequences"
	# Check if this unlocks dialogue options
	# Check if this unlocks quests
	# Check if this completes memory chains
	# etc.
	pass

# Signal handlers
func _on_memory_discovered_in_gamestate(memory_tag: String, description: String):
	var _fname = "_on_memory_discovered_in_gamestate"
	# GameState discovered a memory, re-emit our signal for other systems
	memory_discovered.emit(memory_tag, description)

func _on_item_acquired(item_id: String, item_data: Dictionary):
	var _fname = "_on_item_acquired"
	trigger_item_acquired(item_id)
	
	# Also check for item tags
	if item_data.has("tags"):
		for tag in item_data.tags:
			trigger_item_acquired(tag)

func _on_dialog_ended(character_id: String):
	var _fname = "_on_dialog_ended"
	# Trigger NPC talked to memory
	trigger_npc_talked_to(character_id)

func _on_memory_unlocked(memory_tag: String):
	var _fname = "_on_memory_unlocked"
	# Direct memory unlock from dialogue
	var description = "Memory unlocked through dialogue"
	GameState.discover_memory(memory_tag, description, "dialogue")

# Utility functions that just query GameState
func has_memory(memory_tag: String) -> bool:
	return GameState.has_tag(memory_tag)

func get_discovered_memories() -> Array:
	return GameState.discovered_memories.duplicate()

func get_memory_history() -> Array:
	return GameState.get_memory_discovery_history()

func get_character_memories(character_id: String) -> Array:
	return GameState.get_character_discoveries(character_id)

# Dialogue integration functions (now using GameState)
func get_available_dialogue_options(character_id: String) -> Array:
	return GameState.get_available_dialogue_options(character_id)

func is_dialogue_available(character_id: String, dialogue_title: String) -> bool:
	return GameState.is_dialogue_available(character_id, dialogue_title)

func get_memory_tag_for_dialogue(character_id: String, dialogue_title: String) -> String:
	return GameState.get_memory_tag_for_dialogue(character_id, dialogue_title)
