extends Node2D

func _ready():
	var label = Label.new() 
	label.text = str(z_index)
	add_child(label)
	
