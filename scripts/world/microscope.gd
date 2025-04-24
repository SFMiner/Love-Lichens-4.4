# microscope.gd
extends InteractionAgent

func _ready():
	# Setup basic properties
	interaction_id = "microscope"
	display_name = "Microscope"
	dialog_id = "microscope"
	object_type = 4  # Lab
	
	# Call parent _ready implementation
	super._ready()
	
