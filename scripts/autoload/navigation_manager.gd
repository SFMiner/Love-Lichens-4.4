extends Node

signal path_found(from_position, to_position, path)
signal path_not_found(from_position, to_position)
signal navigation_completed(character)



# Cache the navigation instances based on scene path
var navigation_instances = {}
var current_scene_path = ""

# References to scene nodes
var current_scene
var current_navigation
var navigation_map_rid: RID

const scr_debug : bool = true  # Enable debug for agent avoidance testing
var debug : bool

func _ready():
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug if Engine.has_singleton("GameController") else scr_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "NavigationManager initialized")
	
	# Get notified when scenes change
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("location_changed"):
		game_controller.location_changed.connect(_on_location_changed)
		
	# Find navigation region in current scene
	call_deferred("_find_navigation_node")
	
	# Setup navigation server parameters for agent avoidance
	_configure_navigation_server()
	

func _configure_navigation_server():
	var _fname = "_configure_navigation_server"
	# Activate the navigation map if using a NavigationRegion2D (assumed)
	var navigation_region = get_tree().get_root().find_child("NavigationRegion2D", true, false)
	if navigation_region:
		navigation_map_rid = navigation_region.get_navigation_map()
		NavigationServer2D.map_set_active(navigation_map_rid, true)
	else:
		push_warning("NavigationRegion2D node not found. Map activation skipped.")

	# Configure all NavigationAgent2D instances if needed globally
	var agents = get_tree().get_nodes_in_group("navigation_agents")
	for agent in agents:
		if agent is NavigationAgent2D:
			_configure_navigation_agent(agent)

func _configure_navigation_agent(agent: NavigationAgent2D):
	var _fname = "_configure_navigation_agent"
	agent.avoidance_enabled = false
	agent.radius = 40.0
	agent.max_neighbors = 15
	agent.max_speed = 400.0
	agent.neighbor_distance = 150.0
	agent.time_horizon = 2.0

func _on_location_changed(old_location, new_location):
	var _fname = "_on_location_changed"

	# Reset navigation when changing location
	current_scene_path = GameController.current_scene_path
	if debug: print(GameState.script_name_tag(self, _fname) + "Location changed to: ", current_scene_path)
	
	# Try to find and cache the navigation node
	_find_navigation_node()
	
	# Re-register all agents after location change
	call_deferred("_register_all_agents")

func _find_navigation_node():
	var _fname = "_find_navigation_node"
	# Get current scene
	current_scene = get_tree().current_scene
	
	# Look for NavigationRegion2D in the scene
	var navigation_regions = _find_navigation_regions_recursive(current_scene)
	
	if navigation_regions.size() > 0:
		current_navigation = navigation_regions[0]
		if debug: print(GameState.script_name_tag(self, _fname) + "Found navigation region: ", current_navigation.name)
		
		# Cache for future use
		navigation_instances[current_scene_path] = current_navigation
		return true
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "No navigation region found in current scene")
		return false

func _find_navigation_regions_recursive(node):
	var _fname = "_find_navigation_regions_recursive"
	var regions = []
	
	if node is NavigationRegion2D:
		regions.append(node)
	
	for child in node.get_children():
		var child_regions = _find_navigation_regions_recursive(child)
		regions.append_array(child_regions)
	
	return regions

func _register_all_agents():
	var _fname = "_register_all_agents"
	# This function makes sure all agents in the scene are properly registered
	var all_navigators = get_tree().get_nodes_in_group("navigator")
	if debug: print(GameState.script_name_tag(self, _fname) + "Found ", all_navigators.size(), " navigation agents to register")
	
	for navigator in all_navigators:
		if navigator.has_node("NavigationAgent2D"):
			var nav_agent = navigator.get_node("NavigationAgent2D")
			_configure_navigation_agent(nav_agent)


func _on_velocity_computed(safe_velocity, agent_parent):
	var _fname = "_on_velocity_computed"
	# This callback handles the safe velocity computed by the navigation agent
	if agent_parent.has_method("_on_velocity_computed"):
		# Call the parent's own velocity computed handler
		agent_parent._on_velocity_computed(safe_velocity)
	else:
		# Fallback if no handling method exists
		if "velocity" in agent_parent:
			agent_parent.velocity = safe_velocity
			if agent_parent.has_method("move_and_slide"):
				agent_parent.move_and_slide()


