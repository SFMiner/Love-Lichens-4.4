@tool
extends Node2D

# Cutscene Designer Tool
# Add this to location scenes temporarily to design cutscenes visually
# Export marker positions to JSON, then remove from scene

@export var cutscene_id: String = "": set = _set_cutscene_id
@export var location_name: String = "": set = _set_location_name
@export_group("Characters")
@export var number_of_characters: int = 0: set = _set_number_of_characters
@export var character_data: Array[CharacterData] = []
@export_group("Export")
@export var export_to_json: bool = false: set = _export_to_json
@export var cutscenes_base_path: String = "res://data/cutscenes/"
@export_group("Preview")
@export var show_marker_labels: bool = true: set = _set_show_labels
@export var marker_color: Color = Color.RED: set = _set_marker_color

var marker_nodes: Array[Node2D] = []
var exported_data: Dictionary = {}


func _ready():
	if Engine.is_editor_hint():
		_collect_markers()
		_update_visual_display()
		print("Cutscene Designer: Found ", marker_nodes.size(), " markers")

func _set_cutscene_id(value: String):
	cutscene_id = value
	if Engine.is_editor_hint():
		_update_display()

func _set_location_name(value: String):
	location_name = value
	if Engine.is_editor_hint():
		_update_display()

func _set_number_of_characters(value: int):
	number_of_characters = value
	if Engine.is_editor_hint():
		_update_character_array()

func _update_character_array():
	"""Update the character_data array when number_of_characters changes"""
	# Resize the array to match the number of characters
	while character_data.size() < number_of_characters:
		var new_char = CharacterData.new()
		character_data.append(new_char)
	
	while character_data.size() > number_of_characters:
		character_data.pop_back()
	
	# Force the inspector to update
	notify_property_list_changed()
	
	print("Updated character array to ", character_data.size(), " characters")

func _set_show_labels(value: bool):
	show_marker_labels = value
	if Engine.is_editor_hint():
		_update_visual_display()

func _set_marker_color(value: Color):
	marker_color = value
	if Engine.is_editor_hint():
		_update_visual_display()

func _export_to_json(value: bool):
	if value and Engine.is_editor_hint():
		export_cutscene_data()
	export_to_json = false  # Reset the button

func _collect_markers():
	"""Collect all marker nodes from direct children"""
	marker_nodes.clear()
	
	# Get all direct children - they're all markers
	for child in get_children():
		if child is Node2D:
			marker_nodes.append(child as Node2D)
	
	print("Cutscene Designer: Collected ", marker_nodes.size(), " markers: ", _get_marker_names())

func _recursive_find_markers(node: Node):
	"""Recursively find all nodes with 'marker' in their name or that are in the 'marker' group"""
	# This function is no longer used since we just get direct children
	pass

func _get_marker_names() -> Array:
	"""Get array of marker names for debugging"""
	var names = []
	for marker in marker_nodes:
		names.append(marker.name)
	return names

func _update_display():
	"""Update the designer display"""
	if not Engine.is_editor_hint():
		return
	
	_collect_markers()
	_update_visual_display()

func _update_visual_display():
	"""Update visual elements of markers"""
	if not Engine.is_editor_hint():
		return
	
	for marker in marker_nodes:
		_update_marker_display(marker)

