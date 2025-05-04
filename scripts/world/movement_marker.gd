extends Node2D

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	# Animate the marker for better visibility
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Set up a self-remove timer (if not already in an animation)
	if not animation_player or not animation_player.is_playing():
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): queue_free())
	
	# Apply a small bounce effect
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
