# location_transition.gd
class_name LocationTransition
extends Area2D

signal transition_triggered(target_location, spawn_point)

@export var target_location: String = "" # The location scene to transition to (e.g., "cemetery")
@export_file("*.tscn") var target_scene: String = "" # Alternatively, use a direct scene path
@export var spawn_point: String = "default" # Where to place the player in the target scene
@export var transition_name: String = "Door" # Display name for the transition
@export var require_interaction: bool = true # Whether player needs to press interact
@export var enabled: bool = true # Whether this transition is currently usable
@export var require_item: String = "" # Optional item required to use this transition
@export var consume_item: bool = false # Whether to remove the item after use
@export var rect_color : Color
# Optional hint text shown when player is near but cannot use transition
@export_multiline var locked_hint: String = "This door is locked."

const scr_debug:bool = true
var debug
var player_in_area: bool = false
@onready var label : Label = $Label


func _ready():
	debug = scr_debug or GameController.sys_debug
	# Set up collision if one doesn't exist
	if not has_node("CollisionShape2D"):
		if debug: print(GameState.script_name_tag(self) + "Creating default collision shape for location transition")
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(50, 50)
		collision.shape = shape
		add_child(collision)
	label.text = transition_name
	$ColorRect.color = rect_color
	# Make sure we're in the interactable group
	add_to_group("interactable")
	
	# Validate target location
	if target_location.is_empty() and target_scene.is_empty():
		if debug: print(GameState.script_name_tag(self) + "ERROR: No target location or scene specified for location transition")
		enabled = false
	elif not target_scene.is_empty() and not FileAccess.file_exists(target_scene):
		if debug: print(GameState.script_name_tag(self) + "ERROR: Target scene file does not exist: ", target_scene)
		enabled = false
	
	# Connect area signals
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		if debug: print(GameState.script_name_tag(self) + "Player entered transition area: ", name)
		
		# Auto-trigger if no interaction required
		if not require_interaction:
			if debug: print(GameState.script_name_tag(self) + "Auto-triggering transition")
			interact()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		if debug: print(GameState.script_name_tag(self) + "Player exited transition area: ", name)

func interact():
	if debug: print(GameState.script_name_tag(self) + "Location transition triggered: ", name)
	
	if not enabled:
		if debug: print(GameState.script_name_tag(self) + "Transition is disabled")
		_show_locked_hint()
		return
	
	# Check if the player has the required item
	if not require_item.is_empty():
		var inventory_system = get_node_or_null("/root/InventorySystem")
		if not inventory_system or not inventory_system.has_item(require_item):
			if debug: print(GameState.script_name_tag(self) + "Player does not have required item: ", require_item)
			_show_locked_hint()
			return
		
		# Consume item if configured to do so
		if consume_item:
			inventory_system.remove_item(require_item, 1)
			if debug: print(GameState.script_name_tag(self) + "Consumed item: ", require_item)
	
	# Determine which scene to load
	var scene_path = ""
	if not target_scene.is_empty():
		scene_path = target_scene
	else:
		# Convert location name to scene path
		scene_path = "res://scenes/world/locations/" + target_location + ".tscn"
	
	if debug: print(GameState.script_name_tag(self) + "Transitioning to: ", scene_path, " at spawn point: ", spawn_point)
	
	# Save player state before transition
	_save_player_state()
	
	# Emit signal for any listeners
	transition_triggered.emit(target_location, spawn_point)
	
	# Change scene
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		_perform_transition(game_controller, scene_path)
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found")
		# Fallback to direct scene change
		get_tree().change_scene_to_file(scene_path)

func _perform_transition(game_controller, scene_path):
	if game_controller.has_method("change_location"):
		print(GameState.script_name_tag(self) + "game_controller.change_location("+scene_path+", "+spawn_point+")")
		game_controller.change_location(scene_path, spawn_point)
	else:
		# Fallback to basic scene change if the enhanced method doesn't exist
		game_controller.change_scene(scene_path)

func _save_player_state():
	# Find the player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		if debug: print(GameState.script_name_tag(self) + "WARNING: Could not find player to save state")
		return
	
	# Get game state singleton
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		if debug: print(GameState.script_name_tag(self) + "WARNING: GameState not found")
		return
	
	# Save player position
	game_state.game_data.player_position = player.position
	
	# Save player direction
	if ("last_direction") in player:
		game_state.game_data.player_direction = player.last_direction
	
	# Save current location
	var current_scene_path = get_tree().current_scene.scene_file_path
	game_state.game_data.current_location = current_scene_path.get_file().get_basename()
	
	if debug: print(GameState.script_name_tag(self) + "Saved player state: Position=", player.position, 
		", Direction=", player.last_direction if "last_direction" in player else Vector2.DOWN)

func _show_locked_hint():
	if locked_hint.is_empty():
		return
		
	if debug: print(GameState.script_name_tag(self) + "Showing locked hint: ", locked_hint)
	
	# Show a notification if we have a notification system
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(locked_hint)
		
# As a final fallback: try to find node by name anywhere in scene
