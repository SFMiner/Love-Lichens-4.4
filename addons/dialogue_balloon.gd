class_name DialogueBalloon extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## The dialogue resource
var resource: DialogueResource
## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			queue_free()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu


var character_fonts = {}
var character_colors = {}
var character_font_sizes = {}  # New dictionary for font sizes

# Map character names to font paths
#var character_fonts = {
#	"Nathan": "res://FfPathSpect-4nKGl.ttf",
#	"Player": "res://JaggedDreams-5XBv.ttf",
#	"Default": "res://CupOfSea-05qz.ttf"  # Default font
#}

# Store references to loaded fonts to avoid reloading
var loaded_fonts = {}



func _ready() -> void:

	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	# Set up default font as fallback
	var default_font_path = "res://assets/fonts/default_font.ttf"
	if ResourceLoader.exists(default_font_path):
		loaded_fonts["Default"] = load(default_font_path)
	
	# Load character fonts from CharacterDataLoader
	load_character_fonts()

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

# New function to load fonts from character data
func load_character_fonts() -> void:
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if not character_loader:
		print("Character Data Loader not found - using default fonts only")
		return
	
	# Access the loaded characters dictionary
	var characters = character_loader.characters
	print("Loading fonts for " + str(characters.size()) + " characters")
	
	for character_id in characters:
		var character_data = characters[character_id]
		
		# Check if character has a specified font
		if character_data.font_path and character_data.font_path != "":
			if ResourceLoader.exists(character_data.font_path):
				# Add to character_fonts dictionary
				character_fonts[character_id] = character_data.font_path
				# Load the font right away
				loaded_fonts[character_id] = load(character_data.font_path)
				print("Loaded font for " + character_id + ": " + character_data.font_path)
			else:
				print("Font path not found for " + character_id + ": " + character_data.font_path)
		
		# Store character color if specified
		if character_data.text_color:
			character_colors[character_id] = character_data.text_color

		character_font_sizes[character_id] = character_data.font_size
		var display_id = character_id.replace("_", " ")
		character_font_sizes[display_id] = character_data.font_size

		if character_data.name and character_data.name != "":
			character_font_sizes[character_data.name.to_lower()] = character_data.font_size

	print("Loaded " + str(loaded_fonts.size()) + " character fonts")


func _on_dialogue_line_started(dialogue_line):
	# Get the character name from the dialogue line
	var character_name = "Default"
	
	if dialogue_line.character and !dialogue_line.character.is_empty():
		character_name = dialogue_line.character
		print("Character detected from dialogue_line.character: ", character_name)
		
	apply_font_for_character(character_name)
	
	# The character name should be the part before the colon in the dialogue text
	if ":" in dialogue_line.text:
		character_name = dialogue_line.text.split(":")[0].strip_edges()
	
	# Apply the appropriate font
	apply_font_for_character(character_name)

# Apply font based on character name
func apply_font_for_character(character_name):
	if not dialogue_label:
		return
		
	print("Applying font for character: ", character_name)
	var font_to_use = loaded_fonts.get("Default")
	var color_to_use = Color(1, 1, 1, 1)  # Default white
	var font_size = 20  # Default font size	
	# Try multiple ways to match the character
	var character_id = character_name.to_lower()  # First try: direct lowercase match
	var character_id_normalized = character_id.replace(" ", "_")  # Second try: replace spaces with underscores
	
	print("Trying to match character name: ", character_name)
	print("Normalized ID for lookup: ", character_id_normalized)
	print("Available loaded fonts: ", loaded_fonts.keys())
	
	# Try to find font - first with original character_id, then with normalized version
	if character_id in loaded_fonts:
		font_to_use = loaded_fonts[character_id]
		print("Found font using direct match: ", character_id)
	elif character_id_normalized in loaded_fonts:
		font_to_use = loaded_fonts[character_id_normalized]
		print("Found font using normalized ID: ", character_id_normalized)
	else:
		print("No font match found, using default font")
	
	# Same approach for colors
	if character_id in character_colors:
		color_to_use = character_colors[character_id]
	elif character_id_normalized in character_colors:
		color_to_use = character_colors[character_id_normalized]

	# Look up font size
	if character_id in character_font_sizes:
		font_size = character_font_sizes[character_id]
	elif character_id_normalized in character_font_sizes:
		font_size = character_font_sizes[character_id_normalized]

	# Apply font, color and size to the dialogue label
	if font_to_use:
		dialogue_label.add_theme_font_override("normal_font", font_to_use)
	dialogue_label.add_theme_color_override("default_color", color_to_use)
	dialogue_label.add_theme_font_size_override("normal_font_size", font_size)
	
func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	print("Start method called")
	print("Dialogue resource: ", dialogue_resource)
	print("Title: ", title)
	
	resource = dialogue_resource
	temporary_game_states = [self] + extra_game_states
	
	print("About to get dialogue line")
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	print("Dialogue line received: ", self.dialogue_line)
	
	if self.dialogue_line:
		print("Dialogue text: ", self.dialogue_line.text)
		_on_dialogue_line_started(self.dialogue_line)
		print("Font applied for character")
	else:
		print("No dialogue line returned!")


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	print("Apply dialogue line called")
	
	
	if dialogue_line and dialogue_line.text:
		_on_dialogue_line_started(dialogue_line)
	
	mutation_cooldown.stop()
	
	print("Character: ", dialogue_line.character)
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	print("Character: ", dialogue_line.character)
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line
	print("Dialogue text in apply: ", dialogue_line.text)
	
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	print("About to show balloon")
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	print("Dialogue label shown")
	if not dialogue_line.text.is_empty():
		print("Starting typing")
		dialogue_label.type_out()
		print("Waiting for typing to finish")
		await dialogue_label.finished_typing
		print("Typing finished")

	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)
	_on_dialogue_line_started(self.dialogue_line)  # Add this line

#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation):
	print(mutation)
	
	if mutation.has("expression") and mutation["expression"].size() >= 3:
		var expr = mutation["expression"][2]
		if expr is Dictionary and expr.get("type", "") == "function":
			var func_name = expr.get("function", "")

			if func_name == "move_character_to_marker":
				var args = expr.get("value", [])
				if args.size() >= 2:
					var character_id = args[0][0].get("value", "")
					var target_marker = args[1][0].get("value", "")
					CutsceneManager.move_character_to_marker(character_id, target_marker)
					return
		
			elif func_name == "wait_for_movements": 
				if CutsceneManager:
					return CutsceneManager.wait_for_movements()
				
				# This will pause the dialogue until all movements complete


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
