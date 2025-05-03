# time_display.gd
extends Control

@onready var day_label = $VBoxContainer/DayLabel
@onready var time_label = $VBoxContainer/TimeLabel
@onready var date_label = $VBoxContainer/DateLabel

var time_system

func _ready():
	time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		time_system.day_changed.connect(_on_day_changed)
		time_system.time_of_day_changed.connect(_on_time_of_day_changed)
	
	update_display()

func _on_day_changed(_old_day, _new_day):
	update_display()

func _on_time_of_day_changed(_old_time, _new_time):
	update_display()

func update_display():
	if time_system:
		day_label.text = "Day " + str(time_system.current_day) + " (" + time_system.get_day_name() + ")"
		time_label.text = time_system.get_time_name()
		date_label.text = "Week " + str(time_system.current_week)
		
		# Debug info to console
		print("Time Display updated: Day " + str(time_system.current_day) + 
			" (" + time_system.get_day_name() + "), " + 
			time_system.get_time_name() + ", Week " + str(time_system.current_week))

func _on_speed_slider_value_changed(value):
	if time_system:
		time_system.set_time_scale(value)

func _on_pause_button_pressed():
	if time_system:
		if time_system.get_time_scale() > 0:
			time_system.pause_time()
		else:
			time_system.resume_time()
			
