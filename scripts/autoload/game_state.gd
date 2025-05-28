# game_state.gd
extends Node

signal game_started(game_id)
signal game_saved(slot)
signal game_loaded(slot)
signal game_ended()
signal tag_added(tag)
signal tag_removed(tag)

# Core game state 
var current_game_id = ""
var is_new_game = false
var start_time = 0
var play_time = 0
var last_save_time = 0
var interaction_range = 0
var player : CharacterBody2D = null
# Tag system for memory and game state tracking
var tags: Dictionary = {}
var looking_at_adam_desk = false
var poison_bugs = ["tarantula"]
var atlas_emergence : int = 28
var current_day : float = 0

var current_scene
var current_npc_list = []
var current_marker_list = []


const scr_debug : bool = true
var debug 

# Game metadata
var game_data = {
	"player_name": "Adam Major",
	"current_location": "",
	"player_position": Vector2.ZERO,
	"current_day": 1,
	"current_turn": 0,
	"turns_per_day": 8
}

# Systems that need resetting when starting a new game
var systems_to_reset = [
	"InventorySystem",
	"QuestSystem",
	"RelationshipSystem",
	"DialogSystem"
]

func _ready():
	debug = scr_debug or GameController.sys_debug

# Start a new game
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
	
	# Emit signal
	game_started.emit(current_game_id)

# End current game
func end_game():
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

# Reset all game systems
func reset_all_systems():
	# Clear all tags
	tags.clear()
	
	for system_name in systems_to_reset:
		var system = get_node_or_null("/root/" + system_name)
		if system and system.has_method("reset"):
			system.reset()
		elif system_name == "InventorySystem" and system:
			# Specific handling for inventory if it doesn't have reset
			if system.has_method("clear_inventory"):
				system.clear_inventory()
		elif system_name == "QuestSystem" and system:
			# Quest system reset
			if system.has_method("load_quests"):
				system.load_quests({"active_quests": {}, "completed_quests": {}, "available_quests": {}, "visited_areas": {}})

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
	var save_load_system = get_node_or_null("/root/SaveLoadSystem")
	if save_load_system:
		var success = save_load_system.load_game(slot)
		if success:
			game_loaded.emit(slot)
			return true
	
	return false

# Collect all game state data for saving
func _collect_save_data():
	# Update play time before saving
	if start_time > 0:
		play_time += Time.get_unix_time_from_system() - start_time
		start_time = Time.get_unix_time_from_system()
	
	var save_data = {
		"game_id": current_game_id,
		"save_time": Time.get_unix_time_from_system(),
		"play_time": play_time,
		"game_data": game_data.duplicate(true),
		"tags": tags.duplicate(true)
	}
	
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		save_data["time_system"] = time_system.save_data()
	
	return save_data

# Apply loaded data to restore game state
func _apply_save_data(save_data):
	if typeof(save_data) != TYPE_DICTIONARY:
		return false
	
	if save_data.has("game_id"):
		current_game_id = save_data.game_id
	
	if save_data.has("play_time"):
		play_time = save_data.play_time
	
	if save_data.has("game_data"):
		game_data = save_data.game_data.duplicate(true)
	
	if save_data.has("tags"):
		tags = save_data.tags.duplicate(true)
	
	# Load time system data
	if save_data.has("time_system"):
		var time_system = get_node_or_null("/root/TimeSystem")
		if time_system:
			time_system.load_data(save_data.time_system)
	
	# Reset start time to now
	start_time = Time.get_unix_time_from_system()
	
	return true

# Generate a unique ID for this game session
func _generate_game_id():
	var time = Time.get_unix_time_from_system()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rand = rng.randi() % 10000
	
	return "game_" + str(time) + "_" + str(rand)

# Turn completion handlers
func _on_turn_completed():
	# Emit signal from GameController
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("turn_completed"):
		game_controller.turn_completed.emit()

func _on_day_advanced():
	# Emit signal from GameController
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("day_advanced"):
		game_controller.day_advanced.emit()

func set_interaction_range(num):
	interaction_range = num
	
func get_interaction_range():
	return interaction_range

# Tag system functions
func has_tag(tag: String) -> bool:
	return tags.has(tag)

func set_tag(tag: String, value: Variant = true) -> void:
	tags[tag] = value
	tag_added.emit(tag)
	
func remove_tag(tag: String) -> void:
	if tags.has(tag):
		tags.erase(tag)
		tag_removed.emit(tag)
		
func get_tag_value(tag: String, default_value: Variant = null) -> Variant:
	if tags.has(tag):
		return tags[tag]
	return default_value

func get_player():
	return 	get_tree().get_first_node_in_group("player")
	
var knowledge : Array[String]= []

func add_knowledge(tag):
	if is_known(tag):
		if debug: print(tag + " is already known.")
	else:
		knowledge.append(tag)

func is_known(tag: String):
	if tag in knowledge:
		return true
	return false
	
func set_looking_at_adam_desk(tf : bool):
	looking_at_adam_desk = tf

func has_in_it(array : Array, tag : String):
	if tag in array:
		return true
	return false


func set_current_scene(scene):
	current_scene = scene
	if debug: print("GameState: Set current scene to ", scene.name)
	
	# Update NPC and marker lists immediately
	set_current_npcs()
	set_current_markers()

func get_current_scene():
	return current_scene

func set_current_npcs():
	current_npc_list = get_tree().get_nodes_in_group("npc")
	if debug: print("GameState: Updated NPC list with ", current_npc_list.size(), " NPCs")
	return current_npc_list

func get_current_npcs():
	return current_npc_list

func set_current_markers():
	current_marker_list = get_tree().get_nodes_in_group("marker")
	if debug: print("GameState: Updated marker list with ", current_marker_list.size(), " markers")
	return current_marker_list

func get_npc_by_id(npc_id):
	# First update the list to make sure it's current
	if current_npc_list.size() == 0:
		set_current_npcs()
	
	# Try to find an NPC with matching name or character_id
	for npc in current_npc_list:
		print("found character " + npc.name)
		if npc.name.to_lower() == npc_id.to_lower(): 
			return npc
			
		if npc.get("character_id") and npc.character_id.to_lower() == npc_id.to_lower():
			return npc
	
	if debug: print("GameState: Could not find NPC with ID: ", npc_id)
	return null

func get_marker_by_id(marker_id):
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
	
	if debug: print("GameState: Could not find marker with ID: ", marker_id)
	return null
	
func get_current_date_string():
	var current_date_string = str(TimeSystem.current_day) + "_" + str(TimeSystem.current_month) + "_" + str(TimeSystem.current_year)
	return (current_date_string)
