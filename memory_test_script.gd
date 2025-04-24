extends Node

const scr_debug = true

func _ready():
	print("Memory System Test initialized")
	
	await get_tree().process_frame
	
	# Verify systems are loaded
	var memory_system = get_node_or_null("/root/MemorySystem")
	var dialog_system = get_node_or_null("/root/DialogSystem")
	var game_state = get_node_or_null("/root/GameState")
	
	if not memory_system:
		push_error("Memory System not found!")
		return
		
	if not dialog_system:
		push_error("Dialog System not found!")
		return
		
	if not game_state:
		push_error("Game State not found!")
		return
	
	print("All required systems loaded successfully!")
	
	# Connect to signals
	memory_system.memory_discovered.connect(_on_memory_discovered)
	memory_system.memory_chain_completed.connect(_on_memory_chain_completed)
	
	if dialog_system.has_signal("memory_dialogue_added"):
		dialog_system.memory_dialogue_added.connect(_on_memory_dialogue_added)
		print("Connected to memory_dialogue_added signal")
	else:
		push_error("Dialog system missing memory_dialogue_added signal!")
	
	# Test memory trigger
	print("Testing memory trigger for Poison's necklace")
#	var test_success = memory_system.trigger_look_at("Poison_necklace")
#	print("Memory trigger test result: ", test_success)
	
	# Check if the tag was set
#	var tag_set = game_state.has_tag("poison_necklace_seen")
#	print("Poison_necklace_seen tag set: ", tag_set)
	
	# Test dialogue mapping
	var options = memory_system.get_available_dialogue_options("Poison")
	print("Available dialogue options for Poison: ", options.size())
	for option in options:
		print("- Option: ", option.dialogue_title, " (tag: ", option.tag, ")")

func _on_memory_discovered(memory_tag, description):
	print("Memory discovered: ", memory_tag)
	print("Description: ", description)

func _on_memory_chain_completed(character_id, chain_id):
	print("Memory chain completed: ", chain_id, " for character ", character_id)

func _on_memory_dialogue_added(character_id, dialogue_title):
	print("Memory dialogue added: ", character_id, " -> ", dialogue_title)
