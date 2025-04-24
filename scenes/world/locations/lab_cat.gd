extends Node2D

func _ready():
	# Ensure we're not in the interactable group
	if is_in_group("interactable"):
		remove_from_group("interactable")
	
	# Add to objects group for z-indexing
	add_to_group("z_Objects")
	
	# Set z-index based on y position
	z_index = position.y
	
	# Start animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("sleeping")
