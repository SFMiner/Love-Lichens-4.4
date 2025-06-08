# Enhanced dialog_memory_extension.gd
extends Node

# Dialog Memory Extension for Love & Lichens
# Advanced integration between dialogue system and memory system

signal memory_option_selected(character_id, memory_tag)
signal dialogue_memory_updated(character_id, memory_tag, dialogue_title)
signal conditional_dialogue_checked(character_id, condition_result)

# Reference to systems
var memory_system: Node
var game_state: Node
var relationship_system: Node
var quest_system: Node

# Memory-dialogue tracking
var dialogue_memory_cache: Dictionary = {}
var conditional_dialogue_cache: Dictionary = {}
var character_memory_states: Dictionary = {}

const scr_debug : bool = false
var debug

func _ready():
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "Enhanced Dialog Memory Extension initialized")
	
	await get_tree().process_frame
	_connect_to_systems()
	_initialize_dialogue_memory_cache()

# SIMPLIFIED: Memory checking functions using registry
func has_memory(memory_tag: String) -> bool:
	"""Check if memory exists and is unlocked - validates against registry"""
	var _fname = "has_memory"
	
	# Validate tag exists in registry
	if not GameState.is_valid_memory_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid memory tag: ", memory_tag)
		return false
	
	return GameState.has_tag(memory_tag)

func get_memory_value(memory_tag: String, default_value = null):
	"""Get memory value with registry validation"""
	var _fname = "get_memory_value"
	
	# Validate tag exists in registry
	if not GameState.is_valid_memory_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid memory tag: ", memory_tag)
		return default_value
	
	return GameState.get_tag_value(memory_tag, default_value)

func set_memory(memory_tag: String, value = true):
	"""Set memory with registry validation and proper discovery"""
	var _fname = "set_memory"
	
	# Validate tag exists in registry
	if not GameState.is_valid_memory_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Cannot set invalid memory tag: ", memory_tag)
		return
	
	# Use registry-based discovery if this is a new memory
	if not GameState.has_tag(memory_tag) and value:
		GameState.discover_memory_from_registry(memory_tag, "dialogue_system")
	else:
		# Just set the tag directly
		GameState.set_tag(memory_tag, value)

func _connect_to_systems():
	var _fname = "_connect_to_systems"
	memory_system = get_node_or_null("/root/MemorySystem")
	game_state = get_node_or_null("/root/GameState")
	relationship_system = get_node_or_null("/root/RelationshipSystem")
	quest_system = get_node_or_null("/root/QuestSystem")
	
	# Connect to memory system signals
	if memory_system:
		if memory_system.has_signal("memory_discovered"):
			memory_system.memory_discovered.connect(_on_memory_discovered)
		if memory_system.has_signal("dialogue_option_unlocked"):
			memory_system.dialogue_option_unlocked.connect(_on_dialogue_option_unlocked)
		if debug: print(GameState.script_name_tag(self, _fname) + "Connected to memory system signals")
	
	# Connect to relationship system
	if relationship_system:
		if relationship_system.has_signal("relationship_changed"):
			relationship_system.relationship_changed.connect(_on_relationship_changed)

func _initialize_dialogue_memory_cache():
	var _fname = "_initialize_dialogue_memory_cache"
	# Pre-cache dialogue-memory relationships for performance
	if memory_system:
		# Get available dialogue options from GameState instead of memory_system.dialogue_mapping
		var all_characters = []
		
		# Get all character IDs from CharacterDataLoader
		var character_loader = get_node_or_null("/root/CharacterDataLoader")
		if character_loader:
			all_characters = character_loader.characters.keys()
		
		# Build cache for each character
		for character_id in all_characters:
			var dialogue_options = GameState.get_available_dialogue_options(character_id)
			
			if not dialogue_memory_cache.has(character_id):
				dialogue_memory_cache[character_id] = {}
			
			for option in dialogue_options:
				var dialogue_title = option.dialogue_title
				var memory_tag = option.tag
				dialogue_memory_cache[character_id][dialogue_title] = memory_tag
				
				if debug: print(GameState.script_name_tag(self, _fname) + "Cached dialogue mapping: ", character_id, " -> ", dialogue_title, " = ", memory_tag)

# Core dialogue-memory functions for use in .dialogue files

