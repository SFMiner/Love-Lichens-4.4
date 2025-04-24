extends Node

# Dialog System for Love & Lichens
# Integrates with the Dialogue Manager addon

signal dialog_started(character_id)
signal dialog_ended(character_id)
signal dialog_choice_made(choice_id)
signal memory_unlocked(memory_tag)
signal memory_dialogue_added(character_id, dialogue_title)
signal memory_dialogue_selected(character_id, dialogue_title, memory_tag)


const scr_debug :bool = false
var debug

# Dictionary to track which dialogs have been seen
# Key: character_id, Value: array of seen dialog titles
var seen_dialogs = {}
var current_character_id = ""
var dialogue_resources = {}
var balloon_scene
var memory_system = null
var game_state

	
# Record that a dialog has been seen
func record_seen_dialog(character_id, dialog_title):
	if not seen_dialogs.has(character_id):
		seen_dialogs[character_id] = []
		
	if not dialog_title in seen_dialogs[character_id]:
		seen_dialogs[character_id].append(dialog_title)
		if debug: print("Recorded seen dialog: ", character_id, " - ", dialog_title)

# Check if a dialog has been seen
func has_seen_dialog(character_id, dialog_title):
	if not seen_dialogs.has(character_id):
		return false
		
	return dialog_title in seen_dialogs[character_id]
	
# Check if dialog is currently active
func is_dialog_active():
	# First check our internal state
	if current_character_id != "":
		# Do a sanity check - is the actual balloon present?
		var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
		if balloons.size() == 0:
			# No actual balloon found, but we think we're in dialog
			# This means our state is out of sync - fix it
			if debug: print("Dialog state mismatch detected - resetting state")
			current_character_id = ""
			return false
		return true
	return false

# Get all seen dialogs for save system
func get_seen_dialogs():
	return seen_dialogs.duplicate(true)

# Set seen dialogs from save data
func set_seen_dialogs(data):
	seen_dialogs = data.duplicate(true)

# Modify the existing start_dialog function
# We need to add just one line to record seen dialogs
func start_dialog(character_id, title = "start"):
	# Add this line to the beginning of your existing start_dialog function
	record_seen_dialog(character_id, title)
	
	# Then the rest of your existing start_dialog function continues below
	current_character_id = character_id
	
	if memory_system:
		var memory_options = memory_system.get_available_dialogue_options(character_id)
		for option in memory_options:
			memory_dialogue_added.emit(character_id, option.dialogue_title)
			if debug: print("Added memory dialogue option: ", option.dialogue_title)


	# Load the dialogue resource if not already loaded
	if not dialogue_resources.has(character_id):
		if not preload_dialogue(character_id):
			if debug: print("ERROR: Failed to load dialogue for: ", character_id)
			return false
	

	# Emit our own signal before DialogueManager does
	dialog_started.emit(character_id)
	
	# Show the dialogue balloon
	if balloon_scene:
		var balloon = DialogueManager.show_dialogue_balloon_scene(
			balloon_scene, 
			dialogue_resources[character_id], 
			title
		)
		if debug: print("Started dialogue with: ", character_id, " at title: ", title)
		return true
	else:
		if debug: print("ERROR: No balloon scene available!")
		return false

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print("Dialog System initialized")
	game_state = GameState
	memory_system = MemorySystem
	if debug: print("Memory system reference obtained: ", memory_system != null)
	# Load our custom balloon scene
	if ResourceLoader.exists("res://scenes/ui/dialogue_balloon/dialogue_balloon.tscn"):
		balloon_scene = load("res://scenes/ui/dialogue_balloon/dialogue_balloon.tscn")
		if debug: print("Loaded custom dialogue balloon scene")
	else:
		# Load the example balloon scene as fallback
		if ResourceLoader.exists("res://addons/dialogue_manager/example_balloon/example_balloon.tscn"):
			balloon_scene = load("res://addons/dialogue_manager/example_balloon/example_balloon.tscn")
			if debug: print("Loaded example balloon scene as fallback")
		else:
			if debug: print("ERROR: Could not find any dialogue balloon scene")
	
	if not has_node("DialogMemoryExtension"):
		var extension_script = load("res://scripts/autoload/dialog_memory_extension.gd")
		if extension_script:
			var extension = extension_script.new()
			extension.name = "DialogMemoryExtension"
			add_child(extension)
			if debug: print("Added DialogMemoryExtension")

	# Connect to DialogueManager signals
	if Engine.has_singleton("DialogueManager"):
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
		if debug: print("Connected to DialogueManager signals")
	else:
		if debug: print("ERROR: DialogueManager singleton not found!")
	
	# Get references to other systems
	await get_tree().process_frame
	
