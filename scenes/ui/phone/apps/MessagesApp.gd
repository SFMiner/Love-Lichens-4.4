extends Control

# --- Node References ---
@onready var conversation_list_view: VBoxContainer = $ConversationListView
@onready var chat_view: Control = $ChatView
@onready var chat_back_button: Button = $ChatView/ChatHeader/ChatBackButton
@onready var chat_title_label: Label = $ChatView/ChatHeader/ChatTitleLabel
@onready var message_stream_label: RichTextLabel = $ChatView/ScrollContainer/MessageStreamLabel
@onready var scroll_container: ScrollContainer = $ChatView/ScrollContainer

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
const TEST_CONVERSATIONS = {
	"poison_chat": {
		"title": "Poison",
		"messages": [
			{"sender": "Poison", "text": "Hey Adam, you there?", "timestamp": "10:30 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "text": "Yeah, what's up?", "timestamp": "10:31 AM", "is_player": true, "style_tag": "player"},
			{"sender": "Poison", "text": "Found that weird glowing lichen we saw yesterday. It's pulsating.", "timestamp": "10:32 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Poison", "text": "Actually, scratch that. It's giving off a faint green glow now.", "timestamp": "10:33 AM", "is_player": false, "style_tag": "spore_data"},
			{"sender": "Adam", "text": "Whoa, seriously? Where are you?", "timestamp": "10:34 AM", "is_player": true, "style_tag": "player"},
		]
	},
	"erik_chat": {
		"title": "Erik",
		"messages": [
			{"sender": "Erik", "text": "Dude, did you finish the history assignment?", "timestamp": "11:00 AM", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "text": "Almost... just the last paragraph.", "timestamp": "11:01 AM", "is_player": true, "style_tag": "player"},
			{"sender": "Erik", "text": "Lucky. I'm still stuck on the causes of the Franco-Prussian War.", "timestamp": "11:02 AM", "is_player": false, "style_tag": "npc_default"},
		]
	},
	"lab_group_chat": {
		"title": "Lab Group",
		"messages": [
			{"sender": "Sarah", "text": "Is anyone else having trouble with experiment 3?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "text": "Yeah, my results were way off.", "timestamp": "Yesterday", "is_player": true, "style_tag": "player"},
			{"sender": "Mike", "text": "Same here. Maybe we should compare notes before class?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
			{"sender": "Adam", "text": "Good idea.", "timestamp": "Today", "is_player": true, "style_tag": "player"},
		]
	}
}


func _ready():
	var conv_buttons = {
		"ConvButton_Poison": "poison_chat",
		"ConvButton_Erik": "erik_chat",
		"ConvButton_LabGroup": "lab_group_chat"
	}
	for button_name in conv_buttons:
		var button_node = conversation_list_view.get_node(button_name)
		if button_node is Button:
			var conv_id = conv_buttons[button_name]
			button_node.pressed.connect(Callable(self, "_on_conversation_selected").bind(conv_id))
		else:
			print("Warning: Conversation button not found: ", button_name)
			
	chat_back_button.pressed.connect(Callable(self, "_show_conversation_list_view"))
	_show_conversation_list_view()


func _show_conversation_list_view():
	conversation_list_view.show()
	chat_view.hide()
	message_stream_label.clear()
	current_view = "list"
	current_conversation_id = ""
	print("MessagesApp: Switched to Conversation List View")

func _show_chat_view(conversation_id: String):
	conversation_list_view.hide()
	chat_view.show()
	current_view = "chat"
	current_conversation_id = conversation_id
	
	if TEST_CONVERSATIONS.has(conversation_id):
		chat_title_label.text = TEST_CONVERSATIONS[conversation_id]["title"]
	else:
		chat_title_label.text = "Unknown Conversation"
		
	load_conversation_by_tags([conversation_id])
	print("MessagesApp: Switched to Chat View for: ", conversation_id)

func _on_conversation_selected(conversation_id: String):
	_show_chat_view(conversation_id)

func add_message(character_name: String, message_text: String, timestamp: String, is_player: bool, style_tag: String = "default"):
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

	var formatted_message_content = ""
	formatted_message_content += "[color=gray][" + timestamp + "][/color] " # Timestamp color fixed
	formatted_message_content += "[b]" + character_name + ":[/b] "
	formatted_message_content += message_text
	
	var final_message = alignment_tag_open + text_color_tag + formatted_message_content + "[/color]" + alignment_tag_close
	message_stream_label.append_text("\n" + final_message)

	await get_tree().create_timer(0.01).timeout
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func load_conversation_by_tags(tags: Array):
	message_stream_label.clear()
	
	if tags.is_empty():
		print("Error: No tags provided to load_conversation_by_tags.")
		add_message("System", "No conversation ID provided.", "Now", false, "system_error")
		return

	var conversation_id_to_load = tags[0]
	print("MessagesApp: Attempting to load conversation with ID (tag): ", conversation_id_to_load)

	if TEST_CONVERSATIONS.has(conversation_id_to_load):
		var conversation_data = TEST_CONVERSATIONS[conversation_id_to_load]
		for message_data in conversation_data["messages"]:
			add_message(
				message_data.get("sender", "Unknown"),
				message_data.get("text", "..."),
				message_data.get("timestamp", " "),
				message_data.get("is_player", false),
				message_data.get("style_tag", "default") # Pass the style_tag
			)
	else:
		print("Error: No test data found for conversation_id: ", conversation_id_to_load)
		add_message("System", "Conversation data not found for ID: " + conversation_id_to_load, "Now", false, "system_error")


func set_conversation_data(conversation_data):
	print("MessagesApp: Received conversation data via set_conversation_data: ", conversation_data)
	message_stream_label.clear()
	if conversation_data and conversation_data.has("messages"):
		if conversation_data.has("title"):
			chat_title_label.text = conversation_data["title"]
		for message_entry in conversation_data["messages"]:
			add_message(
				message_entry.get("sender", "Unknown"), 
				message_entry.get("text", "..."), 
				message_entry.get("timestamp", " "), 
				message_entry.get("is_player", false),
				message_entry.get("style_tag", "default") # Pass style_tag here too
			)
	else:
		add_message("System", "Received invalid conversation data.", "Now", false, "system_error")

# --- Conceptual DialogueManager Integration Points ---
# (Kept for future reference)
# func load_conversation_from_dialogue_manager(dialogue_resource_id: String, start_node: String = ""): ...
# func _on_dialogue_line_received(line_data): ...
# func _on_choices_presented(choices_data): ...
# func get_current_time_string() -> String: ...
