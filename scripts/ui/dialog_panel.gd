extends Control

# UI script for the dialog panel
# Handles displaying dialog text, character names, and dialog options

@onready var character_name_label = $CharacterName
@onready var dialog_text = $DialogText
@onready var options_container = $OptionsContainer

const scr_debug :bool = false
var debug


var dialog_system
var current_options = []

func _ready():
	debug = scr_debug or GameController.sys_debug 

	# Get reference to the dialog system autoload
	dialog_system = get_node("/root/DialogSystem")
	
	# Connect signals
	if dialog_system:
		dialog_system.dialog_started.connect(_on_dialog_started)
		dialog_system.dialog_ended.connect(_on_dialog_ended)
	
	# Initially hide the dialog panel
	hide()

func _on_dialog_started(character_id):
	# Show the dialog panel
	show()
	
	# Set character name
	# In a real implementation, you'd get this from the NPC data
	character_name_label.text = character_id.capitalize()
	
	# Display initial dialog
	var initial_text = dialog_system.start_dialog(character_id)
	dialog_text.text = initial_text
	
	# Display dialog options
	display_options()
	
func display_options():
	# Clear previous options
	for child in options_container.get_children():
		child.queue_free()
	
	# Get current dialog options
	current_options = dialog_system.get_dialog_options()
	
	# Create buttons for each option
	for option in current_options:
		var button = Button.new()
		button.text = option["text"]
		button.pressed.connect(func(): _on_option_selected(option["id"]))
		options_container.add_child(button)
	
	# If no options, add an "End conversation" button
	if current_options.is_empty():
		var end_button = Button.new()
		end_button.text = "End conversation"
		end_button.pressed.connect(_on_dialog_end_requested)
		options_container.add_child(end_button)

func _on_option_selected(option_id):
	# Get response for the selected option
	var response = dialog_system.make_choice(option_id)
	
	# Update dialog text
	dialog_text.text = response
	
	# Update options
	display_options()
	
func _on_dialog_end_requested():
	dialog_system.end_dialog()
	
func _on_dialog_ended(_character_id):
	# Hide the dialog panel
	hide()