func find_path(from_position: Vector2, to_position: Vector2) -> Array:
	var _fname = "find_path"
	if current_navigation == null:
		if not _find_navigation_node():
			if debug: print(GameState.script_name_tag(self, _fname) + "Cannot find path - no navigation region")
			path_not_found.emit(from_position, to_position)
			return []
	
	# Get the navigation map ID from the current region
	var map_rid = current_navigation.get_navigation_map()
	
	# Use the NavigationServer2D to find a path
	var path = NavigationServer2D.map_get_path(
		map_rid, 
		from_position, 
		to_position, 
		true  # optimize path
	)
	
	if path.size() == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "No path found from ", from_position, " to ", to_position)
		path_not_found.emit(from_position, to_position)
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "Path found with ", path.size(), " points")
		path_found.emit(from_position, to_position, path)
	
	return path

# Move character along path
func navigate_character(character: Node2D, target_position: Vector2, run: bool = false) -> bool:
	var _fname = "navigate_character"
	if not is_instance_valid(character):
		if debug: print(GameState.script_name_tag(self, _fname) + "Invalid character for navigation")
		return false
	
	# Make sure the character has a navigation agent
	var nav_agent
	if character.has_node("NavigationAgent2D"):
		nav_agent = character.get_node("NavigationAgent2D")
		
		# Configure the navigation agent if needed
		if not nav_agent.avoidance_enabled:
			_configure_navigation_agent(nav_agent)
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "Character lacks NavigationAgent2D node")
		return false
	
	# Set the target position
	nav_agent.target_position = target_position
	
	# Configure character properties for navigation
	if character.has_method("move_to"):
		character.move_to(target_position)
	
	if "is_running" in character:
		character.is_running = run
		
		# Adjust navigation agent max speed based on run state
		if run and "run_speed_multiplier" in character and "current_speed" in character:
			nav_agent.max_speed = character.current_speed * character.run_speed_multiplier
		else:
			nav_agent.max_speed = character.current_speed
	
	return true

# Navigate character to a marker by ID
func navigate_to_marker(character: Node2D, marker_id: String, run: bool = false) -> bool:
	var _fname = "navigate_to_marker"
	# Find the marker in the scene
	var marker = _find_marker(marker_id)
	if not marker:
		if debug: print(GameState.script_name_tag(self, _fname) + "Cannot find marker: ", marker_id)
		return false
	
	# Navigate to marker position
	return navigate_character(character, marker.global_position, run)

# Find a marker by ID
func _find_marker(marker_id: String) -> Node2D:
	var _fname = "_find_marker"
	# Try to find through GameState first
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_marker_by_id"):
		var marker = game_state.get_marker_by_id(marker_id)
		if marker:
			return marker
	
	# Fallback to direct scene search
	var markers = get_tree().get_nodes_in_group("marker")
	for marker in markers:
		if marker.name == marker_id:
			return marker
		
		if marker.has_method("get_marker_id") and marker.get_marker_id() == marker_id:
			return marker
	
	return null

# Test navigation function for debugging
func debug_find_path(from_pos: Vector2, to_pos: Vector2) -> void:
	var _fname = "debug_find_path"
	var path = find_path(from_pos, to_pos)
	if path.size() > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "DEBUG: Found path with ", path.size(), " points")
		for i in range(path.size()):
			if debug: print(GameState.script_name_tag(self, _fname) + "Point ", i, ": ", path[i])
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "DEBUG: No path found between points")


func get_save_data() -> Dictionary:
	var _fname = "get_save_data"
	var save_data := {
		"navigation_instances": navigation_instances.duplicate(true),
		"current_scene_path": current_scene_path.duplicate(true),
		"": current_navigation.duplicate(true),
		"navigation_state": current_scene_path.duplicate(true),
	}

	if debug:
		print(GameState.script_name_tag(self, _fname) + "Collected navigation data: ", 
			"navigation_instances=",  str(navigation_instances), 
			", current_scene_path=", str(current_scene_path), 
			", current_navigation=", str(current_navigation))
	return save_data

# Legacy compatibility wrapper
func save_navigation() -> Dictionary:
	return get_save_data()


func load_save_data(data: Dictionary) -> bool:
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for navigation system load")
		return false

	if data.has("navigation_instances"):
		navigation_instances = data.navigation_instances
	if data.has("current_scene_path"):
		current_scene_path = data.current_scene_path
	if data.has("current_navigation"):
		current_navigation = data.current_navigation


	if debug:
		print(GameState.script_name_tag(self, _fname) + "Navigation system restoration complete: ",
			"navigation_instances=",  str(navigation_instances), 
			", current_scene_path=", str(current_scene_path), 
			", current_navigation=", str(current_navigation))

	# If necessary, re-validate or reset agent behaviors
	call_deferred("_reinitialize_navigation_agents")
	return true

# Legacy compatibility wrapper
func load_navigation(data: Dictionary) -> bool:
	return load_save_data(data)
