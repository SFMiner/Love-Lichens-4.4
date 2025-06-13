extends NPCCombatant
class_name NPC
# Base script for all NPCs in the game
# Now includes all character data with optimal access patterns

signal interaction_started(npc_id)
signal interaction_ended(npc_id)
signal observed(feature_id)

# ==========================================
# CORE CHARACTER IDENTITY (@export for Inspector editing)
# ==========================================

@export_group("Character Identity")
@export var character_id: String = ""
@export var character_name: String = "Unknown"
@export var description: String = ""

@export_group("Dialogue & Interaction")  
@export var dialogue_file: String = ""
@export var initial_dialogue_title: String = "start"
@export var interactable: bool = true

@export_group("Visual Appearance")
@export var portrait_path: String = ""
@export var initial_animation: String = "idle_down"


# ==========================================
# CHARACTER PERSONALITY & BACKGROUND (@export for easy editing)
# ==========================================

@export_group("Personality")
@export var personality_traits: Array[String] = []
@export var interests: Array[String] = []
@export var background: String = ""
@export var base_relationship_level: int = 0

@export_group("UI Styling")
@export var font_path: String = ""
@export var font_color: Color = Color(1, 1, 1, 1)
@export var font_size: int = 20

@export_group("Special Items")
@export var special_items: Array[String] = []

# ==========================================
# LEGACY COMPATIBILITY & SERIALIZATION
# ==========================================

# Keep character_data dictionary for compatibility and serialization
var character_data: Dictionary = {}

# Runtime observable features (built from setup)
var observable_features: Dictionary = {}

# ==========================================
# GAME BEHAVIOR PROPERTIES (existing functionality)
# ==========================================

# Node references
@onready var sprite = get_node_or_null("Sprite2D")
@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var interaction_area = get_node_or_null("InteractionArea")
@onready var ap = get_node_or_null("AnimationPlayer")
@onready var char_anim = get_node_or_null("CharacterAnimator")

# Character state and animation

# System references
var dialogue_system
var memory_system

const scr_debug : bool = true


# ==========================================
# INITIALIZATION
# ==========================================

func _ready():
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug 
	if debug: print(GameState.script_name_tag(self, _fname) + "NPC initialized: ", character_id)
	
	super._ready()
	
	# Sync @export variables to character_data dictionary
	_sync_to_character_data()
	
	# Set up character-specific features
	_setup_character_specific_features()
	
	# Initialize game behavior
	_initialize_game_behavior()
	
	if debug: 
		print(GameState.script_name_tag(self, _fname) + "Character setup complete. Observable features: ", observable_features.keys())
		print(GameState.script_name_tag(self, _fname) + "Character setup complete. Character font_path: ", font_path)
		print(GameState.script_name_tag(self, _fname) + "Character setup complete. Character font_color: ", font_color)
		print(GameState.script_name_tag(self, _fname) + "Character setup complete. Character font_size: ", str(font_size))

		char_anim._initialize_animation_info(initial_animation)

func set_animation(animation_direction):
	var animation_name= animation_direction.left(animation_direction.find("_"))
	var direction_name = animation_direction.right(animation_direction.length() - animation_name.length() - 1)

	char_anim.set_animation(animation_name,  direction_name, character_id)

func _sync_to_character_data():
	"""Sync @export variables to character_data dictionary and load additional data from JSON"""
	var _fname = "_sync_to_character_data"
	
	# First, populate from @export variables
	character_data = {
		"id": character_id,
		"name": character_name,
		"description": description,
		"dialogue_file": dialogue_file,
		"initial_dialogue_title": initial_dialogue_title,
		"portrait_path": portrait_path,
		"personality_traits": personality_traits.duplicate(),
		"interests": interests.duplicate(),
		"background": background,
		"base_relationship_level": base_relationship_level,
		"font_path": font_path,
		"font_color": font_color,
		"font_size": font_size,
		"special_items": special_items.duplicate()
	}
	if debug: print(GameState.script_name_tag(self, _fname) + "character_data for " + character_id + " = " + str(character_data))

	# Then, load and merge additional data from JSON file if it exists
	_load_additional_data_from_json()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Synced character data for: ", character_id)

