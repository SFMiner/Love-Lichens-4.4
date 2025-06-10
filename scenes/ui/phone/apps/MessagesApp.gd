extends Control

# --- Node References ---
@onready var conversation_list_view: VBoxContainer = $ConversationListView
@onready var chat_view: Control = $ChatView
@onready var archived_view: VBoxContainer = $ArchivedView
@onready var blocked_view: VBoxContainer = $BlockedView
@onready var messages_helper = get_node_or_null("/root/MessagesHelper")

# Chat view components
@onready var chat_back_button: Button = $ChatView/VBoxContainer/ChatHeader/ChatBackButton
@onready var chat_title_label: Label = $ChatView/VBoxContainer/ChatHeader/ChatTitleLabel
@onready var chat_options_button: Button = $ChatView/VBoxContainer/ChatHeader/ChatOptionsButton
@onready var message_stream_label: RichTextLabel = %MessageStreamLabel
@onready var scroll_container: ScrollContainer = $ChatView/VBoxContainer/ScrollContainer
@onready var reply_text_edit: TextEdit = %ReplyTextEdit
@onready var reply_button: Button = %ReplyButton

# Tab switching
@onready var tab_container: TabContainer = $TabContainer
@onready var inbox_list: VBoxContainer = $TabContainer/InboxTab/InboxList
@onready var archived_list: VBoxContainer = $TabContainer/ArchivedTab/ArchivedList
@onready var blocked_list: VBoxContainer = $TabContainer/BlockedTab/BlockedList

# Options menu
@onready var options_popup: PopupMenu = $ChatView/OptionsPopup

# --- Style Constants ---
const STYLE_TAG_COLORS = {
	"default": "",
	"player": "[color=#D0D0FF]",
	"npc_default": "[color=#E0E0E0]",
	"spore_data": "[color=#A0FFA0]",
	"system_error": "[color=#FF8080]",
}

const BASE_NPC_COLOR_TAG = "[color=#E0E0E0]"
const BASE_PLAYER_COLOR_TAG = "[color=#D0D0FF]"

# --- State ---
var current_view: String = "list" # "list" or "chat"
var current_conversation_id: String = ""
var all_conversations: Dictionary = {}

const scr_debug := true
var debug := false

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug
	
	# Initialize conversations data structure in GameState if it doesn't exist
	if not GameState.phone_apps.has("messages_app_entries"):
		GameState.phone_apps["messages_app_entries"] = {}
	
	if not GameState.phone_apps.has("blocked_contacts"):
		GameState.phone_apps["blocked_contacts"] = []
	
	# Load conversations and setup UI
	initialize_test_data()
	load_conversation_lists()
	connect_all_signals()
	setup_options_menu()
	show_tab("inbox")
	_show_conversation_list_view()

func connect_all_signals() -> void:
	# Chat controls
	chat_back_button.pressed.connect(Callable(self, "_show_conversation_list_view"))
	reply_button.pressed.connect(Callable(self, "_on_reply_button_pressed"))
	chat_options_button.pressed.connect(Callable(self, "_show_options_menu"))
	
	# Options menu
	options_popup.id_pressed.connect(Callable(self, "_on_options_menu_selected"))

func setup_options_menu():
	options_popup.clear()
	options_popup.add_item("Archive Conversation", 0)
	options_popup.add_item("Block Contact", 1)
	options_popup.add_separator()
	options_popup.add_item("Unblock Contact", 2)
	options_popup.add_item("Unarchive Conversation", 3)

func load_conversation_lists() -> void:
	all_conversations = GameState.phone_apps["messages_app_entries"]
	
	# Clear existing buttons
	for container in [inbox_list, archived_list, blocked_list]:
		for child in container.get_children():
			child.queue_free()
	
	# Add conversations to appropriate lists
	for conv_id in all_conversations.keys():
		var conversation = all_conversations[conv_id]
		var sender_name = conversation.get("sender_name", "Unknown")
		
		# Check if contact is blocked
		if sender_name in GameState.phone_apps["blocked_contacts"]:
			add_conversation_button_to_list(blocked_list, conv_id, conversation)
		elif conversation.get("archived", false):
			add_conversation_button_to_list(archived_list, conv_id, conversation)
		else:
			add_conversation_button_to_list(inbox_list, conv_id, conversation)

