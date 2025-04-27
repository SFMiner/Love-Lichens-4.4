extends Node

# Memory System for Love & Lichens
# Handles character memory discovery through player exploration and interactions

# Memory chains stored by ID
var memory_chains: Dictionary = {}
var active_chains: Array[MemoryChain] = []

# Dialogue mapping
# Key: unlock_tag, Value: {character_id, dialogue_title}
var dialogue_mapping: Dictionary = {}

# Signals
signal memory_discovered(memory_tag: String, description: String)
signal memory_chain_completed(character_id: String, chain_id: String)
signal dialogue_option_unlocked(character_id: String, dialogue_title: String, memory_tag: String)

# Debug flag
const scr_debug : bool = false
var debug

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug
	if debug: print("Memory System initialized")
	
	_load_all_memory_data()
	
	# Connect to existing systems
	if has_node("/root/GameState"):
		GameState.game_loaded.connect(_on_game_loaded)
	
	# Connect to dialog system for memory relevance tracking
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		if dialog_system.has_signal("memory_unlocked"):
			dialog_system.memory_unlocked.connect(_on_memory_unlocked)
			if debug: print("Connected to DialogSystem memory_unlocked signal")

# Main API for handling memory triggers
func trigger_look_at(target_id: String) -> bool:
	if debug: print("Memory trigger: Look at ", target_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.LOOK_AT, target_id)
	return triggered

func trigger_item_acquired(item_id: String) -> bool:
	if debug: print("Memory trigger: Item acquired ", item_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.ITEM_ACQUIRED, item_id)
	return triggered

func trigger_location_visited(location_id: String) -> bool:
	if debug: print("Memory trigger: Location visited ", location_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.LOCATION_VISITED, location_id)
	return triggered
	
func trigger_dialogue_choice(choice_id: String) -> bool:
	if debug: print("Memory trigger: Dialogue choice ", choice_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.DIALOGUE_CHOICE, choice_id)
	return triggered

func trigger_quest_completed(quest_id: String) -> bool:
	if debug: print("Memory trigger: Quest completed ", quest_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.QUEST_COMPLETED, quest_id)
	return triggered

func trigger_character_relationship(character_id: String) -> bool:
	if debug: print("Memory trigger: Character relationship update for ", character_id)
	var triggered = _check_triggers(MemoryTrigger.TriggerType.CHARACTER_RELATIONSHIP, character_id)
	return triggered

# Check for triggered memories
func _check_triggers(trigger_type: int, target_id: String) -> bool:
	var triggered_any = false
	
	for chain in active_chains:
		var current_trigger = chain.get_current_trigger()
		if current_trigger and current_trigger.trigger_type == trigger_type:
			if current_trigger.is_triggered(target_id):
				if debug: print("Memory triggered: ", current_trigger.unlock_tag)
				
				# Set the memory tag
				GameState.set_tag(current_trigger.unlock_tag)
				
				# Emit the discovery signal
				memory_discovered.emit(current_trigger.unlock_tag, current_trigger.description)
				
				# Display notification about the memory
				_show_memory_discovery_notification(current_trigger.description)
				
				# Check if this memory unlocks a dialogue option
				if not current_trigger.dialogue_title.is_empty():
					# Emit signal to unlock dialogue option
					dialogue_option_unlocked.emit(chain.character_id, current_trigger.dialogue_title, current_trigger.unlock_tag)
					if debug: print("Unlocked dialogue option: ", chain.character_id, " -> ", current_trigger.dialogue_title)
				
				# Advance to the next step in the chain
				var has_more_steps = chain.advance()
				
				# Check if the chain was completed
				if not has_more_steps:
					memory_chain_completed.emit(chain.character_id, chain.id)
					_on_memory_chain_completed(chain)
				
				triggered_any = true
	
	return triggered_any

# Check if a specific character has a memory tag
func character_has_memory(character_id: String, memory_tag: String) -> bool:
	if GameState.has_tag(memory_tag):
		for chain_id in memory_chains:
			var chain = memory_chains[chain_id]
			if chain.character_id == character_id:
				for step in chain.steps:
					if step.unlock_tag == memory_tag:
						return true
	return false