func _update_marker_display(marker: Node2D):
	"""Update the visual display of a single marker"""
	if not marker:
		return
	
	# Find or create ColorRect for visual indicator
	var color_rect = marker.get_node_or_null("ColorRect")
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.name = "ColorRect"
		color_rect.size = Vector2(32, 32)
		color_rect.position = Vector2(-16, -16)  # Center it
		marker.add_child(color_rect)
		color_rect.owner = get_tree().edited_scene_root
	
	# Update color and visibility
	color_rect.color = marker_color
	color_rect.modulate.a = 0.7  # Semi-transparent
	color_rect.visible = true
	
	# Find or create label
	var label = color_rect.get_node_or_null("Label")
	if not label and show_marker_labels:
		label = Label.new()
		label.name = "Label"
		label.position = Vector2(0, -20)
		label.size = Vector2(100, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		color_rect.add_child(label)
		label.owner = get_tree().edited_scene_root
	
	if label:
		label.text = marker.name
		label.visible = show_marker_labels

func export_cutscene_data():
	"""Export the cutscene data to individual JSON file"""
	if cutscene_id == "":
		print("ERROR: cutscene_id must be set before exporting")
		return
	
	if location_name == "":
		print("ERROR: location_name must be set before exporting")
		return
	
	# Collect marker positions
	var marker_positions = {}
	for marker in marker_nodes:
		marker_positions[marker.name] = {
			"x": marker.position.x,
			"y": marker.position.y
		}
	
	print("Cutscene Designer: Exporting ", marker_positions.size(), " marker positions")
	print("Marker positions: ", marker_positions)
	
	# Build file path: res://data/cutscenes/[location_name]/cs_[cutscene_id].json
	var file_path = _get_cutscene_file_path()
	
	# Load existing cutscene data or create new
	var cutscene_data = _load_existing_cutscene_data(file_path)
	
	# Update marker positions and basic info
	cutscene_data["cutscene_id"] = cutscene_id
	cutscene_data["location"] = location_name
	cutscene_data["marker_positions"] = marker_positions
	
	# Export character data
	var npcs_data = []
	var player_start_marker = ""
	
	for char_data in character_data:
		if char_data.character_id == "":
			continue  # Skip empty character entries
		
		if char_data.is_player:
			# This is the player
			player_start_marker = char_data.starting_marker
		else:
			# This is an NPC
			var npc_entry = {
				"id": char_data.character_id,
				"scene_path": char_data.scene_path,
				"marker": char_data.starting_marker,
				"character_id": char_data.character_id,
				"character_name": char_data.character_name,
				"dialogue_file": char_data.dialogue_file,
				"dialogue_title": char_data.initial_dialogue_title,
				"initial_animation": char_data.initial_animation,
				"temporary": char_data.temporary
			}
			npcs_data.append(npc_entry)
	
	cutscene_data["npcs"] = npcs_data
	if player_start_marker != "":
		cutscene_data["player_start_marker"] = player_start_marker
	
	# Set defaults for new cutscenes
	if not cutscene_data.has("dialog_file"):
		cutscene_data["dialog_file"] = cutscene_id
	if not cutscene_data.has("dialog_title"):
		cutscene_data["dialog_title"] = "start"
	if not cutscene_data.has("description"):
		cutscene_data["description"] = "Auto-generated cutscene"
	if not cutscene_data.has("triggers"):
		cutscene_data["triggers"] = []
	if not cutscene_data.has("unlocks"):
		cutscene_data["unlocks"] = []
	if not cutscene_data.has("one_time"):
		cutscene_data["one_time"] = true
	if not cutscene_data.has("auto_trigger"):
		cutscene_data["auto_trigger"] = false
	if not cutscene_data.has("priority"):
		cutscene_data["priority"] = 1
	if not cutscene_data.has("npcs"):
		cutscene_data["npcs"] = []
	if not cutscene_data.has("props"):
		cutscene_data["props"] = []
	
	# Save to individual file
	_save_cutscene_file(file_path, cutscene_data)
	
	exported_data = cutscene_data
	print("Cutscene Designer: Export complete to ", file_path)

func _get_cutscene_file_path() -> String:
	"""Get the file path for this cutscene"""
	return cutscenes_base_path + location_name + "/cs_" + cutscene_id + ".json"

func _load_existing_cutscene_data(file_path: String) -> Dictionary:
	"""Load existing cutscene data or return empty dict"""
	if not FileAccess.file_exists(file_path):
		print("Creating new cutscene file: ", file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open cutscene file: ", file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse existing cutscene JSON: ", json.get_error_message())
		return {}
	
	var data = json.data
	if data is Dictionary:
		print("Loaded existing cutscene data from: ", file_path)
		return data
	else:
		print("Cutscene file is not a valid dictionary")
		return {}

func _save_cutscene_file(file_path: String, cutscene_data: Dictionary):
	"""Save the cutscene data to individual JSON file"""
	# Ensure directory exists
	var dir_path = file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.open("res://").make_dir_recursive(dir_path)
		print("Created directory: ", dir_path)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("ERROR: Failed to open cutscene file for writing: ", file_path)
		return
	
	var json_string = JSON.stringify(cutscene_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("Saved cutscene to: ", file_path)

# Helper functions for editor workflow

func create_marker(marker_name: String, position: Vector2) -> Node2D:
	"""Create a new marker at the specified position"""
	if not Engine.is_editor_hint():
		return null
	
	var marker = Node2D.new()
	marker.name = marker_name
	marker.position = position
	add_child(marker)
	marker.owner = get_tree().edited_scene_root
	marker.add_to_group("marker")
	
	_update_marker_display(marker)
	_collect_markers()
	
	print("Created marker: ", marker_name, " at ", position)
	return marker

func remove_all_markers():
	"""Remove all marker nodes (for cleanup)"""
	if not Engine.is_editor_hint():
		return
	
	for marker in marker_nodes:
		if is_instance_valid(marker):
			marker.queue_free()
	
	marker_nodes.clear()
	print("Removed all markers")

func cleanup_for_export():
	"""Clean up visual elements before exporting scene (optional)"""
	if not Engine.is_editor_hint():
		return
	
	for marker in marker_nodes:
		var color_rect = marker.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.visible = false

# Validation functions

func validate_cutscene() -> Array[String]:
	"""Validate the current cutscene setup and return any errors"""
	var errors: Array[String] = []
	
	if cutscene_id == "":
		errors.append("cutscene_id is required")
	
	if location_name == "":
		errors.append("location_name is required")
	
	if marker_nodes.size() == 0:
		errors.append("No markers found - add some markers as children")
	
	# Check for duplicate marker names
	var marker_names = {}
	for marker in marker_nodes:
		if marker_names.has(marker.name):
			errors.append("Duplicate marker name: " + marker.name)
		marker_names[marker.name] = true
	
	# Validate character data
	var player_count = 0
	var character_ids = {}
	
	for i in range(character_data.size()):
		var char_data = character_data[i]
		
		if char_data.character_id == "":
			continue  # Empty entries are ok
		
		# Check for duplicate character IDs
		if character_ids.has(char_data.character_id):
			errors.append("Duplicate character_id: " + char_data.character_id)
		character_ids[char_data.character_id] = true
		
		# Count players
		if char_data.is_player:
			player_count += 1
		
		# Check if starting marker exists
		if char_data.starting_marker != "":
			var marker_exists = false
			for marker in marker_nodes:
				if marker.name == char_data.starting_marker:
					marker_exists = true
					break
			if not marker_exists:
				errors.append("Character " + char_data.character_id + " references non-existent marker: " + char_data.starting_marker)
		
		# Validate NPC scene path
		if not char_data.is_player and char_data.scene_path != "" and not ResourceLoader.exists(char_data.scene_path):
			errors.append("Character " + char_data.character_id + " scene path not found: " + char_data.scene_path)
	
	# Check player count
	if player_count > 1:
		errors.append("Only one character can be marked as player, found: " + str(player_count))
	
	return errors

func get_export_preview() -> String:
	"""Get a preview of what will be exported"""
	var preview = "=== CUTSCENE EXPORT PREVIEW ===\n"
	preview += "Cutscene ID: " + cutscene_id + "\n"
	preview += "Location: " + location_name + "\n"
	preview += "Markers (" + str(marker_nodes.size()) + "):\n"
	
	for marker in marker_nodes:
		preview += "  - " + marker.name + " at " + str(marker.position) + "\n"
	
	preview += "\nCharacters (" + str(character_data.size()) + "):\n"
	for char_data in character_data:
		if char_data.character_id != "":
			var type = "Player" if char_data.is_player else "NPC"
			preview += "  - " + char_data.character_id + " (" + type + ") at marker " + char_data.starting_marker + "\n"
			if not char_data.is_player:
				preview += "    Scene: " + char_data.scene_path + "\n"
				preview += "    Dialogue: " + char_data.dialogue_file + " -> " + char_data.initial_dialogue_title + "\n"
	
	var errors = validate_cutscene()
	if errors.size() > 0:
		preview += "\nERRORS:\n"
		for error in errors:
			preview += "  ! " + error + "\n"
	
	return preview
