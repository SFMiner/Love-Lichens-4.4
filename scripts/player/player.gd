extends PlayerCombatant

# Player script for Love & Lichens
# Handles player movement, interactions, and character stats

# Player movement and interaction signals
signal interaction_triggered(object)
var current_location_scene = null
var is_player_controlled := true
var in_dialogue : bool = false
#var speed
var current_scene_speed_mod = 1
@export var character_name = "Adam Young"
@export var character_id: String = ""
@export var portrait: Texture2D = preload("res://assets/images/portraits/adam_portrait.png")
var interaction_range : int
@onready var max_interaction_distance : int= interaction_range  # Maximum distance for mouse clicks
@onready var current_speed = base_speed
@onready var AP = get_node_or_null("AnimationPlayer")
@onready var sprite = get_node_or_null("Sprite2D")
@onready var interaction_area = get_node_or_null("InteractionArea")
#@onready var animator = get_node_or_null("CharacterAnimator")
var path_to_target = []


# Jumping
var run_toggle = false  # For CapsLock toggle functionality
# Interaction variables
var interactable_object = null
var in_dialog = false
@export var curr_animation_frame : int = 0

@onready var label : Label = $Label
@onready var camera = $Camera2D

# Sleep interface reference
var sleep_interface_scene
var sleep_interface

var jump_speed

# Navigation
var keyboard_override_timeout = 0.0  # Timer to allow keyboard to override navigation
var navigate_on_click = true  # Toggle for click-to-move functionality
var movement_marker_scene
@onready var nav_agent : NavigationAgent2D = get_node_or_null("NavigationAgent2D")

# Mouse interaction variables
var interactables_in_range = []
signal interaction_requested(object)
const scr_debug = true  # Enable debugging to help diagnose navigation issues

func _ready():
	super._ready()
	
	initialize_stats()
	interaction_range = 30 * scale.y
#	GameState.set_player(self)
	current_location_scene = get_location_scene()
	calculate_speed()
	current_speed = base_speed * current_scene_speed_mod
	debug = scr_debug or GameController.sys_debug 
	if debug: print("Player initialized: ", character_name)
	
	# Set up interaction area if it doesn't exist
	if not has_node("InteractionArea"):
		var area = Area2D.new()
		area.name = "InteractionArea"
		area.collision_mask = 2 # Set to interaction layer
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 60 # Wider interaction radius
		collision.shape = shape
		
		area.add_child(collision)
		add_child(area)
		
		# Connect signals
		area.area_entered.connect(_on_interaction_area_area_entered)
		area.area_exited.connect(_on_interaction_area_area_exited)
		
		if debug: print("Created InteractionArea with collision mask: ", area.collision_mask)
	else:
		if debug: print("InteractionArea already exists")
	
	# Connect to dialog system signals
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		# First disconnect any existing connections to avoid duplicates
		if dialog_system.dialog_started.is_connected(_on_dialog_started):
			dialog_system.dialog_started.disconnect(_on_dialog_started)
		if dialog_system.dialog_ended.is_connected(_on_dialog_ended):
			dialog_system.dialog_ended.disconnect(_on_dialog_ended)
			
		# Now connect the signals
		dialog_system.dialog_started.connect(_on_dialog_started)
		dialog_system.dialog_ended.connect(_on_dialog_ended)
		if debug: print("Connected to DialogSystem signals")
	else:
		if debug: print("DialogSystem not found")
	
	if ResourceLoader.exists("res://scenes/ui/sleep_interface.tscn"):
		sleep_interface_scene = load("res://scenes/ui/sleep_interface.tscn")
	
	print("Force reset dialog state on initialization")
	in_dialog = false
	add_to_group("player")
	add_to_group("z_Objects")
	add_to_group("navigator")


	# Connect to item pickup signals
	connect_to_pickup_signals()
	# Initialize with idle animation
	print("play_animation('idle')")
	if ResourceLoader.exists("res://scenes/world/movement_marker.tscn"):
		movement_marker_scene = load("res://scenes/world/movement_marker.tscn")
	else:
		# Create a simple marker if scene doesn't exist
		movement_marker_scene = _create_default_movement_marker()
	
	# Configure navigation agent
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 50.0
	nav_agent.max_speed = current_speed * run_speed_multiplier * 1.2  # Give it some extra headroom
	nav_agent.neighbor_distance = 100.0
	nav_agent.max_neighbors = 15
	nav_agent.time_horizon = 3.0
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = 15.0
	
	# Connect velocity_computed signal
	if not nav_agent.velocity_computed.is_connected(_on_velocity_computed):
		if nav_agent.velocity_computed.connect(_on_velocity_computed) == OK:
			if debug: print("DEBUG: velocity_computed signal connected successfully")
		else:
			print("ERROR: Failed to connect velocity_computed signal")
	
	# Add to navigation group for the NavigationManager to recognize
	if not is_in_group("navigation_agents"):
		add_to_group("navigation_agents")
	
	# Check if navigation is available in current scene
	call_deferred("_check_navigation_region")
		
