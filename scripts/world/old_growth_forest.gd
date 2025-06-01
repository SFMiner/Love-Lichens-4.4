extends Node2D
const location_scene : bool = true

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
var camera_limit_right = 2000
var camera_limit_bottom = 2030
var camera_limit_left = 0
var camera_limit_top = 0
var zoom_factor = 0.75
var scene_speed_mod : float = 1.8

func _ready():
	debug = scr_debug or GameController.sys_debug 
	GameState.set_current_scene(self)
	var debug_label = get_node_or_null("CanvasLayer/GameInfo")
	player.set_camera_limits(camera_limit_right, camera_limit_bottom, camera_limit_left, camera_limit_top)
	if debug_label:
		var player = $Player
		if player and player.interactable_object:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
		else:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
	for child in z_objects.get_children():
		child.z_index = child.global_position.y
		if debug: print(GameState.script_name_tag(self) + child.name + " now has z-index " + str(child.z_index))
	for bugzone in bugzones.get_children():
		bugzone.z_index = bugzone.global_position.y + 10	
		if debug: print(GameState.script_name_tag(self) + bugzone.name + " now has z-index " + str(bugzone.z_index))

	
func spawn_player():
	player.global_position = entrance.global_position

func _process(delta):
	curr_scale = float(player.global_position.y/2125)*8
	scene_speed_mod = curr_scale/4
	player.scale = Vector2(curr_scale, curr_scale)
	player.calculate_speed()
