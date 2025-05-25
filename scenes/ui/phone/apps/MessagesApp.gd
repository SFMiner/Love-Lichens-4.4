extends Control

# --- Node References ---
@onready var conversation_list_view: VBoxContainer = $ConversationListView
@onready var chat_view: Control = $ChatView
@onready var chat_back_button: Button = $ChatView/ChatHeader/ChatBackButton
@onready var chat_title_label: Label = $ChatView/ChatHeader/ChatTitleLabel
@onready var message_stream_label: RichTextLabel = $ChatView/ScrollContainer/MessageStreamLabel
@onready var scroll_container: ScrollContainer = $ChatView/ScrollContainer
@onready var dialogue_runner: Node = $DialogueRunner # Added
@onready var choice_button_container: VBoxContainer = $ChatView/ChoiceButtonContainer # Added

# --- Constants ---
const PLAYER_CHARACTER_NAME = "Adam" # Added

# --- Style Constants ---
const STYLE_TAG_COLORS = {
	"default": "", # Will default to NPC/Player base colors if empty
	"player": "[color=#D0D0FF]",
	"npc_default": "[color=#E0E0E0]",
	"spore_data": "[color=#A0FFA0]", # Light green for spore/oud
	"system_error": "[color=#FF8080]", # Reddish for errors
}

# Base colors if no specific style_tag color is found or applicable
const BASE_NPC_COLOR_TAG = "[color=#E0E0E0]" # Default NPC
const BASE_PLAYER_COLOR_TAG = "[color=#D0D0FF]" # Default Player

# --- State ---
var current_view: String = "list" # "list" or "chat"
var current_conversation_id: String = ""