# Preload a dialogue resource
func preload_dialogue(character_id):
	var file_path = "res://data/dialogues/" + character_id + ".dialogue"
	
	if ResourceLoader.exists(file_path):
		dialogue_resources[character_id] = load(file_path)
		if debug: print("Preloaded dialogue for: ", character_id)
		return true
	else:
		if debug: print("ERROR: Could not find dialogue file: ", file_path)
		return false

# Pass custom signals from DialogueManager to our own signals
func _on_dialogue_started():
	if debug: print("DialogueManager started dialogue")
	# We've already emitted our own signal at this point

func _on_dialogue_ended():
	if debug: print("DialogueManager ended dialogue")
	
	# Get the current balloons and force cleanup if any remain
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	if balloons.size() > 0:
		if debug: print("Found " + str(balloons.size()) + " dialogue balloons to force cleanup")
		for balloon in balloons:
			if balloon.has_method("queue_free"):
				balloon.queue_free()
	
	dialog_ended.emit(current_character_id)
	# Clear the current character ID to indicate dialogue is no longer active
	current_character_id = ""
	
	# Make sure to properly "release" the dialogue control mode
	# This ensures the game knows we're no longer in dialogue
	Engine.time_scale = 1.0
	get_tree().paused = false
	if debug: print("Dialog ended - control released")

# For backwards compatibility with existing code
func end_dialog():
	if debug: print("Dialog ended manually")
	
	# Get the current balloons and force cleanup if any remain
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	if balloons.size() > 0:
		if debug: print("Found " + str(balloons.size()) + " dialogue balloons to force cleanup")
		for balloon in balloons:
			if balloon.has_method("queue_free"):
				balloon.queue_free()
	
	dialog_ended.emit(current_character_id)
	
	# Clear the current character ID to indicate dialogue is no longer active
	current_character_id = ""
	
	# Make sure to properly "release" the dialogue control mode
	# This ensures the game knows we're no longer in dialogue
	Engine.time_scale = 1.0
	get_tree().paused = false
	if debug: print("Dialog ended manually - control released")
	
func get_dialog_options():
	if debug: print("DEPRECATED: get_dialog_options() - Using DialogueManager directly instead")
	return []
	
func make_choice(choice_id):
	if debug: print("Choice made: " + choice_id)
	dialog_choice_made.emit(choice_id)
	
	# If memory system exists, trigger the dialogue choice event
	if memory_system:
		memory_system.trigger_dialogue_choice(choice_id)
	
	return ""

func select_memory_dialogue(character_id: String, dialogue_title: String) -> bool:
	if memory_system:
		var memory_tag = memory_system.get_memory_tag_for_dialogue(character_id, dialogue_title)
		if not memory_tag.is_empty():
			memory_dialogue_selected.emit(character_id, dialogue_title, memory_tag)
			
			# Start the dialogue at the specified title
			return start_dialog(character_id, dialogue_title)
	
	return false

# Starts a custom dialog from a string
func start_custom_dialog(dialog_content: String, entry_point: String = "start"):
	if debug: print("Starting custom dialog at ", entry_point)
	
	# Use the Dialogue Manager to parse and start the dialogue
	var dialogue_resource = DialogueManager.create_resource_from_text(dialog_content)
	
	if dialogue_resource:
		# Emit our own signal before DialogueManager does
		dialog_started.emit("custom_dialog")
		
		# Show the dialogue balloon
		if balloon_scene:
			var balloon = DialogueManager.show_dialogue_balloon_scene(
				balloon_scene, 
				dialogue_resource, 
				entry_point
			)
			return true
	
	if debug: print("Failed to start custom dialog")
	return false
	
# Helper functions for memory-based dialogue

# Check if a tag is set in GameState
func can_unlock(tag: String) -> bool:
	if game_state:
		return game_state.has_tag(tag)
	return false

# Add a dialogue choice if a tag condition is met
func add_conditional_choice(choices: Array, condition_tag: String, text: String, target: String) -> Array:
	if can_unlock(condition_tag):
		choices.append({
			"text": text,
			"target": target
		})
	return choices

# Set a memory tag and notify the system
func unlock_memory(tag: String) -> void:
	if game_state:
		game_state.set_tag(tag)
		memory_unlocked.emit(tag)
		
		# Also notify the memory system if available
		if memory_system and memory_system.has_method("_on_memory_unlocked"):
			memory_system._on_memory_unlocked(tag)
	
# Get all unlocked memory tags for a character
func get_unlocked_memories_for_character(character_id: String) -> Array:
	var unlocked_memories = []
	
	if game_state and memory_system:
		# Iterate through all tags to find character-related ones
		for tag in game_state.tags.keys():
			if tag.begins_with(character_id + "_") and memory_system.character_has_memory(character_id, tag):
				unlocked_memories.append(tag)
	
	return unlocked_memories