func move_to(target: Vector2):
	nav_agent.target_position = target
		
func get_location_scene():
	var parent = get_parent()
	print("Trying parent" + parent.name + "...")
	
	while "location_scene" not in parent:
		print("NOPE!")
		print("Now trying parent" + parent.get_parent().name + "...")
		parent = parent.get_parent()
	return parent
	
func get_character_id():
	return character_id

func get_initiative():
	return speed + randi() % 5

func take_damage(amount, is_nonlethal=true):
	var damage_reduction = defense / 100.0
	var actual_damage = amount * (1 - damage_reduction)
	actual_damage = max(1, int(actual_damage))
	
	current_health = max(0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		# Handle defeat
		pass
	
	return actual_damage
	

# Attack implementation
func perform_attack(target, action):
	var base_damage = strength
	var actual_damage = target.take_damage(base_damage, true)
	
	current_stamina = max(0, current_stamina - 5)
	stamina_changed.emit(current_stamina, max_stamina)
	
	return {
		"success": true,
		"damage": actual_damage
	}
	
# Placeholder for skills data - replace with actual skills
func get_available_skills():
	# Return some basic combat skills
	return [
		{
			"name": "Power Strike",
			"stamina_cost": 15,
			"effects": [
				{
					"type": "damage",
					"value": strength * 1.5
				}
			]
		},
		{
			"name": "Quick Jab",
			"stamina_cost": 8,
			"effects": [
				{
					"type": "damage",
					"value": strength * 0.7
				}
			]
		}
	]

# Placeholder for combat-usable items data
func get_combat_usable_items():
	# Check if player has an inventory system
	var inventory = get_node_or_null("Inventory")
	if inventory and inventory.has_method("get_items_by_tag"):
		return inventory.get_items_by_tag("usable_in_combat")
	
	# Default empty list if no inventory or method
	return []

func _physics_process(delta):
	if debug: print("Frame: ", Engine.get_process_frames(), " - is_navigating: ", is_navigating)
	
	if keyboard_override_timeout > 0:
		keyboard_override_timeout -= delta

	# PRIORITY 1: Handle dialogue
	if in_dialogue:
		return
		
	# PRIORITY 2: Navigation takes precedence if active
	if is_navigating:
		if debug: print("Navigation is active - processing navigation")
		process_navigation(delta)
		return

	# PRIORITY 3: Player control if not navigating and not in dialogue
	if is_player_controlled:
		handle_dialogue_state()
		
		# Get input and update movement state
		var input_vector = get_movement_input()
		handle_movement_state(input_vector)
		
		# Process jumping if active
		process_jumping(delta)
		
		# Set velocity based on input and speed
		self.velocity = input_vector * speed
		
		# Update animation based on movement state
		update_animation(input_vector)
		
		# Check for interactable objects in range
		check_for_interactable()
		
		# Apply movement
		move_and_slide()
		
		# Update position tracking and z-index
		update_position_tracking()

	else:
		# Your autonomous/repulsion/pathfinding logic here
		if _is_near_interaction_zone():
			nav_agent.set_velocity(Vector2.ZERO)
			return

		if nav_agent.is_navigation_finished():
			return

		var next_point = nav_agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		self.velocity = direction * speed
		nav_agent.set_velocity(direction * speed)
	# Check dialogue system state
	var should_wait := false
	var push_vector := Vector2.ZERO
	var MIN_SEPARATION := 16.0
	var REPULSION_STRENGTH := 50.0



	if in_dialogue:
		return

	if is_navigating:
		process_navigation(delta)
		return

	if nav_agent.is_navigation_finished():
		return  # Reached goal

	if _is_near_interaction_zone():
		nav_agent.set_velocity(Vector2.ZERO)
		return
		
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	#var speed = 100.0  # Example speed
	var velocity = direction * current_speed
	nav_agent.set_velocity(velocity)

	handle_dialogue_state()


	for other in get_tree().get_nodes_in_group("navigators"):
		if other == self:
			continue
		var distance := global_position.distance_to(other.global_position)
		if distance < MIN_SEPARATION and distance > 0:
			var away = (global_position - other.global_position).normalized()
			push_vector += away * ((MIN_SEPARATION - distance) / MIN_SEPARATION)

	# Apply repulsion
	if push_vector.length() > 0:
		velocity = push_vector.normalized() * REPULSION_STRENGTH
		nav_agent.set_velocity(velocity)
		return

	# Skip movement if near an interaction zone
	var input_vector = get_movement_input()

	if is_player_controlled:
		# Get input and update movement state
		handle_movement_state(input_vector)
	
	# Process jumping if active
	process_jumping(delta)
	
	# Set velocity based on input and speed
	velocity = input_vector * speed
	
	# Update animation based on movement state
	update_animation(input_vector)
	
	# Check for interactable objects in range
	check_for_interactable()
	
	# Apply movement
	move_and_slide()
	
	# Update position tracking and z-index
	update_position_tracking()

func _is_near_interaction_zone() -> bool:
	for area in interaction_area.get_overlapping_areas():
		if area.get_parent() != self:
			return true
	return false
	
func handle_dialogue_state():
	if in_dialog:
		# Check if dialogue system reports it's still active
		var dialog_system = get_node_or_null("/root/DialogSystem")
		if dialog_system and dialog_system.current_character_id == "":
			if debug: print("Dialog ended detection: Fixing stuck dialog state (empty character ID)")
			in_dialog = false
			return
			
		# Check if any dialogue balloons exist in the scene
		var balloons = get_tree().get_nodes_in_group("dialogue_balloon")
		if balloons.size() == 0:
			if debug: print("Dialog ended detection: No dialogue balloons found in scene tree")
			in_dialog = false
			return
			
		# Periodic debug check
		if Engine.get_process_frames() % 60 == 0 and debug:  # Check once a second
			print("DEBUG: Still in dialog mode with character: ", dialog_system.current_character_id)

func get_movement_input():
	var input_vector = Vector2.ZERO
	
	# First try using the built-in input actions
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# If no input from UI actions, try direct WASD inputs
	if input_vector == Vector2.ZERO:
		var x_input = 0
		var y_input = 0
		
		# Check WASD keys directly
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			y_input -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			y_input += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			x_input -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			x_input += 1
			
		input_vector = Vector2(x_input, y_input).normalized()
	
	# If we get keyboard input while navigating, cancel navigation
	if input_vector.length() > 0.1 and is_navigating and keyboard_override_timeout <= 0:
		is_navigating = false
		path_to_target.clear()
		if debug: print("Navigation canceled due to keyboard input")
	
	return input_vector

func handle_movement_state(input_vector):
	# Update running state
	is_running = Input.is_key_pressed(KEY_SHIFT) or run_toggle
	
	# Set appropriate speed
	if is_running:
		speed = current_speed * run_speed_multiplier
	else:
		speed = current_speed
	if debug: print("base_speed = " + str(base_speed))
	# Update movement state tracking
	was_moving = is_moving
	is_moving = input_vector.length() > 0.1
	
	if is_moving and input_vector != Vector2.ZERO:
		last_direction = input_vector

func process_jumping(delta):
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0:
			is_jumping = false
			last_animation = ""  # Reset animation state when jump ends

func update_anim_direction():
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			anim_direction = "right" 
		else:
			anim_direction = "left"
	else:
		if last_direction.y > 0:
			anim_direction = "down" 
		else:
			anim_direction = "up"

func play_animation(anim_name):
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name) and anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func update_interaction_ray(input_dir):
	# This function is now a placeholder for compatibility
	# We no longer use a ray for interaction
	pass
		