func add_conversation_button_to_list(container: VBoxContainer, conv_id: String, conversation: Dictionary) -> void:
	var sender_name = conversation.get("sender_name", "Unknown")
	var last_message = ""
	
	# Get preview of last message
	if conversation.has("messages") and conversation["messages"].size() > 0:
		var messages = conversation["messages"]
		var last_msg = messages[messages.size() - 1]
		last_message = get_preview_line(last_msg.get("text", ""))
	
	var label = "%s — %s" % [sender_name, last_message]
	var button = Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_FILL
	button.clip_text = true
	button.gui_input.connect(Callable(self, "_on_conversation_gui_input").bind(conv_id))
	container.add_child(button)

func get_preview_line(text: String) -> String:
	var lines := text.split("\n")
	if lines.size() > 0:
		var preview = lines[0]
		if preview.length() > 30:
			return preview.substr(0, 30) + "..."
		return preview
	return ""

func _on_conversation_gui_input(event: InputEvent, conv_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.double_click:
		_show_chat_view(conv_id)

func _show_conversation_list_view():
	tab_container.visible = true
	chat_view.visible = false
	current_view = "list"
	current_conversation_id = ""
	if debug: print("MessagesApp: Switched to Conversation List View")

func _show_chat_view(conversation_id: String):
	tab_container.visible = false
	chat_view.visible = true
	current_view = "chat"
	current_conversation_id = conversation_id
	
	if all_conversations.has(conversation_id):
		var conversation = all_conversations[conversation_id]
		chat_title_label.text = conversation.get("sender_name", "Unknown")
		load_conversation_messages(conversation_id)
	else:
		chat_title_label.text = "Unknown Conversation"
		message_stream_label.clear()
		add_message("System", "Conversation not found.", "Now", false, "system_error")
	
	# Clear reply field
	reply_text_edit.text = ""
	
	if debug: print("MessagesApp: Switched to Chat View for: ", conversation_id)

func load_conversation_messages(conv_id: String):
	message_stream_label.clear()
	
	if not all_conversations.has(conv_id):
		add_message("System", "Conversation data not found.", "Now", false, "system_error")
		return
	
	var conversation = all_conversations[conv_id]
	if conversation.has("messages"):
		for message_data in conversation["messages"]:
			add_message(
				message_data.get("sender", "Unknown"),
				message_data.get("text", "..."),
				message_data.get("timestamp", ""),
				message_data.get("is_player", false),
				message_data.get("style_tag", "default")
			)

func add_message(character_name: String, message_text: String, timestamp: String, is_player: bool, style_tag: String = "default"):
	var text_color_tag = STYLE_TAG_COLORS.get(style_tag, "")
	
	if text_color_tag == "":
		text_color_tag = BASE_PLAYER_COLOR_TAG if is_player else BASE_NPC_COLOR_TAG
	
	var alignment_tag_open = ""
	var alignment_tag_close = ""
	if is_player:
		alignment_tag_open = "[p align=right]"
		alignment_tag_close = "[/p]"
	else:
		alignment_tag_open = "[p align=left]"
		alignment_tag_close = "[/p]"

	var formatted_message_content = ""
	if timestamp != "":
		formatted_message_content += "[color=gray][" + timestamp + "][/color] "
	formatted_message_content += "[b]" + character_name + ":[/b] "
	formatted_message_content += message_text
	
	var final_message = alignment_tag_open + text_color_tag + formatted_message_content + "[/color]" + alignment_tag_close + '\n'
	message_stream_label.append_text("\n" + final_message)

	await get_tree().create_timer(0.01).timeout
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_reply_button_pressed() -> void:
	var reply_text = reply_text_edit.text.strip_edges()
	
	if reply_text == "":
		if debug: print("MessagesApp: Cannot send empty reply")
		return
	
	if current_conversation_id == "":
		if debug: print("MessagesApp: No conversation selected")
		return
	
	# Add reply to conversation
	send_reply(current_conversation_id, reply_text)
	
	# Clear reply field
	reply_text_edit.text = ""

func send_reply(conv_id: String, reply_text: String) -> void:
	if not all_conversations.has(conv_id):
		if debug: print("MessagesApp: Conversation not found for reply")
		return
	
	var timestamp = TimeSystem.format_game_time("h:nn AM") if TimeSystem else "Now"
	
	var new_message = {
		"sender": "Adam",
		"text": reply_text,
		"timestamp": timestamp,
		"is_player": true,
		"style_tag": "player"
	}
	
	# Add to conversation data
	all_conversations[conv_id]["messages"].append(new_message)
	
	# Add to display
	add_message("Adam", reply_text, timestamp, true, "player")
	
	# Update GameState
	GameState.phone_apps["messages_app_entries"] = all_conversations
	
	if debug: print("MessagesApp: Sent reply to conversation: ", conv_id)

func _show_options_menu() -> void:
	var button_rect = chat_options_button.get_global_rect()
	options_popup.position = Vector2i(button_rect.position.x, button_rect.position.y + button_rect.size.y)
	options_popup.popup()

func _on_options_menu_selected(id: int) -> void:
	match id:
		0: # Archive Conversation
			archive_conversation(current_conversation_id)
		1: # Block Contact
			block_contact(current_conversation_id)
		2: # Unblock Contact
			unblock_contact(current_conversation_id)
		3: # Unarchive Conversation
			unarchive_conversation(current_conversation_id)

func archive_conversation(conv_id: String) -> void:
	if all_conversations.has(conv_id):
		all_conversations[conv_id]["archived"] = true
		GameState.phone_apps["messages_app_entries"] = all_conversations
		load_conversation_lists()
		_show_conversation_list_view()
		if debug: print("MessagesApp: Archived conversation: ", conv_id)

func unarchive_conversation(conv_id: String) -> void:
	if all_conversations.has(conv_id):
		all_conversations[conv_id]["archived"] = false
		GameState.phone_apps["messages_app_entries"] = all_conversations
		load_conversation_lists()
		_show_conversation_list_view()
		if debug: print("MessagesApp: Unarchived conversation: ", conv_id)

func block_contact(conv_id: String) -> void:
	if all_conversations.has(conv_id):
		var sender_name = all_conversations[conv_id].get("sender_name", "")
		if sender_name != "" and sender_name not in GameState.phone_apps["blocked_contacts"]:
			GameState.phone_apps["blocked_contacts"].append(sender_name)
			load_conversation_lists()
			_show_conversation_list_view()
			if debug: print("MessagesApp: Blocked contact: ", sender_name)

func unblock_contact(conv_id: String) -> void:
	if all_conversations.has(conv_id):
		var sender_name = all_conversations[conv_id].get("sender_name", "")
		if sender_name in GameState.phone_apps["blocked_contacts"]:
			GameState.phone_apps["blocked_contacts"].erase(sender_name)
			load_conversation_lists()
			_show_conversation_list_view()
			if debug: print("MessagesApp: Unblocked contact: ", sender_name)

func show_tab(tab: String) -> void:
	match tab:
		"inbox":
			tab_container.current_tab = 0
		"archived":
			tab_container.current_tab = 1
		"blocked":
			tab_container.current_tab = 2

func receive_new_message(sender_name: String, message_text: String, style_tag: String = "npc_default") -> void:
	# Don't receive messages from blocked contacts
	if sender_name in GameState.phone_apps["blocked_contacts"]:
		if debug: print("MessagesApp: Blocked message from: ", sender_name)
		return
	
	var timestamp = TimeSystem.format_game_time("h:nn AM") if TimeSystem else "Now"
	var conv_id = sender_name.to_lower() + "_conversation"
	
	var new_message = {
		"sender": sender_name,
		"text": message_text,
		"timestamp": timestamp,
		"is_player": false,
		"style_tag": style_tag
	}
	
	# Create or update conversation
	if not all_conversations.has(conv_id):
		all_conversations[conv_id] = {
			"conversation_id": conv_id,
			"sender_name": sender_name,
			"archived": false,
			"messages": []
		}
	
	all_conversations[conv_id]["messages"].append(new_message)
	
	# Update GameState
	GameState.phone_apps["messages_app_entries"] = all_conversations
	
	# Refresh UI if we're in list view
	if current_view == "list":
		load_conversation_lists()
	elif current_view == "chat" and current_conversation_id == conv_id:
		# If we're viewing this conversation, add the message to display
		add_message(sender_name, message_text, timestamp, false, style_tag)
	
	if debug: print("MessagesApp: Received new message from: ", sender_name)

# Function to be called by dialogue system or other scripts to send messages
func send_message_from_script(sender_name: String, message_text: String, style_tag: String = "npc_default") -> void:
	receive_new_message(sender_name, message_text, style_tag)

# Initialize with test data if needed
func initialize_test_data() -> void:
	var test_conversations = {
		"poison_conversation": {
			"conversation_id": "poison_conversation",
			"sender_name": "Poison",
			"archived": false,
			"messages": [
				{"sender": "Poison", "text": "Hey Adam, you there?", "timestamp": "10:30 AM", "is_player": false, "style_tag": "npc_default"},
				{"sender": "Adam", "text": "Yeah, what's up?", "timestamp": "10:31 AM", "is_player": true, "style_tag": "player"},
				{"sender": "Poison", "text": "Found that weird glowing lichen we saw yesterday. It's pulsating.", "timestamp": "10:32 AM", "is_player": false, "style_tag": "npc_default"},
				{"sender": "Poison", "text": "Actually, scratch that. It's giving off a faint green glow now.", "timestamp": "10:33 AM", "is_player": false, "style_tag": "spore_data"},
			]
		},
		"erik_conversation": {
			"conversation_id": "erik_conversation",
			"sender_name": "Erik",
			"archived": false,
			"messages": [
				{"sender": "Erik", "text": "Dude, did you finish the history assignment?", "timestamp": "11:00 AM", "is_player": false, "style_tag": "npc_default"},
				{"sender": "Adam", "text": "Almost... just the last paragraph.", "timestamp": "11:01 AM", "is_player": true, "style_tag": "player"},
				{"sender": "Erik", "text": "Lucky. I'm still stuck on the causes of the Franco-Prussian War.", "timestamp": "11:02 AM", "is_player": false, "style_tag": "npc_default"},
			]
		},
		"lab_group_conversation": {
			"conversation_id": "lab_group_conversation",
			"sender_name": "Lab Group",
			"archived": false,
			"messages": [
				{"sender": "Sarah", "text": "Is anyone else having trouble with experiment 3?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
				{"sender": "Adam", "text": "Yeah, my results were way off.", "timestamp": "Yesterday", "is_player": true, "style_tag": "player"},
				{"sender": "Mike", "text": "Same here. Maybe we should compare notes before class?", "timestamp": "Yesterday", "is_player": false, "style_tag": "npc_default"},
				{"sender": "Adam", "text": "Good idea.", "timestamp": "Today", "is_player": true, "style_tag": "player"},
			]
		}
	}
	
	# Only add test data if no conversations exist
	if GameState.phone_apps["messages_app_entries"].size() == 0:
		GameState.phone_apps["messages_app_entries"] = test_conversations
		all_conversations = test_conversations
		load_conversation_lists()
		if debug: print("MessagesApp: Initialized with test data")

# Save/load functionality for phone app data
func get_save_data() -> Dictionary:
	return {
		"conversations": all_conversations,
		"blocked_contacts": GameState.phone_apps.get("blocked_contacts", [])
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("conversations"):
		all_conversations = data["conversations"]
		GameState.phone_apps["messages_app_entries"] = all_conversations
	
	if data.has("blocked_contacts"):
		GameState.phone_apps["blocked_contacts"] = data["blocked_contacts"]
	
	load_conversation_lists()