func _load_additional_data_from_json():
	"""Load additional character data from JSON file to supplement @export variables"""
	var _fname = "_load_additional_data_from_json"
	
	if character_id == "":
		return
	
	var data_path = "res://data/characters/" + character_id + ".json"
	if not FileAccess.file_exists(data_path):
		if debug: print(GameState.script_name_tag(self, _fname) + "No JSON file found for: ", character_id)
		return
	
	var file = FileAccess.open(data_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		if debug: print(GameState.script_name_tag(self, _fname) + "Failed to parse JSON for: ", character_id)
		return
	
	
	var json_data = json.data
	
	# Override @export variables with JSON data where JSON has more complete info
	if json_data.has("name") and json_data.name != "":
		character_name = json_data.name
		character_data.name = json_data.name
	
	if json_data.has("description") and json_data.description != "":
		description = json_data.description  
		character_data.description = json_data.description

	if json_data.has("font_path") and json_data.font_path != "":
		font_path = json_data.font_path  
		character_data.font_path = json_data.font_path

	if json_data.has("font_size") and json_data.font_size:
		font_size = json_data.font_size  
		character_data.font_size = json_data.font_size
		
	if json_data.has("font_color") and json_data.font_color != "":
		font_color = json_data.font_color  
		character_data.font_color = json_data.font_color

	if json_data.has("personality_traits") and json_data.personality_traits.size() > 0:
		personality_traits.assign(json_data.personality_traits)
		character_data.personality_traits = json_data.personality_traits
	
	if json_data.has("interests") and json_data.interests.size() > 0:
		interests.assign(json_data.interests)
		character_data.interests = json_data.interests
	
	# Add other JSON fields to character_data even if not in @export variables
	for key in json_data.keys():
		if not character_data.has(key):
			character_data[key] = json_data[key]
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Merged JSON data for: ", character_id)

func _setup_character_specific_features():
	"""Load observable features from character data files, not hardcoded"""
	var _fname = "_setup_character_specific_features"
	
	# Load observable features from the character data file
	_load_observable_features_from_data()

func _load_observable_features_from_data():
	"""Load observable features from character JSON files"""
	var _fname = "_load_observable_features_from_data"
	
	if character_id == "":
		if debug: print(GameState.script_name_tag(self, _fname) + "No character_id set, skipping feature loading")
		return
	
	var data_path = "res://data/characters/" + character_id + ".json"
	if debug: print(GameState.script_name_tag(self, _fname) + "Loading features from: ", data_path)
	
	if not FileAccess.file_exists(data_path):
		if debug: print(GameState.script_name_tag(self, _fname) + "No data file found for: ", character_id)
		return
	
	var file = FileAccess.open(data_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		if debug: print(GameState.script_name_tag(self, _fname) + "Failed to parse JSON for: ", character_id)
		return
	
	var data = json.data
	if not data.has("observable_features"):
		if debug: print(GameState.script_name_tag(self, _fname) + "No observable_features in data for: ", character_id)
		return
	
	var features_data = data["observable_features"]
	if debug: print(GameState.script_name_tag(self, _fname) + "Loading ", features_data.size(), " features for ", character_id)
	
	# Load each feature from the data
	for feature_id in features_data.keys():
		var feature_data = features_data[feature_id]
		var description = feature_data.get("description", "")
		var memory_tag = feature_data.get("memory_tag", "")
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Adding feature: ", feature_id, " -> ", memory_tag)
		add_observable_feature(feature_id, description, memory_tag)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Successfully loaded features: ", observable_features.keys())

func _initialize_game_behavior():
	"""Initialize game behavior systems"""
	var _fname = "_initialize_game_behavior"
	
	# Set up groups
	add_to_group("interactable")
	add_to_group("npc")
	add_to_group("navigator")
	
	# Get system references
	dialogue_system = get_node_or_null("/root/DialogSystem")
	memory_system = get_node_or_null("/root/MemorySystem")
	
	# Set up sprite and animation
	_setup_sprite()
	_setup_navigation()
	
	# Play initial animation
	if ap:
		ap.play(initial_animation)

# ==========================================
# CHARACTER DATA ACCESS METHODS
# ==========================================

# Direct property access (preferred - type safe and fast)
func get_character_id() -> String:
	return character_id

func get_character_name() -> String:
	return character_name

func get_personality_traits() -> Array[String]:
	return personality_traits

func get_interests() -> Array[String]:
	return interests

func get_background() -> String:
	return background

func get_special_items() -> Array[String]:
	return special_items

# Dictionary interface (for compatibility and serialization)
func get_character_data() -> Dictionary:
	"""Get all character data as dictionary (auto-synced from @export vars)"""
	return character_data.duplicate(true)

func set_character_data(data: Dictionary):
	"""Set character data from dictionary (syncs to @export vars)"""
	var _fname = "set_character_data"
	
	# Update @export variables from dictionary
	character_id = data.get("id", character_id)
	character_name = data.get("name", character_name)
	description = data.get("description", description)
	dialogue_file = data.get("dialogue_file", dialogue_file)
	initial_dialogue_title = data.get("initial_dialogue_title", initial_dialogue_title)
	portrait_path = data.get("portrait_path", portrait_path)
	personality_traits = data.get("personality_traits", personality_traits)
	interests = data.get("interests", interests)
	background = data.get("background", background)
	base_relationship_level = data.get("base_relationship_level", base_relationship_level)
	font_path = data.get("font_path", font_path)
	if debug: print(GameState.script_name_tag(self, _fname) + "font_path for " + character_id + " = " + font_path)
	font_color = data.get("font_color", font_color)
	font_size = data.get("font_size", font_size)
	special_items = data.get("special_items", special_items)
	
	# Re-sync to character_data dictionary
	_sync_to_character_data()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Updated character data for: ", character_id)

# Legacy compatibility function
func get_character_property(property_name: String):
	"""Get character property by name (legacy compatibility)"""
	return character_data.get(property_name, null)

# ==========================================
# RELATIONSHIP SYSTEM INTEGRATION  
# ==========================================

func get_current_relationship_level() -> int:
	"""Get current relationship level from RelationshipSystem"""
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system:
		return relationship_system.get_relationship_score(character_id)
	else:
		# Fallback to base level
		return base_relationship_level

# ==========================================
# OBSERVABLE FEATURES SYSTEM (existing functionality)
# ==========================================

func observe_feature(feature_id: String) -> String:
	"""Observe a feature and trigger memory system"""
	var _fname = "observe_feature"
	print(GameState.script_name_tag(self, _fname) + "Observing feature: ", feature_id, " on ", character_id)
	
	if not observable_features.has(feature_id):
		print(GameState.script_name_tag(self, _fname) + "Feature not found: ", feature_id)
		return ""
	
	var feature = observable_features[feature_id]
	print(GameState.script_name_tag(self, _fname) + "Feature data: ", feature)
	
	if not feature.get("observed", false):
		feature["observed"] = true
		observed.emit(feature_id)
		
		# Set memory tag if it exists
		var memory_tag = feature.get("memory_tag", "")
		if memory_tag != "":
			print(GameState.script_name_tag(self, _fname) + "Setting memory tag: ", memory_tag)
			GameState.set_tag(memory_tag, true)
		
		var description = feature.get("description", "")
		print(GameState.script_name_tag(self, _fname) + "Returning description: ", description)
		return description
	else:
		var short_desc = feature.get("short_description", feature.description)
		print(GameState.script_name_tag(self, _fname) + "Feature already observed: ", short_desc)
		return short_desc

func add_observable_feature(feature_id: String, description: String, memory_tag: String = "") -> void:
	"""Add an observable feature to this character"""
	var _fname = "add_observable_feature"
	
	observable_features[feature_id] = {
		"description": description,
		"observed": false,
		"memory_tag": memory_tag,
		"short_description": "You notice the " + feature_id + " again."
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Added observable feature: ", feature_id, " with tag: ", memory_tag)

func has_observable_feature(feature_id: String) -> bool:
	return observable_features.has(feature_id)

func is_feature_observed(feature_id: String) -> bool:
	if observable_features.has(feature_id):
		return observable_features[feature_id].observed
	return false

# ==========================================
# PERSONALITY-BASED BEHAVIOR
# ==========================================

func has_personality_trait(char_trait: String) -> bool:
	"""Check if character has a specific personality trait"""
	return char_trait in personality_traits

func has_interest(interest: String) -> bool:
	"""Check if character has a specific interest"""
	return interest in interests

func get_personality_response(topic: String) -> String:
	"""Generate a personality-appropriate response to a topic"""
	# This can be overridden in character-specific scripts
	if has_personality_trait("sarcastic"):
		return "Oh, " + topic + ". How absolutely fascinating."
	elif has_personality_trait("shy"):
		return "Um... I don't really know much about " + topic + "..."
	elif has_personality_trait("friendly"):
		return "Oh, " + topic + "! That's interesting!"
	else:
		return "I don't have much to say about " + topic + "."

func should_react_to_topic(topic: String) -> bool:
	"""Check if this character would be interested in a topic"""
	return topic in interests

# ==========================================
# GAME INTERACTION METHODS (existing functionality preserved)
# ==========================================

func get_look_description() -> String:
	"""Get description when player looks at this NPC"""
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
	return result

func interact():
	const _fname : String = "interact"
	if debug: print(GameState.script_name_tag(self, _fname) + "Interaction pressed")
	"""Handle player interaction with this NPC"""
	if not interactable:
		if debug: print(GameState.script_name_tag(self, _fname) + character_name, " is not interactable")
		return
		
	if debug: print(GameState.script_name_tag(self, _fname) + "Interacting with: ", character_name)
	interaction_started.emit(character_id)
	
	var player = GameState.get_player()
	if player:
		if debug: print(GameState.script_name_tag(self, _fname) + "player found, face_target called")
		face_target(player)
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "player not found")
	
	# Start dialogue using the Dialogue Manager
	if dialogue_system:
		GameState.set_current_npcs()
		GameState.set_current_markers()
		
		var result = dialogue_system.start_dialog(character_id, initial_dialogue_title)
		if result:
			if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue started successfully")
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "Failed to start dialogue!")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue system not found!")

# ==========================================
# SERIALIZATION SUPPORT
# ==========================================

func serialize_character_data() -> Dictionary:
	"""Serialize all character data for saving"""
	return get_character_data()

func deserialize_character_data(data: Dictionary):
	"""Restore character data from save file"""
	set_character_data(data)

# ==========================================
# SPRITE AND ANIMATION SETUP (existing functionality)
# ==========================================

func _setup_sprite():
	"""Set up character sprite and texture"""
	var _fname = "_setup_sprite"
	
	if sprite:
		var texture_path = "res://assets/character_sprites/" + character_id + "/standard/idle.png"
		if debug: print(GameState.script_name_tag(self, _fname) + "Loading texture from: " + texture_path)
		
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.hframes = 2
			sprite.vframes = 4
			sprite.visible = true
			sprite.modulate.a = 1.0
			sprite.position = Vector2(0, -30)
			sprite.z_index = 1
			if debug: print(GameState.script_name_tag(self, _fname) + "Successfully loaded texture")
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "Failed to load texture, using fallback")
			# Try fallback texture
			var fallback_path = "res://assets/character_sprites/kitty/standard/idle.png"
			texture = load(fallback_path)
			if texture:
				sprite.texture = texture
				sprite.hframes = 2
				sprite.vframes = 4