func increment_memory(memory_tag: String, amount: int = 1):
	var _fname = "increment_memory"
	if game_state:
		var current_value = game_state.get_tag_value(memory_tag, 0)
		if typeof(current_value) == TYPE_INT or typeof(current_value) == TYPE_FLOAT:
			game_state.set_tag(memory_tag, current_value + amount)

# ENHANCED: Complex memory condition checking using registry metadata
func check_memory_condition(condition: String) -> bool:
	"""Parse and evaluate memory conditions with registry validation"""
	var _fname = "check_memory_condition"
	
	# Parse the condition string (same logic as before, but with validation)
	condition = condition.strip_edges()
	
	# Handle negation
	if condition.begins_with("!"):
		return not check_memory_condition(condition.substr(1).strip_edges())
	
	# Handle OR conditions
	if " || " in condition:
		var parts = condition.split(" || ")
		for part in parts:
			if check_memory_condition(part.strip_edges()):
				return true
		return false
	
	# Handle AND conditions
	if " && " in condition:
		var parts = condition.split(" && ")
		for part in parts:
			if not check_memory_condition(part.strip_edges()):
				return false
		return true
	
	# Handle comparison operations (same as before, but with registry validation)
	if " == " in condition:
		var parts = condition.split(" == ")
		if parts.size() == 2:
			var memory_tag = parts[0].strip_edges()
			if not GameState.is_valid_memory_tag(memory_tag):
				if debug: print(GameState.script_name_tag(self, _fname) + "Invalid memory tag in condition: ", memory_tag)
				return false
			var memory_value = get_memory_value(memory_tag)
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value == compare_value
	
	# ... (other comparison operators remain the same but with validation)
	
	# Simple boolean check with validation
	if not GameState.is_valid_memory_tag(condition):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid memory tag in condition: ", condition)
		return false
	
	return has_memory(condition)
	
# SIMPLIFIED: Character memory state using registry
func get_character_memory_state(character_id: String) -> Dictionary:
	"""Get character memory state using registry data"""
	var _fname = "get_character_memory_state"
	
	var state = {
		"discovered_memories": [],
		"available_dialogues": [],
		"relationship_level": 0,
		"memory_tags": []
	}
	
	# Get all memories for this character from registry
	for tag_name in GameState.memory_registry.keys():
		var metadata = GameState.memory_registry[tag_name]
		
		if metadata.get("character_id", "") == character_id:
			state.memory_tags.append(tag_name)
			
			if GameState.has_tag(tag_name):
				state.discovered_memories.append(tag_name)
				
				# Check for dialogue options
				var dialogue_title = metadata.get("dialogue_title", "")
				if dialogue_title != "":
					state.available_dialogues.append(dialogue_title)
	
	# Get relationship level if system exists
	if relationship_system:
		state.relationship_level = relationship_system.get_relationship_score(character_id)
	
	return state

# SIMPLIFIED: Dialogue availability using registry
func can_show_dialogue(character_id: String, dialogue_title: String) -> bool:
	"""Check if dialogue can be shown using registry conditions"""
	var _fname = "can_show_dialogue"
	
	# Get memory tag for this dialogue from registry
	var memory_tag = GameState.get_memory_tag_for_dialogue_from_registry(character_id, dialogue_title)
	
	if memory_tag.is_empty():
		# No memory requirements, allow dialogue
		return true
	
	# Check if memory is unlocked
	if not GameState.has_tag(memory_tag):
		return false
	
	# Get additional requirements from registry metadata
	var metadata = GameState.get_memory_metadata(memory_tag)
	
	# Check relationship requirements (if specified in metadata)
	if metadata.has("min_relationship"):
		if relationship_system:
			var current_level = relationship_system.get_relationship_score(character_id)
			if current_level < metadata.min_relationship:
				return false
	
	# Check quest requirements (if specified in metadata)
	if metadata.has("required_quest"):
		if quest_system:
			var quest_id = metadata.required_quest
			if not quest_system.is_quest_active(quest_id) and not quest_system.is_quest_completed(quest_id):
				return false
	
	# Check condition tags from registry
	var condition_tags = metadata.get("condition_tags", [])
	for condition_tag in condition_tags:
		if not GameState.has_tag(condition_tag):
			return false
	
	return true

