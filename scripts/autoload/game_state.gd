# Enhanced game_state.gd with memory data storage

extends Node

# Existing signals
signal game_started(game_id)
signal game_saved(slot)
signal game_loaded(slot)
signal game_ended()
signal tag_added(tag)
signal tag_removed(tag)
signal memory_discovered(memory_tag: String, description: String)

# New memory-related signals
signal memory_data_loaded()

# Existing game state variables
var current_game_id = ""
var is_new_game = false
var start_time = 0
var play_time = 0
var last_save_time = 0
var interaction_range = 0
var has_phone = false
var player : CharacterBody2D = null
var tracker_id : int = 0

@onready var phone = get_node_or_null("/root/Game/PhoneCanvasLayer/PhoneSceneInstance")
@onready var camera_app = load(PHONE_APP_SCRIPT_PATHS["camera_roll"])
var tags: Dictionary = {}
var scenes: Dictionary = {
	"CampusQuad":{
		"pickups":[]
	},
	"Library":{
		"pickups":[]
	},
	"ResearchLab":{
		"pickups":[]
	},
	"DormRoom":{
		"pickups":[]
	},
	"OldGrowthForest":{
		"pickups":[]
	},
	"Cemetery":{
		"pickups":[]
	},
	"MemorySpring":{
		"pickups":[]
	},
	"CouncilOfToadstools":{
		"pickups":[]
	},
	"Theater":{
		"pickups":[]
	},
	"PermacultureGarden":{
		"pickups":[]
	}	
}


const PHONE_APP_SCRIPT_PATHS = {
	"messages": "res://scenes/ui/phone/apps/MessagesApp.gd",
	"discord": "res://scenes/ui/phone/apps/DiscordApp.gd", # Updated path
	"social_feed": "res://scenes/ui/phone/apps/SocialFeedApp.gd", # Assuming this exists or is placeholder
	"journal": "res://scenes/ui/phone/apps/JournalApp.gd", # Assuming this exists or is placeholder
	"email": "res://scenes/ui/phone/apps/EmailApp.gd", # Updated path
	"grades": "res://scenes/ui/phone/apps/GradesApp.gd", # Assuming this exists or is placeholder
	"camera_roll": "res://scenes/ui/phone/apps/CameraRollApp.gd",
	"spore": "res://scenes/ui/phone/apps/SporeApp.gd", # Assuming this exists or is placeholder
	"snake": "res://scenes/ui/phone/apps/SnakeApp.gd"
	}

var phone_apps : Dictionary = {
	"camera_roll_app_entries": {},
	"discord_app_entries": {},
	"email_app_entries": {},	
	"grades_app_entries": {},
	"journal_app_entries": [],
	"messaging_app_entries": {},
	"social_media_app_entries": {},
	"snake_media_app_entries": {},
	"spore_app_entries": {},
}
var scenes_visited = []

#var memory_tag_registry 
# Variables from original GameState that might be missing
var looking_at_adam_desk = false
var poison_bugs = ["tarantula"]
var atlas_emergence : int = 28
var current_day : float = 0
var memory_registry : Dictionary

var current_scene
var current_npc_list = []
var current_marker_list = []
var knowledge : Array[String] = []

# NEW: Memory data storage (loaded at startup, persisted in saves)
var memory_definitions: Dictionary = {}
var memory_chains: Dictionary = {}
var discovered_memories: Array = []
var memory_discovery_history: Array = []
# Dialogue mapping - Key: unlock_tag, Value: {character_id, dialogue_title}
var dialogue_mapping: Dictionary = {}


# Optimized lookup - properly typed keys
var memories_by_trigger: Dictionary = {
	0: {},  # LOOK_AT
	1: {},  # ITEM_ACQUIRED
	2: {},  # LOCATION_VISITED
	3: {},  # DIALOGUE_CHOICE
	4: {},  # QUEST_COMPLETED
	5: {},  # CHARACTER_RELATIONSHIP
	6: {},  # TIME_PASSED
	7: {},  # ITEM_USED
	8: {}   # NPC_TALKED_TO
}

# Existing game data...
var game_data = {
	"player_name": "Adam Major",
	"current_location": "",
	"player_position": Vector2.ZERO,
	"current_day": 1,
	"current_turn": 0,
	"turns_per_day": 8
}

const scr_debug : bool = true
var debug 

func _ready():
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
#	_load_memory_registry()

func _initialize_camera_roll_starter_images():
	const _fname = "_initialize_camera_roll_starter_images"

	# Ensure the camera roll data structure exists
	if debug: print(script_name_tag(self, _fname) + " function called.")

	if not phone_apps.has("camera_roll_app_entries"):
		phone_apps["camera_roll_app_entries"] = {}
	
	# Add starter images directly to GameState
	var starter_images = {
		"campus_welcome": {
			"image_id": "mantis1",
			"thumbnail_path": "res://assets/images/camera_roll_images/mantis.jpg",
			"full_image_path": "res://assets/images/camera_roll_images/mantis.jpg",
			"caption": "Mantis I found in the cemetery!",
			"timestamp": "March 10, 2024",
			"tags": "#mantis, #bug",
			"source": "Adam's Camera"
		},
		"Mushroom": {
			"image_id": "mushroom1", 
			"thumbnail_path": "res://assets/images/camera_roll_images/mushroom1.png",
			"full_image_path": "res://assets/images/camera_roll_images/mushroom1.png",
			"caption": "New friend!",
			"timestamp": "March 10, 2024",
			"tags": "#musfroom, #fungus",
			"source": "Adam's Camera"
		}
	}
	
	# Only add if camera roll is empty
	if phone_apps["camera_roll_app_entries"].size() == 0:
		if debug: print(script_name_tag(self, _fname) + "phone_apps['camera_roll_app_entries'].size() = " + str(phone_apps["camera_roll_app_entries"].size()))
		phone_apps["camera_roll_app_entries"] = starter_images
	else:
		if debug: print(script_name_tag(self, _fname) + "phone_apps['camera_roll_app_entries'].size() = " + str(phone_apps["camera_roll_app_entries"].size()))
	print(script_name_tag(self, _fname) + "Added starter images to camera roll")
	print(script_name_tag(self, _fname) + "phone_apps(camera_roll_app_entries) = " + str(phone_apps["camera_roll_app_entries"]))
	
	