func _setup_navigation():
	"""Set up navigation agent"""
	if nav_agent:
		nav_agent.avoidance_enabled = true
		nav_agent.radius = 8.0
		nav_agent.neighbor_distance = 32.0

# [Rest of existing NPC functionality preserved - movement, animation, etc.]
# [All the existing methods from the original npc.gd should be included here]

# ==========================================
# MOVEMENT AND PHYSICS (from original NPC)
# ==========================================

func move_to(target: Vector2):
	"""Move NPC to target position using navigation"""
	if nav_agent:
		nav_agent.target_position = target

func get_movement_input() -> Vector2:
	"""Get AI-determined movement input"""
	var input_vector = Vector2.ZERO
	
	# If we have AI movement, calculate direction
	if has_method("get") and get("movement_target") != null:
		var movement_target = get("movement_target")
		if has_method("get") and get("pathfinding_enabled") and has_method("get") and get("path_to_target") and get("path_to_target").size() > 0:
			# Move along pathfinding path
			var path_to_target = get("path_to_target")
			var next_point = path_to_target[0]
			input_vector = (next_point - global_position).normalized()
			
			# Check if we reached the next point
			if global_position.distance_to(next_point) < 10:
				path_to_target.remove_at(0)
		else:
			# Direct movement toward target
			input_vector = (movement_target - global_position).normalized()
	
	return input_vector

