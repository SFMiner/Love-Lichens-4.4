# MessagesHelper.gd
# Helper script for integrating the Messages App with other systems
extends Node

const scr_debug := true
var debug := false

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug

# Send a text message to the Messages App
func send_text_message(sender_name: String, message_text: String, style_tag: String = "npc_default") -> bool:
	var messages_app = _get_messages_app()
	if messages_app and messages_app.has_method("send_message_from_script"):
		messages_app.send_message_from_script(sender_name, message_text, style_tag)
		if debug: print("MessagesHelper: Sent message from ", sender_name, ": ", message_text)
		return true
	else:
		if debug: print("MessagesHelper: Could not find Messages App to send message")
		return false

# Check if a contact is blocked
func is_contact_blocked(contact_name: String) -> bool:
	if GameState.phone_apps.has("blocked_contacts"):
		return contact_name in GameState.phone_apps["blocked_contacts"]
	return false

# Block a contact
func block_contact(contact_name: String) -> void:
	if not GameState.phone_apps.has("blocked_contacts"):
		GameState.phone_apps["blocked_contacts"] = []
	
	if contact_name not in GameState.phone_apps["blocked_contacts"]:
		GameState.phone_apps["blocked_contacts"].append(contact_name)
		if debug: print("MessagesHelper: Blocked contact: ", contact_name)

# Unblock a contact
func unblock_contact(contact_name: String) -> void:
	if GameState.phone_apps.has("blocked_contacts"):
		if contact_name in GameState.phone_apps["blocked_contacts"]:
			GameState.phone_apps["blocked_contacts"].erase(contact_name)
			if debug: print("MessagesHelper: Unblocked contact: ", contact_name)

# Get the Messages App instance
func _get_messages_app():
	# Try various paths to find the Messages App
	var paths = [
		"/root/Game/PhoneCanvasLayer/PhoneSceneInstance/MessagesApp",
		"/root/PhoneScene/MessagesApp",
		"/root/Game/PhoneScene/MessagesApp"
	]
	
	for path in paths:
		var app = get_node_or_null(path)
		if app:
			return app
	
	# Search the scene tree for MessagesApp
	var found_apps = get_tree().get_nodes_in_group("messages_app")
	if found_apps.size() > 0:
		return found_apps[0]
	
	# Last resort: find by class name
	var all_nodes = get_tree().get_nodes_in_group("phone_apps")
	for node in all_nodes:
		if node.get_script() and "MessagesApp" in str(node.get_script().get_path()):
			return node
	
	return null

# Example usage for dialogue system integration
func send_dialogue_message(character_id: String, dialogue_line: String, dialogue_style: String = "npc_default") -> void:
	# Convert character_id to display name if needed
	var display_name = _get_character_display_name(character_id)
	send_text_message(display_name, dialogue_line, dialogue_style)

# Convert character ID to display name
func _get_character_display_name(character_id: String) -> String:
	# This can be expanded to use a character name mapping
	var name_mapping = {
		"poison": "Poison",
		"erik": "Erik",
		"professor_moss": "Prof. Moss",
		"kitty": "Kitty",
		"dusty": "Dusty",
		"li": "Li"
	}
	
	return name_mapping.get(character_id, character_id.capitalize())

# Initialize Messages App with test data if needed
func initialize_messages_app() -> void:
	var messages_app = _get_messages_app()
	if messages_app and messages_app.has_method("initialize_test_data"):
		messages_app.initialize_test_data()
		if debug: print("MessagesHelper: Initialized Messages App with test data")

# Example function that can be called from dialogue files or other scripts
func trigger_text_conversation(character_id: String, messages: Array) -> void:
	for message_data in messages:
		var sender = message_data.get("sender", character_id)
		var text = message_data.get("text", "")
		var style = message_data.get("style", "npc_default")
		
		if text != "":
			send_text_message(sender, text, style)
			
			# Add a small delay between messages for realism
			await get_tree().create_timer(0.5).timeout

# Function to send system messages (like notifications)
func send_system_message(message_text: String) -> void:
	send_text_message("System", message_text, "system_error")

# Function to check conversation status
func has_conversation_with(contact_name: String) -> bool:
	if GameState.phone_apps.has("messages_app_entries"):
		var conversations = GameState.phone_apps["messages_app_entries"]
		var conv_id = contact_name.to_lower() + "_conversation"
		return conversations.has(conv_id)
	return false

# Get message count for a contact
func get_message_count_with(contact_name: String) -> int:
	if GameState.phone_apps.has("messages_app_entries"):
		var conversations = GameState.phone_apps["messages_app_entries"]
		var conv_id = contact_name.to_lower() + "_conversation"
		if conversations.has(conv_id) and conversations[conv_id].has("messages"):
			return conversations[conv_id]["messages"].size()
	return 0