# Get all memories for a specific character
func get_character_memories(character_id: String) -> Array:
	var memories = []
	for chain_id in memory_chains:
		var chain = memory_chains[chain_id]
		if chain.character_id == character_id:
			for step in chain.steps:
				if GameState.has_tag(step.unlock_tag):
					memories.append({
						"tag": step.unlock_tag,
						"description": step.description
					})
	return memories

# Get dialogue options that should be available for a character
func get_available_dialogue_options(character_id: String) -> Array:
	var options = []
	
	for tag in dialogue_mapping.keys():
		var mapping = dialogue_mapping[tag]
		
		# Check if this mapping is for the requested character and the tag is active
		if mapping.character_id == character_id and GameState.has_tag(tag):
			options.append({
				"tag": tag,
				"dialogue_title": mapping.dialogue_title
			})
	
	return options

# Check if a specific dialogue option should be available
func is_dialogue_available(character_id: String, dialogue_title: String) -> bool:
	for tag in dialogue_mapping.keys():
		var mapping = dialogue_mapping[tag]
		
		if mapping.character_id == character_id and mapping.dialogue_title == dialogue_title:
			return GameState.has_tag(tag)
	
	return false

# Get the memory tag for a dialogue option
func get_memory_tag_for_dialogue(character_id: String, dialogue_title: String) -> String:
	for tag in dialogue_mapping.keys():
		var mapping = dialogue_mapping[tag]
		
		if mapping.character_id == character_id and mapping.dialogue_title == dialogue_title:
			return tag
	
	return ""

# Load memory data from JSON files
func _load_all_memory_data() -> void:
	# First load memory chains from JSON files
	var dir = DirAccess.open("res://data/memories/")
	if not dir:
		if debug: print("ERROR: Could not open memory data directory")
		# Try to create the directory
		if DirAccess.open("res://data/"):
			DirAccess.open("res://data/").make_dir("memories")
			if debug: print("Created memories directory")
			dir = DirAccess.open("res://data/memories/")
			if not dir:
				if debug: print("ERROR: Failed to create memories directory")
				return
		else:
			if debug: print("ERROR: Could not open data directory")
			return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path = "res://data/memories/" + file_name
			_load_memory_file(path)
		file_name = dir.get_next()
	
	# Then load memory chains from character data
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		# Load memories for each character
		for character_id in character_loader.characters:
			_load_memory_chain_from_character_data(character_id)
	
	if debug: print("Loaded ", memory_chains.size(), " memory chains")
	if debug: print("Active memory chains: ", active_chains.size())

func _load_memory_chain_from_character_data(character_id: String) -> void:
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if not character_loader:
		return
		
	var character_data = character_loader.get_character(character_id)
	if not character_data:
		return
		
	# Check if character has dialogue_memories
	if not character_data.has("dialogue_memories") or character_data.dialogue_memories.is_empty():
		return
		
	# Each dialogue memory can be converted to a memory chain
	var memory_chains_created = 0
	
	for memory_key in character_data.dialogue_memories:
		var memory_data = character_data.dialogue_memories[memory_key]
		
		# Create a chain ID based on character and memory
		var chain_id = character_id.to_lower() + "_" + memory_key + "_chain"
		
		# Skip if we already have this chain
		if memory_chains.has(chain_id):
			continue
			
		# Create a memory chain
		var chain = MemoryChain.new()
		chain.id = chain_id
		chain.character_id = character_id
		
		# Create a memory trigger
		var trigger = MemoryTrigger.new()
		trigger.id = memory_key
		trigger.trigger_type = MemoryTrigger.TriggerType.DIALOGUE_CHOICE
		trigger.unlock_tag = memory_data.unlock_condition
		trigger.description = memory_data.description
		
		# Add trigger to chain
		chain.steps.append(trigger)
		
		# Add to memory chains
		memory_chains[chain.id] = chain
		active_chains.append(chain)
		memory_chains_created += 1
		
	if memory_chains_created > 0:
		if debug: print("Created ", memory_chains_created, " memory chains from character data for ", character_id)