func handle_movement_state(input_vector: Vector2):
	"""Handle movement state for NPCs"""
	# NPCs generally walk unless they're in combat
	var is_running = false  # Can be set by AI behaviors
	
	# Set appropriate speed
	var speed = base_speed if has_method("get") and get("base_speed") else 100
	if is_running and has_method("get") and get("run_speed_multiplier"):
		speed = speed * get("run_speed_multiplier")
	
	# Update movement state tracking
	var was_moving = is_moving
	is_moving = input_vector.length() > 0.1
	
	if is_moving and input_vector != Vector2.ZERO:
		last_direction = input_vector

func move_to_position(target_position: Vector2, run: bool = false):
	"""Move to specific position"""
	if has_method("set"):
		set("movement_target", target_position)
		set("is_running", run)

func stop_movement():
	"""Stop NPC movement"""
	if has_method("set"):
		set("movement_target", null)
	is_moving = false

func _physics_process(delta):
	"""NPC physics processing - movement and navigation"""
	var _should_wait := false
	var _push_vector := Vector2.ZERO
	var MIN_SEPARATION := 16.0
	var REPULSION_STRENGTH := 50.0
	
	if not nav_agent:
		return
	
	# Check if navigation is finished
	if nav_agent.is_navigation_finished():
		return
	
	# Get next navigation position
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	var speed = base_speed if has_method("get") and get("base_speed") else 100
	var velocity = direction * speed
	
	# Handle navigation if active
	if has_method("get") and get("is_navigating"):
		if has_method("process_navigation"):
			process_navigation(delta)
		return
	
	# Avoidance with other navigators
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
	
	# Handle collisions
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Only respond to specific interaction types
		if collider.is_in_group("player") and collider.has_method("is_interacting_with") and collider.is_interacting_with(self):
			handle_movement_state(input_vector)
			
			# Process jumping if active
			if has_method("process_jumping"):
				process_jumping(delta)
			
			# Set velocity based on input and speed
			velocity = input_vector * speed
			
			# Update animation based on movement state
			update_animation(input_vector)
			
			# Apply movement
			move_and_slide()
			
			# Update position tracking and z-index
			if has_method("update_position_tracking"):
				update_position_tracking()

