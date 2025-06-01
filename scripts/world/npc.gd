extends NPCCombatant

# Base script for all NPCs in the game
# Handles character data, interactions, memories, and appearance

signal interaction_started(npc_id)
signal interaction_ended(npc_id)
signal observed(feature_id)

@export var character_name: String = "Unknown"
@export var initial_animation: String = "idle_down"
@export var portrait: Texture2D
#@export var description: String = ""
@export var interactable: bool = true
@export var initial_dialogue_title: String = ""
@export var character_id: String = ""
# Observable features for memory discovery
@export var observable_features: Dictionary = {
	# Format: "feature_id": {"description": "Feature description", "observed": false, "memory_tag": "optional_tag"}
}
var description: String = ""

@onready var sprite = get_node_or_null("Sprite2D")
@onready var nav_agent : NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var interaction_area = get_node_or_null("InteractionArea")



# Character data
var character_data = {}
var relationship_level = 0 # 0=stranger, 1=acquaintance, 2=friend, 3=close friend, 4=romantic
var dialogue_system
var memory_system
var game_state
var ap = get_node_or_null("AnimationPlayer")

const scr_debug : bool = false

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print(GameState.script_name_tag(self) + "NPC initialized: ", character_id)
	
	super._ready()
	
	if debug: print(GameState.script_name_tag(self) + "--- NPC NODE HIERARCHY DEBUG ---")
	for child in get_children():
		if debug: print(GameState.script_name_tag(self) + "Child node: " + child.name + ", class: " + child.get_class())
	
	if description == "":
		description = "You see " + character_name + "."
		if debug: print(GameState.script_name_tag(self) + "NPC: Set default description for ", character_id)
	
	# Debug CharacterAnimator specifically
	if animator:
		if debug: print(GameState.script_name_tag(self) + "Found CharacterAnimator")
		
		# Check if the animator has the required functionality
		if animator.has_method("set_animation"):
			print(GameState.script_name_tag(self) + "CharacterAnimator has set_animation method")
		else:
			if debug: print(GameState.script_name_tag(self) + "ERROR: CharacterAnimator missing set_animation method")
		
		# Check if the animator has found its sprite
		if "sprite" in animator:
			if debug: print(GameState.script_name_tag(self) + "CharacterAnimator has sprite reference: " + str(animator.sprite != null))
		else:
			if debug: print(GameState.script_name_tag(self) + "ERROR: CharacterAnimator has no sprite property")
			
		# Check for AnimationPlayer
		if ap:
			if debug: print(GameState.script_name_tag(self) + "Found AnimationPlayer, animations: " + str(ap.get_animation_list()))
		else:
			if debug: print(GameState.script_name_tag(self) + "ERROR: No AnimationPlayer found for animations")
	
	if sprite:
		if debug: print(GameState.script_name_tag(self) + "Found Sprite2D node for " + character_id)
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Sprite2D node not found for " + character_id)
		# Try to create it if missing
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		if debug: print(GameState.script_name_tag(self) + "Created new Sprite2D node for " + character_id)
		
	var texture_path = "res://assets/character_sprites/" + character_id + "/standard/idle.png"
	if debug: print(GameState.script_name_tag(self) + "Loading texture from: " + texture_path)
	
	var texture = load(texture_path)
	if texture:
		if debug: print(GameState.script_name_tag(self) + "Successfully loaded texture")
		sprite.texture = texture
		sprite.hframes = 2
		sprite.vframes = 4
		if debug: print(GameState.script_name_tag(self) + "Applied texture to sprite: " + str(texture.get_path()))
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Failed to load texture from " + texture_path)
		
		# Try with a hardcoded path as fallback
		var fallback_path = "res://assets/character_sprites/kitty/standard/idle.png" 
		if debug: print(GameState.script_name_tag(self) + "Trying fallback texture: " + fallback_path)
		texture = load(fallback_path)
		
		if texture:
			if debug: print(GameState.script_name_tag(self) + "Fallback texture loaded successfully")
			sprite.texture = texture
			sprite.hframes = 2
			sprite.vframes = 4
		else:
			if debug: print(GameState.script_name_tag(self) + "ERROR: Even fallback texture failed to load")
			
	# Additional debug - verify texture is set
	if sprite.texture:
		if debug: print(GameState.script_name_tag(self) + "Sprite texture is set: " + str(sprite.texture.get_path()))
	else:
		if debug: print(GameState.script_name_tag(self) + "WARNING: Sprite texture is still null after setup")
		
	# Ensure the sprite is visible and properly positioned
	sprite.visible = true
	sprite.modulate.a = 1.0  # Full opacity
	sprite.position = Vector2(0, -30)  # Position slightly above the character's origin
	sprite.z_index = 1  # Ensure it's visible above other elements
		
