extends Node

# Dialog Memory Extension for Love & Lichens
# Connects the dialogue system with memory discoveries
# This script should be attached to the DialogSystem node

signal memory_option_selected(character_id, memory_tag)

# Reference to systems
var memory_system: Node
var game_state: Node

const scr_debug : bool = true
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print("Dialog Memory Extension initialized")
	
	# Connect to other systems
	await get_tree().process_frame
	memory_system = get_node_or_null("/root/MemorySystem")
	game_state = get_node_or_null("/root/GameState")
	
	# Connect to memory system signals
	if memory_system:
		if memory_system.has_signal("dialogue_option_unlocked"):
			memory_system.dialogue_option_unlocked.connect(_on_dialogue_option_unlocked)
			if debug: print("Connected to dialogue_option_unlocked signal")

# Get all available memory-based dialogue options for a character
func get_memory_dialogue_options(character_id: String) -> Array:
	var options = []
	
	if memory_system:
		options = memory_system.get_available_dialogue_options(character_id)
		if debug and not options.is_empty(): 
			print("Found ", options.size(), " memory dialogue options for ", character_id)
	
	return options

# Check if a specific dialogue option should be available
func is_dialogue_available(character_id: String, dialogue_title: String) -> bool:
	if memory_system:
		return memory_system.is_dialogue_available(character_id, dialogue_title)
	
	return false

# Get a list of all unlocked memory tags for a character
func get_unlocked_memory_tags(character_id: String) -> Array:
	var tags = []
	
	if memory_system:
		var memories = memory_system.get_character_memories(character_id)
		for memory in memories:
			tags.append(memory.tag)
	
	return tags

# Check if a memory tag has been unlocked
func has_memory_tag(tag: String) -> bool:
	if game_state:
		return game_state.has_tag(tag)
	
	return false

# Signal handler when a new dialogue option is unlocked
func _on_dialogue_option_unlocked(character_id: String, dialogue_title: String, memory_tag: String) -> void:
	if debug: print("New dialogue option unlocked: ", character_id, " -> ", dialogue_title, " (", memory_tag, ")")
	
	# You could show a notification here
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification("New conversation option available with " + character_id)

# Helper for Dialogue Manager to check if dialogue should be available
# This will be called from dialogue files using "DialogMemoryExtension.can_show_dialogue"
func can_show_dialogue(character_id: String, dialogue_title: String) -> bool:
	return is_dialogue_available(character_id, dialogue_title)
