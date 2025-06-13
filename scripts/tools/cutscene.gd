# cutscene.gd  
# Updated main controller script for cutscenes that integrates with CutsceneManager
# This script reads cutscene data from the JSON registry automatically

extends Node2D

@export var cutscene_id: String = ""

# Loaded cutscene data from JSON
var cutscene_data: Dictionary = {}
var dialog_file: String = ""
var auto_start: bool = false
var cleanup_after_cutscene: bool = true
var npcs_to_spawn: Array = []
var props_to_spawn: Array = []

# Internal references
var spawned_npcs: Array[Node] = []
var spawned_props: Array[Node] = []
var marker_nodes: Array[Node] = []
var target_scene: Node = null
var z_objects_container: Node = null
var cutscene_manager: Node = null

# Signal emitted when cutscene setup is complete
signal cutscene_ready
signal cutscene_finished

const scr_debug : bool = true
var debug

func _ready():
	const _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, _fname) + "Cutscene initialized!")
	# Get reference to CutsceneManager
	cutscene_manager = CutsceneManager
	
	if debug: print(GameState.script_name_tag(self, _fname) + "cutscene_id = " + cutscene_id)

	# Load cutscene data from registry
	if cutscene_id != "":
		load_cutscene_data()
	if debug: print(GameState.script_name_tag(self, _fname) + "load_cutscene_data passed")

	# Find the target scene and z_Objects container
	_find_target_containers()
	if debug: print(GameState.script_name_tag(self, _fname) + "_find_target_containers passed")
	
	# Collect all markers in this cutscene
	_collect_markers()
	if debug: print(GameState.script_name_tag(self, _fname) + "_collect_markers passed")

	# Setup the cutscene
	setup_cutscene()
	if debug: print(GameState.script_name_tag(self, _fname) + "_collect_markers passed")

	if auto_start:
		call_deferred("start_cutscene")

func load_cutscene_data():
	const _fname : String = "load_cutscene_data"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Load cutscene configuration from the JSON registry"""
	if debug: print(GameState.script_name_tag(self, _fname) + "load_cutscene_data called.")
	if not cutscene_manager:
		if debug: print(GameState.script_name_tag(self, _fname) + "CutsceneManager not found, cannot load cutscene data")
		return
	
	cutscene_data = cutscene_manager.get_cutscene_data(cutscene_id)
	if debug: print(GameState.script_name_tag(self, _fname) + "cutscene_id = ", cutscene_id)
	if debug: print(GameState.script_name_tag(self, _fname) + "Cutscen_data = ", cutscene_data)
	if debug: print(GameState.script_name_tag(self, _fname) + "cutscene_manager.get_cutscene_data(cutscene_id)", cutscene_manager.get_cutscene_data(cutscene_id))
	if cutscene_data.is_empty():
		if debug: print(GameState.script_name_tag(self, _fname) + "No cutscene data found for ID: ", cutscene_id)
		return
	
	# Load basic properties from JSON
	dialog_file = cutscene_data.get("dialog_file", "")
	auto_start = cutscene_data.get("auto_trigger", false)
	cleanup_after_cutscene = cutscene_data.get("cleanup", true)
	
	# Load NPCs and props if defined in the data
	npcs_to_spawn = cutscene_data.get("npcs", [])
	props_to_spawn = cutscene_data.get("props", [])
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Loaded cutscene data for: ", cutscene_id)

func _find_target_containers():
	const _fname : String = "_find_target_containers"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Find the main scene and z_Objects container to spawn entities in"""
	var current_scene = get_tree().current_scene
	
	# Look for a Node2D with z_Objects child (typical structure)
	target_scene = current_scene.find_child("Node2D", true, false)
	if not target_scene:
		target_scene = current_scene
	
	# Find z_Objects container
	z_objects_container = target_scene.find_child("z_Objects", true, false)
	if not z_objects_container:
		# Create z_Objects if it doesn't exist
		z_objects_container = Node2D.new()
		z_objects_container.name = "z_Objects"
		z_objects_container.y_sort_enabled = true
		target_scene.add_child(z_objects_container)
		if debug: print(GameState.script_name_tag(self, _fname) + "Created z_Objects container for cutscene")