# ==========================================
# ANIMATION SYSTEM (from original NPC)
# ==========================================

func update_animation(input_vector: Vector2):
	"""Update character animation based on movement"""
	if has_method("get") and get("is_jumping"):
		# Jump animation already set in begin_jump()
		return
	
	if input_vector != Vector2.ZERO:
		var old_direction = get("anim_direction") if has_method("get") else "down"
		if has_method("update_anim_direction"):
			update_anim_direction()
		
		var anim_direction = get("anim_direction") if has_method("get") else "down"
		
		# Choose animation type based on running state
		var anim_type = ""
		var is_running = get("is_running") if has_method("get") else false
		if is_running:
			anim_type = "run"
		else:
			anim_type = "walk"
		
		# Only update animation if direction changed or animation type changed
		var last_animation = get("last_animation") if has_method("get") else ""
		var was_moving = get("was_moving") if has_method("get") else false
		if old_direction != anim_direction or last_animation != anim_type or not was_moving:
			if debug: print(GameState.script_name_tag(self) + "Setting " + anim_type + " animation - dir: " + anim_direction)
			if has_method("get") and get("animator") and get("animator").has_method("set_animation"):
				get("animator").set_animation(anim_type, anim_direction, get_character_id())
			if has_method("set"):
				set("last_animation", anim_type)
	else:
		var last_animation = get("last_animation") if has_method("get") else ""
		if last_animation != "idle":
			if debug: print(GameState.script_name_tag(self) + "Setting idle animation - current anim: " + last_animation)
			var anim_direction = get("anim_direction") if has_method("get") else "down"
			if has_method("get") and get("animator") and get("animator").has_method("set_animation"):
				get("animator").set_animation("idle", anim_direction, get_character_id())
			if has_method("set"):
				set("last_animation", "idle")

