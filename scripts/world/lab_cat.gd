extends Node2D

func _ready():
	# Ensure we're not in the interactable group
	if is_in_group("interactable"):
		remove_from_group("interactable")

	# Start animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("sleeping")
