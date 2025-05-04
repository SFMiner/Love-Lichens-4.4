extends Node2D

@export var marker_id: String = ""
@export var color : Color = Color("white")
@onready var color_rect = get_node_or_null("ColorRect")

func _ready():
	add_to_group("marker")
	color_rect.visible = false

func get_marker_id() -> String:
	if marker_id.is_empty():
		return name
	return marker_id
