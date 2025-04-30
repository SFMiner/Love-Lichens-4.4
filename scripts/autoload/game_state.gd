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

var poison_bugs = ["empty"]

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
	pass

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