func check_for_interactable():
	# Clear the current list of interactables in range
	interactables_in_range.clear()
	
	# Find all interactable objects within range
	var interactables = get_tree().get_nodes_in_group("interactable")
	
	for obj in interactables:
		# Skip if object doesn't have interact method
		if not obj.has_method("interact"):
			continue
			
		var dist = global_position.distance_to(obj.global_position)
		if dist <= interaction_range:
			interactables_in_range.append(obj)
			
			# Update this object's interaction status
			if obj.has_method("update_interaction_status"):
				obj.update_interaction_status(global_position)
	
	# Set the closest interactable as our current keypress interactable
	update_closest_interactable()
	
#	if debug:
#		print("Found ", interactables_in_range.size(), " interactables in range")

func update_closest_interactable():
	# Find the closest interactable in range for key-based interaction
	var closest_interactable = null
	var closest_distance = interaction_range
	
	for obj in interactables_in_range:
		var dist = global_position.distance_to(obj.global_position)
		if dist < closest_distance:
			closest_interactable = obj
			closest_distance = dist
	
	# Set the closest interactable as our current interactable
	var previous_interactable = interactable_object
	interactable_object = closest_interactable
	
	# Debug output for object change
	if debug and interactable_object != previous_interactable:
		if interactable_object:
			print("Updated closest interactable to: ", interactable_object.name)
		else:
			print("No interactable objects in range")

