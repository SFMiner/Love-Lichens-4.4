extends Node

@export var sprite_path: NodePath = NodePath("Sprite2D")
@onready var sprite: Sprite2D = get_parent().get_node_or_null("Sprite2D")
@onready var spritesheets = "res://assets/character_sprites/" + get_parent().character_id + "/standard/"
@onready var AP = get_parent().get_node_or_null("AnimationPlayer")
@onready var player = get_parent()
@onready var animation_data : Dictionary = {
	"walk": {
		"path": spritesheets + "walk.png", 
		"hframes": 9, 
		"vframes": 4, 
		"total_frames": 36, 
		"frame_time": 0.1,
		# You can specify different timing for each frame in the animation
		"frame_times": {
			# Format: "direction": [time_for_frame0, time_for_frame1, ...]
			"down": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
			"left": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
			"right": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
			"up": [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
		}
	},
	"climb": {"path": spritesheets + "climb.png", "hframes": 6, "vframes": 1, "total_frames": 6, "frame_time": 0.1},
	"emote": {"path": spritesheets + "emote.png", "hframes": 3, "vframes": 4, "total_frames": 12, "frame_time": 0.1},
	"hurt":  {"path": spritesheets + "hurt.png",  "hframes": 6, "vframes": 1, "total_frames": 6, "frame_time": 0.1},
	"idle":  {"path": spritesheets + "idle.png",  "hframes": 2, "vframes": 4, "total_frames": 8, "frame_time": 0.4},
	"jump":  {
		"path": spritesheets + "jump.png", 
		"hframes": 6, 
		"vframes": 4, 
		"total_frames": 24, 
		"frame_time": 0.3,
		# Custom frame timing for each direction's jump animation
		"frame_times": {
			"down": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15],  # Total: 1.2 seconds
			"left": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15],  # Total: 1.2 seconds
			"right": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15], # Total: 1.2 seconds
			"up": [0.05, 0.2, 0.2, 0.4, 0.2, 0.15]     # Total: 1.2 seconds
		}
	},
	"run":  {
		"path": spritesheets + "run.png",  
		"hframes": 8, 
		"vframes": 4, 
		"total_frames": 32, 
		"frame_time": 0.08,  # Run animation should be faster than walk
		# Add frame timing for run animation
		"frame_times": {
			"down": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
			"left": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
			"right": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
			"up": [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08]
		}
	},
}

var current_anim = "idle"
var current_frame : int = 0
var current_direction = 0
var last_anim : String = "idle"
var frame_index = 0
var frame_timer = 0.0
# This is the default frame time used if not specified in animation_data
var default_frame_time = 0.1 
# Track current frame within current row
var current_row_frame = 0
# Track current row's animation direction name
var current_direction_name = "down"
# Track the current animation + direction
var current_animation_name = ""
# Track just the base animation (without direction)  
var current_base_anim = ""

func _ready():
	# Initialize the sprite properties
	if not animation_data.is_empty() and "idle" in animation_data:
		var anim = animation_data["idle"]
		print("INITIALIZING CharacterAnimator with sprite: " + anim.path)
		var texture = load(anim.path)
		if texture:
			sprite.texture = texture
			sprite.hframes = anim.hframes
			sprite.vframes = anim.vframes
			print("Sprite initialized successfully with: texture=" + str(sprite.texture) + 
				", hframes=" + str(sprite.hframes) + 
				", vframes=" + str(sprite.vframes))
		else:
			push_error("Failed to load texture: " + anim.path)
	
	# Set initial animation 
	current_base_anim = "idle"
	current_animation_name = "idle_down"
	
	# Play initial animation
	if AP and AP.has_animation("idle_down"):
		AP.play("idle_down")
		print("Playing initial idle_down animation")
	else:
		print("WARNING: Could not play initial animation")

func set_animation(anim_name: String, direction: String = player.last_direction):
	# Generate the full animation name
	var new_animation_name = anim_name + "_" + direction
	
	print("REQUEST TO PLAY: " + new_animation_name + 
		", Current: " + current_animation_name + 
		", Current Base: " + current_base_anim)
	
	# Check if the AnimationPlayer has the animation
	if not AP.has_animation(new_animation_name):
		print("ERROR: Animation not found in AnimationPlayer: " + new_animation_name)
		print("Available animations: " + str(AP.get_animation_list()))
		return
		
	# Update spritesheet if animation type has changed
	var spritesheet_changed = false
	if current_base_anim != anim_name:
		current_base_anim = anim_name
		spritesheet_changed = true
		
		# Load the new spritesheet texture
		if anim_name in animation_data:
			var anim = animation_data[anim_name]
			print("Changing spritesheet to: " + anim.path + " for animation: " + anim_name)
			print("Sprite settings BEFORE change: texture=" + str(sprite.texture) + 
				", hframes=" + str(sprite.hframes) + 
				", vframes=" + str(sprite.vframes))
			
			var tex = load(anim.path)
			sprite.texture = tex
			sprite.hframes = anim.hframes
			sprite.vframes = anim.vframes
			
			print("Sprite settings AFTER change: texture=" + str(sprite.texture) + 
				", hframes=" + str(sprite.hframes) + 
				", vframes=" + str(sprite.vframes))
		else:
			print("WARNING: Animation data not found for: " + anim_name)
	
	# Only change animation if it's actually different or we changed spritesheets
	if new_animation_name != current_animation_name or spritesheet_changed:
		# Update the current animation name
		current_animation_name = new_animation_name
		print("PLAYING ANIMATION: " + new_animation_name)
		
		# Special handling for run animation to ensure it starts correctly
		if anim_name == "run":
			print("SPECIAL HANDLING FOR RUN ANIMATION")
			AP.stop()  # Force stop any previous animation
			
			# Make sure the frame is reset properly for run animation
			# This is critical if we're seeing only the first frame
			if direction == "down":
				sprite.frame = 16  # Starting frame for run_down
			elif direction == "left":
				sprite.frame = 8   # Starting frame for run_left
			elif direction == "right":
				sprite.frame = 24  # Starting frame for run_right
			elif direction == "up":
				sprite.frame = 0   # Starting frame for run_up
				
			print("Set initial run frame to: " + str(sprite.frame) + " for direction: " + direction)
			
			# Now play the animation
			AP.play(new_animation_name)
		else:
			# Normal animation handling for non-run animations
			AP.stop() # Force stop any previous animation
			AP.play(new_animation_name)
		
		# Debug animation properties
		print("Animation properties: frames=" + str(sprite.frame) + 
			", animation_name=" + str(AP.current_animation) + 
			", is_playing=" + str(AP.is_playing()) + 
			", texture_path=" + str(sprite.texture.resource_path if sprite.texture else "None"))
	else:
		print("Animation " + new_animation_name + " is already playing, skipping")
		
	# Verify that the animation is actually playing
	print("AnimationPlayer current animation: " + AP.current_animation)
