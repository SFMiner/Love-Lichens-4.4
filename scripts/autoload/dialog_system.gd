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
	var _fname = "record_seen_dialog"
	if not seen_dialogs.has(character_id):
		seen_dialogs[character_id] = []
		
	if not dialog_title in seen_dialogs[character_id]:
		seen_dialogs[character_id].append(dialog_title)
		if debug: print(GameState.script_name_tag(self, _fname) + "Recorded seen dialog: ", character_id, " - ", dialog_title)

# Check if a dialog has been seen
func has_seen_dialog(character_id, dialog_title):
	var _fname = "has_seen_dialog"
	if not seen_dialogs.has(character_id):
		return false
		
	return dialog_title in seen_dialogs[character_id]
	
# Check if dialog is currently active
func is_dialog_active():
	var _fname = "is_dialog_active"
	# First check our internal state
	if current_character_id != "":
		# Do a sanity check - is the actual balloon present?
		var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
		if balloons.size() == 0:
			# No actual balloon found, but we think we're in dialog
			# This means our state is out of sync - fix it
			if debug: print(GameState.script_name_tag(self, _fname) + "Dialog state mismatch detected - resetting state")
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
	var _fname = "start_dialog"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting dialog with: ", character_id, " at title: ", title)
	# Add this line to the beginning of your existing start_dialog function
	print(GameState.script_name_tag(self, _fname) + "=== DIALOG START DEBUG ===")
	print(GameState.script_name_tag(self, _fname) + "Starting dialog with: ", character_id)
	print(GameState.script_name_tag(self, _fname) + "Dialog title: ", title)
	
	# Add this line to the beginning of your existing start_dialog function
	record_seen_dialog(character_id, title)
	
	# Then the rest of your existing start_dialog function continues below
	current_character_id = character_id
	
	print(GameState.script_name_tag(self, _fname) + "DIALOG: Checking memory options for ", character_id)

	# Check what memory tags are currently set
	print(GameState.script_name_tag(self, _fname) + "DIALOG: Current memory tags in GameState:")
	for tag in GameState.tags.keys():
		if tag.contains(character_id):
			print(GameState.script_name_tag(self, _fname) + "  - ", tag, " = ", GameState.tags[tag])

	
	if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Checking memory options for ", character_id)

	var memory_options = GameState.get_available_dialogue_options(character_id)
	if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Found ", memory_options.size(), " memory-unlocked options")
	
	for option in memory_options:
		if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Memory option available: ", option.dialogue_title, " (tag: ", option.tag, ")")
		memory_dialogue_added.emit(character_id, option.dialogue_title)
	
	# Check MemorySystem dialogue options
	if memory_system:
		var memory_sys_options = memory_system.get_available_dialogue_options(character_id)
		print(GameState.script_name_tag(self, _fname) + "DIALOG: Found ", memory_sys_options.size(), " options from MemorySystem")
		for option in memory_sys_options:
			memory_dialogue_added.emit(character_id, option.dialogue_title)
			print(GameState.script_name_tag(self, _fname) + "DIALOG: Added memory dialogue option: ", option.dialogue_title)
	
	print(GameState.script_name_tag(self, _fname) + "=== END DIALOG START DEBUG ===")
	
	# Load the dialogue resource if not already loaded
	if not dialogue_resources.has(character_id):
		if not preload_dialogue(character_id):
			if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Failed to load dialogue for: ", character_id)
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
		if debug: print(GameState.script_name_tag(self, _fname) + "Started dialogue with: ", character_id, " at title: ", title)
		return true
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: No balloon scene available!")
		return false

func _ready():
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog System initialized")
	game_state = GameState
	memory_system = MemorySystem
	if debug: print(GameState.script_name_tag(self, _fname) + "Memory system reference obtained: ", memory_system != null)
	# Load our custom balloon scene
	if ResourceLoader.exists("res://scenes/ui/dialogue_balloon/encounter_dialogue_balloon.tscn"):
		balloon_scene = load("res://scenes/ui/dialogue_balloon/encounter_dialogue_balloon.tscn")
		if debug: print(GameState.script_name_tag(self, _fname) + "Loaded enhanced dialogue balloon scene")
	elif ResourceLoader.exists("res://scenes/ui/dialogue_balloon/dialogue_balloon.tscn"):
	#if ResourceLoader.exists("res://scenes/ui/dialogue_balloon/dialogue_balloon.tscn"):
		balloon_scene = load("res://scenes/ui/dialogue_balloon/dialogue_balloon.tscn")
		if debug: print(GameState.script_name_tag(self, _fname) + "Loaded custom dialogue balloon scene")
	else:
		# Load the example balloon scene as fallback
		if ResourceLoader.exists("res://addons/dialogue_manager/example_balloon/example_balloon.tscn"):
			balloon_scene = load("res://addons/dialogue_manager/example_balloon/example_balloon.tscn")
			if debug: print(GameState.script_name_tag(self, _fname) + "Loaded example balloon scene as fallback")
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Could not find any dialogue balloon scene")
	
	if not has_node("DialogMemoryExtension"):
		var extension_script = load("res://scripts/autoload/dialog_memory_extension.gd")
		if extension_script:
			var extension = extension_script.new()
			extension.name = "DialogMemoryExtension"
			add_child(extension)
			if debug: print(GameState.script_name_tag(self, _fname) + "Added DialogMemoryExtension")

	# Connect to DialogueManager signals
	if Engine.has_singleton("DialogueManager"):
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
		if debug: print(GameState.script_name_tag(self, _fname) + "Connected to DialogueManager signals")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: DialogueManager singleton not found!")
	
	# Get references to other systems
	await get_tree().process_frame
	