func update_running_state():
	# Update speed based on running state
	if is_running:
		speed = base_speed * run_speed_multiplier  
	elif is_jumping:
		speed = jump_speed
	else:
		speed = base_speed  
	print ("is_running = " + str(is_running) + ": speed set to " + str(speed))

	# Update animation if the character is already moving
	var anim_name : String = ""
	if is_moving and !is_jumping and last_animation != "idle":
		if is_running:
			anim_name = "run"
		else: 
			anim_name = "walk"
		if last_animation != anim_name:
			if AP:
				var new_anim = anim_name + "_" + anim_direction
				print("Updating to animation: " + new_anim)
				AP.stop()
				AP.play(new_anim)
				last_animation = anim_name
			else:
				print("AnimationPlayer reference not found")

func _unhandled_input(event):
	# Handle CapsLock toggle - this needs to be first
	if in_dialog:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and navigate_on_click:
		# Get click position in world space
		var click_pos = get_global_mouse_position()
		
		# Show marker at destination
		_show_movement_marker(click_pos)
		
		# Force debug output to be true temporarily for diagnosing issues
		var temp_debug = true
		
		# Create a simple direct path to the click point
		var direct_path = [click_pos]
		if temp_debug: print("NAVIGATION DEBUG: Creating direct path to ", click_pos)
		
		# Use this simple path for navigation
		if direct_path.size() > 0:
			path_to_target = direct_path
			is_navigating = true
			
			# Set a timeout to allow keyboard override immediately
			keyboard_override_timeout = 0.1
			
			if temp_debug: print("NAVIGATION DEBUG: Path set with ", path_to_target.size(), " points")
			if temp_debug: print("NAVIGATION DEBUG: is_navigating = ", is_navigating)
		else:
			if temp_debug: print("NAVIGATION DEBUG: Failed to create path")
			
			# Try to notify the user
			var notification_system = get_node_or_null("/root/NotificationSystem")
			if notification_system and notification_system.has_method("show_notification"):
				notification_system.show_notification("Cannot navigate to that location")
			
			
	if event is InputEventKey and event.keycode == KEY_CAPSLOCK and event.pressed:
		run_toggle = !run_toggle
		print("Run toggle is now: ", run_toggle)

	# Add sleep key (press H to sleep/rest)
	if event is InputEventKey and event.keycode == KEY_H and event.pressed and not in_dialog:
		sleep()

	# Jump handling (existing code)
	if event.is_action_pressed("jump") and !in_dialog:
		print("JUMP pressed.")
		begin_jump()
		
	if event.is_action_pressed("click") and !in_dialog:
		print("GLOBAL CLICK DETECTED!")
		
		# Check if we clicked on any interactable directly
		var space = get_viewport().get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_viewport().get_mouse_position()
		query.collision_mask = 2  # Interaction layer
		query.collide_with_areas = true
		query.collide_with_bodies = false
		
		var results = space.intersect_point(query)
		print("Click detected " + str(results.size()) + " objects at position " + str(query.position), " out of ", str(30 * scale.y))
		
		# Process clicked objects
		var closest_obj = null
		var closest_dist = 30 * scale.y #99999.0
		
		for result in results:
			var obj = result["collider"]
			if obj.is_in_group("interactable") and obj.has_method("interact"):
				var dist = global_position.distance_to(obj.global_position)
				print("- Clicked on: " + obj.name + " at distance " + str(dist))
				
				if dist < closest_dist:
					closest_dist = dist
					closest_obj = obj
		
		# Check if any object was clicked
		if closest_obj:
			print("Selected object: " + closest_obj.name + " (distance: " + str(closest_dist) + ", max range: " + str(max_interaction_distance) + ")")
			
			# STRICT RANGE CHECK - force object to be within max_interaction_distance
			if closest_dist <= max_interaction_distance:
				print("Object in range, interacting with: " + closest_obj.name)
				if global_position.distance_to(closest_obj.global_position) <= 30 * scale.y:	
					print("Distance to interactable = " + str(global_position.distance_to(closest_obj.global_position)), " out of ", str(30 * scale.y))
					closest_obj.interact()
			else:
				print("Object too far away: " + closest_obj.name + " (" + str(closest_dist) + " > " + str(max_interaction_distance) + ")")
				# Show too far away notification
				var notification_system = get_node_or_null("/root/NotificationSystem")
				if notification_system and notification_system.has_method("show_notification"):
					# Safely get display name
					var display_name : String = ""
					if "display_name" in closest_obj:
						display_name = closest_obj.display_name
					else:
						closest_obj.name
					notification_system.show_notification("Too far away to interact with " + display_name)
				else:
					print("Too far away to interact with " + closest_obj.name)

	elif event.is_action_pressed("interact"): 
		print("Interact button pressed")
		
		# Add emergency dialog reset logic
		if in_dialog:
			print("Emergency dialog reset: Player was stuck in dialog mode")
			in_dialog = false
			
		if interactable_object and !in_dialog:
			print("Interacting with: ", interactable_object.name)
			if global_position.distance_to(interactable_object.global_position) <= 30 * scale.y:
				print("Distance to interactable = " + str(global_position.distance_to(interactable_object.global_position)), " out of ", str(30 * scale.y))
				interaction_requested.emit(interactable_object)
				interactable_object.interact()
		else:
			print("No interactable object in range or dialog active")
			print("In dialog: ", in_dialog)
			
			# Print all nearby interactable objects for debugging
			var areas = get_tree().get_nodes_in_group("interactable")
			print("Interactable objects in scene: ", areas.size())
			for area in areas:
				print("- ", area.name, " at distance ", global_position.distance_to(area.global_position))

	elif event.is_action_pressed("look_at"):
	 # Get the LookAtSystem singleton
		print("Look_at pressed.")
		var look_at_system = get_node_or_null("/root/LookAtSystem")
		if look_at_system:
			  # Find the nearest interactable object
			var nearest_obj = null
			var nearest_distance = interaction_range

			for obj in interactables_in_range:
				var dist = global_position.distance_to(obj.global_position)
				if dist < nearest_distance:
					nearest_obj = obj
					nearest_distance = dist

			  # Look at the nearest object if found
			if nearest_obj:
				print("Looking at: ", nearest_obj.name)
				look_at_system.look_at(nearest_obj)
			else:
				print("No interactable objects in range to look at")