#	sprite.hframes = 2
#	sprite.vframes = 4
#	var texture = load("res://assets/character_sprites/kitty/standard/idle.png")
#	sprite.texture = texture
	add_to_group("interactable")
	add_to_group("npc")
	add_to_group("navigator")

	GameState.set_current_npcs()
#	get_tree().get_node_or_null("root").label1.text = GameState.set_current_npcs()
#	get_tree().get_node_or_null("root").label2.text = get_tree().get_nodes_in_group("npc")
	# Load character data
	load_character_data()
	
	# Get reference to the dialogue system
	dialogue_system = get_node_or_null("/root/DialogSystem")
	if not dialogue_system:
		if debug: print(GameState.script_name_tag(self) + "WARNING: DialogSystem not found!")
	
	# Get reference to the memory system
	memory_system = get_node_or_null("/root/MemorySystem")
	if not memory_system:
		if debug: print(GameState.script_name_tag(self) + "WARNING: MemorySystem not found!")
	
	# Get reference to the game state
	game_state = get_node_or_null("/root/GameState")
	if not game_state:
		if debug: print(GameState.script_name_tag(self) + "WARNING: GameState not found!")
	
	# Make sure the collision shape is enabled
	for child in get_children():
		if child is CollisionShape2D:
			if not child.disabled:
				if debug: print(GameState.script_name_tag(self) + "Collision shape for ", character_id, " is enabled")
			else:
				if debug: print(GameState.script_name_tag(self) + "Enabling collision shape for ", character_id)
				child.disabled = false

	nav_agent.avoidance_enabled = true
	nav_agent.radius = 8.0
	nav_agent.neighbor_distance = 32.0

	call_deferred("setup_sprite_deferred")
	get_node_or_null("AnimationPlayer").play(initial_animation)

# ENHANCED: Observable feature handling with registry validation
func observe_feature(feature_id: String) -> String:
	"""Observe a feature and trigger memory using registry"""
	var _fname = "observe_feature"
	print(GameState.script_name_tag(self, _fname) + "=== NPC OBSERVE_FEATURE DEBUG (REGISTRY) ===")
	print(GameState.script_name_tag(self, _fname) + "character_id: ", character_id)
	print(GameState.script_name_tag(self, _fname) + "feature_id: ", feature_id)
	print(GameState.script_name_tag(self, _fname) + "observable_features: ", observable_features)
	
	if not observable_features.has(feature_id):
		print(GameState.script_name_tag(self, _fname) + "ERROR: Feature not found: ", feature_id)
		return ""
	
	var feature = observable_features[feature_id]
	print(GameState.script_name_tag(self, _fname) + "Feature data: ", feature)
	
	# Mark as observed
	if not feature.get("observed", false):
		print(GameState.script_name_tag(self, _fname) + "Marking feature as observed")
		feature["observed"] = true
		observed.emit(feature_id)
		
		# ENHANCED: Use registry to find and trigger memory
		var memory_tag = _find_memory_tag_for_feature(feature_id)
		if memory_tag != "":
			print(GameState.script_name_tag(self, _fname) + "Found memory tag in registry: ", memory_tag)
			
			# Validate and trigger memory using registry
			if GameState.is_valid_memory_tag(memory_tag):
				if GameState.can_unlock_memory(memory_tag):
					if GameState.discover_memory_from_registry(memory_tag, "observable_feature"):
						print(GameState.script_name_tag(self, _fname) + "Successfully triggered memory: ", memory_tag)
					else:
						print(GameState.script_name_tag(self, _fname) + "Failed to trigger memory: ", memory_tag)
				else:
					print(GameState.script_name_tag(self, _fname) + "Memory conditions not met: ", memory_tag)
			else:
				print(GameState.script_name_tag(self, _fname) + "Invalid memory tag: ", memory_tag)
		else:
			print(GameState.script_name_tag(self, _fname) + "No memory tag found for feature: ", feature_id)
		
		var description = feature.get("description", "")
		print(GameState.script_name_tag(self, _fname) + "Returning description: '", description, "'")
		return description
	else:
		# Return short description for already observed features
		var short_desc = feature.get("short_description", feature.description)
		print(GameState.script_name_tag(self, _fname) + "Feature already observed, returning short description: '", short_desc, "'")
		return short_desc

