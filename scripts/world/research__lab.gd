extends Node2D

# Initializes the level and manages scene-specific logic
const scr_debug :bool = false
var debug
var visit_areas = {}
var curr_scale : float = 1.0
var all_areas_visited = false
@onready var z_objects = $Sprite2D/z_Objects
@onready var bugzones = $Sprite2D/bugzones
@onready var player = $Player
@onready var entrance = $entrance
var camera_limit_right = 4780
var camera_limit_bottom = 1525
var camera_limit_left = 0
var camera_limit_top = 0
var zoom_factor = 0.8

func _ready():
	var debug_label = get_node_or_null("CanvasLayer/GameInfo")
	player.set_camera_limits(camera_limit_right, camera_limit_bottom, camera_limit_left, camera_limit_top, zoom_factor)
	if debug_label:
		var player = $Player
		if player and player.interactable_object:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
		else:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
	for child in z_objects.get_children():
		child.z_index = child.global_position.y
		print(child.name + " now has z-index " + str(child.z_index))
	for bugzone in bugzones.get_children():
		bugzone.z_index = bugzone.global_position.y + 10	
		print(bugzone.name + " now has z-index " + str(bugzone.z_index))

	
func spawn_player():
	player.global_position = entrance.global_position
