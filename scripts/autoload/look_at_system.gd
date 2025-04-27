extends Node

# Look At System for Love & Lichens
# Handles observations of objects, NPCs, and memory-related features

signal description_shown(text: String)
signal feature_observed(target_id: String, feature_id: String)

# References to other systems
var memory_system: Node
var notification_system: Node
var game_state: Node

# Debug flags
const scr_debug : bool = false
var debug

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug
	if debug: print("Look At System initialized")
	
	# Connect to other systems
	await get_tree().process_frame
	memory_system = get_node_or_null("/root/MemorySystem")
	notification_system = get_node_or_null("/root/NotificationSystem")
	game_state = get_node_or_null("/root/GameState")

# Main function for looking at a target
func look_at(target: Node) -> void:
	if debug: print("look_at called on " + target.character_id)

	if not is_instance_valid(target):
		if debug: print("Look at target is not valid")
		return
	
	# Get a more specific target ID if available
	var target_id = target.name
	
	if debug: print("Looking at: ", target_id)
	
	# For NPCs, check for observable features
	if target.is_in_group("npc"):
		_handle_npc_observation(target)
	else:
		# For regular objects, get a description and show it
		var description = _get_look_description(target)
		show_description(description)
	
	# Check if this triggers a memory
	if memory_system:
		memory_system.trigger_look_at(target_id)

# Handle NPC observation with multiple observable features
func _handle_npc_observation(npc: Node) -> void:
	if debug: print("_handle_npc_observation called")
	# Basic NPC description
	var basic_description = _get_npc_description(npc)
	show_description(basic_description)
	
	# Check for character data
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	var character_data = null
	
	if character_loader and "character_id" in npc:
		character_data = character_loader.get_character(npc.character_id)
	
	# Check for observable features
	var has_observable_features = false
	
	if npc.has_method("has_observable_feature"):
		if debug: print(npc.character_id + " has observable feature.")
		# If we have character data, use its features
		if character_data and not character_data.observable_features.is_empty():
			for feature_id in character_data.observable_features:
				if npc.has_observable_feature(feature_id):
					has_observable_features = true
					_observe_npc_feature(npc, feature_id)
		else:
			# Fallback to checking common features
			var features_to_check = ["necklace", "glasses", "pendant", "backpack", "phone", "lab_cabinet"]
			for feature in features_to_check:
				if npc.has_observable_feature(feature):
					has_observable_features = true
					_observe_npc_feature(npc, feature)
	else:
		if debug: print(npc.character_id + "has no observable feature.")

	if not has_observable_features and debug:
		print("NPC has no observable features: ", npc.name)
		

# Observe a specific feature on an NPC
func _observe_npc_feature(npc: Node, feature_id: String) -> void:
	if not npc.has_method("observe_feature"):
		return
		
	var feature_desc = npc.observe_feature(feature_id)
	if not feature_desc.is_empty():
		# Show the feature description
		show_description(feature_desc)
		
		# Emit observed signal
		feature_observed.emit(npc.name, feature_id)
		
		# Trigger memory system
		if memory_system:
			var target_id = npc.name + "_" + feature_id
			memory_system.trigger_look_at(target_id)
			
			if debug: print("Triggered look at for feature: ", target_id)

# Show a description to the player
func show_description(text: String) -> void:
	if text.is_empty():
		return
		
	# First try to use DialogSystem to show the text in a dialogue balloon
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system and dialog_system.has_method("start_custom_dialog"):
		# Create a simple dialogue with the description
		var dialogue_content = """
~ start
[color=yellow]Observation[/color]
{text}
=> END
"""
		# Replace the {text} with actual content
		dialogue_content = dialogue_content.replace("{text}", text)
		
		# Start the dialogue
		var success = dialog_system.start_custom_dialog(dialogue_content)
		if success:
			# Successfully displayed in dialogue balloon
			description_shown.emit(text)
			return
	
	# Fallback to notification system if dialogue didn't work
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(text)
	
	description_shown.emit(text)

# Get the appropriate description for a target
func _get_look_description(target: Node) -> String:
	# Default description
	var description = "You see " + target.name
	
	# Try to get a custom description from the target
	if target.has_method("get_look_description"):
		var custom_desc = target.get_look_description()
		if not custom_desc.is_empty():
			description = custom_desc
	
	# Check for NPC specific logic
	if target.is_in_group("npc"):
		description = _get_npc_description(target)
	
	# Check for item specific logic
	elif target.is_in_group("item"):
		description = _get_item_description(target)
	
	# Check for interactable specific logic
	elif target.is_in_group("interactable"):
		description = _get_interactable_description(target)
	
	return description

# NPC descriptions can be more detailed
func _get_npc_description(npc: Node) -> String:
	var description = "You see " + npc.name
	
	# Try to get a custom description
	if npc.has_method("get_look_description"):
		var custom_desc = npc.get_look_description()
		if not custom_desc.is_empty():
			description = custom_desc
	
	return description

# Item descriptions
func _get_item_description(item: Node) -> String:
	var description = "You see a " + item.name
	
	# Try to get a custom description
	if item.has_method("get_look_description"):
		var custom_desc = item.get_look_description()
		if not custom_desc.is_empty():
			description = custom_desc
	
	return description

# Interactable descriptions
func _get_interactable_description(interactable: Node) -> String:
	var description = "You see a " + interactable.name
	
	# Try to get a custom description
	if interactable.has_method("get_look_description"):
		var custom_desc = interactable.get_look_description()
		if not custom_desc.is_empty():
			description = custom_desc
	
	return description