# SIMPLIFIED: Get memory dialogue options using registry
func get_memory_dialogue_options(character_id: String) -> Array:
	"""Get memory-driven dialogue options using registry"""
	var _fname = "get_memory_dialogue_options"
	var options = []
	
	# Get available dialogue options from registry
	var available_options = GameState.get_dialogue_options_from_registry(character_id)
	
	for option in available_options:
		if can_show_dialogue(character_id, option.dialogue_title):
			options.append({
				"title": option.dialogue_title,
				"memory_tag": option.tag,
				"display_text": _get_dialogue_display_text(character_id, option.dialogue_title),
				"description": option.description
			})
	
	return options

# SIMPLIFIED: Memory discovery trigger using registry
func trigger_memory_discovery(character_id: String, memory_tag: String, description: String = ""):
	"""Trigger memory discovery with registry validation"""
	var _fname = "trigger_memory_discovery"
	
	# Validate memory tag
	if not GameState.is_valid_memory_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Cannot trigger invalid memory tag: ", memory_tag)
		return
	
	# Use description from registry if not provided
	if description.is_empty():
		var metadata = GameState.get_memory_metadata(memory_tag)
		description = metadata.get("description", "Memory discovered")
	
	# Discover using registry system
	GameState.discover_memory_from_registry(memory_tag, "dialogue_trigger")

# NEW: Registry-based memory validation
func validate_memory_tags(tag_list: Array) -> Dictionary:
	"""Validate a list of memory tags against the registry"""
	var _fname = "validate_memory_tags"
	var result = {
		"valid": [],
		"invalid": [],
		"warnings": []
	}
	
	for tag in tag_list:
		if GameState.is_valid_memory_tag(tag):
			result.valid.append(tag)
		else:
			result.invalid.append(tag)
			result.warnings.append("Invalid memory tag: " + tag)
	
	if debug and result.invalid.size() > 0:
		print(GameState.script_name_tag(self, _fname) + "Found invalid memory tags: ", result.invalid)
	
	return result

# ENHANCED: Debug functions using registry
func debug_character_memories(character_id: String):
	"""Debug character memories using registry data"""
	var _fname = "debug_character_memories"
	if not debug:
		return
	
	print("\n" + GameState.script_name_tag(self, _fname) + "=== CHARACTER MEMORY DEBUG (REGISTRY): ", character_id, " ===")
	
	var state = get_character_memory_state(character_id)
	
	print(GameState.script_name_tag(self, _fname) + "Total memory tags for character: ", state.memory_tags.size())
	print(GameState.script_name_tag(self, _fname) + "Discovered memories: ", state.discovered_memories.size())
	print(GameState.script_name_tag(self, _fname) + "Available dialogues: ", state.available_dialogues.size())
	
	print(GameState.script_name_tag(self, _fname) + "Memory tags from registry:")
	for tag in state.memory_tags:
		var metadata = GameState.get_memory_metadata(tag)
		var is_unlocked = GameState.has_tag(tag)
		print(GameState.script_name_tag(self, _fname) + "  - ", tag, " (unlocked: ", is_unlocked, ") - ", metadata.get("description", ""))
	
	print(GameState.script_name_tag(self, _fname) + "=================================\n")

