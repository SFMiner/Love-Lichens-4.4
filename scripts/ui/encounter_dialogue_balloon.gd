# encounter_dialogue_balloon.gd
extends CanvasLayer

@onready var balloon = %Balloon
@onready var dialogue_label = %DialogueLabel
@onready var responses = %Responses
@onready var response_template = %ResponseTemplate
@onready var participants_list = %ParticipantsList
@onready var participant_template = %ParticipantTemplate
@onready var speaker_name = %SpeakerName
@onready var speaker_badge = %SpeakerBadge
@onready var portrait_rect = %PortraitRect
@onready var animation_player = $AnimationPlayer

# Current state
var dialogue: DialogueResource
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var current_speaker_id = ""
var encounter_id = ""
var participants = {}  # Dictionary of {character_id: {name, portrait, node}}

# Character style dictionary
var character_styles = {
	"narrator": {
		"color": Color(0.3, 0.7, 0.3),  # Green
		"font": null,  # Default font
		"font_size": 16,
		"background": null  # No special background
	},
	"professor_moss": {
		"color": Color(0.2, 0.8, 0.4), 
		"font": preload("res://assets/fonts/bainsley/Bainsley-VGgJ6.ttf"),  # Would be preload("res://assets/fonts/professor_font.ttf")
		"font_size": 18,
		"name": "Professor Moss"
	},
	"li": {
		"color": Color(0.2, 0.8, 0.8),
		"font": preload("res://assets/fonts/cup_of_sea/CupOfSea-05qz.ttf"),
		"font_size": 16,
		"name": "Li"
	},
	"fate": {
		"color": Color(0.2, 0.8, 0.8),
		"font": preload("res://assets/fonts/medieval_sharp_tool/MedievalSharp-xOZ5.ttf"),
		"font_size": 16,
		"name": "Fate"
	},
	"dusty": {
		"color": Color(0.8, 0.6, 0.2),
		"font": null,
		"font_size": 16,
		"name": "Dusty"
	},
	"erik": {
		"color": Color(0.8, 0.6, 0.2),
		"font": preload("res://assets/fonts/numb_bunny/Numbbunny-L7L5.otf"),
		"font_size": 16,
		"name": "erik"
	},
	"poison": {
		"color": Color(0.8, 0.2, 0.6),
		"font": preload("res://assets/fonts/bored_in_science/BoredInScience-9GXL.ttf"),
		"font_size": 16,
		"name": "Poison"
	},
	"iris_bookwright": {
		"color": Color(0.8, 0.2, 0.6),
		"font": preload("res://assets/fonts/quango/Quango-xlVR.otf"),
		"font_size": 16,
		"name": "Poison"	},
	"terminal": {  # For computer terminals/consoles
		"color": Color(0.2, 0.9, 0.2),  # Bright green
		"font": preload("res://assets/fonts/ff-path-spect/FfPathSpect-4nKGl.ttf"),  # Would be preload("res://assets/fonts/digital_font.ttf")
		"font_size": 14,
		"background": Color(0.05, 0.05, 0.05, 0.95),  # Almost black
		"name": "Terminal"
	},
	"sign": {  # For message boards, signs, etc.
		"color": Color(0.1, 0.1, 0.1),  # Dark text
		"font": null,  # Would be preload("res://assets/fonts/handwritten_font.ttf")
		"font_size": 16,
		"background": Color(0.95, 0.95, 0.8, 1.0),  # Parchment/paper color
		"name": "Sign"
	}
}

# Constants
const scr_debug: bool = true
var debug: bool = false

# Signals from Dialogue Manager
signal dialogue_action(action_value)
signal dialogue_signal(signal_name, signal_args)

# Custom signals
signal speaker_changed(character_id)
signal encounter_response_selected(response_index)

func _ready():
	debug = scr_debug or GameController.sys_debug if Engine.has_singleton("GameController") else scr_debug
	if debug: print("Encounter Dialogue Balloon initialized")
	
	# Hide UI elements initially
	balloon.hide()
	dialogue_label.hide()
	responses.hide()
	
	# Connect to necessary signals
	dialogue_label.finished_typing.connect(_on_dialogue_label_finished_typing)
	
	# Hide templates
	response_template.hide()
	participant_template.hide()
	
	# Add to dialogue balloon group for management
	add_to_group("dialogue_balloon")

func start(encounter_id, dialogue_resource: DialogueResource, title: String, temporary_states: Array = []) -> void:
	self.dialogue = dialogue_resource
	self.temporary_game_states = temporary_states
	self.encounter_id = encounter_id
	
	# Get list of participants
	_load_participants()
	
	# Show the balloon
	balloon.show()
	dialogue_label.show()
	dialogue_label.type_out()
	
	# Start the dialogue
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, title)
	
	# Update UI for any participants
	_update_participants_list()

func _load_participants():
	# This would load participant info from the encounter
	var encounter_manager = get_node_or_null("/root/EncounterManager")
	if encounter_manager:
		var encounter = encounter_manager.get_encounter(encounter_id)
		if encounter:
			for participant in encounter.participant_nodes:
				var character_id = participant.character_id
				var character_name = participant.character_name
				var portrait = participant.portrait if participant.get("portrait") else null
				
				participants[character_id] = {
					"name": character_name,
					"portrait": portrait,
					"node": participant
				}
			
			if debug: print("Loaded ", participants.size(), " participants for encounter")

