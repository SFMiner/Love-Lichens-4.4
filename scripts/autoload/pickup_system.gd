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
	
	active_pickups.clear()
	
	await get_tree().process_frame


func save_current_scene_pickup_state():
	var _fname = "save_current_scene_pickup_state"
	var scene_path = get_tree().current_scene.scene_file_path
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Saving pickup state for scene: ", scene_path)

func manage_scene_pickups():
	var _fname = "manage_scene_pickups"
	var scene_path = get_tree().current_scene.scene_file_path
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Managing pickups for scene: ", scene_path)
	
	GameState.clear_pickups_save_data()
	if debug: GameState.print_pickups(GameState.script_name_tag(self, _fname))
	GameState.load_pickups_save_data()
	if debug: GameState.print_pickups(GameState.script_name_tag(self, _fname))
	GameState.clear_pickups()
	if debug: GameState.print_pickups(GameState.script_name_tag(self, _fname))

	restore_scene_from_saved_state()


func restore_scene_from_saved_state():
	var _fname = "restore_scene_from_saved_state"
	var scene_instance = GameState.get_current_scene()
	var restored_pickup
	GameState.get_player().set_camera_limits()
	if debug: print(GameState.script_name_tag(self, _fname) + "scene_visited = " + str(GameState.scene_visited(scene_instance.name)))
	if GameState.scene_visited(scene_instance.name):
		GameState.clear_pickups()
		if debug: print(GameState.script_name_tag(self, _fname) + str(GameState.get_pickups()))
		var pickups_to_put_down = GameState.get_scene_pickups_save_data()
		for pickup in pickups_to_put_down:
			restored_pickup = PickupSystem.create_pickup_from_data(pickup)
			if debug: print(GameState.script_name_tag(self, _fname) + "Pickup " + restored_pickup.item_id + " restored at " + str(restored_pickup.position))
			scene_instance.z_objects.add_child(restored_pickup)
	else:
		GameState.visit_scene(scene_instance.name)
	
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
	print(GameState.script_name_tag(self, _fname) + " called")
	# Create the pickup item
	var player : Player = GameState.get_player()
	var current_scene = GameState.get_current_scene()
	var pickup_scene = load("res://scenes/pickups/pickup_item.tscn")
	if not pickup_scene:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Could not load pickup_item.tscn")
		return null
	
	var pickup_instance = pickup_scene.instantiate()
	pickup_instance.item_id = pickup_data.item_id
	pickup_instance.item_data.item_name = pickup_data.item_name
	pickup_instance.name = pickup_data.item_name
	pickup_instance.item_amount = pickup_data.item_amount
	pickup_instance.auto_pickup = pickup_data.auto_pickup
	pickup_instance.scale = pickup_data.scale
	if debug: print(GameState.script_name_tag(self, _fname) + "pickup scale = ", str(pickup_instance.scale))
	pickup_instance.pickup_range = pickup_data.pickup_range
	pickup_instance.pickup_instance_id = pickup_data.pickup_instance_id
	if pickup_data.has("position"):
		pickup_instance.position = pickup_data.position
	
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



func drop_item_in_world(pickup_data : Dictionary) -> void:
	var _fname = "drop_item_in_world"
	if debug: print(GameState.script_name_tag(self, _fname) + " function called")
	var current_scene = GameState.get_current_scene()
	var scene_path = current_scene.scene_file_path
	
	var player = GameState.get_player()
	
	var position = Vector2(pickup_data.position)
	var drop_pos = player.get_position()
	if is_instance_valid(player) and player.get("last_direction") != null:
		drop_pos += player.last_direction.normalized() * 40

	# Create the actual pickup in the scene
	
	var pickup_id = pickup_data.pickup_instance_id
	
	pickup_data["position"] = drop_pos
	var pickup_instance = create_pickup_from_data(pickup_data)
	current_scene.add_child(pickup_instance)
	pickup_instance.add_to_group("pickup")


	if debug: print(GameState.script_name_tag(self, _fname) + "Dropped item " + pickup_data.item_id + " at " + str(pickup_data.position) + " with ID: " + pickup_id)
	pickup_dropped.emit(pickup_id, pickup_data.item_id, position)


func get_save_data() -> Dictionary:
	var _fname = "get_save_data"
	
	# Save current scene state before saving
#	save_current_scene_pickup_state()
	GameState.load_pickups_save_data()
	var save_data = {
		"scene_pickup_states": GameState.scenes# cene_pickup_states.duplicate(true)
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected pickup data for ", scene_pickup_states.size(), " scenes")
	return save_data

func load_save_data(data: Dictionary) -> bool:
	var _fname = "load_save_data"

	GameState.load_pickups_save_data()
	# Restore scene pickup states
	if data.has("scene_pickup_states"):
		GameState.scenes = data.scene_pickup_states.duplicate(true)


	
	if debug: print(GameState.script_name_tag(self, _fname) + "Pickup system restoration complete")
	return true

func reset():
	var _fname = "reset"
	for scene in GameState.scenes.keys():
		GameState.scenes[scene]["pickups"] = []
	GameState.scenes_visited = []
	scene_pickup_states.clear()
	active_pickups.clear()
	if debug: print(GameState.script_name_tag(self, _fname) + "Pickup system reset")
