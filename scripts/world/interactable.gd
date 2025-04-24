extends InteractionAgent

@export var int_id: String = "interactable"
@export var dis_name: String = "Interactable"
@export var dia_id: String = "interactable_dialog_name"
@export var dia_tit: String = "start"
@export_enum("Generic", "NPC", "Tool", "Computer", "Lab", "Furniture") var obj_type: int = 0
@export var highlight_on_hover: bool = true
@export var highlight_color: Color = Color(1, 1, 0, 0.3)  # Yellow semi-transparent
# Visual feedback for highlighting
var is_highlighted: bool = false
var original_modulate: Color

func _ready():
	# Assign the exported properties to the inherited properties
	interaction_id = int_id
	display_name = dis_name
	dialog_id = dia_id
	dialog_title = dia_tit
	object_type = obj_type
	
	# Save original modulate color for highlighting
	if get_parent() and get_parent().has_method("get_modulate"):
		original_modulate = get_parent().modulate
	else:
		original_modulate = Color(1, 1, 1, 1)
	
	# Make sure this object is in the right collision layer and mask
	# Layer 2 is the interaction layer
	collision_layer = 2
	collision_mask = 0  # We don't need to detect collisions with anything
	
	# CRITICAL: Override the mouse interaction settings to ensure they work
	input_pickable = true  # This is what allows the Area2D to detect mouse events
	
	# Test direct connection to _input_event
	var base_method = "_on_input_event"
	if has_method(base_method):
		print(name + ": Already has _on_input_event method")
	else:
		print(name + ": WARNING - does not have _on_input_event method")
	
	# Ensure we're connecting all required signals
	if not is_connected("input_event", _input_fallback):
		connect("input_event", _input_fallback)
	if not is_connected("mouse_entered", _on_mouse_entered):
		connect("mouse_entered", _on_mouse_entered)
	if not is_connected("mouse_exited", _on_mouse_exited):
		connect("mouse_exited", _on_mouse_exited)
	
	# Critical debug info
	print(name + ": Set up direct interactable mouse handling")
	
	# Add debug output
	print("Interactable initialized: ", name)
	print("  interaction_id: ", interaction_id)
	print("  dialog_id: ", dialog_id)
	print("  dialog_tit: ", dialog_title)
	print("  has interact method: ", has_method("interact"))
	print("  collision shape: ", $CollisionShape2D if has_node("CollisionShape2D") else "None")

# Direct input event handler in case inheritance is causing issues
func _input_fallback(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("DIRECT CLICK ON " + name + "!")
		var player = GameState.get_player()
		if global_position.distance_to(player.global_position) <= 30 * player.scale.y:
			print("Distance to player = " + str(global_position.distance_to(player.global_position)))
			   
			interact()  # Call interact directly

func _on_mouse_entered():
	print("MOUSE ENTERED: " + name)
	if highlight_on_hover:
		set_highlight(true)
		
func _on_mouse_exited():
	print("MOUSE EXITED: " + name)
	if highlight_on_hover:
		set_highlight(false)
		
func set_highlight(enabled: bool):
	is_highlighted = enabled
	
	# Only highlight the object itself, not the parent
	# This prevents screen-wide color shifts
	modulate = highlight_color if enabled else Color(1, 1, 1, 1)
	print("HIGHLIGHT: Set " + name + " highlight to " + str(enabled))
	
	# Show name popup when highlighted
	if enabled:
		var tooltip = display_name
		if tooltip_text != "":
			tooltip += "\n" + tooltip_text
		print("Highlighting: " + tooltip)
		# TODO: Show floating tooltip near object
