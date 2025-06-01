## Overview

This plan details a modular context menu system triggered by left-clicking on game objects. The system allows different game systems to register interaction options dynamically.

## Core Components

### 1. ContextMenuManager (Autoload Singleton)

gdscript

```gdscript
# context_menu_manager.gd - Add as autoload
extends Node

# Dictionary to store registered interaction types
# Format: { "action_id": { "text": "Display Text", "icon": icon_texture, "priority": 10, "handler": callable_reference, "validator": callable_reference } }
var registered_actions = {}

# Register a new interaction type
func register_action(action_id, display_text, icon, priority, handler_callable, validator_callable=null):
	registered_actions[action_id] = {
		"text": display_text,
		"icon": icon,
		"priority": priority,
		"handler": handler_callable,
		"validator": validator_callable
	}
	
# Get all valid actions for a target
func get_valid_actions(target):
	var valid_actions = {}
	
	for action_id in registered_actions:
		var action = registered_actions[action_id]
		
		# If no validator is provided, action is always valid
		if action.validator == null or action.validator.call(target):
			valid_actions[action_id] = action
	
	return valid_actions

# Execute an action on a target
func execute_action(action_id, target):
	if registered_actions.has(action_id):
		registered_actions[action_id].handler.call(target)
```

### 2. ContextMenu Scene

gdscript

```gdscript
# context_menu.gd
extends Control

signal menu_closed

var target_object = null
var menu_items = {}

@onready var menu_container = $MenuContainer

func _ready():
	visible = false
	
func show_menu(screen_position, target):
	# Store target
	target_object = target
	
	# Position menu
	global_position = screen_position
	
	# Clear existing buttons
	for child in menu_container.get_children():
		child.queue_free()
	
	# Get valid actions for this target
	var valid_actions = ContextMenuManager.get_valid_actions(target)
	
	# Sort actions by priority
	var sorted_actions = []
	for action_id in valid_actions:
		sorted_actions.append({"id": action_id, "data": valid_actions[action_id]})
	
	sorted_actions.sort_custom(func(a, b): return a.data.priority > b.data.priority)
	
	# Create menu items
	for action in sorted_actions:
		var button = Button.new()
		button.text = action.data.text
		if action.data.icon:
			button.icon = action.data.icon
		
		# Connect button press
		button.pressed.connect(_on_action_button_pressed.bind(action.id))
		
		menu_container.add_child(button)
	
	# Show menu if we have actions
	if menu_container.get_child_count() > 0:
		visible = true
	else:
		hide_menu()

func hide_menu():
	visible = false
	target_object = null
	menu_closed.emit()

func _on_action_button_pressed(action_id):
	# Execute action
	ContextMenuManager.execute_action(action_id, target_object)
	hide_menu()

# Close menu when clicking outside
func _input(event):
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not get_rect().has_point(get_local_mouse_position()):
			hide_menu()
```

### 3. Integration with Player Script

gdscript

```gdscript
# Add to player.gd
var context_menu_scene = preload("res://scenes/ui/context_menu.tscn")
var context_menu

func _ready():
	# Existing code...
	
	# Set up context menu
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	
	context_menu = context_menu_scene.instantiate()
	canvas_layer.add_child(context_menu)
	
	# Connect to click events
	set_process_unhandled_input(true)

func _unhandled_input(event):
	# Handle existing inputs...
	
	# Handle left-click for context menu
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if in_dialog or is_navigating:
			return  # Don't show menu during dialog
		
		# Cast a ray to find what was clicked
		var space = get_viewport().get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_viewport().get_mouse_position()
		query.collision_mask = 2  # Interaction layer
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		var results = space.intersect_point(query)
		
		var clicked_object = null
		var closest_dist = max_interaction_distance
		
		for result in results:
			var obj = result.collider
			if not obj.is_in_group("interactable"):
				continue
				
			var dist = global_position.distance_to(obj.global_position)
			if dist < closest_dist:
				clicked_object = obj
				closest_dist = dist
		
		if clicked_object:
			context_menu.show_menu(get_viewport().get_mouse_position(), clicked_object)
		else:
			context_menu.hide_menu()
```

### 4. System Registration Examples

gdscript

```gdscript
# Add this during initialization (could be in an autoload _ready function)

# Register Look action
ContextMenuManager.register_action(
	"look", 
	"Examine",
	preload("res://assets/icons/look_icon.png"),
	100,  # High priority
	func(target): 
		var look_system = get_node_or_null("/root/LookAtSystem")
		if look_system:
			look_system.look_at(target)
)

# Register Talk action
ContextMenuManager.register_action(
	"talk", 
	"Talk",
	preload("res://assets/icons/talk_icon.png"),
	90,
	func(target): 
		target.interact()
	,
	# Validator to check if this is an NPC
	func(target): 
		return target.is_in_group("npc")
)

# Register Pick Up action
ContextMenuManager.register_action(
	"pickup", 
	"Pick Up",
	preload("res://assets/icons/pickup_icon.png"),
	80,
	func(target): 
		if target.has_method("pickup"):
			target.pickup()
	,
	# Validator to check if this is a pickup item
	func(target): 
		return target.is_in_group("pickup") or target.has_method("pickup")
)
```

## Implementation Steps

1. Create the `ContextMenuManager` singleton script and add it as an autoload
2. Create the context menu scene with a VBoxContainer for menu items
3. Add the context menu code to player.gd
4. Register standard actions (look, talk, pickup)
5. Register additional actions for any other systems

## Key Design Benefits

1. **Modularity**: New actions can be registered without modifying existing code
2. **Prioritization**: Actions can be displayed in order of importance
3. **Validation**: Show only relevant actions for each object type
4. **Separation of concerns**: Each system handles its own interaction logic
5. **Extensibility**: Can easily add new validation rules or action types

This system provides a solid foundation that can be expanded with more specific actions like "Observe with microscope", "Collect sample", etc., as your game mechanics grow.