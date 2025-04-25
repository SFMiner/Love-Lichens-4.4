extends Node

@export var sprite_path: NodePath = NodePath("Sprite2D")
@onready var sprite: Sprite2D = get_parent().get_node_or_null("Sprite2D")
@onready var spritesheets = "res://assets/character_sprites/" + get_parent().character_id + "/standard/"
@onready var AP = get_parent().get_node_or_null("AnimationPlayer")
@onready var animation_data : Dictionary = {
	"walk": {"path": spritesheets + "walk.png", "hframes": 9, "vframes": 4, "total_frames": 36},
	"climb": {"path": spritesheets + "climb.png", "hframes": 6, "vframes": 1, "total_frames": 6},
	"emote": {"path": spritesheets + "emote.png", "hframes": 3, "vframes": 4, "total_frames": 12},
	"hurt":  {"path": spritesheets + "hurt.png",  "hframes": 6, "vframes": 1, "total_frames": 6},
	"idle":  {"path": spritesheets + "idle.png",  "hframes": 2, "vframes": 4, "total_frames": 8},
	"jump":  {"path": spritesheets + "jump.png",  "hframes": 5, "vframes": 4, "total_frames": 20},
	"run":  {"path": spritesheets + "run.png",  "hframes": 8, "vframes": 4, "total_frames": 32},
}

var current_anim = "idle"
var current_direction = 0
var frame_index = 0
var frame_timer = 0.0
var frame_time = 0.1

func _process(delta):
	if not current_anim in animation_data:
		return
	frame_timer += delta
	if frame_timer >= frame_time:
		frame_timer = 0.0
		advance_frame()

func advance_frame():
	var anim = animation_data[current_anim]
	frame_index = (frame_index + 1) % anim.total_frames
	var row = current_direction
	if row >= anim.vframes:
		row = 0
	var col = frame_index % anim.hframes
	sprite.frame = row * anim.hframes + col

func set_animation(anim_name: String, direction: String = "down"):
	if not anim_name in animation_data:
		print("Unknown animation: ", anim_name)
		return
	var anim = animation_data[anim_name]
	print ("ANIMATION_DATA = " + str(anim))
	print ("ANIMATION_DATA.path = " + str(anim.path))
	sprite.texture = load(anim.path)
	sprite.hframes = anim.hframes
	sprite.vframes = anim.vframes
	current_anim = anim_name
	frame_index = 0
	frame_timer = 0.0
	
	match direction:
		"down": current_direction = 0
		"left": current_direction = 1
		"right": current_direction = 2
		"up": current_direction = 3
		_: current_direction = 0
		
	AP.play(anim_name + "_" + direction)
