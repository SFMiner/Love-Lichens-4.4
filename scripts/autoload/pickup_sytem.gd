# pickup_system.gd
extends Node

# Pickup System for Love & Lichens
# Tracks the state of all pickup items across all scenes

signal pickup_collected(pickup_id, item_id)
signal pickup_dropped(pickup_id, item_id, position)

const scr_debug: bool = false
var debug

# Dictionary to track pickup states by scene
# Key: scene_path, Value: Dictionary of pickup states or null if never visited
var scene_pickup_states = {}

# Dictionary to track currently active pickups in current scene
# Key: pickup_instance_id, Value: pickup node reference
var active_pickups = {}

func _ready():
	debug = scr_debug or GameController.sys_debug if Engine.has_singleton("GameController") else scr_debug
	if debug: print(GameState.script_name_tag(self) + "Pickup System initialized")
	
	# Connect to scene changes to manage pickups
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("location_changed"):
		game_controller.location_changed.connect(_on_location_changed)

func _on_location_changed(old_location, new_location):
	var _fname = "_on_location_changed"
	if debug: print(GameState.script_name_tag(self, _fname) + "Location changed from ", old_location, " to ", new_location)
	
	# Save state of previous scene before switching
	if not old_location.is_empty():
		save_current_scene_pickup_state()
	
	# Clear active pickups from previous scene
	active_pickups.clear()
	
	# Wait for new scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Manage pickups in the new scene
	manage_scene_pickups()

func save_current_scene_pickup_state():
	var _fname = "save_current_scene_pickup_state"
	var scene_path = get_tree().current_scene.scene_file_path
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Saving pickup state for scene: ", scene_path)
	
	# Get all pickup items currently in the scene
	var pickups = get_tree().get_nodes_in_group("pickup")
	var pickup_states = {}
	
	for pickup in pickups:
		if pickup.has_method("get_pickup_save_data"):
			var pickup_data = pickup.get_pickup_save_data()
			var pickup_id = pickup_data.pickup_instance_id
			
			# Store the pickup data (it exists, so it's not collected)
			pickup_states[pickup_id] = {
				"collected": false,
				"data": pickup_data
			}
			
			if debug: print(GameState.script_name_tag(self, _fname) + "Saved uncollected pickup: ", pickup_id)
	
	# Also check our active_pickups for any that were collected this session
	for pickup_id in active_pickups:
		if not pickup_states.has(pickup_id):
			# This pickup was collected (not in scene anymore)
			pickup_states[pickup_id] = {
				"collected": true,
				"data": null
			}
			if debug: print(GameState.script_name_tag(self, _fname) + "Marked collected pickup: ", pickup_id)
	
	# Store the state for this scene
	scene_pickup_states[scene_path] = pickup_states
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Saved ", pickup_states.size(), " pickup states for scene")

func manage_scene_pickups():
	var _fname = "manage_scene_pickups"
	var scene_path = get_tree().current_scene.scene_file_path
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Managing pickups for scene: ", scene_path)
	
	# Check if we have saved state for this scene
	if scene_pickup_states.has(scene_path):
		# We've been here before - restore from saved state
		if debug: print(GameState.script_name_tag(self, _fname) + "Scene has saved state, restoring pickups")
		restore_scene_from_saved_state(scene_path)
	else:
		# First time in this scene - initialize from scene file
		if debug: print(GameState.script_name_tag(self, _fname) + "First time in scene, initializing from scene file")
		initialize_scene_pickups_from_scene_file(scene_path)

func restore_scene_from_saved_state(scene_path: String):
	var _fname = "restore_scene_from_saved_state"
	
	# Step 1: Remove all pickup items that were placed in the scene file
	remove_all_scene_pickups()
	
	# Step 2: Recreate only the uncollected pickups from saved state
	var saved_states = scene_pickup_states[scene_path]
	var restored_count = 0
	
	for pickup_id in saved_states:
		var pickup_state = saved_states[pickup_id]
		
		if not pickup_state.collected:
			# Recreate this pickup
			var pickup_data = pickup_state.data
			create_pickup_from_data(pickup_data)
			restored_count += 1
			if debug: print(GameState.script_name_tag(self, _fname) + "Restored pickup: ", pickup_id)
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "Skipped collected pickup: ", pickup_id)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", restored_count, " uncollected pickups")

func initialize_scene_pickups_from_scene_file(scene_path: String):
	var _fname = "initialize_scene_pickups_from_scene_file"
	
	# Wait one more frame to ensure all pickups are ready
	await get_tree().process_frame
	
	# Get all pickup nodes that were created by the scene file
	var pickups = get_tree().get_nodes_in_group("pickup")
	if debug: print(GameState.script_name_tag(self, _fname) + "Found ", pickups.size(), " pickups in scene file")
	
	var pickup_states = {}
	
	# Register each pickup and create initial state
	for pickup in pickups:
		if pickup.has_method("get_pickup_save_data"):
			# Ensure pickup has an ID
			if pickup.pickup_instance_id.is_empty():
				pickup.pickup_instance_id = pickup._generate_pickup_id()
			
			var pickup_data = pickup.get_pickup_save_data()
			var pickup_id = pickup_data.pickup_instance_id
			
			# Register as active
			active_pickups[pickup_id] = pickup
			
			# Create initial state entry
			pickup_states[pickup_id] = {
				"collected": false,
				"data": pickup_data
			}
			
			if debug: print(GameState.script_name_tag(self, _fname) + "Initialized pickup: ", pickup_id)
	
	# Store initial state for this scene
	scene_pickup_states[scene_path] = pickup_states
	if debug: print(GameState.script_name_tag(self, _fname) + "Created initial state with ", pickup_states.size(), " pickups")

