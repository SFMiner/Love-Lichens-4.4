extends Node

# Signals for other systems
signal memory_chain_completed(character_id: String, chain_id: String)
signal memory_discovered(memory_tag: String, description: String)
signal dialogue_option_unlocked(character_id: String, dialogue_title: String, memory_tag: String)

signal quest_unlocked_by_memory(quest_id: String, memory_tag: String)

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

const scr_debug : bool = false
var debug

var current_target = null
var examination_history: Array = []

func _ready():
	var _fname = "ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory System initialized")
	
	# Wait for GameState to load memory data
	if not GameState.safe_connect(GameState, "memory_data_loaded", Callable(self, "_on_memory_data_ready")):
		# If connection fails, proceed deferred
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
	if inventory_system:
		GameState.safe_connect(inventory_system, "item_added", Callable(self, "_on_item_acquired"))

	# Connect to dialog system for dialogue choices
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		GameState.safe_connect(dialog_system, "dialog_ended", Callable(self, "_on_dialog_ended"))

# SIMPLIFIED: Main trigger functions now use registry
func trigger_look_at(target_id: String) -> bool:
	var _fname = "trigger_look_at"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Look at ", target_id)
	
	return _process_memory_triggers(TriggerType.LOOK_AT, target_id, "look_at")

func trigger_item_acquired(item_id: String) -> bool:
	var _fname = "trigger_item_acquired"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Item acquired ", item_id)
	
	return _process_memory_triggers(TriggerType.ITEM_ACQUIRED, item_id, "item_acquired")

func trigger_location_visited(location_id: String) -> bool:
	var _fname = "trigger_location_visited"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Location visited ", location_id)
	
	return _process_memory_triggers(TriggerType.LOCATION_VISITED, location_id, "location_visit")

func trigger_npc_talked_to(npc_id: String) -> bool:
	var _fname = "trigger_npc_talked_to"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Talked to NPC ", npc_id)
	
	return _process_memory_triggers(TriggerType.NPC_TALKED_TO, npc_id, "npc_interaction")

func trigger_quest_completed(quest_id: String) -> bool:
	var _fname = "trigger_quest_completed"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Quest completed ", quest_id)
	
	return _process_memory_triggers(TriggerType.QUEST_COMPLETED, quest_id, "quest_completed")

func trigger_dialogue_choice(choice_id: String) -> bool:
	var _fname = "trigger_dialogue_choice"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Dialogue choice ", choice_id)
	
	return _process_memory_triggers(TriggerType.DIALOGUE_CHOICE, choice_id, "dialogue_choice")

func trigger_item_used(item_id: String) -> bool:
	var _fname = "trigger_item_used"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Item used ", item_id)
	
	return _process_memory_triggers(TriggerType.ITEM_USED, item_id, "item_used")

func trigger_character_relationship(character_id: String) -> bool:
	var _fname = "trigger_character_relationship"
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory trigger: Character relationship change ", character_id)
	
	return _process_memory_triggers(TriggerType.CHARACTER_RELATIONSHIP, character_id, "relationship_change")

# CORE: Process memory triggers using registry
func _process_memory_triggers(trigger_type: int, target_id: String, discovery_method: String) -> bool:
	var _fname = "_process_memory_triggers"
	var triggered_any = false
	
	# Get matching memories from registry
	var matching_memories = GameState.get_memories_for_trigger_type(trigger_type, target_id)
	
	if matching_memories.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory triggers found for: ", target_id)
		return false
	
	for memory_data in matching_memories:
		var tag_name = memory_data.tag_name
		var metadata = memory_data.metadata
		
		# Check if memory can be unlocked using registry-based function
		if GameState.can_unlock_memory(tag_name):
			# Discover the memory
			if GameState.discover_memory_from_registry(tag_name, discovery_method):
				triggered_any = true
				
				# Check for dialogue unlocks
				var dialogue_title = metadata.get("dialogue_title", "")
				var character_id = metadata.get("character_id", "")
				
				if dialogue_title != "" and character_id != "":
					dialogue_option_unlocked.emit(character_id, dialogue_title, tag_name)
					if debug: print(GameState.script_name_tag(self, _fname) + "Unlocked dialogue option: ", character_id, " -> ", dialogue_title)
				
				# Show notification
				var notification_system = get_node_or_null("/root/NotificationSystem")
				if notification_system and notification_system.has_method("show_notification"):
					notification_system.show_notification(metadata.get("description", ""))
	
	return triggered_any

# SIMPLIFIED: Dialogue integration functions
func get_available_dialogue_options(character_id: String) -> Array:
	"""Get available dialogue options for a character - now uses registry"""
	return GameState.get_dialogue_options_from_registry(character_id)

func is_dialogue_available(character_id: String, dialogue_title: String) -> bool:
	"""Check if dialogue is available - now uses registry"""
	return GameState.is_dialogue_available_from_registry(character_id, dialogue_title)

func get_memory_tag_for_dialogue(character_id: String, dialogue_title: String) -> String:
	"""Get memory tag for dialogue - now uses registry"""
	return GameState.get_memory_tag_for_dialogue_from_registry(character_id, dialogue_title)

# Utility functions remain the same
func has_memory(memory_tag: String) -> bool:
	return GameState.has_tag(memory_tag)

func get_discovered_memories() -> Array:
	return GameState.discovered_memories.duplicate()

func get_character_memories(character_id: String) -> Array:
	return GameState.get_character_discoveries(character_id)

# Signal handlers
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
	# Direct memory unlock from dialogue - use registry to get metadata
	var metadata = GameState.get_memory_metadata(memory_tag)
	var description = metadata.get("description", "Memory unlocked through dialogue")
	GameState.discover_memory_from_registry(memory_tag, "dialogue")


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
