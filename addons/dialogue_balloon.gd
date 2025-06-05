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

# Character font and styling dictionaries
var character_fonts = {}
var character_colors = {}
var character_font_sizes = {}

# Store references to loaded fonts to avoid reloading
var loaded_fonts = {}

const scr_debug :bool = true
var debug

func _ready() -> void:
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	# Set up default font as fallback
	var default_font_path = "res://assets/fonts/default_font.ttf"
	if ResourceLoader.exists(default_font_path):
		loaded_fonts["Default"] = load(default_font_path)
	
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


# Enhanced character name extraction and font application
func _on_dialogue_line_started(dialogue_line: DialogueLine):
	var _fname = "_on_dialogue_line_started"
	
	# Extract character name with multiple fallback methods
	var character_name = ""
	
	# Method 1: Use dialogue_line.character if available
	if dialogue_line.character and not dialogue_line.character.is_empty():
		character_name = dialogue_line.character
		if debug: print(GameState.script_name_tag(self, _fname) + "Character from dialogue_line.character: '", character_name, "'")
	
	# Method 2: Extract from dialogue text if character field is empty
	if character_name.is_empty() and ":" in dialogue_line.text:
		character_name = dialogue_line.text.split(":")[0].strip_edges()
		if debug: print(GameState.script_name_tag(self, _fname) + "Character extracted from text: '", character_name, "'")
	
	# Method 3: Use current character ID from dialog system as fallback
	if character_name.is_empty():
		var dialog_system = get_node_or_null("/root/DialogSystem")
		if dialog_system and dialog_system.current_character_id != "":
			character_name = dialog_system.current_character_id
			if debug: print(GameState.script_name_tag(self, _fname) + "Character from dialog system: '", character_name, "'")
	
	if character_name.is_empty():
		character_name = "Default"
		if debug: print(GameState.script_name_tag(self, _fname) + "No character found, using Default")
	
	# Apply the appropriate font
	apply_font_for_character(character_name)

# Enhanced font application with better character matching
func apply_font_for_character(character_name: String):
	var _fname = "apply_font_for_character"
	if not dialogue_label:
		if debug: print(GameState.script_name_tag(self, _fname) + "No dialogue label available")
		return

	var character_id = character_name.to_lower().replace(" ","_")

		
	if debug: print(GameState.script_name_tag(self, _fname) + "Applying font for character: '", character_name, "' with character_id '" + character_id + "'")

	var character = GameState.get_npc_by_id(character_id) 
	
	# Default values
	var font_to_use = loaded_fonts.get("Default")
	var color_to_use = Color(1, 1, 1, 1)  # Default white
	var font_size = 20  # Default font size
	
	if character.font_path:
		font_to_use = load(character.font_path)
	if character.font_color:
		color_to_use = character.font_color
	if character.font_size:
		font_size = character.font_size
	
	dialogue_label.add_theme_font_override("normal_font", font_to_use)
	if debug: print(GameState.script_name_tag(self, _fname) + "Applied font: ", font_to_use.resource_path if font_to_use.resource_path else "built-in")
	
	dialogue_label.add_theme_color_override("default_color", color_to_use)
	dialogue_label.add_theme_font_size_override("normal_font_size", font_size)
	if debug: print(GameState.script_name_tag(self, _fname) + "Applied color: ", color_to_use, " and size: ", font_size)

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
	var _fname = "start"
	if debug: print(GameState.script_name_tag(self, _fname) + "Start method called")
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue resource: ", dialogue_resource)
	if debug: print(GameState.script_name_tag(self, _fname) + "Title: ", title)
	
	resource = dialogue_resource
	temporary_game_states = [self] + extra_game_states
	
	if debug: print(GameState.script_name_tag(self, _fname) + "About to get dialogue line")
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue line received: ", self.dialogue_line)
	
	if self.dialogue_line:
		if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue text: ", self.dialogue_line.text)
		_on_dialogue_line_started(self.dialogue_line)
		if debug: print(GameState.script_name_tag(self, _fname) + "Font applied for character")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "No dialogue line returned!")

## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	var _fname = "apply_dialogue_line"
	if debug: print(GameState.script_name_tag(self, _fname) + "Apply dialogue line called")
	
	# Apply character styling first
	if dialogue_line and dialogue_line.text:
		_on_dialogue_line_started(dialogue_line)
	
	mutation_cooldown.stop()
	
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue text in apply: ", dialogue_line.text)
	
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	if debug: print(GameState.script_name_tag(self, _fname) + "About to show balloon")
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if debug: print(GameState.script_name_tag(self, _fname) + "Dialogue label shown")
	if not dialogue_line.text.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "Starting typing")
		dialogue_label.type_out()
		if debug: print(GameState.script_name_tag(self, _fname) + "Waiting for typing to finish")
		await dialogue_label.finished_typing
		if debug: print(GameState.script_name_tag(self, _fname) + "Typing finished")

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
	var _fname = "next"
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)
	# Apply character styling when moving to next line
	if self.dialogue_line:
		_on_dialogue_line_started(self.dialogue_line)

#region Signals

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()

func _on_mutated(mutation):
	var _fname = "_on_mutated"
	if debug: print(GameState.script_name_tag(self, _fname) + str(mutation))
	
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
