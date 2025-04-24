extends Node2D
@onready var z_objects = $Sprite2D/z_Objects
func _ready():
	var debug_label = get_node_or_null("CanvasLayer/GameInfo")
	if debug_label:
		var player = $Player
		if player and player.interactable_object:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
		else:
			debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