func play_animation(anim_name: String):
	const _fname : String = "play_animation"
	"""Play specific animation"""
	if debug: print(GameState.script_name_tag(self, _fname) + "Playing animation " + anim_name + " for " + character_id)
	
	# Check if this is a jump animation
	var is_jump_anim = anim_name.begins_with("jump")
	
	# If we're jumping and this isn't the end of a jump, don't interrupt
	var is_jumping = get("is_jumping") if has_method("get") else false
	var jump_timer = get("jump_timer") if has_method("get") else 0.0
	if is_jumping and not is_jump_anim and jump_timer > 0.2:
		if debug: print(GameState.script_name_tag(self) + "Ignoring animation during jump: " + anim_name)
		return
	
	# Start jump if this is a jump animation
	if is_jump_anim and not is_jumping:
		if has_method("set"):
			set("is_jumping", true)
			set("jump_timer", get("JUMP_DURATION") if has_method("get") else 0.5)
		if debug: print(GameState.script_name_tag(self) + "Starting jump animation")
	
	# Update texture through character animator
	if has_method("get") and get("animator") and get("animator").has_method("set_animation"):
		get("animator").set_animation(anim_name, null, character_id)
	
	# Play animation through AnimationPlayer
	if ap and ap.has_animation(anim_name):
		if debug: print(GameState.script_name_tag(self) + "Playing animation " + anim_name + " using AnimationPlayer")
		ap.play(anim_name)
	else:
		if debug: print(GameState.script_name_tag(self) + "Animation not found: " + anim_name)

func change_facing(dir: String):
	const _fname : String = "change_facing"
	"""Change character facing direction"""
	if debug: print(GameState.script_name_tag(self, _fname) + "Changing facing toward: ", dir)

	var last_animation = get("last_animation") if has_method("get") else "idle"

	if debug: print(GameState.script_name_tag(self, _fname) + character_id + "was originally facing direction " + last_animation)

	if has_method("get") and get("animator") and get("animator").has_method("set_animation"):
		get("animator").set_animation(last_animation, dir, character_id)

	if debug: print(GameState.script_name_tag(self, _fname) + character_id + "is now  facing direction " + last_animation + dir + character_id)




func test_all_animations():
	"""Test all character animations (debug function)"""
	if not has_method("get") or not get("animator"):
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
	
	# Run through each animation
	for i in range(test_sequence.size()):
		var test = test_sequence[i]
		var anim_name = test.anim
		var direction = test.dir
		
		if debug: print(GameState.script_name_tag(self) + "Testing animation: ", anim_name, "_", direction)
		
		# Play the animation
		if get("animator").has_method("set_animation"):
			get("animator").set_animation(anim_name, direction, character_id)
		
		# Wait before the next animation
		await get_tree().create_timer(1.6).timeout
	
	# Return to idle
	if get("animator").has_method("set_animation"):
		get("animator").set_animation("idle", "down", character_id)

# ==========================================
# INTERACTION SYSTEM (from original NPC)
# ==========================================

func _unhandled_input(event):
	"""Handle unhandled input events"""
	if event is InputEventKey and event.keycode == KEY_T and event.pressed and not event.echo:
		test_all_animations()
		if debug: print(GameState.script_name_tag(self) + "Started animation test sequence")

func _is_near_interaction_zone() -> bool:
	"""Check if near interaction zone"""
	if not interaction_area:
		return false
	
	for area in interaction_area.get_overlapping_areas():
		if area.get_parent() != self:
			return true
	return false

func update_relationship(new_level: int):
	"""Update relationship level with this character"""
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system:
		relationship_system.set_relationship_score(character_id, new_level)
		if debug: print(GameState.script_name_tag(self) + character_name, " relationship updated to level ", new_level)
		
		# Notify memory system of relationship change
		if memory_system:
			memory_system.trigger_character_relationship(character_id)

func end_interaction():
	"""End interaction with this NPC"""
	interaction_ended.emit(character_id)

func face_target(target):
	const _fname : String ="face_target"
	"""Face toward a target (like the player)"""
	if debug: print(GameState.script_name_tag(self, _fname) + "called")

	if not target:
		return
	
	var direction = (target.global_position - global_position).normalized()
	var facing_dir = "down"
	
	if abs(direction.x) > abs(direction.y):
		facing_dir = "right" if direction.x > 0 else "left"
	else:
		facing_dir = "down" if direction.y > 0 else "up"
	if debug: print(GameState.script_name_tag(self, _fname) + "last_direction = " + str(last_direction))
	change_facing(facing_dir)
	if debug: print(GameState.script_name_tag(self, _fname) + "last_direction = " + str(last_direction))