func _collect_markers():
	const _fname : String = "_collect_markers"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Collect all marker nodes from this cutscene"""
	marker_nodes.clear()
	_recursive_find_markers(self)
	
	# Add markers to the "marker" group so GameState can find them
	for marker in marker_nodes:
		if not marker.is_in_group("marker"):
			marker.add_to_group("marker")
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Cutscene collected ", marker_nodes.size(), " markers")

func _recursive_find_markers(node: Node):
	const _fname : String = "_recursive_find_markers"
	
	marker_nodes = get_tree().get_nodes_in_group("marker_nodes")
	#"""Recursively find all nodes with 'marker' in their name"""
	
	#if "marker" in node.name.to_lower():
	#	marker_nodes.append(node)
	
	#for child in node.get_children():
	#	_recursive_find_markers(child)

func get_marker_position(marker_name: String) -> Vector2:
	const _fname : String = "get_marker_position"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Get the global position of a marker by name"""
	for marker in marker_nodes:
		if marker.name.to_lower() == marker_name.to_lower():
			return marker.global_position
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Warning: Marker '", marker_name, "' not found in cutscene")
	return Vector2.ZERO

func setup_cutscene():
	const _fname : String = "setup_cutscene"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Main setup function - spawn NPCs and props"""
	
	_spawn_npcs()
	_spawn_props()
	
	# Update GameState with new entities
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_current_npcs()
		game_state.set_current_markers()
	
	cutscene_ready.emit()
	if debug: print(GameState.script_name_tag(self, _fname) + "Cutscene setup complete: ", cutscene_id)

func _spawn_npcs():
	const _fname : String = "_spawn_npcs"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Spawn all NPCs defined in npcs_to_spawn from JSON data"""
	if debug: print(GameState.script_name_tag(self, _fname) + "npocs to spwan = " + str(npcs_to_spawn))
	for npc_data in npcs_to_spawn:
		if not npc_data is Dictionary:
			if debug: print(GameState.script_name_tag(self, _fname) + "npc_data is not  Dictionary.")
			continue
			
		var scene_path = npc_data.get("scene_path", "")
		if debug: print(GameState.script_name_tag(self, _fname) + "scene_path = " + scene_path)

		if scene_path == "":
			continue
		
		# Load the NPC scene
		var npc_scene = load(scene_path)
		if not npc_scene:
			if debug: print(GameState.script_name_tag(self, _fname) + "Failed to load NPC scene: ", scene_path)
			continue
		
		# Instance the NPC
		var npc_instance = npc_scene.instantiate()
		if debug: print(GameState.script_name_tag(self, _fname) + "npc_instance: ", str(npc_instance))
		var npc_id = npc_data.get("npc_id", npc_data.get("id", ""))
		npc_instance.name = npc_id
		
		# Set character_id if the NPC has this property
		var character_id = npc_data.get("character_id", npc_id)
		if npc_instance.has_method("set") and "character_id" in npc_instance:
			npc_instance.character_id = character_id
		
		# Determine spawn position
		var spawn_pos = Vector2.ZERO
		var spawn_marker = npc_data.get("spawn_marker", npc_data.get("marker", ""))
		
		if spawn_marker != "":
			spawn_pos = get_marker_position(spawn_marker)
		else:
			var pos_data = npc_data.get("spawn_position", npc_data.get("position", {}))
			if pos_data is Dictionary:
				spawn_pos = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
			elif pos_data is Array and pos_data.size() >= 2:
				spawn_pos = Vector2(pos_data[0], pos_data[1])
		
		npc_instance.global_position = spawn_pos
		
		# Set initial direction if supported
		var direction = npc_data.get("initial_direction", npc_data.get("direction", "down"))
		if npc_instance.has_method("set_direction"):
			npc_instance.set_direction(direction)
		elif "direction" in npc_instance:
			npc_instance.direction = direction
		
		# Add to z_Objects and NPC group
		z_objects_container.add_child(npc_instance)
		npc_instance.add_to_group("npc")
		
		# Track spawned NPCs
		spawned_npcs.append(npc_instance)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Spawned NPC: ", npc_id, " at ", spawn_pos)

