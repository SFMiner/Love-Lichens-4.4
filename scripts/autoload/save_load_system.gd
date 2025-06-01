extends Node

# Save/Load System for Love & Lichens
# Handles saving and loading game state, including player progress, inventory, relationships

signal game_saved(slot)
signal game_loaded(slot)

const SAVE_FOLDER = "user://saves/"
const SAVE_EXTENSION = ".json"
const MAX_SAVE_SLOTS = 5

const scr_debug :bool = false
var debug

var current_save_slot = -1

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print(GameState.script_name_tag(self) + "Save/Load System initialized")
	# Create the saves directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_FOLDER.trim_suffix("/")):
		dir.make_dir(SAVE_FOLDER.trim_suffix("/"))

func save_game(slot):
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		if debug: print(GameState.script_name_tag(self) + "Invalid save slot: ", slot)
		return false
		
	var save_data = _collect_save_data()
	var save_path = SAVE_FOLDER + "save_" + str(slot) + SAVE_EXTENSION
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		if debug: print(GameState.script_name_tag(self) + "Failed to open save file: ", save_path)
		return false
		
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	current_save_slot = slot
	if debug: print(GameState.script_name_tag(self) + "Game saved to slot: ", slot)
	game_saved.emit(slot)
	return true
	
func load_game(slot):
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		if debug: print(GameState.script_name_tag(self) + "Invalid save slot: ", slot)
		return false
		
	var save_path = SAVE_FOLDER + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		if debug: print(GameState.script_name_tag(self) + "Save file does not exist: ", save_path)
		return false
		
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		if debug: print(GameState.script_name_tag(self) + "Failed to open save file: ", save_path)
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		if debug: print(GameState.script_name_tag(self) + "Failed to parse save file JSON: ", json.get_error_message())
		return false
		
	var save_data = json.data
	_apply_save_data(save_data)
	
	current_save_slot = slot
	if debug: print(GameState.script_name_tag(self) + "Game loaded from slot: ", slot)
	game_loaded.emit(slot)
	return true
	
func get_save_info(slot):
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return null
		
	var save_path = SAVE_FOLDER + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		return null
		
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return null
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return null
		
	var save_data = json.data
	
	# Return a summary of the save data for the save slot UI
	return {
		"player_name": save_data.player_name if save_data.has("player_name") else "Player",
		"save_date": save_data.save_date if save_data.has("save_date") else "Unknown Date",
		"play_time": save_data.play_time if save_data.has("play_time") else 0,
		"location": save_data.current_location if save_data.has("current_location") else "Unknown",
		"player_pos": save_data.player_position if save_data.has("player_position") else null
	}
	
func get_all_save_slots_info():
	var save_slots = []
	
	for slot in range(MAX_SAVE_SLOTS):
		var info = get_save_info(slot)
		save_slots.append(info) # Will be null if the slot is empty
		
	return save_slots
	
func delete_save(slot):
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
		
	var save_path = SAVE_FOLDER + "save_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		return false
		
	var dir = DirAccess.open(SAVE_FOLDER)
	if dir.remove("save_" + str(slot) + SAVE_EXTENSION) != OK:
		if debug: print(GameState.script_name_tag(self) + "Failed to delete save file: ", save_path)
		return false
		
	if debug: print(GameState.script_name_tag(self) + "Deleted save in slot: ", slot)
	if current_save_slot == slot:
		current_save_slot = -1
	
	return true
	
# Collect all game state data from various systems
func _collect_save_data():
	var datetime = Time.get_datetime_dict_from_system()
	var date_string = "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var save_data = {
		"save_format_version": 1,
		"save_date": date_string,
		"play_time": 0,  # In a real game, you'd track play time
		"player_name": "Adam Major",
		"current_location": "campus_quad"
	}
	
	# Get game controller data
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		# Add current scene path
		save_data["current_scene_path"] = game_controller.current_scene_path
		
	# Get inventory data
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		save_data["inventory"] = inventory_system.get_all_items()
		
	# Get relationship data
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system:
		save_data["relationships"] = relationship_system.relationships
		
	# Get quest data
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("get_all_quests"):
		save_data["quests"] = quest_system.get_all_quests()
		
	# Get dialog system data - track seen dialogs
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		if dialog_system.has_method("get_seen_dialogs"):
			save_data["dialog_seen"] = dialog_system.get_seen_dialogs()
		save_data["current_dialog"] = dialog_system.current_character_id
	
	# Add player position and state
	# Try different ways to find the player
	var player = null
	
	# First try various common paths
	player = get_node_or_null("/root/CurrentScene/Player")
	if not player:
		player = get_node_or_null("/root/Game/CurrentScene/Player")
	
	# If still not found, try searching for it in the scene tree
	if not player:
		var players = get_tree().get_nodes_in_group("z_Objects")
		for obj in players:
			if obj.name == "Player":
				player = obj
				break
				
	if player:
		save_data["player_position"] = {
			"x": player.position.x,
			"y": player.position.y
		}
		
		# Save player direction if available
		if player.has_method("get_last_direction") or player.get("last_direction"):
			save_data["player_direction"] = {
				"x": player.last_direction.x,
				"y": player.last_direction.y
			}
			
		# Save current animation if available
		var anim_player = player.get_node_or_null("AnimationPlayer")
		if anim_player:
			save_data["player_animation"] = anim_player.current_animation
		
	return save_data