# ==========================================
# DIALOGUE INTEGRATION (from original NPC)
# ==========================================

func get_memory_dialogue_options() -> Array:
	"""Get dialogue options available based on discovered memories"""
	if memory_system:
		return memory_system.get_available_dialogue_options(character_id)
	return []

func is_dialogue_option_available(dialogue_title: String) -> bool:
	"""Check if specific dialogue option is available"""
	if memory_system:
		return memory_system.is_dialogue_available(character_id, dialogue_title)
	return false

# ==========================================
# SPRITE SYSTEM (from original NPC)
# ==========================================

func setup_sprite_deferred():
	"""Deferred sprite setup"""
	call_deferred("_setup_sprite_deferred")

func _setup_sprite_deferred():
	"""Set up sprite with deferred call"""
	if sprite:
		var texture_path = "res://assets/character_sprites/" + character_id + "/standard/idle.png"
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.hframes = 2
			sprite.vframes = 4
			if debug: print(GameState.script_name_tag(self) + "Deferred sprite setup complete")

func _on_sprite_2d_frame_changed() -> void:
	"""Handle sprite frame changes"""
#	if sprite and debug:
#		print(GameState.script_name_tag(self) + "Playing NPC Frame " + str(sprite.frame))

func _on_sprite_2d_texture_changed() -> void:
	"""Handle sprite texture changes"""
#	if sprite and debug:
#		print(GameState.script_name_tag(self) + "NPC Texture = ", str(sprite.texture))

# ==========================================
# UTILITY AND VALIDATION (from original NPC)
# ==========================================

func validate_observable_features() -> Dictionary:
	"""Validate observable features are properly set up"""
	var _fname = "validate_observable_features"
	var validation_result = {
		"feature_count": observable_features.size(),
		"features_with_memory_tags": 0,
		"features_without_memory_tags": 0,
		"valid": true,
		"warnings": []
	}
	
	# Validate each feature that exists (no hardcoded expectations)
	for feature_id in observable_features.keys():
		var feature = observable_features[feature_id]
		
		# Check if feature has required properties
		if not feature.has("description") or feature.description == "":
			validation_result.warnings.append("Feature '" + feature_id + "' missing description")
			validation_result.valid = false
		
		# Count features with/without memory tags
		var memory_tag = feature.get("memory_tag", "")
		if memory_tag != "":
			validation_result.features_with_memory_tags += 1
		else:
			validation_result.features_without_memory_tags += 1
	
	if debug and validation_result.warnings.size() > 0:
		print(GameState.script_name_tag(self, _fname) + "Observable feature validation issues for ", character_id, ":")
		for warning in validation_result.warnings:
			print(GameState.script_name_tag(self, _fname) + "  ", warning)
	
	return validation_result

# ==========================================
# DEBUGGING AND VALIDATION
# ==========================================

func debug_character_info():
	"""Debug function to print all character information"""
	if not debug:
		return
	
	print("\n=== CHARACTER DEBUG INFO: ", character_id, " ===")
	print("Name: ", character_name)
	print("Description: ", description)
	print("Personality traits: ", personality_traits)
	print("Interests: ", interests)
	print("Background: ", background)
	print("Observable features: ", observable_features.keys())
	print("Character data dict size: ", character_data.size())
	print("Current relationship level: ", get_current_relationship_level())
	print("=================================\n")

func validate_character_setup() -> bool:
	"""Validate that character is set up correctly"""
	var _fname = "validate_character_setup"
	var valid = true
	
	if character_id == "":
		print(GameState.script_name_tag(self, _fname) + "ERROR: character_id is empty")
		valid = false
	
	if character_name == "":
		print(GameState.script_name_tag(self, _fname) + "WARNING: character_name is empty")
	
	if observable_features.is_empty() and character_id != "":
		print(GameState.script_name_tag(self, _fname) + "WARNING: No observable features set up for ", character_id)
	
	return valid