func _on_navigation_completed(character):
	# Only handle our own completion
	if character == self:
		is_navigating = false
		path_to_target = []
		
		# Disconnectig to avoid memory leaks
		var navigation_manager = get_node_or_null("/root/NavigationManager")
		if navigation_manager and navigation_manager.navigation_completed.is_connected(_on_navigation_completed):
			navigation_manager.navigation_completed.disconnect(_on_navigation_completed)

func begin_jump():
	if is_running:
		jump_speed = base_speed * run_speed_multiplier
	else:
		jump_speed = base_speed
	is_jumping = true
	
	
	jump_timer = 1.2  # JUMP_DURATION 
	update_anim_direction()
	animator.set_animation("jump", anim_direction, get_character_id())


func _on_dialog_started(character_id):
	if debug: print("Dialog started with: ", character_id)
	in_dialog = true
	
	# Make sure we're not stuck in an intermediate state
	velocity = Vector2.ZERO
	
	# Stop any ongoing animations and return to idle
	play_animation("idle")
	
func _on_dialog_ended(character_id):
	if debug: print("Dialog ended with: ", character_id)
	in_dialog = false
	
	# Force input processing to resume
	set_process_input(true)
	set_physics_process(true)
	
	# Clear any lingering input to prevent unwanted movement
	# Just let the next frame handle input reset naturally
	
	if debug: print("Player movement re-enabled")

