@tool
extends Node2D

@export var color: Color = Color("white"): set = _set_color
@onready var color_rect = get_node_or_null("ColorRect")
@onready var label: Label = get_node_or_null("ColorRect/Label")

const scr_debug : bool = false
var debug


func _ready():
	print(GameState.script_name_tag(self) + "cutscene marker " + self.name + " set")
	add_to_group("marker_nodes")
	print(GameState.script_name_tag(self) + "'marker_nodes' = " + str(get_tree().get_nodes_in_group("marker_nodes")))


	# Only hide ColorRect at runtime, not in editor
	if not Engine.is_editor_hint():
		if color_rect:
			color_rect.visible = false
	else:
		# In editor, make sure it's visible and update the display
		if color_rect:
			color_rect.visible = true
			_update_editor_display()




# Update display when the node name changes
func _notification(what):
	if what == NOTIFICATION_PATH_RENAMED and Engine.is_editor_hint():
		call_deferred("_update_editor_display")

func _set_color(value: Color):
	color = value
	if Engine.is_editor_hint():
		_update_editor_display()

func _update_editor_display():
	"""Update the visual display in the editor"""
	# Get nodes directly since @onready might not work in editor
	var rect = get_node_or_null("ColorRect")
	var lbl = get_node_or_null("ColorRect/Label")
	
	if rect:
		rect.color = color
		rect.visible = true
	
	if lbl:
		lbl.text = name

func get_marker_id() -> String:
	return name