# Archive a conversation programmatically
func archive_conversation_with(contact_name: String) -> bool:
	if GameState.phone_apps.has("messages_app_entries"):
		var conversations = GameState.phone_apps["messages_app_entries"]
		var conv_id = contact_name.to_lower() + "_conversation"
		if conversations.has(conv_id):
			conversations[conv_id]["archived"] = true
			
			# Refresh Messages App UI if it's open
			var messages_app = _get_messages_app()
			if messages_app and messages_app.has_method("load_conversation_lists"):
				messages_app.load_conversation_lists()
			
			if debug: print("MessagesHelper: Archived conversation with: ", contact_name)
			return true
	return false

# Unarchive a conversation programmatically
func unarchive_conversation_with(contact_name: String) -> bool:
	if GameState.phone_apps.has("messages_app_entries"):
		var conversations = GameState.phone_apps["messages_app_entries"]
		var conv_id = contact_name.to_lower() + "_conversation"
		if conversations.has(conv_id):
			conversations[conv_id]["archived"] = false
			
			# Refresh Messages App UI if it's open
			var messages_app = _get_messages_app()
			if messages_app and messages_app.has_method("load_conversation_lists"):
				messages_app.load_conversation_lists()
			
			if debug: print("MessagesHelper: Unarchived conversation with: ", contact_name)
			return true
	return false

# Function for relationship system integration
# This can be called when someone is blocked/unblocked to affect relationships
func _notify_relationship_system(contact_name: String, action: String) -> void:
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system and relationship_system.has_method("get_relationship_level"):
		match action:
			"blocked":
				# Decrease relationship when blocked
				if relationship_system.has_method("increase_affinity"):
					relationship_system.increase_affinity(contact_name.to_lower(), -20)
				if debug: print("MessagesHelper: Decreased relationship with ", contact_name, " due to blocking")
			"unblocked":
				# Small relationship recovery when unblocked
				if relationship_system.has_method("increase_affinity"):
					relationship_system.increase_affinity(contact_name.to_lower(), 5)
				if debug: print("MessagesHelper: Slightly improved relationship with ", contact_name, " due to unblocking")

# Enhanced block function with relationship effects
func block_contact_with_relationship_effect(contact_name: String) -> void:
	block_contact(contact_name)
	_notify_relationship_system(contact_name, "blocked")

# Enhanced unblock function with relationship effects
func unblock_contact_with_relationship_effect(contact_name: String) -> void:
	unblock_contact(contact_name)
	_notify_relationship_system(contact_name, "unblocked")

# Function to get all conversations (for save/load or debugging)
func get_all_conversations() -> Dictionary:
	if GameState.phone_apps.has("messages_app_entries"):
		return GameState.phone_apps["messages_app_entries"]
	return {}

# Function to get all blocked contacts
func get_blocked_contacts() -> Array:
	if GameState.phone_apps.has("blocked_contacts"):
		return GameState.phone_apps["blocked_contacts"]
	return []

# Clear all messages (for new game or reset)
func clear_all_messages() -> void:
	GameState.phone_apps["messages_app_entries"] = {}
	GameState.phone_apps["blocked_contacts"] = []
	
	var messages_app = _get_messages_app()
	if messages_app and messages_app.has_method("load_conversation_lists"):
		messages_app.load_conversation_lists()
	
	if debug: print("MessagesHelper: Cleared all messages and contacts")

# Example integration functions for quest system
func send_quest_related_message(character_id: String, quest_id: String, message_text: String) -> void:
	var style_tag = "npc_default"
	
	# Special styling for different quest types
	if quest_id.contains("lichen") or quest_id.contains("spore"):
		style_tag = "spore_data"
	
	send_dialogue_message(character_id, message_text, style_tag)

# Function to send a series of messages with delays (for story sequences)
func send_message_sequence(character_id: String, messages: Array, delay_between: float = 1.0) -> void:
	var display_name = _get_character_display_name(character_id)
	
	for i in range(messages.size()):
		var message_data = messages[i]
		var text = message_data.get("text", "") if typeof(message_data) == TYPE_DICTIONARY else str(message_data)
		var style = message_data.get("style", "npc_default") if typeof(message_data) == TYPE_DICTIONARY else "npc_default"
		
		if text != "":
			send_text_message(display_name, text, style)
			
			# Wait before sending next message, but not after the last one
			if i < messages.size() - 1:
				await get_tree().create_timer(delay_between).timeout

# Function to handle emergency or urgent messages
func send_urgent_message(character_id: String, message_text: String) -> void:
	var display_name = _get_character_display_name(character_id)
	send_text_message(display_name, "🚨 URGENT: " + message_text, "system_error")

# Function for timed messages (messages that arrive after a delay)
func send_delayed_message(character_id: String, message_text: String, delay: float, style: String = "npc_default") -> void:
	await get_tree().create_timer(delay).timeout
	send_dialogue_message(character_id, message_text, style)
