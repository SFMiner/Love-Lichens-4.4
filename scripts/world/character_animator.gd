extends Node

const scr_debug: bool = false
var debug: bool

@onready var sprite: Sprite2D = get_parent().get_node_or_null("Sprite2D")
@onready var AP = get_parent().get_node_or_null("AnimationPlayer")
@onready var parent = get_parent()

var animation_data: Dictionary = {}
var sheets_path: String = ""
var current_anim = "idle"
var current_direction = 0
var last_anim: String = "idle"
var current_base_anim = "idle"
var current_animation_name = "idle_down"
var current_direction_name = "down"

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self) + "CharacterAnimator initialized for: ", get_parent().name)
	
	# Initial setup
	if "character_id" in get_parent():
		var char_id = get_parent().character_id
		if char_id and char_id != "":
			set_sheets_path(char_id)
			if debug: print(GameState.script_name_tag(self) + "Set character sheets path: ", sheets_path)
	
	# Set up sprite if it exists
	if sprite:
		if debug: print(GameState.script_name_tag(self) + "Found sprite reference for: ", get_parent().name)
		
		# Try to load initial texture for idle animation
		_load_animation_texture("idle")
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: No sprite found for: ", get_parent().name)

func set_sheets_path(char_id: String):
	sheets_path = "res://assets/character_sprites/" + char_id + "/standard/"
	if debug: print(GameState.script_name_tag(self) + "Sheets path set to: ", sheets_path)
	set_animation_data()

func set_animation_data():
	animation_data = {
		"walk": {
			"path": sheets_path + "walk.png", 
			"hframes": 9, 
			"vframes": 4, 
			"total_frames": 36, 
			"frame_time": 0.1,
			"frame_times": {
				"down": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
				"left": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
				"right": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
				"up": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
			}
		},
		"climb": {"path": sheets_path + "climb.png", "hframes": 6, "vframes": 1, "total_frames": 6, "frame_time": 0.1},
		"emote": {"path": sheets_path + "emote.png", "hframes": 3, "vframes": 4, "total_frames": 12, "frame_time": 0.1},
		"hurt": {"path": sheets_path + "hurt.png", "hframes": 6, "vframes": 1, "total_frames": 6, "frame_time": 0.1},
		"idle": {"path": sheets_path + "idle.png", "hframes": 2, "vframes": 4, "total_frames": 8, "frame_time": 0.4},
		"jump": {
			"path": sheets_path + "jump.png", 
			"hframes": 6, 
			"vframes": 4, 
			"total_frames": 24, 
			"frame_time": 0.3,
			"frame_times": {
				"down": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15],
				"left": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15],
				"right": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15],
				"up": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15]
			}
		},
		"run": {
			"path": sheets_path + "run.png",  
			"hframes": 8, 
			"vframes": 4, 
			"total_frames": 32, 
			"frame_time": 0.08,
			"frame_times": {
				"down": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
				"left": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
				"right": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
				"up": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08]
			}
		},
	}
	
	if debug: print(GameState.script_name_tag(self) + "Animation data initialized for: ", get_parent().name)

