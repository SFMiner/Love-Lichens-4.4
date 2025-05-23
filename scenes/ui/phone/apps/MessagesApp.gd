extends Control

@onready var message_stream_label: RichTextLabel = $ScrollContainer/MessageStreamLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer

# Color for NPC messages (default RichTextLabel color is usually white/light)
const NPC_COLOR = Color(0.8, 0.8, 0.8) # Light gray, adjust as needed
# Color for Player messages
const PLAYER_COLOR = Color(0.6, 0.8, 1.0) # A light blue, adjust as needed

func _ready():
	# Example call to load a conversation based on tags.
	# In a real scenario, these tags might come from game events or player choices.
	load_conversation_by_tags(["test_conversation_1"])

func add_message(character_name: String, message_text: String, timestamp: String, is_player: bool):
	var formatted_message = ""
	
	# Timestamp
	formatted_message += "[color=gray][" + timestamp + "][/color] "
	
	# Character Name (bold)
	formatted_message += "[b]" + character_name + ":[/b] "
	
	# Message Text
	formatted_message += message_text
	
	# Apply alignment and color based on who sent the message
	if is_player:
		# Player messages: Right-aligned and specific color
		message_stream_label.append_text("\n[p align=right][color=#" + PLAYER_COLOR.to_html(false) + "]" + formatted_message + "[/color][/p]")
	else:
		# NPC messages: Left-aligned (default) and specific color
		message_stream_label.append_text("\n[p align=left][color=#" + NPC_COLOR.to_html(false) + "]" + formatted_message + "[/color][/p]")

	# Scroll to the bottom after adding a new message
	# Give a brief moment for the RichTextLabel to update its size
	await get_tree().create_timer(0.01).timeout
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


func load_conversation_by_tags(tags: Array):
	"""
	Loads and displays a conversation based on a set of tags.
	
	TODO: This function will be updated to:
	1. Query a central ContentProvider/DataManager singleton using the provided 'tags'.
	2. The ContentProvider would return dialogue entries or a DialogueResource path.
	3. This app would then use DialogueManager (or a similar system) to play out the 
	   conversation, with each line/event being fed to the 'add_message' function
	   or a new function like '_on_dialogue_line_received'.
	
	For now, it uses placeholder hardcoded messages.
	The 'tags' parameter is currently unused but demonstrates the intended API.
	"""
	print("MessagesApp: Attempting to load conversation with tags: ", tags)
	
	# --- Placeholder Content ---
	# In the future, this section will be replaced by data fetched via ContentProvider
	# and processed by DialogueManager.
	message_stream_label.clear() # Clear previous messages
	
	add_message("Poison", "Hey Adam, you there? (Loaded via tags: " + str(tags) + ")", "10:30 AM", false)
	add_message("Adam", "Yeah, what's up?", "10:31 AM", true)
	add_message("Poison", "Found that weird glowing lichen we saw yesterday. It's pulsating.", "10:32 AM", false)
	add_message("Adam", "Whoa, seriously? Where are you?", "10:33 AM", true)
	add_message("Poison", "Near the old oak, by the creek. You gotta see this.", "10:34 AM", false)
	# --- End Placeholder Content ---

func set_conversation_data(conversation_data):
	"""
	(Conceptual) This function would be called by a ContentProvider or DataManager
	after it has asynchronously fetched conversation data.
	
	It would then process this data, for example:
	- If 'conversation_data' is a DialogueResource path, it might initialize DialogueManager.
	- If 'conversation_data' is a pre-structured list of messages, it might loop through
	  them and call 'add_message'.
	
	For now, it just prints the received data.
	"""
	print("MessagesApp: Received conversation data: ", conversation_data)
	# Placeholder:
	# message_stream_label.clear()
	# for message_entry in conversation_data:
	#    add_message(message_entry.character, message_entry.text, message_entry.timestamp, message_entry.is_player)


# --- DialogueManager Integration Points (Conceptual - kept for reference) ---
# func load_conversation_from_dialogue_manager(dialogue_resource_id: String, start_node: String = ""):
# ... (rest of the conceptual DialogueManager comments can remain as they are relevant)
# func _on_dialogue_line_received(line_data):
# ...
# func _on_choices_presented(choices_data):
# ...
# func get_current_time_string() -> String:
# ...
