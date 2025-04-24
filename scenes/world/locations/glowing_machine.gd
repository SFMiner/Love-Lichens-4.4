extends Node2D

func _ready():
	# Ensure we're not in the interactable group
	if is_in_group("interactable"):
		remove_from_group("interactable")
	
	# Start animation
	if has_node("Sprite2D/AnimationPlayer"):
		$Sprite2D/AnimationPlayer.play("bubble")
	if has_node("Sprite2D2/AnimationPlayer"):
		$Sprite2D2/AnimationPlayer.play("bubble")
