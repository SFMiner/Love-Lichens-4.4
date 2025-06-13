# Resource class for character data
class_name CharacterData
extends Resource

@export var character_id: String = ""
@export var character_name: String = ""
@export var starting_marker: String = ""
@export var dialogue_file: String = ""
@export var initial_dialogue_title: String = ""
@export var initial_animation: String = "idle_right"
@export var is_player: bool = false
@export var scene_path: String = "res://scenes/npcs/npc.tscn"
@export var temporary: bool = false
