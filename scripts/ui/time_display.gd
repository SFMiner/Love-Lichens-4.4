# res://scripts/ui/time_display.gd
extends Control

# assumes your TimeSystem is autoloaded as "TimeSystem"
@onready var ts = get_node("/root/TimeSystem")

@onready var day_label    = $VBoxContainer/DayLabel
@onready var time_label   = $VBoxContainer/TimeLabel
@onready var date_label   = $VBoxContainer/DateLabel
@onready var speed_slider = $VBoxContainer/HBoxContainer/SpeedSlider

func _ready() -> void:
	# connect using Callables
	ts.connect("day_changed",          Callable(self, "_on_day_changed"))
	ts.connect("time_of_day_changed",  Callable(self, "_on_time_changed"))
	ts.connect("month_changed",        Callable(self, "_on_date_changed"))
	ts.connect("year_changed",         Callable(self, "_on_date_changed"))

	# initialize display
	day_label.text  = "Day %d (%s)" % [ts.current_day, ts.get_day_name()]
	time_label.text = ts.get_time_name()
	date_label.text = ts.get_formatted_date()

	# set slider to current scale
	speed_slider.value = ts.get_time_scale()

func _on_day_changed(old_day: int, new_day: int) -> void:
	day_label.text = "Day %d (%s)" % [new_day, ts.get_day_name()]

func _on_time_changed() -> void: #old_t: int, new_t: int) -> void:
	time_label.text = ts.get_time_name()

func _on_date_changed() -> void: #old_val: int, new_val: int) -> void:
	date_label.text = ts.get_formatted_date()

func _on_speed_slider_value_changed(value: float) -> void:
	ts.set_time_scale(value)

func _on_pause_button_pressed() -> void:
	if ts.get_time_scale() > 0.0:
		ts.pause_time()
	else:
		ts.resume_time()