func add_journal_entry(entry_string : String):
	var _fname = "add_journal_entry"
	if debug: print(script_name_tag(self, _fname) + "entry_string = " + entry_string)
	# get path to journal.gd script:
	var journal_path : String = PHONE_APP_SCRIPT_PATHS["journal"]
	if debug: print(script_name_tag(self, _fname) + "journal_path =" + journal_path)
	# load script at object "journal"
	var journal = load(journal_path)
	# check that "journal" exists
	if debug: print(script_name_tag(self, _fname) + "journal = " + str(journal))
	# call add_packed_entry on journal
	journal.add_packed_entry(entry_string)
	
# GameState.gd additions

func add_email_to_inbox(email_data: Dictionary) -> void:
	email_data["box"] = "inbox"
	var email_id = email_data.get("email_id", generate_email_id())
	email_data["email_id"] = email_id
	["email_app_entries"][email_id] = email_data

func add_email_to_sent(email_data: Dictionary) -> void:
	email_data["box"] = "sent"
	var email_id = email_data.get("email_id", generate_email_id())
	email_data["email_id"] = email_id
	phone_apps["email_app_entries"][email_id] = email_data

func get_email_by_id(email_id: String) -> Dictionary:
	return phone_apps["email_app_entries"].get(email_id, {})

func send_email_from_dialogue(sender: String, recipient: String, subject: String, body: String, reply_to_id: String = "") -> void:
	var email_id = generate_email_id()
	var email := {
		"email_id": email_id,
		"reply_to_id": reply_to_id,
		"subject": subject,
		"body": body,
		"timestamp": TimeSystem.format_game_time("Mmmm, dd, yyyy h:nn"),
		"sender": sender,
		"recipient": recipient,
		"box": "inbox"
	}
	phone_apps["email_app_entries"][email_id] = email

func generate_email_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi())




# SIMPLIFIED: Load only the registry
func _load_memory_registry():
	var _fname = "_load_memory_registry"
	var file := FileAccess.open("res://data/generated/memory_tag_registry.json", FileAccess.READ)
	if file:
		var json_string := file.get_as_text()
		file.close()
		var json_result := JSON.new()
		if json_result.parse(json_string) == OK:
			memory_registry = json_result.get_data()
			if debug: print(script_name_tag(self, _fname) + "Loaded ", memory_registry.size(), " memory tags from registry")
		else:
			if debug: print(script_name_tag(self, _fname) + "ERROR: Failed to parse memory registry JSON")
	else:
		if debug: print(script_name_tag(self, _fname) + "ERROR: Could not load memory registry file")

# NEW: Core registry access functions
func get_memory_metadata(tag_name: String) -> Dictionary:
	"""Get all metadata for a memory tag from the registry"""
	return memory_registry.get(tag_name, {})

func is_valid_memory_tag(tag_name: String) -> bool:
	"""Check if a memory tag exists in the registry"""
	return memory_registry.has(tag_name)

func can_unlock_memory(tag_name: String) -> bool:
	"""Check if all condition_tags are met for this memory tag"""
	var metadata = get_memory_metadata(tag_name)
	if metadata.is_empty():
		return false
	
	# Check if already discovered
	if has_tag(tag_name):
		return false
	
	# Check condition tags
	var condition_tags = metadata.get("condition_tags", [])
	for condition_tag in condition_tags:
		if not has_tag(condition_tag):
			return false
	
	return true

func discover_memory_from_registry(tag_name: String, discovery_method: String = "") -> bool:
	"""Discover a memory using registry metadata"""
	var _fname = "discover_memory_from_registry"
	
	if not can_unlock_memory(tag_name):
		return false
	
	var metadata = get_memory_metadata(tag_name)
	var description = metadata.get("description", "")
	var character_id = metadata.get("character_id", "")
	
	# Set the tag
	set_tag(tag_name, true)
	
	# Add to discovered list
	if tag_name not in discovered_memories:
		discovered_memories.append(tag_name)
	
	# Emit discovery signal
	memory_discovered.emit(tag_name, description)
	
	if debug: print(script_name_tag(self, _fname) + "Memory discovered: ", tag_name, " - ", description)
	return true

# NEW: Get memories by trigger type using registry
func get_memories_for_trigger_type(trigger_type: int, target_id: String) -> Array:
	"""Get all memory tags that match trigger_type and target_id"""
	var matching_memories = []
	
	for tag_name in memory_registry.keys():
		var metadata = memory_registry[tag_name]
		
		# Convert float trigger_type to int if needed
		var meta_trigger_type = metadata.get("trigger_type", -1)
		if typeof(meta_trigger_type) == TYPE_FLOAT:
			meta_trigger_type = int(meta_trigger_type)
		
		var meta_target_id = metadata.get("target_id", "")
		
		if meta_trigger_type == trigger_type and (meta_target_id == target_id or meta_target_id == target_id.to_lower()):
			matching_memories.append({
				"tag_name": tag_name,
				"metadata": metadata
			})
	
	return matching_memories

