extends Node2D

# Campus Quad scene script
# Initializes the level and manages scene-specific logic
const location_scene :bool = true

const scr_debug :bool = false
var debug
var visit_areas = {}
var all_areas_visited = false
@onready var z_objects = $Node2D/z_Objects
var camera_limit_right = 1790	
var camera_limit_bottom = 1790
var camera_limit_left = 0
var camera_limit_top = 0
var zoom_factor = 1.2
@onready var player = $Player

func _ready():
	var debug_label = get_node_or_null("CanvasLayer/GameInfo")
	GameState.set_current_scene(self)
	player.set_camera_limits(camera_limit_right, camera_limit_bottom, camera_limit_left, camera_limit_top, zoom_factor)
	if debug_label:
		if player and player.interactable_object:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
		else:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
	$ColorRect.size.x = 30 * player.scale.y
	
	
	print(GameState.script_name_tag(self) + "Campus Quad scene initialized")
	# Set up the scene components
	setup_player()
#	setup_npcs()
	setup_items()
	
	# Initialize necessary systems
	initialize_systems()
	for child in z_objects.get_children():
			child.z_index = child.global_position.y
			print(GameState.script_name_tag(self) + child.name + " now has z-index " + str(child.z_index))
	
	# Find and set up visitable areas
	setup_visit_areas()
	
	# Notify quest system that player is in campus quad
	await get_tree().create_timer(0.2).timeout
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("on_location_entered"):
		quest_system.on_location_entered("campus_quad")
		print(GameState.script_name_tag(self) + "Notified quest system of location: campus_quad")


func setup_player():
	var player = $Player
	if player:
		print(GameState.script_name_tag(self) + "Player found in scene")
		# Make sure the player's input settings are correct
		if not InputMap.has_action("interact"):
			print(GameState.script_name_tag(self) + "Adding 'interact' action to InputMap")
			InputMap.add_action("interact")
			var event = InputEventKey.new()
			event.keycode = KEY_E
			InputMap.action_add_event("interact", event)
		else:
			print(GameState.script_name_tag(self) + "'interact' action already exists in InputMap")
	else:
		print(GameState.script_name_tag(self) + "ERROR: Player not found in scene!")

func setup_visit_areas():
	# Find all Area2D nodes in the "visitable_area" group
	var areas = get_tree().get_nodes_in_group("visitable_area")
	print(GameState.script_name_tag(self) + "Found " + str(areas.size()) + " visitable areas in the scene")
	
	# Set up tracking for each area
	for area in areas:
		# Store the area in our tracking dict
		visit_areas[area.name] = {
			"visited": false,
			"area": area
		}
		
		# Connect the body_entered signal if not already connected
		if not area.body_entered.is_connected(_on_visit_area_entered):
			area.body_entered.connect(_on_visit_area_entered.bind(area.name))
			
func setup_npcs():
	# Setup Professor Moss
	var professor_moss = $ProfessorMoss
	if professor_moss:
		print(GameState.script_name_tag(self) + "Professor Moss found in scene")
		# Ensure Professor Moss has the correct collision settings
		if professor_moss.get_collision_layer() != 2:
			print(GameState.script_name_tag(self) + "Setting Professor Moss collision layer to 2")
			professor_moss.set_collision_layer(2)
	else:
		print(GameState.script_name_tag(self) + "ERROR: Professor Moss not found in scene!")
	
	# Find and setup all NPCs
	var npcs = get_tree().get_nodes_in_group("interactable")
	print(GameState.script_name_tag(self) + "Found ", npcs.size(), " interactable NPCs in scene")

func setup_items():
	var interactables = get_tree().get_nodes_in_group("interactable")
			 
func initialize_systems():
	# Get references to necessary systems
	var dialog_system = get_node_or_null("/root/DialogSystem")
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	
	if dialog_system:
		print(GameState.script_name_tag(self) + "Dialog System found")
	else:
		print(GameState.script_name_tag(self) + "WARNING: Dialog System not found! Adding a temporary one.")
		var new_dialog_system = Node.new()
		new_dialog_system.name = "DialogSystem"
		new_dialog_system.set_script(load("res://scripts/systems/dialog_system.gd"))
		get_tree().root.add_child(new_dialog_system)
	
	if relationship_system:
		print(GameState.script_name_tag(self) + "Relationship System found")
		
		# Initialize relationship with Professor Moss if needed
		if not relationship_system.relationships.has("professor_moss"):
			print(GameState.script_name_tag(self) + "Initializing relationship with Professor Moss")
			relationship_system.initialize_relationship("professor_moss", "Professor Moss")
	else:
		print(GameState.script_name_tag(self) + "WARNING: Relationship System not found")

# Optional function to update debug info on screen
func _process(delta):
	pass
#	var debug_label = $CanvasLayer/GameInfo
#	if debug_label:
#		var player = $Player
#		if player and player.interactable_object:
#			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
#		else:
#			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"

func _on_visit_area_entered(body, area_name):
	if not body.is_in_group("player"):
		return
		
	print(GameState.script_name_tag(self) + "Player entered area: " + area_name)
	
	# Mark as visited
	if visit_areas.has(area_name):
		# If already visited, no need to process again
		if visit_areas[area_name].visited:
			print(GameState.script_name_tag(self) + "Area already visited: " + area_name)
			return
			
		visit_areas[area_name].visited = true
		print(GameState.script_name_tag(self) + "Marked area as visited: " + area_name)
		
		# Change visual indicator to show it's been visited
		var area = visit_areas[area_name].area
		var indicator = area.find_child("VisualIndicator") # Name your ColorRect or Sprite2D this
		if indicator:
			if indicator is ColorRect:
				indicator.color = Color(0.0, 1.0, 0.0, 0.5) # Change to green
			elif indicator is Sprite2D:
				indicator.modulate = Color(0.0, 1.0, 0.0, 0.5)
		
		# Check if we've visited all areas
		var all_visited = check_all_areas_visited()
		print(GameState.script_name_tag(self) + "All areas visited: ", all_visited)
		
		# Notify quest system
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system:
			if quest_system.has_method("on_area_visited"):
				print(GameState.script_name_tag(self) + "Calling quest_system.on_area_visited with ", area_name, " and campus_quad")
				quest_system.on_area_visited(area_name, "campus_quad")
				
			# If all areas visited, also notify for a complete exploration
			if all_visited and quest_system.has_method("on_area_exploration_completed"):
				print(GameState.script_name_tag(self) + "Calling quest_system.on_area_exploration_completed with campus_quad")
				quest_system.on_area_exploration_completed("campus_quad")

func check_all_areas_visited():
	# Return early if we already know all areas are visited
	if all_areas_visited:
		return true
		
	for area_name in visit_areas:
		if not visit_areas[area_name].visited:
			return false
	
	# If we get here, all areas have been visited
	all_areas_visited = true
	print(GameState.script_name_tag(self) + "All areas in campus quad have been visited!")
	return true