func remove_all_scene_pickups():
	var _fname = "remove_all_scene_pickups"
	
	# Remove all pickup items that were instantiated by the scene file
	var pickups = get_tree().get_nodes_in_group("pickup")
	if debug: print(GameState.script_name_tag(self, _fname) + "Removing ", pickups.size(), " scene pickups")
	
	for pickup in pickups:
		if debug: print(GameState.script_name_tag(self, _fname) + "Removing pickup: ", pickup.name)
		pickup.queue_free()

func create_pickup_from_data(pickup_data: Dictionary):
	var _fname = "create_pickup_from_data"
	
	# Create the pickup item
	var pickup_scene = load("res://scenes/pickups/pickup_item.tscn")
	if not pickup_scene:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Could not load pickup_item.tscn")
		return null
	
	var pickup_instance = pickup_scene.instantiate()
	pickup_instance.item_id = pickup_data.item_id
	pickup_instance.item_amount = pickup_data.item_amount
	pickup_instance.auto_pickup = pickup_data.auto_pickup
	pickup_instance.pickup_range = pickup_data.pickup_range
	pickup_instance.pickup_instance_id = pickup_data.pickup_instance_id
	pickup_instance.global_position = Vector2(pickup_data.position.x, pickup_data.position.y)
	
	# Add to scene
	get_tree().current_scene.add_child(pickup_instance)
	
	# Register as active
	active_pickups[pickup_data.pickup_instance_id] = pickup_instance
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Created pickup: ", pickup_data.pickup_instance_id)
	return pickup_instance

func mark_pickup_collected(pickup_id: String):
	var _fname = "mark_pickup_collected"
	
	# Remove from active pickups
	if active_pickups.has(pickup_id):
		active_pickups.erase(pickup_id)
	
	# Update the state in current scene's saved state
	var scene_path = get_tree().current_scene.scene_file_path
	if scene_pickup_states.has(scene_path) and scene_pickup_states[scene_path].has(pickup_id):
		scene_pickup_states[scene_path][pickup_id].collected = true
		if debug: print(GameState.script_name_tag(self, _fname) + "Marked pickup as collected: ", pickup_id)
	
	pickup_collected.emit(pickup_id, "")

func register_pickup(pickup_node):
	var _fname = "register_pickup"
	if not pickup_node or not pickup_node.has_method("get_pickup_save_data"):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid pickup node")
		return
	
	var pickup_id = pickup_node.pickup_instance_id
	active_pickups[pickup_id] = pickup_node
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Registered pickup: ", pickup_id)

func drop_item_in_world(item_id: String, amount: int, position: Vector2) -> String:
	var _fname = "drop_item_in_world"
	var scene_path = get_tree().current_scene.scene_file_path
	
	# Generate unique pickup ID for dropped item
	var pos_str = str(int(position.x)) + "_" + str(int(position.y))
	var scene_name = scene_path.get_file().get_basename()
	var pickup_id = scene_name + "_dropped_" + item_id + "_" + pos_str + "_" + str(Time.get_unix_time_from_system())
	
	# Create pickup data
	var pickup_data = {
		"pickup_instance_id": pickup_id,
		"item_id": item_id,
		"item_amount": amount,
		"auto_pickup": false,
		"pickup_range": 50.0,
		"position": {
			"x": position.x,
			"y": position.y
		},
		"scene_path": scene_path
	}
	
	# Create the actual pickup in the scene
	var pickup_instance = create_pickup_from_data(pickup_data)
	
	# Add to current scene state
	if not scene_pickup_states.has(scene_path):
		scene_pickup_states[scene_path] = {}
	
	scene_pickup_states[scene_path][pickup_id] = {
		"collected": false,
		"data": pickup_data
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Dropped item ", item_id, " at ", position, " with ID: ", pickup_id)
	pickup_dropped.emit(pickup_id, item_id, position)
	
	return pickup_id

func get_save_data() -> Dictionary:
	var _fname = "get_save_data"
	
	# Save current scene state before saving
	save_current_scene_pickup_state()
	
	var save_data = {
		"scene_pickup_states": scene_pickup_states.duplicate(true)
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected pickup data for ", scene_pickup_states.size(), " scenes")
	return save_data

func load_save_data(data: Dictionary) -> bool:
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for pickup system load")
		return false
	
	# Restore scene pickup states
	if data.has("scene_pickup_states"):
		scene_pickup_states = data.scene_pickup_states.duplicate(true)
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored pickup states for ", scene_pickup_states.size(), " scenes")
	
	# Re-manage current scene with loaded data
	call_deferred("manage_scene_pickups")
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Pickup system restoration complete")
	return true

func reset():
	var _fname = "reset"
	scene_pickup_states.clear()
	active_pickups.clear()
	if debug: print(GameState.script_name_tag(self, _fname) + "Pickup system reset")
