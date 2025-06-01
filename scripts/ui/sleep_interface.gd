# sleep_interface.gd
extends Control

signal sleep_completed(time_periods)

@onready var morning_button = $VBoxContainer/ButtonsContainer/MorningButton
@onready var afternoon_button = $VBoxContainer/ButtonsContainer/AfternoonButton
@onready var evening_button = $VBoxContainer/ButtonsContainer/EveningButton
@onready var night_button = $VBoxContainer/ButtonsContainer/NightButton
@onready var cancel_button = $VBoxContainer/CancelButton

var time_system

func _ready():
	time_system = get_node_or_null("/root/TimeSystem")
	
	# Manually connect signals in code (more reliable than scene connections)
	morning_button.pressed.connect(_on_morning_button_pressed)
	afternoon_button.pressed.connect(_on_afternoon_button_pressed)
	evening_button.pressed.connect(_on_evening_button_pressed)
	night_button.pressed.connect(_on_night_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# Set process mode to handle input while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	update_buttons()
	print(GameState.script_name_tag(self) + "Sleep interface initialized and signals connected")

func update_buttons():
	if time_system:
		var current_time = time_system.current_time_of_day
		
		# Disable buttons for times we've already passed today
		morning_button.disabled = current_time > time_system.TimeOfDay.MORNING
		afternoon_button.disabled = current_time > time_system.TimeOfDay.AFTERNOON
		evening_button.disabled = current_time > time_system.TimeOfDay.EVENING
		night_button.disabled = current_time > time_system.TimeOfDay.NIGHT
		
		# If we're at night, allow sleeping until morning (next day)
		if current_time == time_system.TimeOfDay.NIGHT:
			morning_button.disabled = false

func _on_morning_button_pressed():
	print(GameState.script_name_tag(self) + "Morning button pressed")
	if time_system:
		var periods = time_system.sleep_until(time_system.TimeOfDay.MORNING)
		sleep_completed.emit(periods)
	visible = false
	get_tree().paused = false

func _on_afternoon_button_pressed():
	print(GameState.script_name_tag(self) + "Afternoon button pressed")
	if time_system:
		var periods = time_system.sleep_until(time_system.TimeOfDay.AFTERNOON)
		sleep_completed.emit(periods)
	visible = false
	get_tree().paused = false

func _on_evening_button_pressed():
	print(GameState.script_name_tag(self) + "Evening button pressed")
	if time_system:
		var periods = time_system.sleep_until(time_system.TimeOfDay.EVENING)
		sleep_completed.emit(periods)
	visible = false
	get_tree().paused = false
	
func _on_night_button_pressed():
	print(GameState.script_name_tag(self) + "Night button pressed")
	if time_system:
		var periods = time_system.sleep_until(time_system.TimeOfDay.NIGHT)
		sleep_completed.emit(periods)
	visible = false
	get_tree().paused = false

func _on_cancel_button_pressed():
	print(GameState.script_name_tag(self) + "Cancel button pressed")
	visible = false
	get_tree().paused = false
	
# Also handle escape key to cancel
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = false
		get_tree().paused = false