# Preload a dialogue resource
func preload_dialogue(character_id):
	var _fname = "preload_dialogue"
	var file_path = "res://data/dialogues/" + character_id + ".dialogue"
	
	if ResourceLoader.exists(file_path):
		dialogue_resources[character_id] = load(file_path)
		if debug: print(GameState.script_name_tag(self, _fname) + "Preloaded dialogue for: ", character_id)
		return true
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Could not find dialogue file: ", file_path)
		return false

# Pass custom signals from DialogueManager to our own signals
func _on_dialogue_started():
	var _fname = "_on_dialogue_started"
	if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager started dialogue")
	# We've already emitted our own signal at this point

func _on_dialogue_ended():
	var _fname = "_on_dialogue_ended"
	if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager ended dialogue")
	
	# Get the current balloons and force cleanup if any remain
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	if balloons.size() > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "Found " + str(balloons.size()) + " dialogue balloons to force cleanup")
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
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended - control released")

# For backwards compatibility with existing code
func end_dialog():
	var _fname = "end_dialog"
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended manually")
	
	# Get the current balloons and force cleanup if any remain
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	if balloons.size() > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "Found " + str(balloons.size()) + " dialogue balloons to force cleanup")
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
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended manually - control released")
	
func get_dialog_options():
	var _fname = "get_dialog_options"
	if debug: print(GameState.script_name_tag(self, _fname) + "DEPRECATED: get_dialog_options() - Using DialogueManager directly instead")
	return []
	
func make_choice(choice_id):
	var _fname = "make_choice"
	if debug: print(GameState.script_name_tag(self, _fname) + "Choice made: " + choice_id)
	dialog_choice_made.emit(choice_id)
	
	# If memory system exists, trigger the dialogue choice event
	if memory_system:
		memory_system.trigger_dialogue_choice(choice_id)
	
	return ""

func select_memory_dialogue(character_id: String, dialogue_title: String) -> bool:
	var _fname = "select_memory_dialogue"
	if memory_system:
		var memory_tag = memory_system.get_memory_tag_for_dialogue(character_id, dialogue_title)
		if not memory_tag.is_empty():
			memory_dialogue_selected.emit(character_id, dialogue_title, memory_tag)
			
			# Start the dialogue at the specified title
			return start_dialog(character_id, dialogue_title)
	
	return false

# Starts a custom dialog from a string
func start_custom_dialog(dialog_content: String, entry_point: String = "start"):
	var _fname = "start_custom_dialog"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting custom dialog at ", entry_point)
	
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
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Failed to start custom dialog")
	return false
	
# Helper functions for memory-based dialogue

# Check if a tag is set in GameState
func can_unlock(tag: String) -> bool:
	var _fname = "can_unlock"
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
	var _fname = "unlock_memory"
	if game_state:
		game_state.set_tag(tag)
		memory_unlocked.emit(tag)
		
		# Also notify the memory system if available
		if memory_system and memory_system.has_method("_on_memory_unlocked"):
			memory_system._on_memory_unlocked(tag)
	
# Get all unlocked memory tags for a character
func get_unlocked_memories_for_character(character_id: String) -> Array:
	var _fname = "get_unlocked_memories_for_character"
	var unlocked_memories = []
	
	if game_state and memory_system:
		# Iterate through all tags to find character-related ones
		for tag in game_state.tags.keys():
			if tag.begins_with(character_id + "_") and memory_system.character_has_memory(character_id, tag):
				unlocked_memories.append(tag)
	
	return unlocked_memories