func _update_participants_list():
	# Clear current list
	for child in participants_list.get_children():
		child.queue_free()
	
	# Add each participant
	for character_id in participants:
		var data = participants[character_id]
		
		# Create a new participant entry
		var entry = participant_template.duplicate()
		entry.visible = true
		
		# Set name and portrait
		var name_label = entry.get_node("HBox/ParticipantName")
		name_label.text = data.name
		
		var portrait = entry.get_node("HBox/PortraitSmall")
		if data.portrait:
			portrait.texture = data.portrait
		
		# Highlight the current speaker
		if character_id == current_speaker_id:
			entry.modulate = Color(1.0, 0.9, 0.3)
		
		# Add to list
		participants_list.add_child(entry)

func _on_response_selected(response: DialogueResponse) -> void:
	encounter_response_selected.emit(response.index)
	
	# Handle normal dialogue progression
	var is_final = _on_response_chosen(response)
	if is_final:
		_close()

func _on_dialogue_manager_dialogue_ended(_resource) -> void:
	_close()

func _on_speaker_change(character_id: String) -> void:
	if character_id == current_speaker_id:
		return
		
	current_speaker_id = character_id

	# For empty speaker or "narrator", use default style
	if character_id.is_empty() or character_id == "narrator":
		speaker_name.text = "Narrator"
		portrait_rect.texture = null
		speaker_badge.self_modulate = Color(0.3, 0.7, 0.3)  # Default green
		
		# Reset to default styling
		dialogue_label.remove_theme_font_override("normal_font")
		dialogue_label.remove_theme_font_size_override("normal_font_size")
		dialogue_label.remove_theme_color_override("default_color")
		dialogue_label.remove_theme_stylebox_override("normal")
	# Otherwise apply custom styling for specific speakers
	elif character_styles.has(character_id):
		var style = character_styles[character_id]
		speaker_name.text = style.name if style.has("name") else character_id.capitalize()
		
		# Apply portrait
		if participants.has(character_id) and participants[character_id].portrait:
			portrait_rect.texture = participants[character_id].portrait
		else:
			portrait_rect.texture = null
			
		# Apply styling
		speaker_badge.self_modulate = style.color
		
		# Apply text styling
		if style.has("font") and style.font:
			dialogue_label.add_theme_font_override("normal_font", style.font)
		
		if style.has("font_size"):
			dialogue_label.add_theme_font_size_override("normal_font_size", style.font_size)
		
		dialogue_label.add_theme_color_override("default_color", style.color)
		
		# Apply background if specified
		if style.has("background") and style.background:
			var panel_style = StyleBoxFlat.new()
			panel_style.bg_color = style.background
			panel_style.corner_radius_top_left = 5
			panel_style.corner_radius_top_right = 5
			panel_style.corner_radius_bottom_left = 5
			panel_style.corner_radius_bottom_right = 5
			dialogue_label.add_theme_stylebox_override("normal", panel_style)
	# For unnamed speakers, generate basic styling
	else:
		speaker_name.text = character_id.capitalize()
		portrait_rect.texture = null
		
		# Set badge color
		var character_color = _get_character_color(character_id)
		speaker_badge.self_modulate = character_color
		
		# Apply basic text styling
		dialogue_label.add_theme_color_override("default_color", character_color.lightened(0.3))
	
	# Update participants list
	_update_participants_list()
	
	# Emit signal
	speaker_changed.emit(character_id)

func _get_character_color(character_id: String) -> Color:
	# Generate a consistent color for each character
	# This gives each speaker a distinct visual identity
	
	# Check if we have a predefined color
	if character_styles.has(character_id):
		return character_styles[character_id].color
	
	# Generate a color based on the character_id hash
	var hash_val = character_id.hash()
	var r = (hash_val % 255) / 255.0
	var g = ((hash_val / 255) % 255) / 255.0
	var b = ((hash_val / 255 / 255) % 255) / 255.0
	
	# Make sure it's not too dark
	var min_value = 0.3
	r = max(r, min_value)
	g = max(g, min_value)
	b = max(b, min_value)
	
	return Color(r, g, b)

func _on_dialogue_label_finished_typing() -> void:
	# Ready for the player to continue or choose a response
	is_waiting_for_input = true

func _on_response_chosen(response: DialogueResponse) -> bool:
	response.dialogue_choice_made.emit()
	return response.choices.size() == 0

func _on_next_pressed():
	if not is_waiting_for_input:
		# Skip typing animation
		dialogue_label.skip_typing()
		return
	
	if dialogue_label.get_remaining_text() != "":
		dialogue_label.skip_typing()
		return
	
	if responses.get_child_count() > 0:
		return
	
	# Continue to next line of dialogue
	DialogueManager.next()

func _close() -> void:
	animation_player.play("close")
	
	# Close after animation finishes
	await animation_player.animation_finished
	balloon.hide()
	
	# Clean up
	dialogue = null
	temporary_game_states = []
	is_waiting_for_input = false
	queue_free()

func _process(_delta):
	# Only process inputs when the balloon is visible
	if not balloon.visible:
		return
		
	# Parse dialogue text for speaker tags
	if is_waiting_for_input and dialogue_label.text.begins_with("[speaker="):
		var speaker_tag = dialogue_label.text.split("]")[0]
		var character_id = speaker_tag.substr(9)  # Remove [speaker=
		
		# Update the speaker
		_on_speaker_change(character_id)
		
		# Remove the tag from the displayed text
		var new_text = dialogue_label.text.substr(speaker_tag.length() + 1)
		dialogue_label.text = new_text
		
	# Press enter to advance
	if Input.is_action_just_pressed("ui_accept") and balloon.visible:
		_on_next_pressed()
