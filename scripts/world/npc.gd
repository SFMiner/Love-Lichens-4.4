extends NPCCombatant

# Base script for all NPCs in the game
# Handles character data, interactions, memories, and appearance

signal interaction_started(npc_id)
signal interaction_ended(npc_id)
signal observed(feature_id)

@export var character_name: String = "Unknown"
@export var portrait: Texture2D
@export var interactable: bool = true
@export var initial_dialogue_title: String = ""
@export var description: String = ""
@export var character_id: String = ""
# Observable features for memory discovery
@export var observable_features: Dictionary = {
	# Format: "feature_id": {"description": "Feature description", "observed": false, "memory_tag": "optional_tag"}
}

@onready var sprite = get_node_or_null("Sprite2D")


# Character data
var character_data = {}
var relationship_level = 0 # 0=stranger, 1=acquaintance, 2=friend, 3=close friend, 4=romantic
var dialogue_system
var memory_system
var game_state
const scr_debug :bool = true

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print("NPC initialized: ", character_id)
	
	super._ready()
	
	print("--- NPC NODE HIERARCHY DEBUG ---")
	for child in get_children():
		print("Child node: " + child.name + ", class: " + child.get_class())
	
	# Debug CharacterAnimator specifically
	var animator = get_node_or_null("CharacterAnimator")
	if animator:
		print("Found CharacterAnimator")
		
		# Check if the animator has the required functionality
		if animator.has_method("set_animation"):
			print("CharacterAnimator has set_animation method")
		else:
			print("ERROR: CharacterAnimator missing set_animation method")
		
		# Check if the animator has found its sprite
		if "sprite" in animator:
			print("CharacterAnimator has sprite reference: " + str(animator.sprite != null))
		else:
			print("ERROR: CharacterAnimator has no sprite property")
			
		# Check for AnimationPlayer
		var ap = get_node_or_null("AnimationPlayer")
		if ap:
			print("Found AnimationPlayer, animations: " + str(ap.get_animation_list()))
		else:
			print("ERROR: No AnimationPlayer found for animations")
	
	if sprite:
		print("Found Sprite2D node for " + character_id)
	else:
		print("ERROR: Sprite2D node not found for " + character_id)
		# Try to create it if missing
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		print("Created new Sprite2D node for " + character_id)
		
	var texture_path = "res://assets/character_sprites/" + character_id + "/standard/idle.png"
	print("Loading texture from: " + texture_path)
	
	var texture = load(texture_path)
	if texture:
		print("Successfully loaded texture")
		sprite.texture = texture
		sprite.hframes = 2
		sprite.vframes = 4
		print("Applied texture to sprite: " + str(texture.get_path()))
	else:
		print("ERROR: Failed to load texture from " + texture_path)
		
		# Try with a hardcoded path as fallback
		var fallback_path = "res://assets/character_sprites/kitty/standard/idle.png" 
		print("Trying fallback texture: " + fallback_path)
		texture = load(fallback_path)
		
		if texture:
			print("Fallback texture loaded successfully")
			sprite.texture = texture
			sprite.hframes = 2
			sprite.vframes = 4
		else:
			print("ERROR: Even fallback texture failed to load")
			
	# Additional debug - verify texture is set
	if sprite.texture:
		print("Sprite texture is set: " + str(sprite.texture.get_path()))
	else:
		print("WARNING: Sprite texture is still null after setup")
		
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
	
	# Load character data
	load_character_data()
	
	# Get reference to the dialogue system
	dialogue_system = get_node_or_null("/root/DialogSystem")
	if not dialogue_system:
		if debug: print("WARNING: DialogSystem not found!")
	
	# Get reference to the memory system
	memory_system = get_node_or_null("/root/MemorySystem")
	if not memory_system:
		if debug: print("WARNING: MemorySystem not found!")
	
	# Get reference to the game state
	game_state = get_node_or_null("/root/GameState")
	if not game_state:
		if debug: print("WARNING: GameState not found!")
	
	# Make sure the collision shape is enabled
	for child in get_children():
		if child is CollisionShape2D:
			if not child.disabled:
				if debug: print("Collision shape for ", character_id, " is enabled")
			else:
				if debug: print("Enabling collision shape for ", character_id)
				child.disabled = false

	call_deferred("setup_sprite_deferred")
#	var debug_rect = ColorRect.new()
#	debug_rect.color = Color(1, 0, 0, 0.5)  # Semi-transparent red
#	debug_rect.size = Vector2(50, 50)
#	debug_rect.position = Vector2(-25, -25)  # Centered at origin
#	add_child(debug_rect)
	
#	print("Added debug rectangle to show character position")
	
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
	
	