func _load_memory_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		if debug: print("ERROR: Memory file does not exist: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json_result = JSON.new()
	var parse_result = json_result.parse(json_text)
	if parse_result != OK:
		if debug: print("ERROR: Failed to parse memory JSON (", path, "): ", json_result.get_error_message())
		return
	
	var json_data = json_result.get_data()
	if typeof(json_data) != TYPE_ARRAY:
		if debug: print("ERROR: Memory JSON must be an array (", path, ")")
		return
	
	# Process each memory chain in the file
	for chain_data in json_data:
		var chain = MemoryChain.new()
		chain.id = chain_data.id
		chain.character_id = chain_data.character_id
		chain.relationship_reward = chain_data.get("relationship_reward", 0)
		chain.completed_tag = chain_data.get("completed_tag", "")
		
		# Load the memory steps
		for step_data in chain_data.steps:
			var trigger = MemoryTrigger.new()
			trigger.id = step_data.id
			trigger.trigger_type = step_data.trigger_type
			trigger.target_id = step_data.target_id
			trigger.unlock_tag = step_data.unlock_tag
			trigger.description = step_data.description
			
			# Store dialogue mapping if available
			if step_data.has("dialogue_title"):
				trigger.dialogue_title = step_data.dialogue_title
				
				# Add to dialogue mapping for quick lookup
				dialogue_mapping[step_data.unlock_tag] = {
					"character_id": chain.character_id,
					"dialogue_title": step_data.dialogue_title
				}
				
				if debug: print("Added dialogue mapping for ", step_data.unlock_tag, ": ", 
					chain.character_id, " -> ", step_data.dialogue_title)
			
			if step_data.has("condition_tags"):
				for tag in step_data.condition_tags:
					trigger.condition_tags.append(tag)
			
			chain.steps.append(trigger)
		
		# Add the chain to our registry and activate it
		memory_chains[chain.id] = chain
		active_chains.append(chain)
		
		if debug: print("Loaded memory chain: ", chain.id, " (", chain.steps.size(), " steps)")

# Show a notification about a memory discovery
func _show_memory_discovery_notification(description: String) -> void:
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification("Memory discovered: " + description)
	else:
		# Fallback to printing if notification system isn't available
		if debug: print("Memory discovered: ", description)

# Handle memory chain completion
func _on_memory_chain_completed(chain: MemoryChain) -> void:
	if debug: print("Memory chain completed: ", chain.id, " for character ", chain.character_id)
	
	# Set the completion tag if one is specified
	if not chain.completed_tag.is_empty():
		GameState.set_tag(chain.completed_tag)
	
	# Award relationship points if applicable
	if chain.relationship_reward > 0:
		var relationship_system = get_node_or_null("/root/RelationshipSystem")
		if relationship_system and relationship_system.has_method("increase_affinity"):
			relationship_system.increase_affinity(chain.character_id, chain.relationship_reward)
			if debug: print("Awarded ", chain.relationship_reward, " relationship points to ", chain.character_id)

# Dialog system integration
func _on_memory_unlocked(memory_tag: String) -> void:
	if debug: print("Dialog system unlocked memory tag: ", memory_tag)
	
	# This allows the dialog system to directly unlock memory tags
	# Useful for when dialog choices trigger memories
	
	# Check if this tag belongs to any memory in our chains
	for chain in active_chains:
		var current_trigger = chain.get_current_trigger()
		if current_trigger and current_trigger.unlock_tag == memory_tag:
			# Check if this memory unlocks a dialogue option
			if not current_trigger.dialogue_title.is_empty():
				# Emit signal to unlock dialogue option
				dialogue_option_unlocked.emit(chain.character_id, current_trigger.dialogue_title, current_trigger.unlock_tag)
				if debug: print("Unlocked dialogue option: ", chain.character_id, " -> ", current_trigger.dialogue_title)
			
			# Advance the memory chain
			var has_more_steps = chain.advance()
			
			# Check if the chain was completed
			if not has_more_steps:
				memory_chain_completed.emit(chain.character_id, chain.id)
				_on_memory_chain_completed(chain)
			
			break

# GameState integration
func _on_game_loaded(_slot = null) -> void:
	if debug: print("Game loaded - resetting and advancing memory chains")
	
	# Reset all memory chains
	for chain in active_chains:
		chain.reset()
	
	# Advance chains based on already discovered memories
	for chain in active_chains:
		var advanced = true
		while advanced:
			var current_trigger = chain.get_current_trigger()
			if current_trigger and GameState.has_tag(current_trigger.unlock_tag):
				advanced = chain.advance()
			else:
				advanced = false