# Add to dialog_system.gd
func _on_mutated(mutation):
	var _fname = "_on_mutated"
	if debug: print(GameState.script_name_tag(self, _fname) + "Handling mutation: ", mutation.name)
	
	if mutation.name == "move_character":
		# Forward the call directly to CutsceneManager
		var cutscene_manager = get_node_or_null("/root/CutsceneManager")
		if cutscene_manager:
			# Pass all arguments directly to the cutscene manager
			if mutation.arguments.size() >= 2:
				var character_id = mutation.arguments[0]
				var target = mutation.arguments[1]
				
				# Set default values for optional parameters
				var animation = "walk"
				var speed = null
				var stop_distance = 0
				var time = null
				
				# Check for additional parameters
				if mutation.arguments.size() >= 3:
					animation = mutation.arguments[2]
				if mutation.arguments.size() >= 4:
					# Try to convert to number, otherwise pass as is
					var speed_val = mutation.arguments[3]
					if speed_val is String and speed_val.is_valid_float():
						speed = float(speed_val)
					else:
						speed = speed_val
				if mutation.arguments.size() >= 5:
					# Try to convert to number, otherwise pass as is
					var stop_val = mutation.arguments[4]
					if stop_val is String and stop_val.is_valid_float():
						stop_distance = float(stop_val)
					else:
						stop_distance = stop_val
				if mutation.arguments.size() >= 6:
					# Try to convert to number, otherwise pass as is
					var time_val = mutation.arguments[5]
					if time_val is String and time_val.is_valid_float():
						time = float(time_val)
					else:
						time = time_val
				
				cutscene_manager.move_character(character_id, target, animation, speed, stop_distance, time)
			else:
				if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: move_character requires at least character_id and target")
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: CutsceneManager not found")
		return null
	
	elif mutation.name == "play_animation":
		var cutscene_manager = get_node_or_null("/root/CutsceneManager")
		if cutscene_manager and mutation.arguments.size() >= 2:
			cutscene_manager.play_animation(mutation.arguments[0], mutation.arguments[1])
		return null
	
	elif mutation.name == "wait_for_movements":
		var cutscene_manager = get_node_or_null("/root/CutsceneManager")
		if not cutscene_manager:
			if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: CutsceneManager not found")
			return null
		
		# If no movements are active, return immediately
		if cutscene_manager.active_movements.size() == 0:
			return true
		
		# Return a coroutine waiting for the movement_completed signal
		return cutscene_manager.movement_completed
	
	return null

func _handle_wait_for_movements_mutation():
	var _fname = "_handle_wait_for_movements_mutation"
	var cutscene_manager = get_node_or_null("/root/CutsceneManager")
	if not cutscene_manager:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: CutsceneManager not found")
		return
	
	# This will pause the dialogue until all movements complete
	await cutscene_manager.movement_completed
	
	# Check if more movements are still happening
	while not cutscene_manager.wait_for_all_movements():
		await cutscene_manager.movement_completed
	
	return true

func _handle_move_character_mutation(mutation):
	var _fname = "_handle_move_character_mutation"
	var cutscene_manager = get_node_or_null("/root/CutsceneManager")
	if not cutscene_manager:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: CutsceneManager not found")
		return
	
	# Check for minimum required arguments
	if mutation.arguments.size() < 2:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: move_character requires at least character_id and target")
		return
	
	var character_id = mutation.arguments[0]
	var target = mutation.arguments[1]
	
	# Create a params dictionary for additional arguments
	var params = {}
	
	# Process pairs of parameter name and value
	for i in range(2, mutation.arguments.size(), 2):
		if i + 1 < mutation.arguments.size():
			var param_name = str(mutation.arguments[i])
			var param_value = mutation.arguments[i + 1]
			
			# Convert numeric strings to actual numbers
			if param_value is String and param_value.is_valid_float():
				param_value = float(param_value)
			
			params[param_name] = param_value
	
	# Start the movement
	cutscene_manager.move_character(character_id, target, params)

func _handle_play_animation_mutation(mutation):
	var _fname = "_handle_play_animation_mutation"
	var character_id = mutation.arguments.get(0, null)
	var animation_name = mutation.arguments.get(1, null)
	
	if not character_id or not animation_name:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Missing character ID or animation in play_animation mutation")
		return
	
	# Find character
	var character
	if character_id == "player":
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.has_method("get_player"):
			character = game_state.get_player()
	else:
		character = get_tree().get_first_node_in_group(character_id)
		if not character:
			# Try by node path
			character = get_tree().current_scene.get_node_or_null(character_id)
	
	if character:
		# Try different animation methods
		if character.has_method("play_animation"):
			character.play_animation(animation_name)
		elif character.has_node("AnimationPlayer"):
			var anim_player = character.get_node("AnimationPlayer")
			if anim_player.has_animation(animation_name):
				anim_player.play(animation_name)
