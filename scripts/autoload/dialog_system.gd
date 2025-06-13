extends Node

# Dialog System for Love & Lichens
# Integrates with the Dialogue Manager addon

signal dialog_started(character_id)
signal dialog_ended(character_id)
signal dialog_choice_made(choice_id)
signal memory_unlocked(memory_tag)
signal memory_dialogue_added(character_id, dialogue_title)
signal memory_dialogue_selected(character_id, dialogue_title, memory_tag)


const scr_debug :bool = true
var debug

# Dictionary to track which dialogs have been seen
# Key: character_id, Value: array of seen dialog titles
var seen_dialogs = {}
var current_character_id = ""
var dialogue_resources = {}
var balloon_scene
var memory_system = null
var game_state

# Add this to dialog_system.gd - replace the existing _ready() function

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

	# SIMPLIFIED: Just try to connect to DialogueManager signals
	if Engine.has_singleton("DialogueManager"):
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		if dialogue_manager.has_signal("dialogue_started"):
			dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		if dialogue_manager.has_signal("dialogue_ended"):
			dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
		if debug: print(GameState.script_name_tag(self, _fname) + "Connected to DialogueManager signals")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: DialogueManager singleton not found!")
	
	# Start a continuous monitoring process for dialogue end detection
	_start_continuous_dialogue_monitoring()
	
	# Get references to other systems
	await get_tree().process_frame

# NEW: Continuous monitoring for dialogue end detection
func _start_continuous_dialogue_monitoring():
	var _fname = "_start_continuous_dialogue_monitoring"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting continuous dialogue monitoring")
	
	# Create a timer that runs continuously
	var monitor_timer = Timer.new()
	monitor_timer.name = "DialogueMonitorTimer"
	monitor_timer.wait_time = 0.2  # Check every 200ms
	monitor_timer.timeout.connect(_monitor_dialogue_state)
	monitor_timer.autostart = true
	add_child(monitor_timer)

# NEW: Monitor dialogue state continuously
func _monitor_dialogue_state():
	var _fname = "_monitor_dialogue_state"
	
	# Only monitor if we think dialogue is active
	if current_character_id == "":
		return
	
	# Check if there are any dialogue balloons still active
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	
	# If no balloons and we have a current character, dialogue has ended
	if balloons.size() == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "=== DIALOGUE END DETECTED VIA MONITORING ===")
		if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager ended dialogue")
		if debug: print(GameState.script_name_tag(self, _fname) + "Current character ID: '", current_character_id, "'")
		
		var ended_character_id = current_character_id
		
		# Emit the signal BEFORE clearing current_character_id
		if debug: print(GameState.script_name_tag(self, _fname) + "Emitting dialog_ended signal with character: '", current_character_id, "'")
		dialog_ended.emit(current_character_id)
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended with " + current_character_id)
		
		# Clear the current character ID AFTER emitting the signal
		current_character_id = ""
		
		# Make sure to properly "release" the dialogue control mode
		Engine.time_scale = 1.0
		get_tree().paused = false
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended with character '", ended_character_id, "' - control released")
		if debug: print(GameState.script_name_tag(self, _fname) + "=== END DIALOGUE END DETECTION ===")

# Keep the original signal handlers in case they work
func _on_dialogue_started():
	var _fname = "_on_dialogue_started"
	if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager started dialogue with character: '", current_character_id, "'")