func load_character_data():
	# First try to use the CharacterDataLoader if available
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var loaded_data = character_loader.get_character(character_id)
		if loaded_data:
			print("Loading character data for: ", character_id)
			
			# Set basic properties
			character_name = loaded_data.name
			description = loaded_data.description
			
			# BUGFIX: Properly set the initial_dialogue_title from character data
			# Only override if the initial_dialogue_title is not already set in the scene
			if loaded_data.initial_dialogue_title and loaded_data.initial_dialogue_title != "":
				if initial_dialogue_title == "":
					initial_dialogue_title = loaded_data.initial_dialogue_title
					print("Setting initial dialogue title to: ", initial_dialogue_title)
				else:
					print("Keeping scene-defined initial dialogue title: ", initial_dialogue_title)
			
			# Debug print to verify initial dialogue title
			print(character_id, " initial dialogue title: ", initial_dialogue_title)
			
			# Load portrait if available
			if ResourceLoader.exists(loaded_data.portrait_path):
				portrait = load(loaded_data.portrait_path)
			
			# Set observable features from character data
			for feature_id in loaded_data.observable_features:
				var feature = loaded_data.observable_features[feature_id]
				add_observable_feature(feature_id, feature.description)
				if debug: print("Added feature ", feature_id, " to ", character_id)
			
			# Create character_data object with interests
			self.character_data = {
				"id": character_id,
				"name": character_name,
				"interests": loaded_data.interests,
				"relationship_level": relationship_level,
				"initial_dialogue_title": initial_dialogue_title  # Store for reference
			}
			
			print("Character data loaded for: ", character_name)
			return
	
	print("Using fallback character data loading for: ", character_id)
	# For now, set default data
	character_data = {
		"id": character_id,
		"name": character_name,
		"interests": ["ecology", "lichens", "sustainability"],
		"relationship_level": relationship_level,
		"initial_dialogue_title": initial_dialogue_title  # Store for reference
	}
	print("Character data loaded for: ", character_name)
	

# Set default data if no file is found
func _set_default_character_data():
	character_data = {
		"id": character_id,
		"name": character_name,
		"interests": ["ecology", "lichens", "sustainability"],
		"relationship_level": relationship_level
	}
	
	if debug: print("Using default data for: ", character_name)

func change_facing(dir):
	animator.set_animation(last_animation, dir, character_id)

func interact():
	if not interactable:
		if debug: print(character_name, " is not interactable")
		return
		
	if debug: print("Interacting with: ", character_name)
	interaction_started.emit(character_id)
	var player = get_tree().get_first_node_in_group("player")
	face_target(player)
	
	# Start dialogue using the Dialogue Manager
	if dialogue_system:
		# BUGFIX: Use default "start" title if none is specified
		var dialogue_title = "start"
		if initial_dialogue_title != null and initial_dialogue_title != "":
			dialogue_title = initial_dialogue_title
		
		print(str(character_id) + " is speaking from title '" + str(dialogue_title) + "'")
		
		var result = dialogue_system.start_dialog(character_id, dialogue_title)
		if result:
			if debug: print("Dialogue started successfully")
			
			# Notify quest system directly that dialogue has started with this NPC
			var quest_system = get_node_or_null("/root/QuestSystem")
			if quest_system and quest_system.has_method("_check_talk_objectives"):
				quest_system.call_deferred("_check_talk_objectives", character_id)
				if debug: print("Directly notified quest system about interaction with: ", character_id)
		else:
			if debug: print("Failed to start dialogue!")
	else:
		if debug: print("Dialogue system not found!")
	
func update_relationship(new_level):
	relationship_level = new_level
	if debug: print(character_name, " relationship updated to level ", relationship_level)
	
	# Notify memory system of relationship change
	if memory_system:
		memory_system.trigger_character_relationship(character_id)
	
func end_interaction():
	interaction_ended.emit(character_id)
	# Clean up any resources or states

# Memory discovery system functions
func get_look_description() -> String:
	if description.is_empty():
		return character_name
	return description

func observe_feature(feature_id: String) -> String:
	if not observable_features.has(feature_id):
		return ""
		
	var feature = observable_features[feature_id]
	if not feature.observed:
		feature.observed = true
		observed.emit(feature_id)
		
		# Set memory tag if one exists
		if feature.has("memory_tag") and game_state:
			game_state.set_tag(feature.memory_tag)
			if debug: print("Set memory tag: ", feature.memory_tag)
		
		# Trigger memory system if available
		if memory_system:
			var target_id = character_id + "_" + feature_id
			memory_system.trigger_look_at(target_id)
			if debug: print("Triggered memory system for: ", target_id)
		
		return feature.description
	else:
		# If already observed, return an abbreviated description
		var short_desc = feature.get("short_description", "")
		if short_desc.is_empty():
			return feature.description
		return short_desc

func has_observable_feature(feature_id: String) -> bool:
	return observable_features.has(feature_id)

func is_feature_observed(feature_id: String) -> bool:
	if observable_features.has(feature_id):
		return observable_features[feature_id].observed
	return false

func add_observable_feature(feature_id: String, description: String, memory_tag: String = "") -> void:
	if debug: print("Adding obser5vable features for " + character_id)
	observable_features[feature_id] = {
		"description": description,
		"observed": false,
		"memory_tag": memory_tag
	}
	
	# Optional: add a shorter description for repeat observations
	var short_description = "You see " + feature_id + " that you noticed earlier."
	observable_features[feature_id]["short_description"] = short_description

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
		print("Deferred sprite setup complete")