func _spawn_props():
	const _fname : String = "_spawn_props"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Spawn all props defined in props_to_spawn from JSON data"""
	for prop_data in props_to_spawn:
		if not prop_data is Dictionary:
			continue
			
		var scene_path = prop_data.get("scene_path", "")
		if scene_path == "":
			continue
		
		# Load the prop scene
		var prop_scene = load(scene_path)
		if not prop_scene:
			if debug: print(GameState.script_name_tag(self, _fname) + "Failed to load prop scene: ", scene_path)
			continue
		
		# Instance the prop
		var prop_instance = prop_scene.instantiate()
		var prop_id = prop_data.get("prop_id", prop_data.get("id", ""))
		prop_instance.name = prop_id
		
		# Determine spawn position
		var spawn_pos = Vector2.ZERO
		var spawn_marker = prop_data.get("spawn_marker", prop_data.get("marker", ""))
		
		if spawn_marker != "":
			spawn_pos = get_marker_position(spawn_marker)
		else:
			var pos_data = prop_data.get("spawn_position", prop_data.get("position", {}))
			if pos_data is Dictionary:
				spawn_pos = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
			elif pos_data is Array and pos_data.size() >= 2:
				spawn_pos = Vector2(pos_data[0], pos_data[1])
		
		prop_instance.global_position = spawn_pos
		
		# Add to z_Objects
		z_objects_container.add_child(prop_instance)
		
		# Track spawned props
		spawned_props.append(prop_instance)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Spawned prop: ", prop_id, " at ", spawn_pos)

func start_cutscene():
	const _fname : String = "start_cutscene"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Start the cutscene dialogue through CutsceneManager integration"""
	if dialog_file == "":
		if debug: print(GameState.script_name_tag(self, _fname) + "No dialog file specified for cutscene: ", cutscene_id)
		return
	
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if not dialog_system:
		if debug: print(GameState.script_name_tag(self, _fname) + "DialogSystem not found")
		return
	
	# Move player to starting position if specified
	var player_start_marker = cutscene_data.get("player_start_marker", "")
	if player_start_marker != "":
		var player = GameState.get_player()
		if player:
			var start_pos = get_marker_position(player_start_marker)
			if start_pos != Vector2.ZERO:
				player.global_position = start_pos
				if debug: print(GameState.script_name_tag(self, _fname) + "Moved player to starting position: ", start_pos)
	
	# Notify CutsceneManager that this cutscene is starting
	if cutscene_manager:
		cutscene_manager.active_cutscene = self
	
	# Start the dialogue - check if we have a specific title
	var dialog_title = cutscene_data.get("dialog_title", "")
	if dialog_title != "":
		dialog_system.start_dialog(dialog_file, dialog_title)
	else:
		dialog_system.start_dialog(dialog_file)
	
	# Connect to dialogue finished signal if available
	if dialog_system.has_signal("dialog_finished"):
		if not dialog_system.dialog_finished.is_connected(_on_cutscene_dialogue_finished):
			dialog_system.dialog_finished.connect(_on_cutscene_dialogue_finished)

func _on_cutscene_dialogue_finished():
	const _fname : String = "_on_cutscene_dialogue_finished"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Called when the cutscene dialogue ends"""
	cutscene_finished.emit()
	
	# Notify CutsceneManager
	if cutscene_manager:
		cutscene_manager.active_cutscene = null
	
	if cleanup_after_cutscene:
		cleanup_cutscene()

func cleanup_cutscene():
	const _fname : String = "cleanup_cutscene"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Clean up temporary NPCs and props after cutscene"""
	# Remove temporary NPCs
	for i in range(spawned_npcs.size() - 1, -1, -1):
		var npc = spawned_npcs[i]
		var npc_data = npcs_to_spawn[i] if i < npcs_to_spawn.size() else {}
		var is_temporary = npc_data.get("is_temporary", npc_data.get("temporary", true))
		
		if is_temporary:
			if is_instance_valid(npc):
				npc.queue_free()
			spawned_npcs.remove_at(i)
	
	# Remove temporary props
	for i in range(spawned_props.size() - 1, -1, -1):
		var prop = spawned_props[i]
		var prop_data = props_to_spawn[i] if i < props_to_spawn.size() else {}
		var is_temporary = prop_data.get("is_temporary", prop_data.get("temporary", true))
		
		if is_temporary:
			if is_instance_valid(prop):
				prop.queue_free()
			spawned_props.remove_at(i)
	
	# Update GameState
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_current_npcs()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Cutscene cleanup complete")