func _on_dialogue_ended():
	var _fname = "_on_dialogue_ended"
	if debug: print(GameState.script_name_tag(self, _fname) + "=== ORIGINAL DIALOGUE_ENDED SIGNAL ===")
	if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager ended dialogue")
	if debug: print(GameState.script_name_tag(self, _fname) + "Current character ID: '", current_character_id, "'")
	
	# Get the current balloons and force cleanup if any remain
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	if balloons.size() > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "Found " + str(balloons.size()) + " dialogue balloons to force cleanup")
		for balloon in balloons:
			if balloon.has_method("queue_free"):
				balloon.queue_free()
	
	# Emit the signal with the character ID
	if debug: print(GameState.script_name_tag(self, _fname) + "Emitting dialog_ended signal with character: '", current_character_id, "'")
	dialog_ended.emit(current_character_id)
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended with " + current_character_id)
	
	# Clear the current character ID AFTER emitting the signal
	var ended_character_id = current_character_id
	current_character_id = ""
	
	# Make sure to properly "release" the dialogue control mode
	Engine.time_scale = 1.0
	get_tree().paused = false
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended with character '", ended_character_id, "' - control released")
	if debug: print(GameState.script_name_tag(self, _fname) + "=== END ORIGINAL DIALOGUE_ENDED SIGNAL ===")