func set_animation(anim_name: String, direction, character_id: String):
	# Make sure our paths are set correctly
	if sheets_path == "" or not sheets_path.contains(character_id):
		set_sheets_path(character_id)
	
	# Handle cases where anim_name already includes direction (like "jump_down")
	var base_anim = anim_name
	var dir_string = ""
	
	if "_" in anim_name:
		var parts = anim_name.split("_")
		base_anim = parts[0]  # "jump", "walk", etc.
		
		# If direction wasn't explicitly provided, use the one from anim_name
		if direction == null or (direction is String and direction.is_empty()):
			if parts.size() > 1:
				dir_string = parts[1]  # "down", "up", etc.
		else:
			# If direction was provided, use that instead
			if direction is Vector2:
				dir_string = _get_direction_from_vector(direction)
			else:
				dir_string = String(direction)
	else:
		# Standard case - separate anim_name and direction
		if direction is Vector2:
			dir_string = _get_direction_from_vector(direction)
		else:
			dir_string = str(direction)
	
	# Default to "down" if no direction is specified
	if dir_string.is_empty():
		dir_string = "down"
		
	# Generate the full animation name
	var new_animation_name = base_anim + "_" + dir_string
	
	if debug: print(GameState.script_name_tag(self) + "Setting animation to: ", new_animation_name, " for character: ", character_id)
	
	# Extract the base animation type (walk, run, jump, etc.)
	var new_base_anim = anim_name
	
	# Check if the AnimationPlayer has the animation
	if not AP.has_animation(new_animation_name):
		if debug: print(GameState.script_name_tag(self) + "ERROR: Animation not found in AnimationPlayer: ", new_animation_name)
		if debug: print(GameState.script_name_tag(self) + "Available animations: ", AP.get_animation_list())
		return
	
	# Update spritesheet if animation type has changed
	var spritesheet_changed = false
	if current_base_anim != base_anim:
		if debug: print(GameState.script_name_tag(self) + "Animation type changed from ", current_base_anim, " to ", base_anim)
		current_base_anim = base_anim
		spritesheet_changed = true
		
		# Load the new spritesheet texture
		if not _load_animation_texture(base_anim):
			if debug: print(GameState.script_name_tag(self) + "Failed to load texture for animation: ", base_anim)
			return
	
	# Only change animation if it's actually different or we changed spritesheets
	if new_animation_name != current_animation_name or spritesheet_changed:
		# Update the current animation name
		current_animation_name = new_animation_name
		current_direction_name = dir_string
		
		if debug: print(GameState.script_name_tag(self) + "Playing animation: ", new_animation_name)
		
		# Stop any current animation
		AP.stop(true)
		
		# Set the correct starting frame based on direction
		_set_initial_frame(new_base_anim, dir_string)
		
		# Play the animation
		AP.play(new_animation_name)
	else:
		if debug: print(GameState.script_name_tag(self) + "Animation ", new_animation_name, " is already playing")

# Load texture for a specific animation type
func _load_animation_texture(anim_type: String) -> bool:
	if not animation_data.has(anim_type):
		if debug: print(GameState.script_name_tag(self) + "ERROR: No animation data for type: ", anim_type, " for character: ", get_parent().name)
		return false
	
	var anim = animation_data[anim_type]
	if not anim.has("path"):
		if debug: print(GameState.script_name_tag(self) + "ERROR: No path defined for animation: ", anim_type, " for character: ", get_parent().name)
		return false
	
	if debug: print(GameState.script_name_tag(self) + "Loading texture from: ", anim.path, " for character: ", get_parent().name)
	
	# Check if texture exists
	if not ResourceLoader.exists(anim.path):
		if debug: print(GameState.script_name_tag(self) + "ERROR: Texture file not found: ", anim.path)
		return false
	
	# Load the texture
	var texture = load(anim.path)
	if not texture:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Failed to load texture: ", anim.path)
		return false
	
	# Apply to sprite
	sprite.texture = texture
	sprite.hframes = anim.hframes
	sprite.vframes = anim.vframes
	
	if debug: print(GameState.script_name_tag(self) + "Successfully loaded texture for ", anim_type, 
		": texture=", sprite.texture.resource_path, 
		", hframes=", sprite.hframes, 
		", vframes=", sprite.vframes)
	
	return true

# Set the initial frame based on direction
func _set_initial_frame(anim_type: String, direction: String):
	# Base frame indices for different directions (default values)
	var frame_indices = {
		"down": 0,
		"left": 0,
		"right": 0,
		"up": 0
	}
	
	# Override with animation-specific frame indices
	match anim_type:
		"run":
			frame_indices = {
				"down": 16,  # Row 3 (0-indexed)
				"left": 8,   # Row 2
				"right": 24, # Row 4
				"up": 0      # Row 1
			}
		"walk":
			frame_indices = {
				"down": 18,  # Row 3
				"left": 9,   # Row 2
				"right": 27, # Row 4
				"up": 0      # Row 1
			}
		"idle":
			frame_indices = {
				"down": 4,   # Row 3
				"left": 2,   # Row 2
				"right": 6,  # Row 4
				"up": 0      # Row 1
			}
		"jump":
			frame_indices = {
				"down": 12,  # Row 3
				"left": 6,   # Row 2
				"right": 18, # Row 4
				"up": 0      # Row 1
			}
	
	# Set the frame if valid
	if frame_indices.has(direction):
		sprite.frame = frame_indices[direction]
		if debug: print(GameState.script_name_tag(self) + "Set initial frame to ", sprite.frame, " for ", anim_type, "_", direction)

# Helper method to convert vector to direction string
func _get_direction_from_vector(direction_vector: Vector2) -> String:
	if abs(direction_vector.x) > abs(direction_vector.y):
		return "right" if direction_vector.x > 0 else "left"
	else:
		return "down" if direction_vector.y > 0 else "up"
