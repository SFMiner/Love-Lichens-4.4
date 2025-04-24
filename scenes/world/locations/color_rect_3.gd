extends ColorRect

@onready var label : Label = $Label

func _ready():
	label.text = str(z_index)
	
	
func _process(delta):
	label.text = str(position.y) + " | " + str(z_index)
		
	