# NEW: Find memory tag for a feature using registry
func _find_memory_tag_for_feature(feature_id: String) -> String:
	"""Find memory tag associated with a feature using registry"""
	var _fname = "_find_memory_tag_for_feature"
	
	# Construct potential target_ids for this feature
	var potential_targets = [
		character_id + "_" + feature_id,  # e.g., "poison_necklace"
		feature_id,                       # e.g., "necklace"
		character_id + "_" + feature_id + "_seen"  # e.g., "poison_necklace_seen"
	]
	
	# Search registry for matching target_ids with LOOK_AT trigger
	for tag_name in GameState.memory_registry.keys():
		var metadata = GameState.memory_registry[tag_name]
		
		# Check if this is a LOOK_AT trigger (trigger_type 0)
		var trigger_type = metadata.get("trigger_type", -1)
		if typeof(trigger_type) == TYPE_FLOAT:
			trigger_type = int(trigger_type)
		
		if trigger_type == 0:  # LOOK_AT
			var target_id = metadata.get("target_id", "")
			var meta_character_id = metadata.get("character_id", "")
			
			# Check if target matches our feature and character
			if (target_id in potential_targets and meta_character_id == character_id):
				if debug: print(GameState.script_name_tag(self, _fname) + "Found matching memory tag: ", tag_name, " for target: ", target_id)
				return tag_name
	
	if debug: print(GameState.script_name_tag(self, _fname) + "No memory tag found for feature: ", feature_id, " with character: ", character_id)
	return ""

