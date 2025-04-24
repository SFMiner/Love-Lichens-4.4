# character_data_loader.gd
extends Node

# Character data storage
var characters: Dictionary = {}
const CHARACTER_DATA_PATH = "res://data/characters/"

# Debug flag
const scr_debug : bool = false
var debug

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug
	if debug: print("Character Data Loader initialized")
	
	# Ensure character directory exists
	_ensure_character_directory()
	
	# Load all character data
	_load_all_character_data()

# Ensure the character data directory exists
func _ensure_character_directory() -> void:
	var dir = DirAccess.open("res://data/")
	if not dir:
		if debug: print("ERROR: Could not open data directory")
		return
		
	if not dir.dir_exists("characters"):
		if debug: print("Creating characters directory")
		dir.make_dir("characters")
	
	if debug: print("Character directory ready")

# Load all character data from JSON files
func _load_all_character_data() -> void:
	var dir = DirAccess.open(CHARACTER_DATA_PATH)
	if not dir:
		if debug: print("ERROR: Could not open character data directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path = CHARACTER_DATA_PATH + file_name
			_load_character_file(path)
		file_name = dir.get_next()
	
	if debug: print("Loaded ", characters.size(), " characters")

# Load a single character file
func _load_character_file(path: String) -> void:
	if debug: print("_load_character_file called.")
	if not FileAccess.file_exists(path):
		if debug: print("ERROR: Character file does not exist: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json_result = JSON.new()
	var parse_result = json_result.parse(json_text)
	if parse_result != OK:
		if debug: print("ERROR: Failed to parse character JSON (", path, "): ", json_result.get_error_message())
		return
	
	var character_data = json_result.get_data()
	if typeof(character_data) != TYPE_DICTIONARY:
		if debug: print("ERROR: Character JSON must be a dictionary (", path, ")")
		return
	
	# Create and store character data
	var character = CharacterData.new()
	character.from_dict(character_data)
	characters[character.id] = character
	
	if debug: print("Loaded character: ", character.id)

# Get a character's data by ID
func get_character(character_id: String) -> CharacterData:
	if character_id in characters:
		return characters[character_id]
	else:
		# Try to load the character file directly - using lowercase filename
		var path = CHARACTER_DATA_PATH + character_id.to_lower() + ".json"
		if debug: print(character_id + " character path is " + path)
		if FileAccess.file_exists(path):
			if debug: print(path + " exists.")
			_load_character_file(path)
			if character_id in characters:
				return characters[character_id]
			else:
				if debug: print(character_id + " does not exist in characters:")
				if debug: print(characters)
		else:
			if debug: print(path + " does not exist.")

	
	if debug: print("ERROR: Character data not found for: ", character_id)
	return null

# Apply character data to an NPC node
func apply_character_data(npc: Node, character_id: String) -> bool:
	var character_data = get_character(character_id)
	if not character_data:
		return false
	
	# Apply basic properties
	if "character_id" in npc:
		npc.character_id = character_data.id
	if "character_name" in npc:
		npc.character_name = character_data.name
	if "description" in npc:
		npc.description = character_data.description
	if "initial_dialogue_title" in npc:
		npc.initial_dialogue_title = character_data.initial_dialogue_title
	
	# Apply portrait if available
	if "portrait" in npc and ResourceLoader.exists(character_data.portrait_path):
		npc.portrait = load(character_data.portrait_path)
	
	# Set observable features
	if npc.has_method("add_observable_feature"):
		for feature_id in character_data.observable_features:
			var feature = character_data.observable_features[feature_id]
			npc.add_observable_feature(feature_id, feature.description)
	
	return true
