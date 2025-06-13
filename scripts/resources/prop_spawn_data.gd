# prop_spawn_data.gd
# Resource class for prop spawn data - save as res://scripts/resources/prop_spawn_data.gd

class_name PropSpawnData
extends Resource

@export var prop_id: String = ""
@export var scene_path: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO
@export var spawn_marker: String = ""  # Alternative to position
@export var is_temporary: bool = true

func _init(id: String = "", path: String = "", pos: Vector2 = Vector2.ZERO, marker: String = "", temporary: bool = true):
	prop_id = id
	scene_path = path
	spawn_position = pos
	spawn_marker = marker
	is_temporary = temporary