#SIMPLIFIED: Memory-based dialogue functions using registry
func unlock_memory(tag: String) -> void:
	"""Set a memory tag and notify the system - now uses registry validation"""
	var _fname = "unlock_memory"
	
	# Validate that this is a real memory tag
	if not GameState.is_valid_memory_tag(tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Attempting to unlock invalid memory tag: ", tag)
		return
	
	# Check if conditions are met
	if not GameState.can_unlock_memory(tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Cannot unlock memory tag (conditions not met): ", tag)
		return
	
	# Discover the memory using registry
	if GameState.discover_memory_from_registry(tag, "dialogue"):
		memory_unlocked.emit(tag)
		
		# Also notify the memory system if available
		if memory_system and memory_system.has_method("_on_memory_unlocked"):
			memory_system._on_memory_unlocked(tag)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Successfully unlocked memory: ", tag)

# SIMPLIFIED: Check if a tag can be unlocked using registry
func can_unlock(tag: String) -> bool:
	"""Check if a tag can be unlocked - now uses registry conditions"""
	return GameState.can_unlock_memory(tag)

# SIMPLIFIED: Get unlocked memories for a character using registry
func get_unlocked_memories_for_character(character_id: String) -> Array:
	"""Get all unlocked memory tags for a character - now uses registry"""
	var _fname = "get_unlocked_memories_for_character"
	var unlocked_memories = []
	
	# Check all memory tags in registry for this character
	for tag_name in GameState.memory_registry.keys():
		var metadata = GameState.memory_registry[tag_name]
		
		if metadata.get("character_id", "") == character_id and GameState.has_tag(tag_name):
			unlocked_memories.append(tag_name)
	
	return unlocked_memories

# UPDATED: Enhanced memory dialogue selection using registry
func select_memory_dialogue(character_id: String, dialogue_title: String) -> bool:
	"""Select a memory-unlocked dialogue option - now uses registry"""
	var _fname = "select_memory_dialogue"
	
	# Get the memory tag for this dialogue using registry
	var memory_tag = GameState.get_memory_tag_for_dialogue_from_registry(character_id, dialogue_title)
	
	if memory_tag.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No memory tag found for dialogue: ", character_id, " -> ", dialogue_title)
		return false
	
	# Check if the memory is unlocked
	if not GameState.has_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "Memory tag not unlocked: ", memory_tag)
		return false
	
	# Emit signal and start dialogue
	memory_dialogue_selected.emit(character_id, dialogue_title, memory_tag)
	return start_dialog(character_id, dialogue_title)

# ENHANCED: Memory condition checking using registry
func check_dialogue_conditions(character_id: String, dialogue_title: String) -> bool:
	"""Check if dialogue conditions are met using registry metadata"""
	var _fname = "check_dialogue_conditions"
	
	# Get memory tag for this dialogue
	var memory_tag = GameState.get_memory_tag_for_dialogue_from_registry(character_id, dialogue_title)
	
	if memory_tag.is_empty():
		# No memory requirements
		return true
	
	# Get metadata from registry
	var metadata = GameState.get_memory_metadata(memory_tag)
	if metadata.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No metadata found for memory tag: ", memory_tag)
		return false
	
	# Check if memory is unlocked
	if not GameState.has_tag(memory_tag):
		return false
	
	# Check additional conditions from metadata
	var condition_tags = metadata.get("condition_tags", [])
	for condition_tag in condition_tags:
		if not GameState.has_tag(condition_tag):
			if debug: print(GameState.script_name_tag(self, _fname) + "Condition not met: ", condition_tag)
			return false
	
	return true

# NEW: Validate memory tag before operations
func validate_memory_operation(tag_name: String, operation: String) -> bool:
	"""Validate that a memory operation is valid using registry"""
	var _fname = "validate_memory_operation"
	
	if not GameState.is_valid_memory_tag(tag_name):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid memory tag for ", operation, ": ", tag_name)
		return false
	
	var metadata = GameState.get_memory_metadata(tag_name)
	if metadata.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No metadata found for ", operation, ": ", tag_name)
		return false
	
	return true

# UPDATED: Enhanced start_dialog function with registry support
func start_dialog(character_id, title = "start"):
	var _fname = "start_dialog"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting dialog with: ", character_id, " at title: ", title)
	
	record_seen_dialog(character_id, title)
	current_character_id = character_id
	
	if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Checking memory options for ", character_id)
	
	# Get memory-unlocked dialogue options using registry
	var memory_options = GameState.get_dialogue_options_from_registry(character_id)
	if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Found ", memory_options.size(), " memory-unlocked options from registry")
	
	for option in memory_options:
		if debug: print(GameState.script_name_tag(self, _fname) + "DIALOG: Memory option available: ", option.dialogue_title, " (tag: ", option.tag, ")")
		memory_dialogue_added.emit(character_id, option.dialogue_title)
	
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

# NEW: Workaround to detect when dialogue ends
func _start_dialogue_end_detection():
	var _fname = "_start_dialogue_end_detection"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting dialogue end detection")
	
	# Create a timer to check for dialogue end
	var timer = Timer.new()
	timer.wait_time = 0.1  # Check every 100ms
	timer.timeout.connect(_check_dialogue_ended)
	add_child(timer)
	timer.start()

# NEW: Check if dialogue has ended by looking for dialogue balloons
func _check_dialogue_ended():
	var _fname = "_check_dialogue_ended"
	
	# Only check if we think dialogue is active
	if current_character_id == "":
		return
	
	# Check if there are any dialogue balloons still active
	var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
	
	if balloons.size() == 0:
		# No balloons found - dialogue has ended
		if debug: print(GameState.script_name_tag(self, _fname) + "=== DIALOGUE END DETECTED (No balloons found) ===")
		if debug: print(GameState.script_name_tag(self, _fname) + "DialogueManager ended dialogue")
		
		# Clean up the timer
		var timers = get_children().filter(func(child): return child is Timer)
		for timer in timers:
			timer.queue_free()
		
		# Emit our signal manually
		if debug: print(GameState.script_name_tag(self, _fname) + "Emitting dialog_ended signal with character: '", current_character_id, "'")
		dialog_ended.emit(current_character_id)
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialog ended with " + current_character_id)
		
		# Clear the current character ID
		current_character_id = ""
		
		# Make sure to properly "release" the dialogue control mode
		Engine.time_scale = 1.0
		get_tree().paused = false
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialog control released")
		if debug: print(GameState.script_name_tag(self, _fname) + "=== END DIALOGUE END DETECTION ===")
		

func _on_dialogue_ended_original():
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
	if debug: 
		print(GameState.script_name_tag(self, _fname) + "Dialog ended with " + current_character_id)
	
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

# Starts a custom dialog from a string
func start_custom_dialog(dialog_content: String, title: String = "start"):
	var _fname = "start_custom_dialog"
	if debug: print(GameState.script_name_tag(self, _fname) + "Starting custom dialog at ", title)
	
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
				title
			)
			return true
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Failed to start custom dialog")
	return false
	
# Helper functions for memory-based dialogue


# Add a dialogue choice if a tag condition is met
func add_conditional_choice(choices: Array, condition_tag: String, text: String, target: String) -> Array:
	if can_unlock(condition_tag):
		choices.append({
			"text": text,
			"target": target
		})
	return choices

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
