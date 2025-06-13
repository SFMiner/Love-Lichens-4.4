# npc_spawn_data.gd
# Resource class for NPC spawn data - save as res://scripts/resources/npc_spawn_data.gd

class_name NpcSpawnData
extends Resource

@export var npc_id: String = ""
@export var scene_path: String = ""
@export var spawn_position: Vector2 = Vector2.ZERO
@export var spawn_marker: String = ""  # Alternative to position
@export var character_id: String = ""  # For dialogue system
@export var initial_direction: String = "down"
@export var is_temporary: bool = true  # Remove after cutscene

func _init(id: String = "", path: String = "", pos: Vector2 = Vector2.ZERO, marker: String = "", char_id: String = "", direction: String = "down", temporary: bool = true):
	npc_id = id
	scene_path = path
	spawn_position = pos
	spawn_marker = marker
	character_id = char_id if char_id != "" else id
	initial_direction = direction
	is_temporary = temporary