# NEW: Get available dialogue options using registry
func get_dialogue_options_from_registry(character_id: String) -> Array:
	"""Get available dialogue options for a character using registry"""
	var _fname = "get_dialogue_options_from_registry"
	var available_options = []
	
	for tag_name in memory_registry.keys():
		var metadata = memory_registry[tag_name]
		
		# Check if this is for our character and has dialogue_title
		if metadata.get("character_id", "") == character_id and metadata.get("dialogue_title", "") != "":
			# Check if the memory tag is unlocked
			if has_tag(tag_name):
				var option = {
					"tag": tag_name,
					"dialogue_title": metadata["dialogue_title"],
					"character_id": character_id,
					"description": metadata.get("description", "")
				}
				available_options.append(option)
				if debug: print(script_name_tag(self, _fname) + "Added dialogue option: ", option)
	
	return available_options

# NEW: Check if specific dialogue is available
func is_dialogue_available_from_registry(character_id: String, dialogue_title: String) -> bool:
	"""Check if a specific dialogue option is available"""
	for tag_name in memory_registry.keys():
		var metadata = memory_registry[tag_name]
		
		if (metadata.get("character_id", "") == character_id and 
			metadata.get("dialogue_title", "") == dialogue_title and
			has_tag(tag_name)):
			return true
	
	return false

# NEW: Get memory tag for specific dialogue
func get_memory_tag_for_dialogue_from_registry(character_id: String, dialogue_title: String) -> String:
	"""Get the memory tag associated with a character's dialogue option"""
	for tag_name in memory_registry.keys():
		var metadata = memory_registry[tag_name]
		
		if (metadata.get("character_id", "") == character_id and 
			metadata.get("dialogue_title", "") == dialogue_title):
			return tag_name
	
	return ""

# BACKWARD COMPATIBILITY: Keep existing functions but make them use registry
func get_available_dialogue_options(character_id: String) -> Array:
	"""Legacy function - now uses registry"""
	return get_dialogue_options_from_registry(character_id)

func is_dialogue_available(character_id: String, dialogue_title: String) -> bool:
	"""Legacy function - now uses registry"""
	return is_dialogue_available_from_registry(character_id, dialogue_title)

func get_memory_tag_for_dialogue(character_id: String, dialogue_title: String) -> String:
	"""Legacy function - now uses registry"""
	return get_memory_tag_for_dialogue_from_registry(character_id, dialogue_title)

# Existing tag system functions remain the same...
func has_tag(tag: String) -> bool:
	return tags.has(tag)

func set_tag(tag: String, value: Variant = true) -> void:
	var _fname = "set_tag"
	
	# COMPREHENSIVE DEBUG TRACKER
	print("🔥🔥🔥 TAG TRACKER: Setting '", tag, "' = ", value)
	print("🔥🔥🔥 Called from stack: ")
	var stack = get_stack()
	for i in range(min(3, stack.size())):  # Show top 3 stack frames
		print("🔥🔥🔥   ", stack[i].source, ":", stack[i].line, " in ", stack[i].function)
	
	tags[tag] = value
	tag_added.emit(tag)
	
	# Verify it was actually set
	print("🔥🔥🔥 Verification: tags['", tag, "'] = ", tags.get(tag, "NOT_FOUND"))

# NEW: Load all memory definitions into GameState
func _load_memory_definitions():
	var _fname = "_load_memory_definitions"
	if debug: print(script_name_tag(self, _fname) + "Loading memory definitions into GameState...")
	
	# Load individual memories
	_load_individual_memories()
	
	# Load memory chains
	_load_memory_chains()
	
	# Load character-specific memory data
	_load_character_memory_data()
	
	# Organize by trigger type for fast lookup
	_organize_memories_by_trigger()
	
	if debug: print(script_name_tag(self, _fname) + "Loaded ", memory_definitions.size(), " memory definitions")
	
	# Debug the loaded data
	call_deferred("debug_memory_definitions")
	
	memory_data_loaded.emit()

