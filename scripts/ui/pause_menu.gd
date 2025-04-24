extends Control

signal resume_game
signal save_game(slot)
signal load_game(slot)
signal quit_to_menu

const scr_debug :bool = false
var debug

var current_save_slot = 0
var max_save_slots = 5

func _ready():
	debug = scr_debug or GameController.sys_debug 
	# Make this a pause-mode process so it keeps running while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect button signals
	$VBoxContainer/ResumeButton.connect("pressed", _on_resume_button_pressed)
	$VBoxContainer/SaveButton.connect("pressed", _on_save_button_pressed)
	$VBoxContainer/LoadButton.connect("pressed", _on_load_button_pressed)
	$VBoxContainer/QuitButton.connect("pressed", _on_quit_button_pressed)
	
	# Connect save slot buttons
	for i in range(max_save_slots):
		if has_node("SaveSlotPanel/SlotContainer/Slot" + str(i)):
			get_node("SaveSlotPanel/SlotContainer/Slot" + str(i)).connect("pressed", _on_save_slot_selected.bind(i))
	
	# Hide the save slot panel initially
	$SaveSlotPanel.visible = false
	
	# Update slot information if we have a save system
	update_slot_info()

func update_slot_info():
	var save_load_system = get_node_or_null("/root/SaveLoadSystem")
	if save_load_system:
		var slot_info = save_load_system.get_all_save_slots_info()
		
		for i in range(max_save_slots):
			var slot_button = get_node_or_null("SaveSlotPanel/SlotContainer/Slot" + str(i))
			if slot_button:
				var info = slot_info[i]
				if info != null:
					# Format slot info
					var date_str = info.save_date.split(" ")[0] if info.has("save_date") else "Empty"
					var location = info.location if info.has("location") else ""
					slot_button.text = "Slot " + str(i) + " - " + date_str + " - " + location
				else:
					slot_button.text = "Slot " + str(i) + " - Empty"

func _on_resume_button_pressed():
	resume_game.emit()

func _on_save_button_pressed():
	# Show the save slot selection panel
	$SaveSlotPanel.visible = true
	$SaveSlotPanel/TitleLabel.text = "Select Save Slot"
	$SaveSlotPanel/ConfirmButton.text = "Save"
	
	# Properly disconnect and reconnect signals
	if $SaveSlotPanel/ConfirmButton.is_connected("pressed", Callable(self, "_on_save_confirmed")):
		$SaveSlotPanel/ConfirmButton.disconnect("pressed", Callable(self, "_on_save_confirmed"))
	
	if $SaveSlotPanel/ConfirmButton.is_connected("pressed", Callable(self, "_on_load_confirmed")):
		$SaveSlotPanel/ConfirmButton.disconnect("pressed", Callable(self, "_on_load_confirmed"))
		
	$SaveSlotPanel/ConfirmButton.connect("pressed", _on_save_confirmed)
	
	# Update slot info before showing
	update_slot_info()

func _on_load_button_pressed():
	# Show the save slot selection panel
	$SaveSlotPanel.visible = true
	$SaveSlotPanel/TitleLabel.text = "Select Load Slot"
	$SaveSlotPanel/ConfirmButton.text = "Load"
	
	# Properly disconnect and reconnect signals
	if $SaveSlotPanel/ConfirmButton.is_connected("pressed", Callable(self, "_on_save_confirmed")):
		$SaveSlotPanel/ConfirmButton.disconnect("pressed", Callable(self, "_on_save_confirmed"))
	
	if $SaveSlotPanel/ConfirmButton.is_connected("pressed", Callable(self, "_on_load_confirmed")):
		$SaveSlotPanel/ConfirmButton.disconnect("pressed", Callable(self, "_on_load_confirmed"))
		
	$SaveSlotPanel/ConfirmButton.connect("pressed", _on_load_confirmed)
	
	# Update slot info before showing
	update_slot_info()

func _on_quit_button_pressed():
	quit_to_menu.emit()

func _on_save_slot_selected(slot):
	current_save_slot = slot
	# Highlight the selected slot
	for i in range(max_save_slots):
		var slot_button = get_node("SaveSlotPanel/SlotContainer/Slot" + str(i))
		if slot_button:
			if i == current_save_slot:
				slot_button.add_theme_color_override("font_color", Color(1, 1, 0))
			else:
				slot_button.remove_theme_color_override("font_color")

func _on_save_confirmed():
	save_game.emit(current_save_slot)
	$SaveSlotPanel.visible = false

func _on_load_confirmed():
	load_game.emit(current_save_slot)
	$SaveSlotPanel.visible = false

func _on_cancel_button_pressed():
	$SaveSlotPanel.visible = false
