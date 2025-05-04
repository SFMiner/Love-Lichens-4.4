extends Node2D

func _ready():
	# Setup animation
	modulate.a = 0
	
	# Animate appearance
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Add circle animation
	var animation_player = $AnimationPlayer
	if animation_player:
		animation_player.play("pulse")
		
	add_to_group("marker")

func _draw():
	# Draw a circle
	draw_circle(Vector2.ZERO, 10, Color(0, 1, 0, 0.4))
	draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color(0, 1, 0, 0.6), 2)
