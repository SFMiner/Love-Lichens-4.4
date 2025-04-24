extends Node2D

# Campus Quad scene script
# Initializes the level and manages scene-specific logic
const scr_debug :bool = false
var debug
var visit_areas = {}
var all_areas_visited = false
@onready var z_objects = $Sprite2D/z_Objects
var camera_limit_right = 2840
var camera_limit_bottom = 1885
var camera_limit_left = 0
var camera_limit_top = 0
var zoom_factor = 0.68
@onready var player = $Player

func _ready():
	var debug_label = get_node_or_null("CanvasLayer/GameInfo")
	player.set_camera_limits(camera_limit_right, camera_limit_bottom, camera_limit_left, camera_limit_top, zoom_factor)
	if debug_label:
		var player = $Player
		if player and player.interactable_object:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
		else:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
	
	
	print("Drom Room scene initialized")
	# Set up the scene components
	setup_player()
#	setup_npcs()
	setup_items()
	
	# Initialize necessary systems
	initialize_systems()
	for child in z_objects.get_children():
			child.z_index = child.global_position.y
			print(child.name + " now has z-index " + str(child.z_index))
	
	# Find and set up visitable areas
	setup_visit_areas()
	
	# Notify quest system that player is in campus quad
	await get_tree().create_timer(0.2).timeout
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("on_location_entered"):
		quest_system.on_location_entered("dorm-room")
		print("Notified quest system of location: dorm-room")


func setup_player():
	var player = $Player
	if player:
		print("Player found in scene")
		var col2d = player.get_node("CollisionShape2D")
		var shape = col2d.shape
		if shape:
			shape.extents.x = 10  # Set the x and y extents
		# Make sure the player's input settings are correct
		if not InputMap.has_action("interact"):
			print("Adding 'interact' action to InputMap")
			InputMap.add_action("interact")
			var event = InputEventKey.new()
			event.keycode = KEY_E
			InputMap.action_add_event("interact", event)
		else:
			print("'interact' action already exists in InputMap")
	else:
		print("ERROR: Player not found in scene!")

func setup_visit_areas():
	# Find all Area2D nodes in the "visitable_area" group
	var areas = get_tree().get_nodes_in_group("visitable_area")
	print("Found " + str(areas.size()) + " visitable areas in the scene")
	
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
	var npcs = get_tree().get_nodes_in_group("interactable")
	print("Found ", npcs.size(), " interactable NPCs in scene")

func setup_items():
	var interactables = get_tree().get_nodes_in_group("interactable")
			 
func initialize_systems():
	# Get references to necessary systems
	var dialog_system = get_node_or_null("/root/DialogSystem")
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
#	var relationship_system = get_node_or_null("/root/SoundManager")
	
	if dialog_system:
		print("Dialog System found")
	else:
		print("WARNING: Dialog System not found! Adding a temporary one.")
		var new_dialog_system = Node.new()
		new_dialog_system.name = "DialogSystem"
		new_dialog_system.set_script(load("res://scripts/systems/dialog_system.gd"))
		get_tree().root.add_child(new_dialog_system)
	
	if relationship_system:
		print("Relationship System found")
		
		# Initialize relationship with Professor Moss if needed
		if not relationship_system.relationships.has("professor_moss"):
			print("Initializing relationship with Professor Moss")
			relationship_system.initialize_relationship("professor_moss", "Professor Moss")
	else:
		print("WARNING: Relationship System not found")

# Optional function to update debug info on screen
func _process(delta):
	var p_scale = player.position.y / 125
	player.scale = Vector2(p_scale, p_scale)
	pass
	


func _on_visit_area_entered(body, area_name):
	if not body.is_in_group("player"):
		return
		
	print("Player entered area: " + area_name)
	