func connect_to_pickup_signals():
	# This will connect to any existing pickup items in the scene
	var pickups = get_tree().get_nodes_in_group("interactable")
	for pickup in pickups:
		if pickup.has_signal("item_picked_up") and not pickup.item_picked_up.is_connected(_on_item_picked_up):
			pickup.item_picked_up.connect(_on_item_picked_up)

func _on_item_picked_up(item_id, item_data):
	if debug: print("Player received item: ", item_id)
	
	
func handle_interaction():
	if interactable_object and interactable_object.has_method("interact"):
		if global_position.distance_to(interactable_object.global_position) <= 30 * scale.y:
			print("distance to interacable object = ", str(global_position.distance_to(interactable_object.global_position)))
			interactable_object.interact()
			interaction_triggered.emit(interactable_object)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("interactable"):
		interactable_object = body
		print("Entered interaction range with: ", body.name)

func _on_interaction_area_area_entered(area):
	if area.is_in_group("interactable"):
		interactable_object = area
		print("Entered interaction range with area: ", area.name)

func _on_interaction_area_body_exited(body):
	if body == interactable_object:
		interactable_object = null
		print("Left interaction range with: ", body.name)

func _on_interaction_area_area_exited(area):
	if area == interactable_object:
		interactable_object = null
		print("Left interaction range with area: ", area.name)

# Function to be called when dialog starts/ends
func set_dialog_mode(active):
	in_dialog = active
	print("Dialog mode set to: ", in_dialog)  

func set_camera_limits(right, bottom, left, top, zoom_factor := 1.0):
	camera.limit_right = right
	camera.limit_bottom = bottom
	camera.limit_left = left
	camera.limit_top = top
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	speed = base_speed / zoom_factor