func _load_individual_memories():
	var _fname = "_load_individual_memories"
	var path = "res://data/memories/individual_memories.json"
	if not FileAccess.file_exists(path):
		if debug: print(script_name_tag(self, _fname) + "No individual memories file found at: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	if debug: print(script_name_tag(self, _fname) + "Loaded JSON text length: ", json_string.length())
	if debug: print(script_name_tag(self, _fname) + "Full JSON content:")
	if debug: print(script_name_tag(self, _fname) + json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		if debug: print(script_name_tag(self, _fname) + "ERROR: Failed to parse individual memories JSON: ", json.get_error_message())
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(script_name_tag(self, _fname) + "ERROR: Individual memories JSON is not a dictionary")
		return
	
	if debug: print(script_name_tag(self, _fname) + "Successfully parsed JSON with ", data.size(), " entries")
	if debug: print(script_name_tag(self, _fname) + "JSON keys: ", data.keys())
	
	# Process each memory, skipping comments and metadata
	for memory_id in data:
		# SKIP COMMENTS AND METADATA
		if memory_id.begins_with("_"):
			if debug: print(script_name_tag(self, _fname) + "Skipping metadata entry: ", memory_id)
			continue
		
		var memory_data = data[memory_id]
		
		if debug: print(script_name_tag(self, _fname) + "Processing memory: ", memory_id)
		if debug: print(script_name_tag(self, _fname) + "  Raw data: ", memory_data)
		if debug: print(script_name_tag(self, _fname) + "  Data type: ", typeof(memory_data))
		
		# Ensure memory_data is a dictionary
		if typeof(memory_data) != TYPE_DICTIONARY:
			if debug: print(script_name_tag(self, _fname) + "ERROR: Memory data for ", memory_id, " is not a dictionary: ", typeof(memory_data))
			continue
		
		# FIX TYPE CONVERSION: Ensure trigger_type is integer
		if memory_data.has("trigger_type"):
			var trigger_type = memory_data["trigger_type"]
			if typeof(trigger_type) == TYPE_FLOAT:
				memory_data["trigger_type"] = int(trigger_type)
				if debug: print(script_name_tag(self, _fname) + "Converted trigger_type from float to int for: ", memory_id)
		
		# Store in memory_definitions
		memory_definitions[memory_id] = memory_data
		if debug: print(script_name_tag(self, _fname) + "Stored memory: ", memory_id, " with data: ", memory_data)
		

func _load_memory_chains():
	var _fname = "_load_memory_chains"
	var dir = DirAccess.open("res://data/memories/")
	if not dir:
		if debug: print(script_name_tag(self, _fname) + "No memories directory found")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with("_chain.json") and not dir.current_is_dir():
			var path = "res://data/memories/" + file_name
			_load_memory_chain_file(path)
		file_name = dir.get_next()

func _load_memory_chain_file(path: String):
	var _fname = "_load_memory_chain_file"
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json_result = JSON.new()
	if json_result.parse(json_text) == OK:
		var data = json_result.get_data()
		if data.has("chains"):
			for chain_data in data.chains:
				var chain_id = chain_data.get("id", "")
				if not chain_id.is_empty():
					memory_chains[chain_id] = chain_data
					if debug: print(script_name_tag(self, _fname) + "Loaded memory chain: ", chain_id)

func _load_character_memory_data():
	var _fname = "_load_character_memory_data()"
	var character_loader = get_node_or_null("/root/CharacterDataLoader")
	if not character_loader:
		return
	
	for character_id in character_loader.characters:
		var character_data = character_loader.get_character(character_id)
		if character_data and character_data.has("memory_data"):
			var memory_data = character_data.memory_data
			
			# Add individual memories from character data
			if memory_data.has("individual"):
				for memory_id in memory_data.individual:
					var memory = memory_data.individual[memory_id]
					memory["character_id"] = character_id
					memory_definitions[memory_id] = memory

func _organize_memories_by_trigger():
	var _fname = "_organize_memories_by_trigger"
	print(script_name_tag(self, _fname) + "=== ORGANIZE MEMORIES BY TRIGGER DEBUG ===")
	print(script_name_tag(self, _fname) + "Total memory_definitions: ", memory_definitions.size())
	print(script_name_tag(self, _fname) + "memory_definitions keys: ", memory_definitions.keys())
	
	# Organize memories by trigger type for O(1) lookup during gameplay
	for memory_id in memory_definitions:
		var memory = memory_definitions[memory_id]
		
		print("\n" + script_name_tag(self, _fname) + "--- Processing memory: ", memory_id, " ---")
		print(script_name_tag(self, _fname) + "Memory type: ", typeof(memory))
		print(script_name_tag(self, _fname) + "Memory contents: ", memory)
		
		# Debug: Check if memory is the right type
		if typeof(memory) != TYPE_DICTIONARY:
			print(script_name_tag(self, _fname) + "ERROR: Memory ", memory_id, " is not a dictionary, it's a ", typeof(memory))
			continue
		
		# ENSURE INTEGER TRIGGER TYPE
		var trigger_type = memory.get("trigger_type", 0)
		if typeof(trigger_type) == TYPE_FLOAT:
			trigger_type = int(trigger_type)
		
		var target_id = memory.get("target_id", "")
		var unlock_tag = memory.get("unlock_tag", "")
		var character_id = memory.get("character_id", "")
		var dialogue_title = memory.get("dialogue_title", "")
		
		print(script_name_tag(self, _fname) + "  trigger_type: ", trigger_type)
		print(script_name_tag(self, _fname) + "  target_id: '", target_id, "'")
		print(script_name_tag(self, _fname) + "  unlock_tag: '", unlock_tag, "'")
		print(script_name_tag(self, _fname) + "  character_id: '", character_id, "'")
		print(script_name_tag(self, _fname) + "  dialogue_title: '", dialogue_title, "'")
		
		if target_id == "":
			print(script_name_tag(self, _fname) + "WARNING: Memory ", memory_id, " has no target_id")
			continue
		
		# Initialize trigger type if not exists
		if not memories_by_trigger.has(trigger_type):
			memories_by_trigger[trigger_type] = {}
		
		# Initialize target list if not exists
		if not memories_by_trigger[trigger_type].has(target_id):
			memories_by_trigger[trigger_type][target_id] = []
		
		# Add memory data
		memories_by_trigger[trigger_type][target_id].append({
			"memory_id": memory_id,
			"unlock_tag": unlock_tag,
			"description": memory.get("description", ""),
			"condition_tags": memory.get("condition_tags", []),
			"character_id": character_id,
			"dialogue_title": dialogue_title
		})
		
		print(script_name_tag(self, _fname) + "  Stored in memories_by_trigger[", trigger_type, "][", target_id, "]")
		
		# CREATE DIALOGUE MAPPING if this memory has dialogue_title
		if dialogue_title != "" and character_id != "" and unlock_tag != "":
			print(script_name_tag(self, _fname) + "  Creating dialogue mapping: ", unlock_tag, " -> ", character_id, ":", dialogue_title)
			
			dialogue_mapping[unlock_tag] = {
				"character_id": character_id,
				"dialogue_title": dialogue_title
			}
			print(script_name_tag(self, _fname) + "  Dialogue mapping created successfully")
		else:
			print(script_name_tag(self, _fname) + "  No dialogue mapping created:")
			print(script_name_tag(self, _fname) + "    dialogue_title empty: ", dialogue_title == "")
			print(script_name_tag(self, _fname) + "    character_id empty: ", character_id == "")
			print(script_name_tag(self, _fname) + "    unlock_tag empty: ", unlock_tag == "")
		
		print(script_name_tag(self, _fname) + "--- End processing ", memory_id, " ---")
	
	# Debug the final dialogue mappings
	print("\n" + script_name_tag(self, _fname) + "=== FINAL DIALOGUE MAPPING RESULTS ===")
	print(script_name_tag(self, _fname) + "dialogue_mapping size: ", dialogue_mapping.size())
	print(script_name_tag(self, _fname) + "Created dialogue mappings:")
	for memory_tag in dialogue_mapping:
		var mapping = dialogue_mapping[memory_tag]
		print(script_name_tag(self, _fname) + "  ", memory_tag, " -> ", mapping)
	print(script_name_tag(self, _fname) + "=== END ORGANIZE MEMORIES DEBUG ===")

# Also fix the debug function
func debug_memory_organization():
	var _fname = "debug_memory_organization"
	if not debug:
		return
	
	print("\n" + script_name_tag(self, _fname) + "=== MEMORY ORGANIZATION DEBUG ===")
	print(script_name_tag(self, _fname) + "memories_by_trigger structure:")
	
	for trigger_type in memories_by_trigger:
		print(script_name_tag(self, _fname) + "Trigger type ", trigger_type, " (", typeof(trigger_type), "):")
		var targets = memories_by_trigger[trigger_type]
		for target_id in targets:
			var memories = targets[target_id]
			print(script_name_tag(self, _fname) + "  Target '", target_id, "': ", memories.size(), " memories")
			for memory in memories:
				print(script_name_tag(self, _fname) + "    - ", memory.memory_id, " (", memory.unlock_tag, ")")
	
	print(script_name_tag(self, _fname) + "===================================\n")

# NEW: Fast memory lookup functions for MemorySystem
func get_memories_for_trigger(trigger_type: int, target_id: String) -> Array:
	var _fname = "get_memories_for_trigger"
	var memories = []
	
	# Direct lookup
	if memories_by_trigger.has(trigger_type) and memories_by_trigger[trigger_type].has(target_id):
		memories.append_array(memories_by_trigger[trigger_type][target_id])
	
	# Also check for lowercase version
	var lowercase_id = target_id.to_lower()
	if lowercase_id != target_id and memories_by_trigger.has(trigger_type):
		if memories_by_trigger[trigger_type].has(lowercase_id):
			memories.append_array(memories_by_trigger[trigger_type][lowercase_id])
	
	return memories

func gs_print(string):
	var _fname = "gs_print"
	print(script_name_tag(self, _fname) + string) 

func has_memory_definition(memory_id: String) -> bool:
	var _fname = "has_memory_definition"
	return memory_definitions.has(memory_id)

func get_memory_definition(memory_id: String) -> Dictionary:
	var _fname = "get_memory_definition"
	return memory_definitions.get(memory_id, {})

func get_memory_chain(chain_id: String) -> Dictionary:
	var _fname = "get_memory_chain"
	return memory_chains.get(chain_id, {})
	
func remove_tag(tag: String) -> void:
	var _fname = "remove_tag"
	if tags.has(tag):
		tags.erase(tag)
		tag_removed.emit(tag)
		
func get_tag_value(tag: String, default_value: Variant = null) -> Variant:
	var _fname = "get_tag_value"
	if tags.has(tag):
		return tags[tag]
	return default_value

# Generate a unique ID for this game session
func _generate_game_id():
	var _fname = "_generate_game_id"
	var time = Time.get_unix_time_from_system()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rand = rng.randi() % 10000
	
	return "game_" + str(time) + "_" + str(rand)

# Turn completion handlers
func _on_turn_completed():
	var _fname = "_on_turn_completed"
	# Emit signal from GameController
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("turn_completed"):
		game_controller.turn_completed.emit()

func _on_day_advanced():
	var _fname = "_on_day_advanced"
	# Emit signal from GameController
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("day_advanced"):
		game_controller.day_advanced.emit()

# Player and interaction functions (updated to avoid duplicate declarations)
func set_interaction_range(num):
	interaction_range = num
	
func get_interaction_range():
	return interaction_range

func get_player():
	return get_tree().get_first_node_in_group("player")

# Knowledge system functions (updated to avoid duplicate declarations)
func add_knowledge(tag):
	var _fname = "add_knowledge"
	if is_known(tag):
		if debug: print(script_name_tag(self, _fname) + tag + " is already known.")
	else:
		knowledge.append(tag)

func is_known(tag: String):
	if tag in knowledge:
		return true
	return false

# Scene and NPC management (updated to avoid duplicate declarations)
func set_current_scene(scene):
	var _fname = "set_current_scene"
	current_scene = scene
	if debug: print(script_name_tag(self, _fname) + "GameState: Set current scene to ", scene.name)
	
	# Update NPC and marker lists immediately
	set_current_npcs()
	set_current_markers()

func get_current_scene():
	return current_scene

func visit_scene(scene_name):
	scenes_visited.append(scene_name)

func scene_visited(scene_name):
	return scene_name in scenes_visited
	

func set_current_npcs():
	var _fname = "set_current_npcs"
	current_npc_list = get_tree().get_nodes_in_group("npc")
	if debug: print(script_name_tag(self, _fname) + "GameState: Updated NPC list with ", current_npc_list.size(), " NPCs")
	return current_npc_list

func get_current_npcs():
	return current_npc_list

func set_current_markers():
	var _fname = "set_current_markers"
	current_marker_list = get_tree().get_nodes_in_group("marker")
	if debug: print(script_name_tag(self, _fname) + "GameState: Updated marker list with ", current_marker_list.size(), " markers")
	return current_marker_list

func get_npc_by_id(npc_id):
	var _fname = "get_npc_by_id"
	# First update the list to make sure it's current
	if current_npc_list.size() == 0:
		set_current_npcs()
	
	# Try to find an NPC with matching name or character_id
	for npc in current_npc_list:
		print(script_name_tag(self, _fname) + "found character " + npc.name)
		if npc.name.to_lower() == npc_id.to_lower(): 
			return npc
			
		if npc.get("character_id") and npc.character_id.to_lower() == npc_id.to_lower():
			return npc
	
	if debug: print(script_name_tag(self, _fname) + "GameState: Could not find NPC with ID: ", npc_id)
	return null

func get_marker_by_id(marker_id):
	var _fname = "get_marker_by_id"
	# First update the list to make sure it's current
	if current_marker_list.size() == 0:
		set_current_markers()
		
	# Try to find a marker with matching name or marker_id
	for marker in current_marker_list:
		if marker.name.to_lower() == marker_id.to_lower():
			return marker
			
		if marker.has_method("get_marker_id") and marker.get_marker_id() == marker_id:
			return marker
		elif marker.get("marker_id") and marker.marker_id == marker_id:
			return marker
	
	if debug: print(script_name_tag(self, _fname) + "GameState: Could not find marker with ID: ", marker_id)
	return null

# Additional state functions (updated to avoid duplicate declarations)
func set_looking_at_adam_desk(tf : bool):
	looking_at_adam_desk = tf

func has_in_it(array : Array, tag : String):
	if tag in array:
		return true
	return false

# NEW: Memory discovery tracking
func discover_memory(memory_tag: String, description: String, discovery_method: String = "", character_id: String = ""):
	var _fname = "discover_memory"
	if memory_tag in discovered_memories:
		return false  # Already discovered
	
	# Add to discovered list
	discovered_memories.append(memory_tag)
	
	# Record discovery details
	var discovery_record = {
		"memory_tag": memory_tag,
		"description": description,
		"discovery_method": discovery_method,
		"character_id": character_id,
		"location": game_data.get("current_location", ""),
		"timestamp": Time.get_unix_time_from_system(),
		"game_day": game_data.get("current_day", 1)
	}
	memory_discovery_history.append(discovery_record)
	
	# Set the tag (using existing GameState functionality)
	tags[memory_tag] = true
	tag_added.emit(memory_tag)
	
	# Emit discovery signal
	memory_discovered.emit(memory_tag, description)
	
	if debug: print(script_name_tag(self, _fname) + "Memory discovered: ", memory_tag, " - ", description)
	return true

func has_discovered_memory(memory_tag: String) -> bool:
	return memory_tag in discovered_memories

func get_memory_discovery_history() -> Array:
	return memory_discovery_history.duplicate()

func get_character_discoveries(character_id: String) -> Array:
	var character_discoveries = []
	for record in memory_discovery_history:
		if record.character_id == character_id:
			character_discoveries.append(record)
	return character_discoveries

# Dialogue mapping functions
func add_dialogue_mapping(memory_tag: String, character_id: String, dialogue_title: String):
	dialogue_mapping[memory_tag] = {
		"character_id": character_id,
		"dialogue_title": dialogue_title
	}

func get_dialogue_mapping(memory_tag: String) -> Dictionary:
	return dialogue_mapping.get(memory_tag, {})


# Game management functions
func start_new_game():
	# Generate a unique ID for this game session
	current_game_id = _generate_game_id()
	is_new_game = true
	start_time = Time.get_unix_time_from_system()
	play_time = 0
	last_save_time = 0
	# Reset all game systems
	reset_all_systems()

	# Set default game data
	game_data = {
		"player_name": "Adam Major",
		"current_location": "dorm_room",
		"player_position": Vector2(966, 516),
		"current_day": 1,
		"current_turn": 0,
		"turns_per_day": 8
	}
	
	# Add starting items
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.add_item("common_lichen1", 1)
		inventory_system.add_item("rare_lichen1", 1)
		inventory_system.add_item("lichenology_book", 1)
		inventory_system.add_item("energy_drink", 2)
	
	# Initialize starting quest
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system.load_new_quest("intro_quest", true)
	
	# Load first scene
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		game_controller.change_scene("res://scenes/world/locations/dorm_room.tscn")
	
	
	_initialize_camera_roll_starter_images()

	
	# Emit signal
	game_started.emit(current_game_id)

# End current game
func end_game():
	reset_all_systems()
	if current_game_id == "":
		return
		
	# Update play time
	if start_time > 0:
		play_time += Time.get_unix_time_from_system() - start_time
	
	# Reset game state
	current_game_id = ""
	is_new_game = false
	start_time = 0
	
	# Optional: save stats or high scores here
	
	# Emit signal
	game_ended.emit()
	
	# Return to main menu
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		game_controller.change_scene("res://scenes/main_menu.tscn")

# Advance the turn
func advance_turn():
	game_data.current_turn += 1
	
	# Check for day change
	if game_data.current_turn >= game_data.turns_per_day:
		game_data.current_day += 1
		game_data.current_turn = 0
		_on_day_advanced()
	
	_on_turn_completed()
	
	# Update play time
	if start_time > 0:
		play_time += Time.get_unix_time_from_system() - start_time
		start_time = Time.get_unix_time_from_system()

# Save current game state
func save_game(slot):
	var save_data = _collect_save_data()
	
	var save_load_system = get_node_or_null("/root/SaveLoadSystem")
	if save_load_system:
		save_load_system.save_game(slot)
	
	last_save_time = Time.get_unix_time_from_system()
	game_saved.emit(slot)
	return true

# Load a saved game
func load_game(slot):
	reset_all_systems()
	var save_load_system = get_node_or_null("/root/SaveLoadSystem")
	if save_load_system:
		var success = save_load_system.load_game(slot)
		if success:
			game_loaded.emit(slot)
			return true
	
	return false

# Enhanced save/load to include memory data
func _collect_save_data():
	var _fname = "_collect_save_data"
	if debug: print(script_name_tag(self, _fname) + "Collecting save data from all systems")
	
	# Update play time before saving
	if start_time > 0:
		play_time += Time.get_unix_time_from_system() - start_time
		start_time = Time.get_unix_time_from_system()
	
	var save_data = {
		"save_format_version": 2,
		"game_id": current_game_id,
		"save_time": Time.get_unix_time_from_system(),
		"play_time": play_time,
		"game_data": game_data.duplicate(true),
		"tags": tags.duplicate(true),
		# Core GameState memory data
		"discovered_memories": discovered_memories.duplicate(),
		"memory_discovery_history": memory_discovery_history.duplicate(true),
		"dialogue_mapping": dialogue_mapping.duplicate(true)
	}
	
	# Inventory System
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system and inventory_system.has_method("get_save_data"):
		save_data["inventory_system"] = inventory_system.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected inventory data")
	
	# Quest System  
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("get_save_data"):
		save_data["quest_system"] = quest_system.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected quest data")
	
	# Pickup System
	var pickup_system = get_node_or_null("/root/PickupSystem")
	if pickup_system and pickup_system.has_method("get_save_data"):
		save_data["pickup_system"] = pickup_system.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected pickup system data")
		
	# Relationship System
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system and relationship_system.has_method("get_save_data"):
		save_data["relationship_system"] = relationship_system.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected relationship data")
	
	# Time System
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system and time_system.has_method("save_data"):
		save_data["time_system"] = time_system.save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected time data")
	
	# Memory System
	var memory_system = get_node_or_null("/root/MemorySystem")
	if memory_system and memory_system.has_method("get_save_data"):
		save_data["memory_system"] = memory_system.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected memory system data")
	
	# Phone Apps (if phone scene exists)
	var phone_scene = get_node_or_null("/root/Game/PhoneCanvasLayer/PhoneSceneInstance")
	if not phone_scene:
		phone_scene = get_node_or_null("/root/PhoneScene")
	if phone_scene and phone_scene.has_method("get_save_data"):
		save_data["phone_apps"] = phone_scene.get_save_data()
		if debug: print(script_name_tag(self, _fname) + "Collected phone app data")
	
	if debug: print(script_name_tag(self, _fname) + "Save data collection complete. Keys: ", save_data.keys())
	return save_data

func _apply_save_data(save_data):
	var _fname = "_apply_save_data"
	if typeof(save_data) != TYPE_DICTIONARY:
		if debug: print(script_name_tag(self, _fname) + "ERROR: Save data is not a dictionary")
		return false
	
	if debug: print(script_name_tag(self, _fname) + "Applying save data to all systems")
	
	# Core GameState data
	if save_data.has("game_id"):
		current_game_id = save_data.game_id
	if save_data.has("play_time"):
		play_time = save_data.play_time
	if save_data.has("game_data"):
		game_data = save_data.game_data.duplicate(true)
	if save_data.has("tags"):
		tags = save_data.tags.duplicate(true)
	
	# GameState memory data
	if save_data.has("discovered_memories"):
		discovered_memories = save_data.discovered_memories.duplicate()
	if save_data.has("memory_discovery_history"):
		memory_discovery_history = save_data.memory_discovery_history.duplicate(true)
	if save_data.has("dialogue_mapping"):
		dialogue_mapping = save_data.dialogue_mapping.duplicate(true)
	
	# Inventory System
	if save_data.has("inventory_system"):
		var inventory_system = get_node_or_null("/root/InventorySystem")
		if inventory_system and inventory_system.has_method("load_save_data"):
			inventory_system.load_save_data(save_data.inventory_system)
			if debug: print(script_name_tag(self, _fname) + "Applied inventory data")
	
	# Quest System
	if save_data.has("quest_system"):
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system and quest_system.has_method("load_save_data"):
			quest_system.load_save_data(save_data.quest_system)
			if debug: print(script_name_tag(self, _fname) + "Applied quest data")
	
	# Pickup System
	if save_data.has("pickup_system"):
		var pickup_system = get_node_or_null("/root/PickupSystem")
		if pickup_system and pickup_system.has_method("load_save_data"):
			pickup_system.load_save_data(save_data.pickup_system)
			if debug: print(script_name_tag(self, _fname) + "Applied pickup system data")
	
	# Relationship System
	if save_data.has("relationship_system"):
		var relationship_system = get_node_or_null("/root/RelationshipSystem")
		if relationship_system and relationship_system.has_method("load_save_data"):
			relationship_system.load_save_data(save_data.relationship_system)
			if debug: print(script_name_tag(self, _fname) + "Applied relationship data")
	
	# Time System
	if save_data.has("time_system"):
		var time_system = get_node_or_null("/root/TimeSystem")
		if time_system and time_system.has_method("load_data"):
			time_system.load_data(save_data.time_system)
			if debug: print(script_name_tag(self, _fname) + "Applied time data")
	
	# Memory System
	if save_data.has("memory_system"):
		var memory_system = get_node_or_null("/root/MemorySystem")
		if memory_system and memory_system.has_method("load_save_data"):
			memory_system.load_save_data(save_data.memory_system)
			if debug: print(script_name_tag(self, _fname) + "Applied memory system data")
	
	# Phone Apps
	if save_data.has("phone_apps"):
		var phone_scene = get_node_or_null("/root/Game/PhoneCanvasLayer/PhoneSceneInstance")
		if not phone_scene:
			phone_scene = get_node_or_null("/root/PhoneScene")
		if phone_scene and phone_scene.has_method("load_save_data"):
			phone_scene.load_save_data(save_data.phone_apps)
			if debug: print(script_name_tag(self, _fname) + "Applied phone app data")
	
	# Reset start time to now
	start_time = Time.get_unix_time_from_system()
	
	if debug: print(script_name_tag(self, _fname) + "Save data application complete")
	return true

# Enhanced reset for new games
func reset_all_systems():
	var _fname = "reset_all_systems"
	# Clear all tags
	tags.clear()
	
	# NEW: Clear memory progress
	discovered_memories.clear()
	memory_discovery_history.clear()
	
	# Reset other systems (using the existing systems list from your current GameState)
	var systems_to_reset = [
		"InventorySystem",
		"QuestSystem", 
		"RelationshipSystem",
		"DialogSystem",
		"PickupSystem",
		"PhoneSystem"
	]
	
		# NEW: Reset pickup system
	
	for system_name in systems_to_reset:
		var system
		if system_name == "PhoneSystem":
			system = get_node_or_null("/root/" + "Game/PhoneCanvasLayer/PhoneSceneInstance")
			if system and system.has_method("reset"):
				system.reset()
		else:
			system = get_node_or_null("/root/" + system_name)
			if system and system.has_method("reset"):
				system.reset()
			elif system_name == "InventorySystem" and system:
				if system.has_method("clear_inventory"):
					system.clear_inventory()
			elif system_name == "QuestSystem" and system:
				if system.has_method("load_quests"):
					system.load_quests({"active_quests": {}, "completed_quests": {}, "available_quests": {}, "visited_areas": {}})
			elif system_name == "PickupSystem" and system:
				if system.has_method("reset"):
					system.reset()
					if debug: print(script_name_tag(self, _fname) + "Reset pickup system")

func get_pickups():
	var _fname = "get_pickups"
	return get_tree().get_nodes_in_group("pickup")

func clear_pickups():
	var pickups = get_pickups()
	for pickup in pickups:
		pickup.die()

func print_pickups(called_from : String):
	var _fname = "print_pickups"
	var current_scene = get_current_scene()
	var pickup_names : String = ""
	if current_scene:
		if "location_scene" in current_scene: 
			for pickup in scenes[current_scene.name]["pickups"]:
				pickup_names += pickup["item_name"] + " at " + str(pickup["position"]) + ", "
			print(script_name_tag(self, _fname) + "Pickups stored for scene " + current_scene.name+ " = " + pickup_names.left(pickup_names.length()-2))
			#str(scenes[current_scene.name]["pickups"].size()))
		else:
			print(script_name_tag(self, _fname) + "No pickups stored for scene " + current_scene.name)
		

func clear_pickups_save_data():
	var _fname = "clear_pickups_save_data"
	var current_scene = get_current_scene()
	if current_scene:
		if "location_scene" in current_scene: 
			scenes[get_current_scene().name]["pickups"].clear()
		
func load_pickups_save_data():
	var _fname = "load_pickups_save_data"
	var current_scene = get_current_scene()
	if current_scene:
		if "location_scene" in current_scene: 
			scenes[current_scene.name]["pickups"] = []
			var pickups = get_pickups()
			if pickups:
				for pickup in pickups:
					scenes[current_scene.name]["pickups"].append(pickup.get_pickup_save_data()) 
				if debug: print(script_name_tag(self, _fname) + "Pickups for scene " + current_scene.name + " = " + str(scenes[current_scene.name]["pickups"].size()))
	

func get_scene_pickups_save_data():
	var _fname = "get_scene_pickups_save_data"
	var current_scene = get_current_scene()
	return scenes[get_current_scene().name]["pickups"]

# Debug function
func debug_memory_state():
	var _fname = "debug_memory_state"
	if not debug:
		return
	
	print("\n" + script_name_tag(self, _fname) + "=== GAMESTATE MEMORY DEBUG ===")
	print(script_name_tag(self, _fname) + "Memory definitions loaded: ", memory_definitions.size())
	print(script_name_tag(self, _fname) + "Memory chains loaded: ", memory_chains.size())
	print(script_name_tag(self, _fname) + "Discovered memories: ", discovered_memories.size())
	print(script_name_tag(self, _fname) + "Discovery history entries: ", memory_discovery_history.size())
	
	print("\n" + script_name_tag(self, _fname) + "Memories by trigger type:")
	for trigger_type in memories_by_trigger:
		var count = 0
		for target_id in memories_by_trigger[trigger_type]:
			count += memories_by_trigger[trigger_type][target_id].size()
		print(script_name_tag(self, _fname) + "  Type ", trigger_type, ": ", count, " memories")
	
	print(script_name_tag(self, _fname) + "============================\n")

# Debug function to check memory data structure
func debug_memory_definitions():
	var _fname = "debug_memory_definitions"
	if not debug:
		return
	
	if debug: print("\n" + script_name_tag(self, _fname) + "=== MEMORY DEFINITIONS DEBUG ===")
	if debug: print(script_name_tag(self, _fname) + "Total memory definitions: ", memory_definitions.size())
	
	for memory_id in memory_definitions:
		var memory = memory_definitions[memory_id]
		if debug: print(script_name_tag(self, _fname) + "Memory ID: ", memory_id)
		if debug: print(script_name_tag(self, _fname) + "  Type: ", typeof(memory))
		if typeof(memory) == TYPE_DICTIONARY:
			if debug: print(script_name_tag(self, _fname) + "  Keys: ", memory.keys())
			if debug: print(script_name_tag(self, _fname) + "  Trigger type: ", memory.get("trigger_type", "MISSING"))
			if debug: print(script_name_tag(self, _fname) + "  Target ID: ", memory.get("target_id", "MISSING"))
		else:
			print(script_name_tag(self, _fname) + "  Value: ", memory)
		print(script_name_tag(self, _fname) + "---")
	
	if debug: print(script_name_tag(self, _fname) + "Memories by trigger:")
	for trigger_type in memories_by_trigger:
		if debug: print(script_name_tag(self, _fname) + "  Type ", trigger_type, ": ", memories_by_trigger[trigger_type].size(), " targets")
	
	if debug: print(script_name_tag(self, _fname) + "===============================\n")
	
func script_name(node):
	var path_string = str(node.get_script().get_path())
	var slash_place = path_string.rfind("/", -1)
	var name_length = path_string.length() - slash_place - 1
	return path_string.right(name_length)
	#return(path_string.right(path_string.length() - 14))

func script_name_tag(node, function_name = null):
	var _fname = "script_name_tag"
	var this_tag : String
	var tracker_str = "%04d" % tracker_id
	if function_name:
		this_tag = tracker_str + ". " + script_name(node) + "." + function_name + ": "
	else:
		this_tag = tracker_str + ". " + script_name(node) + ": "
	tracker_id += 1
	return this_tag