# Modify the existing _apply_save_data function in save_load_system.gd

# Apply loaded save data to game systems
# Apply loaded save data to game systems
# Apply loaded save data to game systems
func _apply_save_data(save_data):
	if debug: print(GameState.script_name_tag(self) + "Applying save data...")
	
	# First, apply scene change if needed
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and save_data.has("current_scene_path"):
		var target_scene = save_data.current_scene_path
		if target_scene.is_empty(): # Fallback to campus_quad if no scene is saved
			target_scene = "res://scenes/world/locations/campus_quad.tscn"
			
		if debug: print(GameState.script_name_tag(self) + "Changing to scene: ", target_scene)
		game_controller.change_scene(target_scene)
		
		# Wait a frame to let the scene load before continuing
		await get_tree().process_frame
		
	# Apply to inventory system
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system and save_data.has("inventory"):
		if debug: print(GameState.script_name_tag(self) + "Restoring inventory data...")
		inventory_system.inventory = save_data.inventory
		
	# Apply to relationship system
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if relationship_system and save_data.has("relationships"):
		if debug: print(GameState.script_name_tag(self) + "Restoring relationship data...")
		relationship_system.relationships = save_data.relationships
		
	# Apply to quest system
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and save_data.has("quests") and quest_system.has_method("load_quests"):
		if debug: print(GameState.script_name_tag(self) + "Restoring quest data...")
		quest_system.load_quests(save_data.quests)
		
	# Apply to dialog system
	var dialog_system = get_node_or_null("/root/DialogSystem")
	if dialog_system:
		if save_data.has("dialog_seen") and dialog_system.has_method("set_seen_dialogs"):
			if debug: print(GameState.script_name_tag(self) + "Restoring dialog history...")
			dialog_system.set_seen_dialogs(save_data.dialog_seen)
	
	# Give the scene time to fully load before trying to find the player
	await get_tree().create_timer(0.1).timeout
	
	# Apply player position if available
	if save_data.has("player_position"):
		if debug: print(GameState.script_name_tag(self) + "Applying player position...")
		
		# Try different ways to find the player
		var player = null
		
		# First check in the Game/CurrentScene structure
		var scene_container = get_node_or_null("/root/Game/CurrentScene")
		if scene_container and scene_container.get_child_count() > 0:
			var scene = scene_container.get_child(0)
			player = scene.get_node_or_null("Player")
		
		# If not found, try various paths
		if not player:
			player = get_node_or_null("/root/CurrentScene/Player")
		if not player:
			player = get_node_or_null("/root/Game/CurrentScene/Player")
			
		# Try to find it in the campus_quad scene
		if not player:
			var quad = get_node_or_null("/root/Game/CurrentScene/CampusQuad")
			if quad:
				player = quad.get_node_or_null("Player")
				
		# Last resort: search in groups
		if not player:
			var players = get_tree().get_nodes_in_group("z_Objects")
			for obj in players:
				if obj.name == "Player":
					player = obj
					break
		
		if player:
			if debug: print(GameState.script_name_tag(self) + "Player found, setting position to: ", save_data.player_position.x, ", ", save_data.player_position.y)
			player.position.x = save_data.player_position.x
			player.position.y = save_data.player_position.y
			
			# Set direction if available - using get() method which is safer
			if save_data.has("player_direction"):
				# Check if player has last_direction property using get() which returns null if not found
				if player.get("last_direction") != null:
					player.last_direction.x = save_data.player_direction.x
					player.last_direction.y = save_data.player_direction.y
					if player.has_method("update_interaction_ray"):
						player.update_interaction_ray(player.last_direction)
				else:
					if debug: print(GameState.script_name_tag(self) + "Player does not have last_direction property")
			
			# Set animation if available
			if save_data.has("player_animation") and player.has_method("play_animation"):
				player.play_animation(save_data.player_animation)
		else:
			if debug: print(GameState.script_name_tag(self) + "Player not found in the scene")

	# Ensure Phone UI is hidden after all data is applied
	if game_controller and game_controller.has_method("hide_phone_ui_on_load"):
		if debug: print(GameState.script_name_tag(self) + "SaveLoadSystem: Ensuring Phone UI is hidden post-load.")
		game_controller.hide_phone_ui_on_load()
	else:
		if debug: print(GameState.script_name_tag(self) + "SaveLoadSystem: GameController or hide_phone_ui_on_load method not found when trying to hide phone UI post-load.")
			
	if debug: print(GameState.script_name_tag(self) + "Save data applied successfully")
	return true