# ENHANCED: Add observable feature with registry integration
func add_observable_feature(feature_id: String, description: String, memory_tag: String = "") -> void:
	"""Add observable feature with optional memory tag validation"""
	var _fname = "add_observable_feature"
	
	# If memory_tag is provided, validate it
	if memory_tag != "" and not GameState.is_valid_memory_tag(memory_tag):
		if debug: print(GameState.script_name_tag(self, _fname) + "WARNING: Invalid memory tag for feature: ", feature_id, " tag: ", memory_tag)
		memory_tag = ""  # Clear invalid tag
	
	observable_features[feature_id] = {
		"description": description,
		"observed": false,
		"memory_tag": memory_tag,
		"short_description": "You notice the " + feature_id + " again."
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Added observable feature: ", feature_id, " to ", character_id)

# ENHANCED: Load character data with registry validation
func load_character_data():
	"""Load character data with registry-based memory validation"""
	var _fname = "load_character_data"
	print(GameState.script_name_tag(self, _fname) + "=== NPC LOAD_CHARACTER_DATA DEBUG (REGISTRY) for ", character_id, " ===")
	
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var loaded_data = character_loader.get_character(character_id)
		
		if loaded_data:
			character_name = loaded_data.name
			description = loaded_data.description
			
			if "observable_features" in loaded_data:
				print(GameState.script_name_tag(self, _fname) + "=== LOADING OBSERVABLE FEATURES WITH REGISTRY VALIDATION ===")
				var features = loaded_data["observable_features"]
				
				for feature_id in features:
					var feature_data = features[feature_id]
					var feature_description = feature_data.get("description", "")
					
					# Find associated memory tag using registry
					var registry_memory_tag = _find_memory_tag_for_feature(feature_id)
					
					# Use registry tag if found, otherwise use data from JSON
					var memory_tag = registry_memory_tag
					if memory_tag == "" and feature_data.has("memory_tag"):
						memory_tag = feature_data.get("memory_tag", "")
					
					print(GameState.script_name_tag(self, _fname) + "Feature: ", feature_id)
					print(GameState.script_name_tag(self, _fname) + "  Registry memory tag: ", registry_memory_tag)
					print(GameState.script_name_tag(self, _fname) + "  Final memory tag: ", memory_tag)
					
					# Validate memory tag if provided
					if memory_tag != "":
						if GameState.is_valid_memory_tag(memory_tag):
							print(GameState.script_name_tag(self, _fname) + "  ✅ Valid memory tag")
						else:
							print(GameState.script_name_tag(self, _fname) + "  ❌ Invalid memory tag: ", memory_tag)
							memory_tag = ""  # Clear invalid tag
					
					# Add the feature
					add_observable_feature(feature_id, feature_description, memory_tag)
				
				print(GameState.script_name_tag(self, _fname) + "Final observable_features: ", observable_features)
				print(GameState.script_name_tag(self, _fname) + "=== END LOADING OBSERVABLE FEATURES ===")
			
			return
	
	print(GameState.script_name_tag(self, _fname) + "Falling back to default character data")
	_set_default_character_data()

# NEW: Validate all observable features against registry
func validate_observable_features() -> Dictionary:
	"""Validate all observable features against the memory registry"""
	var _fname = "validate_observable_features"
	var validation_result = {
		"valid_features": [],
		"invalid_memory_tags": [],
		"missing_registry_entries": [],
		"warnings": []
	}
	
	for feature_id in observable_features.keys():
		var feature = observable_features[feature_id]
		var memory_tag = feature.get("memory_tag", "")
		
		if memory_tag != "":
			if GameState.is_valid_memory_tag(memory_tag):
				validation_result.valid_features.append(feature_id)
			else:
				validation_result.invalid_memory_tags.append({
					"feature_id": feature_id,
					"invalid_tag": memory_tag
				})
		else:
			# Check if there should be a memory tag based on registry
			var registry_tag = _find_memory_tag_for_feature(feature_id)
			if registry_tag != "":
				validation_result.missing_registry_entries.append({
					"feature_id": feature_id,
					"suggested_tag": registry_tag
				})
	
	if debug and (validation_result.invalid_memory_tags.size() > 0 or validation_result.missing_registry_entries.size() > 0):
		print(GameState.script_name_tag(self, _fname) + "Observable feature validation issues for ", character_id, ":")
		print(GameState.script_name_tag(self, _fname) + "  Invalid tags: ", validation_result.invalid_memory_tags)
		print(GameState.script_name_tag(self, _fname) + "  Missing registry entries: ", validation_result.missing_registry_entries)
	
	return validation_result


func move_to(target: Vector2):
	nav_agent.target_position = target
	
func get_character_id():
	return character_id

func get_movement_input():
	var input_vector = Vector2.ZERO
	
	# If we have AI movement, calculate direction
	if movement_target != null:
		if pathfinding_enabled and path_to_target.size() > 0:
			# Move along pathfinding path
			var next_point = path_to_target[0]
			input_vector = (next_point - global_position).normalized()
			
			# Check if we reached the next point
			if global_position.distance_to(next_point) < 10:
				path_to_target.remove_at(0)
		else:
			# Direct movement toward target
			input_vector = (movement_target - global_position).normalized()
	
	return input_vector
	
func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_T and event.pressed and not event.echo:
		test_all_animations()
		if debug: print(GameState.script_name_tag(self) + "Started animation test sequence")
		
func handle_movement_state(input_vector):
	# NPCs generally walk unless they're in combat
	is_running = false  # Can be set by AI behaviors
	
	# Set appropriate speed
	if is_running:
		speed = base_speed * run_speed_multiplier
	else:
		speed = base_speed
	
	# Update movement state tracking
	was_moving = is_moving
	is_moving = input_vector.length() > 0.1
	
	if is_moving and input_vector != Vector2.ZERO:
		last_direction = input_vector

func move_to_position(target_position, run = false):
	movement_target = target_position
	is_running = run

func stop_movement():
	movement_target = null
	is_moving = false

func _physics_process(delta):
	# NPC movement processing
	var _should_wait := false
	var _push_vector := Vector2.ZERO
	var MIN_SEPARATION := 16.0
	var REPULSION_STRENGTH := 50.0
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	#var speed = 100.0  # Example speed
	var velocity = direction * speed
	
	if is_navigating:
		process_navigation(delta)
		return

	if nav_agent.is_navigation_finished():
		return  # Reached goal


	for other in get_tree().get_nodes_in_group("navigators"):
		if other == self:
			continue
		var distance := global_position.distance_to(other.global_position)
		if distance < MIN_SEPARATION and distance > 0:
			var away = (global_position - other.global_position).normalized()
			_push_vector += away * ((MIN_SEPARATION - distance) / MIN_SEPARATION)

	nav_agent.set_velocity(velocity)

	
	# Get AI-determined movement input
	var input_vector = get_movement_input()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Only respond to specific interaction types, ignore physics pushes
		if collider.is_in_group("player") and collider.is_interacting_with(self):
			handle_movement_state(input_vector)
			
			# Process jumping if active (unlikely for NPCs but supported)
			process_jumping(delta)
			
			# Set velocity based on input and speed
			velocity = input_vector * speed
			
			# Update animation based on movement state
			update_animation(input_vector)
			
			# Apply movement
			move_and_slide()
			
			# Update position tracking and z-index
			update_position_tracking()
	

func update_animation(input_vector):
	if is_jumping:
		# Jump animation already set in begin_jump()
		return
		
	if input_vector != Vector2.ZERO:
		var old_direction = anim_direction
		update_anim_direction()
		
		# Choose animation type based on running state
		var anim_type = ""
		if is_running:
			anim_type = "run"
		else:
			anim_type = "walk"
		
		# Only update animation if direction changed or animation type changed
		if old_direction != anim_direction or last_animation != anim_type or !was_moving:
			if debug: print(GameState.script_name_tag(self) + "Setting " + anim_type + " animation - dir: " + anim_direction)
			animator.set_animation(anim_type, anim_direction, get_character_id())
			last_animation = anim_type
	elif last_animation != "idle":
		# Only set idle if we're not already idle
		if debug: print(GameState.script_name_tag(self) + "Setting idle animation - current anim: " + last_animation)
		animator.set_animation("idle", anim_direction, get_character_id())
		last_animation = "idle"
	
func play_animation(anim_name: String):
	if debug: print(GameState.script_name_tag(self) + "Trying to call animation " + anim_name + " for " + character_id)
	
	# Check if this is a jump animation
	var is_jump_anim = anim_name.begins_with("jump")
	
	# If we're jumping and this isn't the end of a jump, don't interrupt
	if is_jumping and !is_jump_anim and jump_timer > 0.2:
		if debug: print(GameState.script_name_tag(self) + "Ignoring animation during jump: " + anim_name)
		return
	
	# Start jump if this is a jump animation
	if is_jump_anim and !is_jumping:
		is_jumping = true
		jump_timer = JUMP_DURATION 
		if debug: print(GameState.script_name_tag(self) + "Starting jump animation, duration: ", JUMP_DURATION)
	
	# First update the texture through the character animator
	if animator and animator.has_method("set_animation"):
		animator.set_animation(anim_name, null, character_id)
	
	# Then play the animation through the AnimationPlayer
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		if debug: print(GameState.script_name_tag(self) + "Playing animation " + anim_name + " using AnimationPlayer")
		anim_player.play(anim_name)
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Animation not found: " + anim_name)
		
		
func _is_near_interaction_zone() -> bool:
	for area in interaction_area.get_overlapping_areas():
		if area.get_parent() != self:
			return true
	return false
	

		
# Set default data if no file is found
func _set_default_character_data():
	character_data = {
		"id": character_id,
		"name": character_name,
		"interests": ["ecology", "lichens", "sustainability"],
		"relationship_level": relationship_level
	}
	
	if debug: print(GameState.script_name_tag(self) + "Using default data for: ", character_name)

func change_facing(dir):
	print(GameState.script_name_tag(self) + "Changing facing toward: ", dir)
	animator.set_animation(last_animation, dir, character_id)

func interact():
	if not interactable:
		if debug: print(GameState.script_name_tag(self) + character_name, " is not interactable")
		return
		
	if debug: print(GameState.script_name_tag(self) + "Interacting with: ", character_name)
	interaction_started.emit(character_id)
	var player = get_tree().get_first_node_in_group("player")
	face_target(player)
	
	# Start dialogue using the Dialogue Manager
	if dialogue_system:
		# Update NPC and marker lists
		GameState.set_current_npcs()
		GameState.set_current_markers()
		# BUGFIX: Use default "start" title if none is specified
		var dialogue_title = "start"
		if initial_dialogue_title != null and initial_dialogue_title != "":
			dialogue_title = initial_dialogue_title
		
		if debug: print(GameState.script_name_tag(self) + str(character_id) + " is speaking from title '" + str(dialogue_title) + "'")
		
		var result = dialogue_system.start_dialog(character_id, dialogue_title)
		if result:
			if debug: print(GameState.script_name_tag(self) + "Dialogue started successfully")
			
			# Notify quest system directly that dialogue has started with this NPC
			var quest_system = get_node_or_null("/root/QuestSystem")
			if quest_system and quest_system.has_method("_check_talk_objectives"):
				quest_system.call_deferred("_check_talk_objectives", character_id)
				if debug: print(GameState.script_name_tag(self) + "Directly notified quest system about interaction with: ", character_id)
		else:
			if debug: print(GameState.script_name_tag(self) + "Failed to start dialogue!")
	else:
		if debug: print(GameState.script_name_tag(self) + "Dialogue system not found!")
	
func update_relationship(new_level):
	relationship_level = new_level
	if debug: print(GameState.script_name_tag(self) + character_name, " relationship updated to level ", relationship_level)
	
	# Notify memory system of relationship change
	if memory_system:
		memory_system.trigger_character_relationship(character_id)
	
func end_interaction():
	interaction_ended.emit(character_id)
	# Clean up any resources or states

# Memory discovery system functions
func get_look_description() -> String:
	print(GameState.script_name_tag(self) + "=== NPC GET_LOOK_DESCRIPTION DEBUG for ", character_id, " ===")
	print(GameState.script_name_tag(self) + "Current description value: '", description, "'")
	print(GameState.script_name_tag(self) + "Current character_name value: '", character_name, "'")
	
	var result = ""
	if description != "" and description != character_id:
		result = description
		print(GameState.script_name_tag(self) + "Using description property: '", result, "'")
	elif character_name != "":
		result = "You see " + character_name + "."
		print(GameState.script_name_tag(self) + "Using character_name fallback: '", result, "'")
	else:
		result = "You see " + name + "."
		print(GameState.script_name_tag(self) + "Using node name fallback: '", result, "'")
	
	print(GameState.script_name_tag(self) + "Final get_look_description result: '", result, "'")
	print(GameState.script_name_tag(self) + "=== END GET_LOOK_DESCRIPTION DEBUG ===")
	return result


func has_observable_feature(feature_id: String) -> bool:
	return observable_features.has(feature_id)

func is_feature_observed(feature_id: String) -> bool:
	if observable_features.has(feature_id):
		return observable_features[feature_id].observed
	return false


# Get dialogue options available based on observed memories
func get_memory_dialogue_options() -> Array:
	var options = []
	
	if memory_system:
		options = memory_system.get_available_dialogue_options(character_id)
	
	return options

# Check if a specific dialogue option should be available
func is_dialogue_option_available(dialogue_title: String) -> bool:
	if memory_system:
		return memory_system.is_dialogue_available(character_id, dialogue_title)
	
	return false

func setup_sprite_deferred():
	# Same sprite setup code here
	if sprite:
		var texture = load("res://assets/character_sprites/" + character_id + "/standard/idle.png")
		sprite.texture = texture
		sprite.hframes = 2
		sprite.vframes = 4
		if debug: print(GameState.script_name_tag(self) + "Deferred sprite setup complete")


func test_all_animations():
	# Make sure animator is loaded
	if self.character_id == "poison":
		if not animator:
			if debug: print(GameState.script_name_tag(self) + "No animator found for NPC: ", character_id)
			return
		
		if debug: print(GameState.script_name_tag(self) + "Testing all animations for NPC: ", character_id)
		
		# Test sequence of animations with different directions
		var test_sequence = [
			{"anim": "idle", "dir": "down"},
			{"anim": "walk", "dir": "down"},
			{"anim": "run", "dir": "down"},
			{"anim": "jump", "dir": "down"},
			{"anim": "idle", "dir": "up"},
			{"anim": "walk", "dir": "left"},
			{"anim": "run", "dir": "right"}
		]
		
		# Create a timer to space out the animations
		var timer = get_tree().create_timer(0.5)
		await timer.timeout
		
		# Run through each animation
		for i in range(test_sequence.size()):
			var test = test_sequence[i]
			var anim_name = test.anim
			var direction = test.dir
			
			if debug: print(GameState.script_name_tag(self) + "\nTesting animation: ", anim_name, "_", direction)
			
			# Print texture before animation
			if sprite and sprite.texture:
				if debug: print(GameState.script_name_tag(self) + "BEFORE - Texture: ", sprite.texture.resource_path)
				if debug: print(GameState.script_name_tag(self) + "BEFORE - Frame: ", sprite.frame, ", hframes: ", sprite.hframes, ", vframes: ", sprite.vframes)
			
			# Play the animation
			if animator.has_method("set_animation"):
				animator.set_animation(anim_name, direction, character_id)
			else:
				if debug: print(GameState.script_name_tag(self) + "ERROR: set_animation method not found!")
				return
			
			# Print texture after animation
			if sprite and sprite.texture:
				if debug: print(GameState.script_name_tag(self) + "AFTER - Texture: ", sprite.texture.resource_path)
				if debug: print(GameState.script_name_tag(self) + "AFTER - Frame: ", sprite.frame, ", hframes: ", sprite.hframes, ", vframes: ", sprite.vframes)
			
			# Wait before the next animation
			timer = get_tree().create_timer(1.6)
			await timer.timeout
	animator.set_animation("idle", "down", "poison")

func _on_sprite_2d_frame_changed() -> void:
	if sprite:
		if debug: print(GameState.script_name_tag(self) + "Playing NPC Frame " + str(sprite.frame))
func _on_sprite_2d_texture_changed() -> void:
	if sprite:
		if debug: print(GameState.script_name_tag(self) + "NPC Texture = ", str(sprite.texture))