func _input(event):
	# F key debug option - lists all interactable objects and their distances
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		print("DEBUG: F key pressed - listing all interactable objects")
		
		# List all interactable objects and their distances
		var all_interactables = get_tree().get_nodes_in_group("interactable")
		print("Found ", all_interactables.size(), " total interactable objects")
		
		for obj in all_interactables:
			var dist = global_position.distance_to(obj.global_position)
			var in_range = dist <= interaction_range
			print("- ", obj.name, " (distance: ", dist, ", in range: ", in_range, ")")
		
		# Force interaction with closest object
		if interactable_object:
			print("DEBUG: Force interacting with closest object: ", interactable_object.name)
			if global_position.distance_to(interactable_object.global_position) <= 30 * scale.y:
				interactable_object.interact()
		else:
			print("DEBUG: No interactable object in range")

#func _on_sprite_2d_frame_changed() -> void:
#	print(str(sprite.texture) + " frame " + str(sprite.frame))

func sleep():
	if sleep_interface_scene and not is_instance_valid(sleep_interface):
		# Create a CanvasLayer for the sleep interface
		var canvas = CanvasLayer.new()
		canvas.layer = 100
		canvas.add_to_group("ui_layer")
		get_tree().root.add_child(canvas)
		
		# Create the sleep interface
		sleep_interface = sleep_interface_scene.instantiate()
		canvas.add_child(sleep_interface)
		
		# Connect sleep completed signal
		sleep_interface.sleep_completed.connect(_on_sleep_completed)
		
		# Pause the game
		get_tree().paused = true
		
	elif is_instance_valid(sleep_interface):
		# Show the existing interface
		sleep_interface.visible = true
		sleep_interface.update_buttons()
		get_tree().paused = true

func calculate_speed():
	if "scene_speed_mod" in current_location_scene:
		current_scene_speed_mod = current_location_scene.scene_speed_mod
	else:
		current_scene_speed_mod = 1
	var original_speed = base_speed
	current_speed = base_speed * current_scene_speed_mod
	if debug: print("speed was " + str(original_speed) + " but was multipliesd by " + str(current_scene_speed_mod) + " and is now " + str(base_speed) )

func _on_sleep_completed(time_periods):
	# Restore player health/energy
	if current_health < max_health:
		current_health = max_health
		health_changed.emit(current_health, max_health)
	
	if current_stamina < max_stamina:
		current_stamina = max_stamina
		stamina_changed.emit(current_stamina, max_stamina)
	
	# Unpause the game
	get_tree().paused = false
	
	# Add any additional effects from sleeping (status effects, etc.)
	for effect_id in status_effects.keys():
		remove_status_effect(effect_id)
	
	# Optional notification
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification("You feel refreshed after sleeping")


func _check_navigation_region():
	# Check if the current scene has a NavigationRegion2D for navigation
	var navigation_region = get_tree().current_scene.find_child("NavigationRegion2D", true, false)
	
	if navigation_region:
		if debug: print("Found NavigationRegion2D for navigation: ", navigation_region.name)
		
		# Make sure the navigation map is active
		var map_rid = navigation_region.get_navigation_map()
		NavigationServer2D.map_set_active(map_rid, true)
		
		# Verify the navigation mesh is valid
		var regions = NavigationServer2D.map_get_regions(map_rid)
		if regions.size() > 0:
			if debug: print("Navigation mesh has ", regions.size(), " regions")
		else:
			if debug: print("WARNING: Navigation mesh has no regions!")
	else:
		if debug: print("WARNING: No NavigationRegion2D found in scene. Click-to-navigate will not work.")
		
		# Try to notify the user about the missing navigation mesh
		var notification_system = get_node_or_null("/root/NotificationSystem")
		if notification_system and notification_system.has_method("show_notification"):
			notification_system.show_notification("Click to navigate not available in this area")

func _show_movement_marker(position):
	# Remove any existing markers
	for marker in get_tree().get_nodes_in_group("player_movement_marker"):
		marker.queue_free()
	
	# Create a new marker
	if movement_marker_scene:
		var marker = movement_marker_scene.instantiate()
		get_tree().current_scene.add_child(marker)
		marker.global_position = position
		marker.add_to_group("player_movement_marker")
		
		# Set up auto-removal
		var tween = create_tween()
		tween.tween_property(marker, "modulate:a", 0.0, 1.0)
		tween.tween_callback(marker.queue_free)

