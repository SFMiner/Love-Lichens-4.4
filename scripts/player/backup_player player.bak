extends PlayerCombatant

# Player script for Love & Lichens
# Handles player movement, interactions, and character stats

# Player movement and interaction signals
signal interaction_triggered(object)

@export var base_speed = 250.0
#var speed
@export var character_name = "Adam Young"
@export var character_id = "adam"
@export var interaction_range = 150.0  # Maximum distance for basic interaction
@export var max_interaction_distance = 150.0  # Maximum distance for mouse clicks

@onready var AP = get_node_or_null("AnimationPlayer")
@onready var sprite = get_node_or_null("Sprite2D")
var is_running = false
var run_speed_multiplier = 1.5  # Player moves faster when running
var run_toggle = false  # For CapsLock toggle functionality
var current_speed_mod = 1
		
# Jumping
var is_jumping = false
var jump_timer = 0.0
const JUMP_DURATION = 1.2  # Seconds - match this to animation length


const scr_debug :bool = false
var debug


# Interaction variables
var interactable_object = null
var in_dialog = false
var last_direction = Vector2(0, 1) # Default facing down
var last_animation = "idle" # Default facing down

var is_moving = false
var anim_direction = "down"  # for animation strings
@export var curr_animation_frame : int = 0

@onready var last_position = position
@onready var label : Label = $Label
@onready var camera = $Camera2D
@onready var animator = $CharacterAnimator

# Mouse interaction variables
var interactables_in_range = []
signal interaction_requested(object)

func _ready():
	initialize_stats()

	GameState.set_player(self)
	speed = base_speed
	debug = scr_debug or GameController.sys_debug 
	if debug: print("Player initialized: ", character_name)
	add_visual_health_bar()
	
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
	
	# Force reset dialog state on initialization
	in_dialog = false
	add_to_group("player")
	add_to_group("z_Objects")
	
	# Connect to item pickup signals
	connect_to_pickup_signals()
	# Initialize with idle animation
	play_animation("idle")

func begin_jump():
	is_jumping = true
	jump_timer = JUMP_DURATION
	update_anim_direction()
	animator.set_animation("jump", anim_direction)
	# (Optional) you could also add a small velocity boost here if you want "momentum"

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
	
	is_running = Input.is_key_pressed(KEY_SHIFT) or run_toggle
	if is_running:
		speed = base_speed * run_speed_multiplier
	else:
		speed = base_speed
	# Check dialog system nodes directly to detect if dialogue has ended
	if in_dialog:
		# First check if our dialog system is even reporting it's still active
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
			
		# If it's been more than 5 seconds since we entered dialogue with no end signal,
		# force exit dialogue mode as a failsafe
		if Engine.get_process_frames() % 60 == 0:  # Check once a second
			if debug: print("DEBUG: Still in dialog mode with character: ", dialog_system.current_character_id)
	
	# Handle movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	var was_moving = is_moving
	is_moving = input_vector.length() > 0.1
	
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0:
			is_jumping = false
			last_animation = ""  # Reset animation state when jump ends
		# We don't want to keep setting the animation repeatedly
		# This animation was already set in begin_jump()
	else:
		# If no input from UI, try direct WASD inputs
		if input_dir == Vector2.ZERO:
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
				
			input_dir = Vector2(x_input, y_input).normalized()
		
		# Set velocity
		velocity = input_dir * speed
		
		# Handle animation changes
		if input_dir != Vector2.ZERO:
			var old_direction = anim_direction
			last_direction = input_dir
			update_anim_direction()
			
			# Choose animation type based on running state
			var anim_type = ""
			if is_running:
				anim_type = "run"
			else:
				anim_type = "walk"
			
			# Only update animation if the direction has changed or animation type changed
			if old_direction != anim_direction or last_animation != anim_type or !was_moving:
				print("Setting " + anim_type + " animation - dir: " + anim_direction)
				animator.set_animation(anim_type, anim_direction)
				last_animation = anim_type
		elif last_animation != "idle":
			# Only set idle if we're not already idle
			print("Setting idle animation - current anim: " + last_animation)
			animator.set_animation("idle", anim_direction)
			last_animation = "idle"
	
	# Check for interactable objects in range
	check_for_interactable()
	
	# Apply movement
	move_and_slide()
	if position != last_position:
		last_position = position
		z_index = int(global_position.y)
		label.text = str(global_position)


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
	if event is InputEventKey and event.keycode == KEY_CAPSLOCK and event.pressed:
		run_toggle = !run_toggle
		print("Run toggle is now: ", run_toggle)

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
