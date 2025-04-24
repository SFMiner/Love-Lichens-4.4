# fast_travel_system.gd
extends Node

# This autoload system provides fast travel functionality between locations
# It can be used via dialogue options or a dedicated fast travel UI

# Signal emitted when fast travel is initiated
signal fast_travel_initiated(location_name, spawn_point)

# Dictionary of available locations
# Key: location_id, Value: { name, scene_path, spawn_point, requires_item, requires_visit, description }
var available_locations = {
	"campus_quad": {
		"name": "Campus Quad",
		"scene_path": "res://scenes/world/locations/campus_quad.tscn",
		"spawn_point": "default",
		"requires_visit": false, # Always available
		"description": "The central meeting area of the university campus."
	},
	"cemetery": {
		"name": "Old Cemetery",
		"scene_path": "res://scenes/world/locations/cemetery.tscn", 
		"spawn_point": "entrance",
		"requires_visit": true,
		"description": "An old cemetery with abundant lichen growth on the tombstones."
	},
	"old_growth_forest": {
		"name": "Old Growth Forest",
		"scene_path": "res://scenes/world/locations/old_growth_forest.tscn",
		"spawn_point": "default",
		"requires_visit": true,
		"description": "A dense forest with ancient trees covered in rare lichens."
	},
	"permaculture_garden": {
		"name": "Permaculture Garden",
		"scene_path": "res://scenes/world/locations/permaculture_garden.tscn",
		"spawn_point": "default",
		"requires_visit": true,
		"description": "A sustainable garden with a variety of ecosystems."
	}
}

var visited_locations = {}
const scr_debug :bool = true
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug
	
	# Always mark campus quad as visited
	visited_locations["campus_quad"] = true
	
	# Connect to location changed signal from GameController
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_signal("location_changed"):
		game_controller.location_changed.connect(_on_location_changed)
		if debug: print("Connected to GameController location_changed signal")
	
	# No need to register with the DialogueManager - the singleton will be 
# automatically available in dialogue scripts through "FastTravelSystem" since
# we registered it in the project.godot file as an autoload
	if debug: print("FastTravelSystem initialized - accessible in dialogue files")

# Called when the player changes location
func _on_location_changed(old_location, new_location):
	if debug: print("Location changed from ", old_location, " to ", new_location)
	
	# Mark this location as visited
	if available_locations.has(new_location):
		visited_locations[new_location] = true
		if debug: print("Marked location as visited: ", new_location)

# Get a list of available fast travel locations
func get_available_locations():
	var result = []
	
	for location_id in available_locations:
		var location_data = available_locations[location_id]
		
		# Check if this location is available
		var available = true
		
		# If location requires a previous visit and hasn't been visited, it's not available
		if location_data.requires_visit and not visited_locations.has(location_id):
			available = false
		
		# If location requires an item, check if player has it
		if location_data.has("requires_item") and location_data.requires_item != "":
			var inventory_system = get_node_or_null("/root/InventorySystem")
			if inventory_system and not inventory_system.has_item(location_data.requires_item):
				available = false
		
		if available:
			result.append({
				"id": location_id,
				"name": location_data.name,
				"description": location_data.description if location_data.has("description") else ""
			})
	
	return result

# Fast travel to a specified location
func fast_travel(location_id, spawn_point = null):
	if debug: print("Attempting fast travel to: ", location_id)
	
	# Validate the location
	if not available_locations.has(location_id):
		if debug: print("Invalid location: ", location_id)
		return false
	
	var location_data = available_locations[location_id]
	
	# Check if location is available
	if location_data.requires_visit and not visited_locations.has(location_id):
		if debug: print("Location hasn't been visited yet: ", location_id)
		return false
	
	# Check if required item is available
	if location_data.has("requires_item") and location_data.requires_item != "":
		var inventory_system = get_node_or_null("/root/InventorySystem")
		if not inventory_system or not inventory_system.has_item(location_data.requires_item):
			if debug: print("Missing required item: ", location_data.requires_item)
			return false
	
	# Use specified spawn point or default from location data
	var target_spawn = spawn_point if spawn_point else location_data.spawn_point
	
	# Emit signal
	fast_travel_initiated.emit(location_id, target_spawn)
	
	# Perform the scene transition
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		# If game controller has the enhanced change_location method, use it
		if game_controller.has_method("change_location"):
			game_controller.change_location(location_data.scene_path, target_spawn)
			if debug: print("Fast traveled to: ", location_id, " at spawn point: ", target_spawn)
			return true
		# Otherwise fallback to basic scene change
		else:
			game_controller.change_scene(location_data.scene_path)
			if debug: print("Fast traveled to: ", location_id, " (basic scene change)")
			return true
	
	return false

# Helper method for dialogue integration - returns a list of travel options
func get_travel_options_for_dialogue():
	var options = get_available_locations()
	var result = []
	
	for option in options:
		result.append(option.name + ": " + option.description)
	
	return result

# Method to be called from dialogue options
func handle_dialogue_travel_selection(option_index):
	var options = get_available_locations()
	
	if option_index >= 0 and option_index < options.size():
		var location = options[option_index]
		return fast_travel(location.id)
	
	return false