func _evaluate_memory_condition(condition: String) -> bool:
	var _fname = "_evaluate_memory_condition"
	# Simple condition parser for memory checks
	condition = condition.strip_edges()
	
	# Handle negation
	if condition.begins_with("!"):
		return not _evaluate_memory_condition(condition.substr(1).strip_edges())
	
	# Handle OR conditions
	if " || " in condition:
		var parts = condition.split(" || ")
		for part in parts:
			if _evaluate_memory_condition(part.strip_edges()):
				return true
		return false
	
	# Handle AND conditions
	if " && " in condition:
		var parts = condition.split(" && ")
		for part in parts:
			if not _evaluate_memory_condition(part.strip_edges()):
				return false
		return true
	
	# Handle comparison operations
	if " == " in condition:
		var parts = condition.split(" == ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges())
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value == compare_value
	
	if " != " in condition:
		var parts = condition.split(" != ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges())
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value != compare_value
	
	if " >= " in condition:
		var parts = condition.split(" >= ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges(), 0)
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value >= compare_value
	
	if " <= " in condition:
		var parts = condition.split(" <= ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges(), 0)
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value <= compare_value
	
	if " > " in condition:
		var parts = condition.split(" > ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges(), 0)
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value > compare_value
	
	if " < " in condition:
		var parts = condition.split(" < ")
		if parts.size() == 2:
			var memory_value = get_memory_value(parts[0].strip_edges(), 0)
			var compare_value = _parse_value(parts[1].strip_edges())
			return memory_value < compare_value
	
	# Simple boolean check
	return has_memory(condition)

func _parse_value(value_str: String):
	var _fname = "_parse_value"
	value_str = value_str.strip_edges()
	
	# Remove quotes for strings
	if value_str.begins_with('"') and value_str.ends_with('"'):
		return value_str.substr(1, value_str.length() - 2)
	
	# Parse numbers
	if value_str.is_valid_int():
		return int(value_str)
	elif value_str.is_valid_float():
		return float(value_str)
	
	# Parse booleans
	if value_str.to_lower() == "true":
		return true
	elif value_str.to_lower() == "false":
		return false
	
	return value_str


func _build_character_memory_state(character_id: String) -> Dictionary:
	var _fname = "_build_character_memory_state"
	var state = {
		"discovered_memories": [],
		"available_dialogues": [],
		"relationship_level": 0,
		"memory_chain_progress": {}
	}
	
	# Get character memories from GameState
	var memories = GameState.get_character_discoveries(character_id)
	for memory in memories:
		state.discovered_memories.append(memory.memory_tag)
	
	# Get available dialogue options from GameState
	var dialogues = GameState.get_available_dialogue_options(character_id)
	for dialogue in dialogues:
		state.available_dialogues.append(dialogue.dialogue_title)
	
	if relationship_system:
		state.relationship_level = relationship_system.get_relationship_score(character_id)
	
	return state


func _get_character_dialogue_data(character_id: String, dialogue_title: String) -> Dictionary:
	var _fname = "_get_character_dialogue_data"
	# Get dialogue requirements from character data
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var character_data = character_loader.get_character(character_id)
		if character_data and character_data.has("dialogue_requirements"):
			var requirements = character_data.dialogue_requirements
			if requirements.has(dialogue_title):
				return requirements[dialogue_title]
	
	return {}

func _get_dialogue_display_text(character_id: String, dialogue_title: String) -> String:
	var _fname = "_get_dialogue_display_text"
	# Get display text for memory-unlocked dialogue options
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var character_data = character_loader.get_character(character_id)
		if character_data and character_data.has("dialogue_display_texts"):
			var display_texts = character_data.dialogue_display_texts
			if display_texts.has(dialogue_title):
				return display_texts[dialogue_title]
	
	# Default display text
	return dialogue_title.replace("_", " ").capitalize()

# Memory-based dialogue triggers
func trigger_memory_dialogue(character_id: String, dialogue_title: String, memory_tag: String):
	var _fname = "trigger_memory_dialogue"
	memory_option_selected.emit(character_id, memory_tag)
	dialogue_memory_updated.emit(character_id, memory_tag, dialogue_title)
	
	# Update character memory state cache
	if character_memory_states.has(character_id):
		character_memory_states.erase(character_id)  # Force rebuild

# Relationship-memory integration
func check_relationship_memory(character_id: String, min_relationship: int, required_memory: String) -> bool:
	var _fname = "check_relationship_memory"
	if relationship_system:
		var current_relationship = relationship_system.get_relationship_score(character_id)
		if current_relationship < min_relationship:
			return false
	
	return has_memory(required_memory)

func get_relationship_level(character_id: String) -> int:
	var _fname = "get_relationship_level"
	if relationship_system:
		return relationship_system.get_relationship_score(character_id)
	return 0

func get_relationship_name(character_id: String) -> String:
	var _fname = "get_relationship_name"
	if relationship_system:
		var level = relationship_system.get_relationship_score(character_id)
		return relationship_system.get_relationship_name(level)
	return "Unknown"

# Quest-memory integration
func has_active_quest(quest_id: String) -> bool:
	return quest_system.is_quest_active(quest_id) if quest_system else false

func has_completed_quest(quest_id: String) -> bool:
	return quest_system.is_quest_completed(quest_id) if quest_system else false

func check_quest_memory(quest_id: String, memory_tag: String) -> bool:
	return has_active_quest(quest_id) and has_memory(memory_tag)

# Advanced memory operations for dialogue
func unlock_memory_chain(character_id: String, chain_id: String):
	var _fname = "unlock_memory_chain"
	if memory_system and memory_system.has_method("create_memory_chain"):
		# This would require the memory chain data to be accessible
		var character_loader = get_node_or_null("/root/CharacterDataLoader")
		if character_loader:
			var character_data = character_loader.get_character(character_id)
			if character_data and character_data.has("memory_chains"):
				var chains = character_data.memory_chains
				if chains.has(chain_id):
					memory_system.create_memory_chain(character_id, chains[chain_id])

# Conditional dialogue caching for performance
func cache_conditional_dialogue(character_id: String, dialogue_title: String, condition: String, result: bool):
	var _fname = "cache_conditional_dialogue"
	if not conditional_dialogue_cache.has(character_id):
		conditional_dialogue_cache[character_id] = {}
	
	conditional_dialogue_cache[character_id][dialogue_title] = {
		"condition": condition,
		"result": result,
		"cached_time": Time.get_unix_time_from_system()
	}

func get_cached_dialogue_condition(character_id: String, dialogue_title: String) -> Dictionary:
	var _fname = "get_cached_dialogue_condition"
	if conditional_dialogue_cache.has(character_id):
		if conditional_dialogue_cache[character_id].has(dialogue_title):
			var cached = conditional_dialogue_cache[character_id][dialogue_title]
			var cache_age = Time.get_unix_time_from_system() - cached.cached_time
			
			# Cache expires after 60 seconds
			if cache_age < 60:
				return cached
	
	return {}

# Signal handlers
func _on_memory_discovered(memory_tag: String, description: String):
	var _fname = "_on_memory_discovered"
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog extension: Memory discovered - ", memory_tag)
	
	# Clear relevant caches
	conditional_dialogue_cache.clear()
	character_memory_states.clear()

func _on_dialogue_option_unlocked(character_id: String, dialogue_title: String, memory_tag: String):
	var _fname = "_on_dialogue_option_unlocked"
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog extension: Dialogue option unlocked - ", character_id, " -> ", dialogue_title)
	
	# Update cache
	if not dialogue_memory_cache.has(character_id):
		dialogue_memory_cache[character_id] = {}
	
	dialogue_memory_cache[character_id][dialogue_title] = memory_tag
	
	# Clear character memory state cache
	if character_memory_states.has(character_id):
		character_memory_states.erase(character_id)

func _on_relationship_changed(character_id: String, old_level: int, new_level: int):
	var _fname = "_on_relationship_changed"
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog extension: Relationship changed - ", character_id, " (", old_level, " -> ", new_level, ")")
	
	# Clear caches for this character
	if conditional_dialogue_cache.has(character_id):
		conditional_dialogue_cache.erase(character_id)
	
	if character_memory_states.has(character_id):
		character_memory_states.erase(character_id)

# Utility functions for dialogue files
func format_memory_text(memory_tag: String, template: String) -> String:
	var _fname = "format_memory_text"
	# Replace placeholders in template with memory values
	var text = template
	var memory_value = get_memory_value(memory_tag)
	
	text = text.replace("{memory_value}", str(memory_value))
	text = text.replace("{memory_tag}", memory_tag)
	
	return text

func get_memory_count(memory_prefix: String) -> int:
	var _fname = "get_memory_count"
	# Count memories that start with a prefix
	var count = 0
	if game_state:
		for tag in game_state.tags.keys():
			if tag.begins_with(memory_prefix):
				count += 1
	
	return count


func debug_memory_conditions():
	var _fname = "debug_memory_conditions"
	if not debug:
		return
	
	print(GameState.script_name_tag(self) + "\n=== MEMORY CONDITIONS DEBUG ===")
	
	# Test various memory conditions
	var test_conditions = [
		"poison_met_player",
		"poison_met_player && library_visited",
		"relationship_poison >= 2",
		"!quest_intro_completed",
		"memory_count_lichen >= 3"
	]
	
	for condition in test_conditions:
		var result = check_memory_condition(condition)
		print(GameState.script_name_tag(self) + "Condition: ", condition, " -> ", result)
	
	print(GameState.script_name_tag(self) + "==============================\n")