func _create_default_movement_marker():
	# Create a simple scene for the movement marker
	var scene = PackedScene.new()
	
	var marker = Sprite2D.new()
	marker.texture = preload("res://icon.svg") # Godot icon as fallback
	marker.scale = Vector2(0.3, 0.3)
	
	var script = GDScript.new()
	script.source_code = """
	extends Sprite2D
	
	func _ready():
		# Fade in
		modulate.a = 0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.2)
	"""
	script.reload()
	marker.set_script(script)
	
	scene.pack(marker)
	return scene

func process_navigation(delta):
	# Force debug to be true for this function
	var force_debug = true
	
	if not is_navigating or path_to_target.size() == 0:
		if force_debug: print("NAVIGATION STOPPED: is_navigating=", is_navigating, ", path_size=", path_to_target.size())
		is_navigating = false
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if force_debug: print("NAVIGATION ACTIVE: Processing navigation. Path points: ", path_to_target.size())
	
	# Get the next point in the path
	var target_point = path_to_target[0]
	
	# Calculate distance to the next point
	var distance = global_position.distance_to(target_point)
	if force_debug: print("NAVIGATION DISTANCE: ", distance, " to point: ", target_point)
	
	# If we've reached the point, remove it and move to the next
	if distance < 10:  # Threshold for reaching a point
		if force_debug: print("NAVIGATION REACHED: waypoint, removing from path")
		path_to_target.remove_at(0)
		
		# If no more points, we're done
		if path_to_target.size() == 0:
			if force_debug: print("NAVIGATION COMPLETE!")
			is_navigating = false
			velocity = Vector2.ZERO
			move_and_slide()
			
			# Try different ways to set animation back to idle
			if animator and animator.has_method("set_animation"):
				animator.set_animation("idle", anim_direction, get_character_id())
				if force_debug: print("NAVIGATION ANIMATION: Using CharacterAnimator.set_animation")
			elif AP and AP.has_animation("idle_" + anim_direction):
				AP.play("idle_" + anim_direction)
				if force_debug: print("NAVIGATION ANIMATION: Using AnimationPlayer.play")
			
			last_animation = "idle"
			return
	
	# Calculate direction directly to the next point in our path
	var direction = (target_point - global_position).normalized()
	if force_debug: print("NAVIGATION DIRECTION: ", direction)
	
	# Update animation based on direction
	last_direction = direction
	update_anim_direction()
	if force_debug: print("NAVIGATION ANIM DIR: ", anim_direction)
	
	# Set speed based on running state
	if is_running:
		speed = current_speed * run_speed_multiplier
	else:
		speed = current_speed
	
	# Calculate velocity (double the speed to make movement more obvious)
	var move_velocity = direction * speed * 1.5
	if force_debug: print("NAVIGATION VELOCITY: ", move_velocity)
	
	# Apply movement directly
	velocity = move_velocity
	move_and_slide()
	
	# Try different ways to update animation
	var anim_type = "run" if is_running else "walk"
	if animator and animator.has_method("set_animation"):
		animator.set_animation(anim_type, anim_direction, get_character_id())
		if force_debug: print("NAVIGATION ANIMATION: Using CharacterAnimator for ", anim_type)
	elif AP:
		var anim_name = anim_type + "_" + anim_direction
		if AP.has_animation(anim_name):
			AP.play(anim_name)
			if force_debug: print("NAVIGATION ANIMATION: Using AnimationPlayer for ", anim_name)
	
	# Update position tracking
	update_position_tracking()
	
# Handle the adjusted velocity from the avoidance system
func _on_velocity_computed(safe_velocity):
	# print("DEBUG: velocity_computed callback called with velocity: ", safe_velocity)
	
	# Apply the safe velocity that avoids other agents
	velocity = safe_velocity
	move_and_slide()
	
	# Update position tracking after movement
	update_position_tracking()

# Set a navigation path
func set_navigation_path(path: Array, run: bool = false):
	path_to_target = path
	is_navigating = true
	is_running = run
