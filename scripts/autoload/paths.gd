extends Node

# Centralized path constants for Love & Lichens
# Prevents hardcoded paths throughout the codebase

const SCENES = {
	"main_menu": "res://scenes/main_menu.tscn",
	"game": "res://scenes/game.tscn",
	"dorm_room": "res://scenes/world/locations/dorm_room.tscn",
	"campus_quad": "res://scenes/world/locations/campus_quad.tscn",
	"campus_path": "res://scenes/world/locations/campus_path.tscn",
	"science_building": "res://scenes/world/locations/science_building.tscn",
	"library": "res://scenes/world/locations/library.tscn",
	"greenhouse": "res://scenes/world/locations/greenhouse.tscn"
}

const UI = {
	"inventory_panel": "res://scenes/ui/inventory_panel.tscn",
	"quest_panel": "res://scenes/ui/quest_panel.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn",
	"dialogue_balloon": "res://scenes/ui/dialogue_balloon.tscn"
}

const DATA = {
	"items": "res://data/items/",
	"quests": "res://data/quests/",
	"dialogues": "res://data/dialogues/",
	"memories": "res://data/memories/",
	"characters": "res://data/characters/"
}

const SCRIPTS = {
	"player": "res://scripts/world/player.gd",
	"npc": "res://scripts/world/npc.gd"
}

# Helper function to get scene path
static func get_scene(scene_id: String) -> String:
	if SCENES.has(scene_id):
		return SCENES[scene_id]
	push_warning("Unknown scene ID: " + scene_id)
	return ""

# Helper function to get UI path
static func get_ui(ui_id: String) -> String:
	if UI.has(ui_id):
		return UI[ui_id]
	push_warning("Unknown UI ID: " + ui_id)
	return ""

# Helper function to get data directory
static func get_data_dir(data_type: String) -> String:
	if DATA.has(data_type):
		return DATA[data_type]
	push_warning("Unknown data type: " + data_type)
	return ""