# Helper functions for easy setup in the editor (for manual overrides)

func add_npc(npc_id: String, scene_path: String, marker_name: String = "", position: Vector2 = Vector2.ZERO, character_id: String = "", direction: String = "down", temporary: bool = true):
	const _fname : String = "add_npc"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Helper to add NPCs programmatically"""
	var npc_data = {
		"npc_id": npc_id,
		"scene_path": scene_path,
		"spawn_position": {"x": position.x, "y": position.y},
		"spawn_marker": marker_name,
		"character_id": character_id if character_id != "" else npc_id,
		"initial_direction": direction,
		"is_temporary": temporary
	}
	npcs_to_spawn.append(npc_data)

func add_prop(prop_id: String, scene_path: String, marker_name: String = "", position: Vector2 = Vector2.ZERO, temporary: bool = true):
	const _fname : String = "add_prop"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Helper to add props programmatically"""
	var prop_data = {
		"prop_id": prop_id,
		"scene_path": scene_path,
		"spawn_position": {"x": position.x, "y": position.y},
		"spawn_marker": marker_name,
		"is_temporary": temporary
	}
	props_to_spawn.append(prop_data)

func get_spawned_npc(npc_id: String) -> Node:
	const _fname : String = "get_spawned_npc"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Get a spawned NPC by its ID"""
	for npc in spawned_npcs:
		if npc.name == npc_id:
			return npc
	return null

func get_spawned_prop(prop_id: String) -> Node:
	const _fname : String = "get_spawned_prop"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Get a spawned prop by its ID"""
	for prop in spawned_props:
		if prop.name == prop_id:
			return prop
	return null

# Integration with CutsceneManager's stored cutscenes
func load_from_registry_data(cutscene_data: Dictionary):
	const _fname : String = "load_from_registry_data"
	if debug: print(GameState.script_name_tag(self, _fname) + "called.")
	"""Load cutscene configuration from CutsceneManager registry data"""
	if cutscene_data.has("dialog_file"):
		dialog_file = cutscene_data.dialog_file
	
	if cutscene_data.has("auto_trigger"):
		auto_start = cutscene_data.auto_trigger
	
	# Additional setup can be added here based on registry data
	if debug: print(GameState.script_name_tag(self, _fname) + "Loaded cutscene from registry: ", cutscene_id)

# Quick setup from CutsceneManager
static func create_from_registry(cutscene_id: String) -> Node:
	const _fname : String = "create_from_registry"
	"""Static function to create a cutscene from CutsceneManager registry"""
	var cutscene_manager = Engine.get_singleton("CutsceneManager")
	if not cutscene_manager:
		cutscene_manager = CutsceneManager
	
	if not cutscene_manager:
		print("cutscene.gd." + _fname + "CutsceneManager not found")
		return null
	
	var cutscene_data = cutscene_manager.get_cutscene_data(cutscene_id)
	if cutscene_data.is_empty():
		print("cutscene.gd." + _fname + "Cutscene data not found for: ", cutscene_id)
		return null
	
	# Load the scene
	var scene_path = cutscene_data.get("scene_path", "")
	if not ResourceLoader.exists(scene_path):
		print("cutscene.gd." + _fname + "Cutscene scene not found: ", scene_path)
		return null
	
	var cutscene_scene = load(scene_path)
	var cutscene_instance = cutscene_scene.instantiate()
	
	# Load registry data
	cutscene_instance.load_from_registry_data(cutscene_data)
	
	return cutscene_instance
