# construct_spawner.gd
extends Node2D

@export var spawn_positions: Array = []
@export var construct_scene: PackedScene
@export var construct_names: Array[String] = ["Animated Chair", "Haunted Bookshelf"]
@export var construct_colors: Array[Color] = [Color(0.7, 0.5, 0.3), Color(0.5, 0.3, 0.7)]
@export var construct_sizes: Array[Vector2] = [Vector2(48, 48), Vector2(64, 64)]
@export var material_types: Array[String] = ["wood", "wood"]
@export var auto_spawn := true

const scr_debug : bool = false
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug
	if auto_spawn:
		spawn_constructs()
		
func spawn_constructs():
	# Make sure we have a valid scene to spawn
	if not construct_scene:
		if debug: print(GameState.script_name_tag(self) + "ERROR: No construct scene set in ConstructSpawner")
		return
		
	# Determine how many constructs to spawn
	var count = min(spawn_positions.size(), construct_names.size())
	if debug: print(GameState.script_name_tag(self) + "Attempting to spawn ", count, " constructs at ", spawn_positions)
	
	for i in range(count):
		var construct = construct_scene.instantiate()
		add_child(construct)
		
		# Configure the construct
		construct.global_position = spawn_positions[i]
		construct.construct_name = construct_names[i]
		
		if i < construct_colors.size():
			construct.construct_color = construct_colors[i]
			
		if i < construct_sizes.size():
			construct.construct_size = construct_sizes[i]
			
		if i < material_types.size():
			construct.material_type = material_types[i]
			
		if debug: print(GameState.script_name_tag(self) + "Spawned construct: ", construct_names[i], " at position ", spawn_positions[i])

# Function to add spawn positions manually
func add_spawn_position(new_position: Vector2):
	spawn_positions.append(new_position)
	if debug: print(GameState.script_name_tag(self) + "Added spawn position: " + str(new_position))

# Function to manually trigger spawning
func spawn():
	spawn_constructs()