# --- Test Conversation Data ---
# Keys should now match character_id directly, e.g., "poison" instead of "poison_chat"
# This data will primarily serve as a fallback or for characters without dialogue files.
const TEST_CONVERSATIONS = {
	"poison": {
		"title": "Poison", # This title could also be dynamically fetched if needed
		"messages": [
			{"sender": "Poison", "character_id": "poison", "text": "Hey Adam, you there?", "timestamp": "10:30 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "character_id": "adam", "text": "Yeah, what's up?", "timestamp": "10:31 AM", "is_player": true, "style_tag": "player"},
			{"sender": "Poison", "character_id": "poison", "text": "Found that weird glowing lichen we saw yesterday. It's pulsating.", "timestamp": "10:32 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Poison", "character_id": "poison", "text": "Actually, scratch that. It's giving off a faint green glow now.", "timestamp": "10:33 AM", "is_player": false, "style_tag": "spore_data"},
			{"sender": "Adam", "character_id": "adam", "text": "Whoa, seriously? Where are you?", "timestamp": "10:34 AM", "is_player": true, "style_tag": "player"},
		]
	},
	"erik": {
		"title": "Erik",
		"messages": [
			{"sender": "Erik", "character_id": "erik", "text": "Dude, did you finish the history assignment?", "timestamp": "11:00 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "character_id": "adam", "text": "Almost... just the last paragraph.", "timestamp": "11:01 AM", "is_player": true, "style_tag": "player"},
			{"sender": "Erik", "character_id": "erik", "text": "Lucky. I'm still stuck on the causes of the Franco-Prussian War.", "timestamp": "11:02 AM", "is_player": false, "style_tag": "npc_default"},
		]
	},
	"lab_group": { # Assuming "lab_group" could be a character_id for a group chat
		"title": "Lab Group",
		"messages": [
			# Note: For group chats, character_id in messages might need special handling
			# For now, using individual character_ids if they are known senders in a group
			{"sender": "Sarah", "character_id": "sarah", "text": "Is anyone else having trouble with experiment 3?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "character_id": "adam", "text": "Yeah, my results were way off.", "timestamp": "Yesterday", "is_player": true, "style_tag": "player"},
			{"sender": "Mike", "character_id": "mike", "text": "Same here. Maybe we should compare notes before class?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "character_id": "adam", "text": "Good idea.", "timestamp": "Today", "is_player": true, "style_tag": "player"},
		]
	}
}


func _ready():
	_populate_conversation_list()
	chat_back_button.pressed.connect(Callable(self, "_show_conversation_list_view"))

	# Dialogue Runner signal connections
	if dialogue_runner:
		dialogue_runner.dialogue_started.connect(Callable(self, "_on_dialogue_started"))
		dialogue_runner.line_received.connect(Callable(self, "_on_dialogue_line_received"))
		dialogue_runner.choices_presented.connect(Callable(self, "_on_dialogue_choices_presented"))
		dialogue_runner.dialogue_finished.connect(Callable(self, "_on_dialogue_finished"))
	else:
		print("MessagesApp: ERROR - DialogueRunner node not found.")

	_show_conversation_list_view() # Initial view setup

func _populate_conversation_list():
	# Clear any existing buttons (e.g., if this function is called multiple times)
	for child in conversation_list_view.get_children():
		child.queue_free()

	var rel_sys = get_node_or_null("/root/RelationshipSystem")
	if not rel_sys:
		print("MessagesApp: ERROR - RelationshipSystem not found.")
		# Fallback: Populate from TEST_CONVERSATIONS if RelationshipSystem is missing
		_populate_from_test_conversations_only()
		return

	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if not character_loader:
		print("MessagesApp: ERROR - CharacterDataLoader not found. Cannot get character names for buttons.")
		# Fallback: Populate from TEST_CONVERSATIONS if CharacterDataLoader is missing
		_populate_from_test_conversations_only()
		return

	var relationships_data = {}
	if rel_sys.has_method("get_relationships"):
		relationships_data = rel_sys.get_relationships()
	elif "relationships" in rel_sys: # Assuming 'relationships' is a Dictionary
		relationships_data = rel_sys.relationships
	else:
		print("MessagesApp: WARNING - RelationshipSystem has no get_relationships() method or 'relationships' property.")
		_populate_from_test_conversations_only()
		return
		
	if relationships_data.is_empty():
		print("MessagesApp: INFO - No relationships found in RelationshipSystem. Checking TEST_CONVERSATIONS.")
		_populate_from_test_conversations_only()
		return

	for char_id_key in relationships_data:
		var char_id = char_id_key # Assuming keys are character_ids
		var char_rel_data = relationships_data[char_id]
		
		var button_text = char_id.capitalize() # Default
		var character_data_resource = character_loader.get_character(char_id)
		if character_data_resource and character_data_resource.name and not character_data_resource.name.is_empty():
			button_text = character_data_resource.name
		elif char_rel_data.has("name") and not char_rel_data.name.is_empty(): # Fallback to name from relationship data
			button_text = char_rel_data.name
			
		# Ensure a TEST_CONVERSATIONS entry exists if we want to use its title or messages as fallback
		# For Dialogue Manager integration, this might be less critical if all convos are dialogue-driven
		if not TEST_CONVERSATIONS.has(char_id):
			TEST_CONVERSATIONS[char_id] = {
				"title": button_text, # Use the best name we found
				"messages": [] # Initially empty, dialogue will populate
			}
		elif not TEST_CONVERSATIONS[char_id].has("title"): # Ensure title exists
			TEST_CONVERSATIONS[char_id]["title"] = button_text

		var button = Button.new()
		button.text = button_text
		button.name = "ConvButton_" + char_id
		button.pressed.connect(Callable(self, "_on_conversation_selected").bind(char_id))
		conversation_list_view.add_child(button)
		print("MessagesApp: Added conversation button for (RelSys): ", char_id)

func _populate_from_test_conversations_only():
	print("MessagesApp: Populating conversation list from TEST_CONVERSATIONS only (fallback).")
	var character_loader = get_node_or_null("/root/CharacterDataLoader")

	for conversation_key in TEST_CONVERSATIONS:
		var button_text = conversation_key.capitalize()
		if character_loader:
			var character_data = character_loader.get_character(conversation_key)
			if character_data and character_data.name and not character_data.name.is_empty():
				button_text = character_data.name
		elif TEST_CONVERSATIONS[conversation_key].has("title"):
			 button_text = TEST_CONVERSATIONS[conversation_key].title

		var button = Button.new()
		button.text = button_text
		button.name = "ConvButton_" + conversation_key
		button.pressed.connect(Callable(self, "_on_conversation_selected").bind(conversation_key))
		conversation_list_view.add_child(button)
		print("MessagesApp: Added conversation button for (Test Data Fallback): ", conversation_key)

func _show_conversation_list_view():
	conversation_list_view.show()
	chat_view.hide()
	message_stream_label.clear() # Clear messages when going back to list
	_clear_choices() # Clear any leftover choice buttons
	current_view = "list"
	current_conversation_id = ""
	if dialogue_runner.current_dialogue_title != "":
		dialogue_runner.stop_dialogue() # Stop any active dialogue
	print("MessagesApp: Switched to Conversation List View")

func _show_chat_view_common_setup(conversation_id: String):
	conversation_list_view.hide()
	chat_view.show()
	message_stream_label.clear() # Clear previous messages
	current_view = "chat"
	current_conversation_id = conversation_id

	# Set chat title using CharacterDataLoader or TEST_CONVERSATIONS
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		var char_data = character_loader.get_character(conversation_id)
		if char_data and char_data.name and not char_data.name.is_empty():
			chat_title_label.text = char_data.name
		elif TEST_CONVERSATIONS.has(conversation_id) and TEST_CONVERSATIONS[conversation_id].has("title"):
			chat_title_label.text = TEST_CONVERSATIONS[conversation_id]["title"]
		else:
			chat_title_label.text = conversation_id.capitalize()
	elif TEST_CONVERSATIONS.has(conversation_id) and TEST_CONVERSATIONS[conversation_id].has("title"):
		chat_title_label.text = TEST_CONVERSATIONS[conversation_id]["title"]
	else:
		chat_title_label.text = conversation_id.capitalize()

	print("MessagesApp: Switched to Chat View for: ", conversation_id)

func _on_conversation_selected(conversation_id: String):
	_show_chat_view_common_setup(conversation_id)

	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if not character_loader:
		print("MessagesApp: ERROR - CharacterDataLoader not found. Cannot start dialogue.")
		_fallback_to_test_conversation(conversation_id, "CharacterDataLoader not found.")
		return

	var char_data = character_loader.get_character(conversation_id)
	if char_data and char_data.dialogue_file and not char_data.dialogue_file.is_empty() and ResourceLoader.exists(char_data.dialogue_file):
		print("MessagesApp: Starting dialogue for ", conversation_id, " with file: ", char_data.dialogue_file, " and title: ", char_data.initial_dialogue_title)
		message_stream_label.text = "" # Clear any previous messages
		dialogue_runner.start_dialogue(char_data.dialogue_file, char_data.initial_dialogue_title)
	else:
		var reason = "No valid dialogue file specified"
		if char_data and (not char_data.dialogue_file or char_data.dialogue_file.is_empty()):
			reason = "Dialogue file path is empty for " + conversation_id
		elif char_data and not ResourceLoader.exists(char_data.dialogue_file):
			reason = "Dialogue file not found at path: " + char_data.dialogue_file
		elif not char_data:
			reason = "Character data not found for " + conversation_id
			
		print("MessagesApp: INFO - Cannot start dialogue for ", conversation_id, ". Reason: ", reason)
		_fallback_to_test_conversation(conversation_id, reason)

func _fallback_to_test_conversation(conversation_id: String, reason: String):
	message_stream_label.clear()
	add_message("System", "system", "Dialogue error: " + reason, "Now", false, "system_error")
	if TEST_CONVERSATIONS.has(conversation_id):
		print("MessagesApp: Falling back to TEST_CONVERSATIONS for ", conversation_id)
		load_conversation_by_tags([conversation_id]) # Load static messages
	else:
		add_message("System", "system", "No fallback conversation data found for " + conversation_id, "Now", false, "system_error")


func _get_character_id_from_name(char_name: String) -> String:
	# This is a helper to map dialogue speaker names to character_ids for avatars.
	# Assumes character_ids are lowercase versions of names if not found directly.
	# This might need to be more robust depending on actual character data setup.
	if char_name.is_empty():
		return "unknown" # Or some default
	
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if character_loader:
		# This is a simplified lookup. If CharacterDataLoader stores characters by ID
		# and those IDs are consistently lowercase versions of names, this might work.
		# A more robust way would be to iterate through all characters in CharacterDataLoader
		# and match by their 'name' property.
		var potential_id = char_name.to_lower()
		var char_data = character_loader.get_character(potential_id)
		if char_data and char_data.name.to_lower() == char_name.to_lower() : # Check if name matches
			return char_data.id # Return the actual ID (which might have different casing)
		
		# Fallback: Iterate if direct lowercase lookup fails or to be more robust
		# This part is commented out for now as it could be slow if many characters.
		# Consider optimizing CharacterDataLoader for name lookups if needed.
		# var all_chars = character_loader.get_all_characters() # Assuming such a method exists
		# for id in all_chars:
		#   if all_chars[id].name.to_lower() == char_name.to_lower():
		#     return id
	
	# If no match, return a lowercase version as a guess, or a default.
	return char_name.to_lower()


# --- Dialogue Manager Signal Handlers ---

func _on_dialogue_started(title: String):
	print("MessagesApp: Dialogue started - ", title)
	message_stream_label.clear() # Clear messages when new dialogue starts
	_clear_choices()

func _on_dialogue_line_received(line: Dictionary): # DialogueLine is a Dictionary
	var character_name = line.get("character", "Unknown Speaker")
	var text = line.get("text", "")
	var tags = line.get("tags", []) # Array of strings
	
	# Timestamp - Dialogue Manager doesn't provide this.
	var timestamp = Time.get_datetime_string_from_system(false, true).substr(9, 5) # HH:MM format
	if timestamp.is_empty(): timestamp = "Now" # Fallback

	var is_player = (character_name == PLAYER_CHARACTER_NAME)
	
	var character_id_for_avatar = _get_character_id_from_name(character_name)
	if character_name == PLAYER_CHARACTER_NAME: # Ensure player avatar uses consistent ID e.g. "adam"
		character_id_for_avatar = PLAYER_CHARACTER_NAME.to_lower()

	# Determine style_tag from line tags if any, otherwise default
	var style_tag = "default" # Default
	for tag in tags:
		if tag.begins_with("style:"):
			style_tag = tag.replace("style:", "").strip_edges()
			break # Use the first style tag found
		elif STYLE_TAG_COLORS.has(tag): # Allow direct tag matching for styles
			style_tag = tag
			break
	
	# If it's the player, but no specific player style tag found, ensure it uses "player"
	if is_player and style_tag == "default" and STYLE_TAG_COLORS.has("player"):
		style_tag = "player"
	# If it's an NPC, and no specific NPC style tag found, ensure it uses "npc_default"
	elif not is_player and style_tag == "default" and STYLE_TAG_COLORS.has("npc_default"):
		style_tag = "npc_default"

	add_message(character_name, character_id_for_avatar, text, timestamp, is_player, style_tag)

func _on_dialogue_choices_presented(choices: Array): # Array of Dictionaries
	_clear_choices()
	if choices.is_empty():
		choice_button_container.hide()
		return

	choice_button_container.show()
	for i in range(choices.size()):
		var choice_data = choices[i] # This is a Dictionary
		var choice_text = choice_data.get("text", "Choice " + str(i + 1))
		# DialogueManager provides choice_id as part of the choice Dictionary if you add it in the dialogue file (e.g. #id:my_choice_id)
		# otherwise, it uses the index. The addon's `make_choice` expects the index if ID is not explicitly set.
		var choice_id_or_index = choice_data.get("id", i) # Prefer explicit ID, fallback to index
		
		var button = Button.new()
		button.text = choice_text
		# The DialogueRunner's make_choice function expects an integer index.
		# If your choices have string IDs, you'd need to map them back or adjust DialogueRunner.
		# For simplicity, we'll assume DialogueRunner expects the index here or a numeric ID.
		# The signal from Dialogue Manager provides choice dictionaries that include an 'index' field.
		var choice_index = choice_data.get("index", i) # Use the provided index

		button.pressed.connect(Callable(self, "_on_player_choice_selected").bind(choice_index))
		choice_button_container.add_child(button)

func _on_player_choice_selected(choice_idx: int):
	_clear_choices()
	if dialogue_runner and dialogue_runner.has_method("make_choice"):
		dialogue_runner.make_choice(choice_idx)
	else:
		print("MessagesApp: ERROR - DialogueRunner not found or no make_choice method.")

func _on_dialogue_finished(title: String):
	print("MessagesApp: Dialogue finished - ", title)
	_clear_choices()
	# Optionally add a "Conversation Ended" message
	# add_message("System", "system", "Conversation ended.", "Now", false, "system_error")

func _clear_choices():
	for button in choice_button_container.get_children():
		button.queue_free()
	choice_button_container.hide()

# --- Existing add_message function (modified slightly if needed) ---
func add_message(character_name_display: String, character_id_for_avatar: String, message_text: String, timestamp: String, is_player: bool, style_tag: String = "default"):
	var text_color_tag = STYLE_TAG_COLORS.get(style_tag, "")
	
	# If style_tag is "default" or not found, or if its color is empty, use base player/NPC colors
	if text_color_tag == "":
		text_color_tag = BASE_PLAYER_COLOR_TAG if is_player else BASE_NPC_COLOR_TAG
	
	var alignment_tag_open = ""
	var alignment_tag_close = ""
	if is_player:
		alignment_tag_open = "[p align=right]"
		alignment_tag_close = "[/p]"
	else:
		alignment_tag_open = "[p align=left]" # Default, but explicit
		alignment_tag_close = "[/p]"

	var avatar_tag = ""
	# Use character_id_for_avatar for fetching avatar
	if character_id_for_avatar and not character_id_for_avatar.is_empty():
		var character_loader = get_node_or_null("/root/CharacterDataLoader") # Use get_node_or_null for safety
		if character_loader:
			var char_data = character_loader.get_character(character_id_for_avatar)
			if char_data and char_data.portrait_path and not char_data.portrait_path.is_empty():
				avatar_tag = "[img=40x40]" + char_data.portrait_path + "[/img] "
			#else:
				#print("MessagesApp: Avatar: Character data or portrait path not found for ID: ", character_id_for_avatar)
		#else:
			#print("MessagesApp: Avatar: CharacterDataLoader not found.")

	var formatted_message_content = ""
	if not is_player: # Avatar on the left for NPC
		formatted_message_content += avatar_tag
	formatted_message_content += "[color=gray][" + timestamp + "][/color] " # Timestamp color fixed
	# Use character_name_display for the name in the message
	formatted_message_content += "[b]" + character_name_display + ":[/b] "
	formatted_message_content += message_text
	if is_player: # Avatar on the right for Player
		formatted_message_content += " " + avatar_tag # Add space before player avatar
	
	var final_message = alignment_tag_open + text_color_tag + formatted_message_content + "[/color]" + alignment_tag_close
	message_stream_label.append_text("\n" + final_message)

	await get_tree().create_timer(0.01).timeout # Ensure scroll updates after new text
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


# load_conversation_by_tags is now primarily a fallback for static content
func load_conversation_by_tags(tags: Array):
	# message_stream_label.clear() # Usually cleared by the calling function (_fallback_to_test_conversation)
	
	if tags.is_empty():
		print("Error: No tags provided to load_conversation_by_tags.")
		add_message("System", "system", "system", "No conversation ID provided.", "Now", false, "system_error")
		return

	var conversation_id_to_load = tags[0] # Assuming first tag is the conversation_id
	print("MessagesApp: Attempting to load static conversation data for ID: ", conversation_id_to_load)

	if TEST_CONVERSATIONS.has(conversation_id_to_load):
		var conversation_data = TEST_CONVERSATIONS[conversation_id_to_load]
		# Set title from test data if not already set by dialogue attempt
		if chat_title_label.text == conversation_id_to_load.capitalize() or chat_title_label.text == "Unknown Conversation":
			if conversation_data.has("title"):
				chat_title_label.text = conversation_data.title
				
		for message_data in conversation_data["messages"]:
			add_message(
				message_data.get("sender", "Unknown"),
				message_data.get("character_id", message_data.get("sender", "unknown").to_lower()), # Fallback for character_id for avatar
				message_data.get("text", "..."),
				message_data.get("timestamp", " "),
				message_data.get("is_player", false),
				message_data.get("style_tag", "default")
			)
	else:
		print("Error: No test data found for conversation_id: ", conversation_id_to_load)
		# Avoid adding message here if called from _fallback_to_test_conversation, as it already adds one.
		if current_view == "chat" and not dialogue_runner.current_dialogue_title: # Only add if not in an active dialogue attempt
			add_message("System", "system", "system", "Static conversation data not found for ID: " + conversation_id_to_load, "Now", false, "system_error")


# set_conversation_data is likely no longer needed if dialogues drive conversations.
# Kept for now in case of other uses, but may be deprecated/removed later.
func set_conversation_data(conversation_data):
	print("MessagesApp: Received conversation data via set_conversation_data (potentially deprecated): ", conversation_data)
	_show_chat_view_common_setup(conversation_data.get("id", "unknown_conv_id")) # Requires an ID in conversation_data

	if conversation_data and conversation_data.has("messages"):
		for message_entry in conversation_data["messages"]:
			add_message(
				message_entry.get("sender", "Unknown"),
				message_entry.get("character_id", message_entry.get("sender", "unknown").to_lower()),
				message_entry.get("text", "..."), 
				message_entry.get("timestamp", " "), 
				message_entry.get("is_player", false),
				message_entry.get("style_tag", "default")
			)
	else:
		add_message("System", "system", "system", "Received invalid conversation data via set_conversation_data.", "Now", false, "system_error")
