# interaction_agent.gd
class_name InteractionAgent
extends Area2D

signal interaction_started
signal interaction_ended
signal selected(agent)

# Basic properties
@export var interaction_id: String = ""
@export var display_name: String = "Object"
@export var interaction_enabled: bool = true
@export var dialog_id: String = ""
@export var dialog_title: String = "start"
@export var interaction_range: float = 150.0  # Max distance for interaction

# Type of interaction - for filtering/categorizing
@export_enum("Generic", "NPC", "Tool", "Computer", "Lab", "Furniture") var object_type: int = 0

# Optional tooltip
@export var tooltip_text: String = ""

# Mouse interaction properties
var can_mouse_interact: bool = false  # True when player is in range
var player_node = null  # Reference to player node for distance checks
var debug_mouseover = false  # For debugging mouse interactions

const scr_debug :bool = false
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug 
	add_to_group("interactable")
	
	# Always ensure we have a properly sized collision shape
	var collision = get_node_or_null("CollisionShape2D")
	if not collision:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
		if debug: print(GameState.script_name_tag(self) + "Created new CollisionShape2D for " + name)
	
	# Make sure the collision shape has a proper shape
	if not collision.shape or not collision.shape is CircleShape2D:
		var shape = CircleShape2D.new()
		shape.radius = 60  # Increased interaction radius
		collision.shape = shape
		if debug: print(GameState.script_name_tag(self) + "Set collision shape for " + name)
		
	# Ensure proper collision settings
	collision_layer = 2   # Interaction layer
	collision_mask = 0    # We don't need to detect collisions
	
	# Make this object mouse interactive - THIS IS CRITICAL FOR MOUSE DETECTION
	input_pickable = true
	
	# Guarantee collision detection works properly
	monitoring = true
	monitorable = true
	
	# Connect to mouse events directly
	if not has_signal("mouse_entered"):
		if debug: print(GameState.script_name_tag(self) + "WARNING: " + name + " does not have mouse_entered signal! This is likely a Godot issue.")
		
	# Force these mouse event connections
	connect("mouse_entered", func(): print(GameState.script_name_tag(self) + "AGENT: Mouse entered " + name); debug_mouseover = true)
	connect("mouse_exited", func(): print(GameState.script_name_tag(self) + "AGENT: Mouse exited " + name); debug_mouseover = false)
	
	# Connect input events - ensure we're not already connected
	if not is_connected("input_event", _on_input_event):
		connect("input_event", _on_input_event)
		
	if debug: print(GameState.script_name_tag(self) + name + ": Interactive setup - pickable: " + str(input_pickable) + 
		", monitoring: " + str(monitoring) + 
		", monitorable: " + str(monitorable))
	
	# Find the player node (for distance checks)
	call_deferred("find_player")

func find_player():
	# Wait a frame to make sure the scene is fully loaded
	await get_tree().process_frame
	GameState.get_player()
	# Find the player in the scene
#	var players = get_tree().get_nodes_in_group("player")
#	if players.size() > 0:
#		player_node = players[0]
#		print(GameState.script_name_tag(self) + name + ": Found player node at " + str(player_node.global_position))



# Main interaction method
func interact():
	if not interaction_enabled:
		return false
		
	# Emit signal that interaction has started
	interaction_started.emit()
	
	# Get context from systems instead of storing it
	process_interaction()
	
	return true

# Process the interaction based on current game context
func process_interaction():
	var dialog_system = get_node_or_null("/root/DialogSystem")
	var quest_system = get_node_or_null("/root/QuestSystem")

	GameState.set_current_npcs()
	GameState.set_current_markers()
	
	# Let quest system determine if this interaction completes objectives
	var processed_by_quest = false
	if quest_system and quest_system.has_method("process_interaction"):
		processed_by_quest = quest_system.process_interaction(interaction_id)
	
	# If no quest handles this, show default dialog
	if not processed_by_quest and dialog_system and dialog_id != "":
		dialog_system.start_dialog(dialog_id, dialog_title)
	elif not processed_by_quest:
		show_notification("You interact with " + display_name)
	
	# Emit signal that interaction has ended
	interaction_ended.emit()

# Handle input events for mouse interaction
func _on_input_event(_viewport, event, _shape_idx):
	# Debug any mouse event received
	if event is InputEventMouse:
		if debug: print(GameState.script_name_tag(self) + "MOUSE EVENT on " + name + ": " + str(event.get_class()))
	
	# IMPORTANT: ALWAYS interact on ANY left click for immediate testing
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if debug: print(GameState.script_name_tag(self) + "MOUSE CLICK DETECTED on " + name + "! INTERACTING!")
		
		# Force interaction immediately regardless of distance
		interact()
		return

# Called by the player to update whether this object is in interaction range
func update_interaction_status(player_position: Vector2):
	var previous_state = can_mouse_interact
	var distance = global_position.distance_to(player_position)
	can_mouse_interact = distance <= interaction_range
	
	# Notify if the state changed
	if can_mouse_interact != previous_state and can_mouse_interact:
		selected.emit(self)
		
func _process(_delta):
	# Update interaction status if player exists
	if player_node:
		var distance = global_position.distance_to(player_node.global_position)
		can_mouse_interact = distance <= interaction_range

# Show a notification message
func show_notification(message):
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(message)
	else:
		if debug: print(GameState.script_name_tag(self) + message)
