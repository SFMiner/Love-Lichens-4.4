# quest_system.gd
extends Node

signal quest_started(quest_id)
signal quest_updated(quest_id)
signal quest_completed(quest_id)
signal objective_updated(quest_id, objective_index, progress, required)

const scr_debug : bool = false
var debug

var visited_areas = {}
var area_exploration = {}
# Dictionary of all available quest templates
# Key: quest_id, Value: quest template data (loaded from JSON)
var quest_templates = {}

# Dictionary of active quests
# Key: quest_id, Value: current quest data with progress
var active_quests = {}

# Dictionary to store completed quests
# Key: quest_id, Value: completed quest data
var completed_quests = {}

# Dictionary of quests available to start but not yet active
var available_quests = {}

# System references
var inventory_system
var dialog_system
var player

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print("Quest System initialized")
	
	# Ensure quest directory exists
	_ensure_quest_directory()
	
	# Initialize collections
	visited_areas = {}
	area_exploration = {}
	
	# Get references to other systems
	inventory_system = get_node_or_null("/root/InventorySystem")
	dialog_system = get_node_or_null("/root/DialogSystem")
	
	# Load quest templates from JSON files
	_load_quest_templates()
	
	# Connect signals from other systems
	_connect_signals()
	
# Add this new function
func _ensure_quest_directory():
	var quest_dir = "res://data/quests/"
	
	# First check if the data directory exists
	var dir = DirAccess.open("res://")
	if not dir:
		if debug: print("ERROR: Could not access root directory")
		return
		
	if not dir.dir_exists("data"):
		if debug: print("Creating data directory")
		dir.make_dir("data")
	
	# Now check if quests directory exists
	dir = DirAccess.open("res://data/")
	if not dir:
		if debug: print("ERROR: Could not access data directory")
		return
		
	if not dir.dir_exists("quests"):
		if debug: print("Creating quests directory")
		dir.make_dir("quests")
	
	if debug: print("Quest directory ready")
	

# Load quest definitions from JSON files
func _load_quest_templates():
	var quest_dir = "res://data/quests/"
	
	# Create the directory if it doesn't exist
	var dir = DirAccess.open("res://data/")
	if dir and not dir.dir_exists("quests"):
		dir.make_dir("quests")
	
	dir = DirAccess.open(quest_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var quest_path = quest_dir + file_name
				_load_quest_from_file(quest_path)
			file_name = dir.get_next()
		
		dir.list_dir_end()
		if debug: print("Loaded ", quest_templates.size(), " quest templates from JSON files")
	else:
		if debug: print("ERROR: Could not open quests directory")

# Load a single quest from JSON file
func _load_quest_from_file(file_path):
	if not FileAccess.file_exists(file_path):
		if debug: print("ERROR: Quest file not found: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if debug: print("ERROR: Could not open quest file: ", file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		if debug: print("ERROR: Failed to parse quest JSON: ", json.get_error_message())
		return false
	
	var quest_data = json.data
	if typeof(quest_data) != TYPE_DICTIONARY:
		if debug: print("ERROR: Quest data is not a dictionary")
		return false
	
	if not quest_data.has("id"):
		if debug: print("ERROR: Quest missing required 'id' field")
		return false
	
	var quest_id = quest_data.id
	quest_templates[quest_id] = quest_data
	if debug: print("Loaded quest template: ", quest_id)
	
	# Check if this should be an available quest
	if are_prerequisites_met(quest_id) and not active_quests.has(quest_id) and not completed_quests.has(quest_id):
		available_quests[quest_id] = quest_data.duplicate(true)
	
	return true

# Load and add a new quest to available quests
func load_new_quest(quest_id, auto_start=false):
	if debug: print("Attempting to load new quest: ", quest_id)
	
	# Check if quest is already loaded or active
	if quest_templates.has(quest_id):
		if debug: print("Quest already loaded: ", quest_id)
		
		# Auto-start if requested and not already active or completed
		if auto_start and not active_quests.has(quest_id) and not completed_quests.has(quest_id):
			return start_quest(quest_id)
		return true
	
	# Check for quest file
	var quest_path = "res://data/quests/" + quest_id + ".json"
	
	if not FileAccess.file_exists(quest_path):
		if debug: print("ERROR: Quest file not found: ", quest_path)
		return false
	
	# Load the quest
	if _load_quest_from_file(quest_path):
		if debug: print("Successfully loaded new quest: ", quest_id)
		
		# Auto-start if requested
		if auto_start:
			return start_quest(quest_id)
		return true
	
	return false

# Connect signals from other systems
func _connect_signals():
	if inventory_system:
		if inventory_system.has_signal("item_added") and not inventory_system.item_added.is_connected(_on_item_added):
			inventory_system.item_added.connect(_on_item_added)
			if debug: print("Connected to inventory item_added signal")
	
	if dialog_system:
		if dialog_system.has_signal("dialog_ended") and not dialog_system.dialog_ended.is_connected(_on_dialog_ended):
			dialog_system.dialog_ended.connect(_on_dialog_ended)
			if debug: print("Connected to dialog_ended signal")
	else:
		if debug: print("WARNING: DialogSystem not found")

# Check if prerequisite quests are completed
func are_prerequisites_met(quest_id):
	if not quest_templates.has(quest_id):
		return false
	
	var quest = quest_templates[quest_id]
	
	# If quest has prerequisites defined
	if quest.has("prerequisites"):
		for prereq_id in quest.prerequisites:
			# Check if prerequisite quest is completed
			if not completed_quests.has(prereq_id):
				return false
	
	return true

# Make a quest available to player but not active
func make_quest_available(quest_id):
	if not quest_templates.has(quest_id):
		return load_new_quest(quest_id, false)
	
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return false
		
	if are_prerequisites_met(quest_id):
		available_quests[quest_id] = quest_templates[quest_id].duplicate(true)
		if debug: print("Quest now available: ", quest_id)
		return true
	
	return false

# Start a quest by ID
func start_quest(quest_id):
	if not quest_templates.has(quest_id):
		if debug: print("ERROR: Unknown quest template: ", quest_id)
		return false
	
	if active_quests.has(quest_id):
		if debug: print("Quest already active: ", quest_id)
		return false
	
	if completed_quests.has(quest_id):
		if debug: print("Quest already completed: ", quest_id)
		return false
	
	# Create a new quest instance from the template
	var quest_template = quest_templates[quest_id]
	var new_quest = quest_template.duplicate(true)
	
	# Initialize objective progress
	if new_quest.has("objectives"):
		for i in range(new_quest.objectives.size()):
			var objective = new_quest.objectives[i]
			
			# Initialize progress for gather objectives
			if objective.type == "gather" or objective.type == "gather_tag":
				if not objective.has("progress"):
					objective.progress = 0
				if not objective.has("required"):
					objective.required = 1
			
			# Initialize completion status
			if not objective.has("completed"):
				objective.completed = false
	
	# Add to active quests
	active_quests[quest_id] = new_quest
	
	# Remove from available quests if it was there
	if available_quests.has(quest_id):
		available_quests.erase(quest_id)
	
	# Emit signal
	quest_started.emit(quest_id)
	
	if debug: print("Started quest: ", quest_id)
	return true

# Signal handlers
func _on_item_added(item_id, item_data):
	# Check for direct item_id match
	_check_gather_objectives(item_id, 1)
	
	# Check for tag-based objectives
	if item_data and item_data.has("tags"):
		for tag in item_data.tags:
			_check_gather_tag_objectives(tag, 1)

func _on_dialog_ended(character_id):
	print("Dialog ended with: ", character_id, " - checking for quest updates")
	_check_talk_objectives(character_id)

# Check if any gather objectives are updated by this item
func _check_gather_objectives(item_id, count=1):
	if debug: print("Checking gather objectives for item: ", item_id, " count: ", count)
	
	var any_objectives_found = false
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				if objective.type == "gather" and objective.target == item_id and not objective.completed:
					# Initialize progress if it doesn't exist
					if not objective.has("progress"):
						objective.progress = 0
					if not objective.has("required"):
						objective.required = 1
						
					objective.progress += count
					any_objectives_found = true
					
					if debug: print("Updated gather objective for ", item_id, ": ", 
						objective.progress, "/", objective.required)
					
					if objective.progress >= objective.required:
						objective.completed = true
						if debug: print("Gather objective completed!")
					
					objective_updated.emit(quest_id, i, objective.progress, objective.required)
					quest_updated.emit(quest_id)
					
					# Check if quest is now complete
					check_quest_completion(quest_id)
	
	if debug and not any_objectives_found:
		print("No gather objectives found for item: ", item_id)

# Check for tag-based gather objectives
func _check_gather_tag_objectives(tag, count=1):
	if debug: print("Checking gather_tag objectives for tag: ", tag, " count: ", count)
	
	var any_objectives_found = false
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				if objective.type == "gather_tag" and objective.tag == tag and not objective.completed:
					# Initialize progress if it doesn't exist
					if not objective.has("progress"):
						objective.progress = 0
					if not objective.has("required"):
						objective.required = 1
						
					objective.progress += count
					any_objectives_found = true
					
					if debug: print("Updated gather_tag objective for ", tag, ": ", 
						objective.progress, "/", objective.required)
					
					if objective.progress >= objective.required:
						objective.completed = true
						if debug: print("Gather tag objective completed!")
					
					objective_updated.emit(quest_id, i, objective.progress, objective.required)
					quest_updated.emit(quest_id)
					
					# Check if quest is now complete
					check_quest_completion(quest_id)
	
	if debug and not any_objectives_found:
		print("No gather_tag objectives found for tag: ", tag)

# Check current inventory against tag-based objectives
func check_inventory_against_tag_objectives():
	if debug: print("Checking current inventory against tag objectives")
	
	if not inventory_system:
		if debug: print("Can't check inventory - no inventory system found")
		return
		
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				if objective.type == "gather_tag" and not objective.completed:
					var tag = objective.tag
					var required = objective.required if objective.has("required") else 1
					
					# Get current count from inventory
					var current_count = inventory_system.count_items_by_tag(tag)
					
					# Update progress if needed
					if current_count > 0:
						var old_progress = objective.progress if objective.has("progress") else 0
						
						# Only increase if current count is higher
						if current_count > old_progress:
							if debug: print("Tag objective for ", tag, " updated based on inventory: ", 
								old_progress, " -> ", current_count)
							
							objective.progress = current_count
							
							if objective.progress >= required:
								objective.completed = true
								if debug: print("Gather tag objective completed!")
							
							objective_updated.emit(quest_id, i, objective.progress, required)
							quest_updated.emit(quest_id)
							
							# Check if quest is now complete
							check_quest_completion(quest_id)

# Check if any talk objectives are updated by this dialog
func _check_talk_objectives(npc_name):
	if debug: print("Checking talk objectives for NPC: ", npc_name)
	
	var any_objectives_found = false
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				if objective.type == "talk" and objective.target == npc_name and not objective.completed:
					if debug: print("Found matching talk objective for ", npc_name)
					objective.completed = true
					any_objectives_found = true
					
					objective_updated.emit(quest_id, i, 1, 1)
					quest_updated.emit(quest_id)
					
					# Check if quest is now complete
					check_quest_completion(quest_id)
	
# quest_system.gd (continued)

	if debug and not any_objectives_found:
		print("No talk objectives found for NPC: ", npc_name)

# Check if a location objective is completed
func on_location_entered(location_id):
	if debug: print("Location entered: ", location_id)
	
	# Record this location as visited
	visited_areas[location_id] = true
	
	var any_objectives_found = false
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				if objective.type == "visit" and objective.target == location_id and not objective.completed:
					if debug: print("Found matching visit objective for location: ", location_id)
					objective.completed = true
					any_objectives_found = true
					
					objective_updated.emit(quest_id, i, 1, 1)
					quest_updated.emit(quest_id)
					
					# Check if quest is now complete
					check_quest_completion(quest_id)
	
	if debug and not any_objectives_found:
		print("No visit objectives found for location: ", location_id)

# Mark a custom objective as completed
func complete_custom_objective(quest_id, objective_target):
	if not active_quests.has(quest_id):
		return false
		
	var quest = active_quests[quest_id]
	if not quest.has("objectives"):
		return false
		
	for i in range(quest.objectives.size()):
		var objective = quest.objectives[i]
		if (objective.type == "visit" or objective.type == "custom") and objective.target == objective_target and not objective.completed:
			objective.completed = true
			objective_updated.emit(quest_id, i, 1, 1)
			quest_updated.emit(quest_id)
			
			# Check if quest is now complete
			check_quest_completion(quest_id)
			return true
			
	return false

# Check if a quest is complete
func check_quest_completion(quest_id):
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	var all_complete = true
	
	if quest.has("objectives"):
		for objective in quest.objectives:
			if not objective.completed:
				all_complete = false
				break
	
	if all_complete:
		complete_quest(quest_id)
		return true
	
	return false

# Unlock follow-up quests when a quest is completed
func unlock_followup_quests(quest_id):
	# Get completed quest
	if not completed_quests.has(quest_id):
		return
	
	var quest = completed_quests[quest_id]
	
	# If quest has follow-ups defined
	if quest.has("follow_up_quests"):
		for followup_id in quest.follow_up_quests:
			# Check if follow-up quest can be loaded
			var auto_start = quest.has("auto_start_follow_ups") and quest.auto_start_follow_ups
			load_new_quest(followup_id, auto_start)
			
			if not auto_start:
				make_quest_available(followup_id)

# Process rewards for a completed quest
func process_rewards(rewards):
	if not rewards or typeof(rewards) != TYPE_ARRAY:
		return
	
	for reward in rewards:
		if not reward.has("type"):
			continue
			
		match reward.type:
			"item":
				if reward.has("id") and reward.has("amount") and inventory_system:
					inventory_system.add_item(reward.id, reward.amount)
					if debug: print("Rewarded item: ", reward.id, " x", reward.amount)
			
			"knowledge":
				if reward.has("id"):
					var game_controller = get_node_or_null("/root/GameController")
					if game_controller and game_controller.has_method("add_knowledge"):
						game_controller.add_knowledge(reward.id)
						if debug: print("Rewarded knowledge: ", reward.id)
			
			"relationship":
				if reward.has("character") and reward.has("amount"):
					var relationship_system = get_node_or_null("/root/RelationshipSystem")
					if relationship_system:
						relationship_system.increase_affinity(reward.character, reward.amount)
						if debug: print("Rewarded relationship: ", reward.character, " +", reward.amount)
			
			"unlock_area":
				if reward.has("id"):
					var game_controller = get_node_or_null("/root/GameController")
					if game_controller and game_controller.has_method("unlock_area"):
						game_controller.unlock_area(reward.id)
						if debug: print("Rewarded area unlock: ", reward.id)

# Mark a quest as complete
func complete_quest(quest_id):
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	quest.completed = true
	
	# Process rewards if defined
	if quest.has("rewards"):
		process_rewards(quest.rewards)
	
	# Move from active to completed
	completed_quests[quest_id] = quest.duplicate(true)
	active_quests.erase(quest_id)
	
	# Emit signal
	quest_completed.emit(quest_id)
	
	if debug: print("Completed quest: ", quest_id)
	
	# Unlock follow-up quests
	unlock_followup_quests(quest_id)
	
	return true

# Get active quests
func get_active_quests():
	return active_quests.duplicate(true)

# Get available quests
func get_available_quests():
	return available_quests.duplicate(true)

# Get quest data by ID
func get_quest(quest_id):
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	elif completed_quests.has(quest_id):
		return completed_quests[quest_id]
	elif available_quests.has(quest_id):
		return available_quests[quest_id]
	elif quest_templates.has(quest_id):
		return quest_templates[quest_id]
	return null

# Get all active and completed quests for save/load
func get_all_quests():
	var data = {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(true),
		"available_quests": available_quests.duplicate(true),
		"visited_areas": visited_areas.duplicate(true)
	}
	return data

# Debug function to manually complete an objective
func debug_complete_objective(quest_id, objective_index):
	if not active_quests.has(quest_id):
		if debug: print("DEBUG: Quest not active: ", quest_id)
		return false
	
	var quest = active_quests[quest_id]
	
	if not quest.has("objectives") or objective_index >= quest.objectives.size():
		if debug: print("DEBUG: Invalid objective index for quest: ", quest_id)
		return false
	
	var objective = quest.objectives[objective_index]
	if debug: print("DEBUG: Completing objective: ", objective.description if objective.has("description") else "Unnamed objective")
	
	if objective.type == "gather" and objective.has("required"):
		objective.progress = objective.required
	elif objective.type == "gather_tag" and objective.has("required"):
		objective.progress = objective.required
	
	objective.completed = true
	objective_updated.emit(quest_id, objective_index, 1, 1)
	quest_updated.emit(quest_id)
	
	# Check if quest is now complete
	check_quest_completion(quest_id)
	return true

# Add to quest_system.gd
func debug_print_all_quests():
	print("\n=== ACTIVE QUESTS ===")
	for quest_id in active_quests:
		print("Quest: ", quest_id, " - ", active_quests[quest_id].title)
		if active_quests[quest_id].has("objectives"):
			for i in range(active_quests[quest_id].objectives.size()):
				var obj = active_quests[quest_id].objectives[i]
				print("  Objective ", i, ": ", obj.description, " - Completed: ", obj.completed)
	
	print("\n=== AVAILABLE QUESTS ===")
	for quest_id in available_quests:
		print("Quest: ", quest_id, " - ", available_quests[quest_id].title)
	
	print("\n=== COMPLETED QUESTS ===")
	for quest_id in completed_quests:
		print("Quest: ", quest_id, " - ", completed_quests[quest_id].title)

# Save quest data
func save_quests():
	var save_data = {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(true),
		"available_quests": available_quests.duplicate(true),
		"visited_areas": visited_areas.duplicate(true)  # Add this line
	}
	return save_data

# Load quest data
func load_quests(save_data):
	if save_data.has("active_quests"):
		active_quests = save_data.active_quests.duplicate(true)
	
	if save_data.has("completed_quests"):
		completed_quests = save_data.completed_quests.duplicate(true)
	
	if save_data.has("available_quests"):
		available_quests = save_data.available_quests.duplicate(true)
	
	if save_data.has("visited_areas"):
		visited_areas = save_data.visited_areas.duplicate(true)
	
	if debug: print("Loaded quest data: ", 
		active_quests.size(), " active quests, ", 
		completed_quests.size(), " completed quests, ",
		available_quests.size(), " available quests, ",
		visited_areas.size(), " visited areas")

	# After loading, validate tag-based objectives against current inventory
	call_deferred("check_inventory_against_tag_objectives")

# Handle when a specific area within a location is visited
func on_area_visited(area_name, location_id=""):
	if debug: print("Area visited: ", area_name, " in location: ", location_id)
	
	# Record this area as visited
	var key = area_name
	if location_id.length() > 0:
		key = location_id + ":" + area_name
	
	visited_areas[key] = true
	
	# Update exploration progress
	if location_id.length() > 0:
		if not area_exploration.has(location_id):
			area_exploration[location_id] = { "visited_areas": [] }
		
		if not area_name in area_exploration[location_id].visited_areas:
			area_exploration[location_id].visited_areas.append(area_name)
			
		if debug: print("Exploration progress for ", location_id, ": ", 
			area_exploration[location_id].visited_areas.size(), " areas visited")
	
	# Check for objectives
	_check_area_visit_objectives(area_name, location_id)
	
	# Check for multi-area objectives - this will handle our campus exploration
	_check_multi_area_objectives()
	
	# Check if we've explored all areas in location
	if location_id.length() > 0 and area_exploration.has(location_id):
		if check_all_areas_visited(location_id):
			on_area_exploration_completed(location_id)

# Check objectives that require visiting specific areas
# Modified function to properly check for area visit objectives
func _check_area_visit_objectives(area_name, location_id=""):
	if debug: print("Checking area visit objectives for area: ", area_name)
	
	var any_objectives_found = false
	var area_with_location = ""
	
	# If location_id is provided, also check for area with location prefix
	if location_id != "":
		area_with_location = location_id + ":" + area_name
		if debug: print("Also checking for combined area: ", area_with_location)
	
	# Loop through all active quests
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				# Check for visit objective that matches area_name (direct match)
				if objective.type == "visit" and not objective.completed:
					# Match the area_name directly or the campus_quad:area_name format
					if objective.target == area_name or (area_with_location != "" and objective.target == area_with_location):
						if debug: print("Found matching visit objective for area: ", area_name)
						objective.completed = true
						any_objectives_found = true
						
						objective_updated.emit(quest_id, i, 1, 1)
						quest_updated.emit(quest_id)
						
						# Check if quest is now complete
						check_quest_completion(quest_id)
					# Special handling for location_id objectives
					elif objective.target == location_id:
						if debug: print("Found matching visit objective for location: ", location_id)
						objective.completed = true
						any_objectives_found = true
						
						objective_updated.emit(quest_id, i, 1, 1)
						quest_updated.emit(quest_id)
						
						# Check if quest is now complete
						check_quest_completion(quest_id)
	
	if debug and not any_objectives_found:
		print("No area visit objectives found for area: ", area_name)
		
func check_all_areas_visited(location_id):
	if not area_exploration.has(location_id):
		return false
		
	# For campus_quad, we know there are 4 areas
	# This should be made more dynamic in a full implementation
	if location_id == "campus_quad" and area_exploration[location_id].visited_areas.size() >= 4:
		return true
		
	return false

# Check objectives that require visiting multiple areas in a location
# Add or update this function in quest_system.gd
func _check_multi_area_objectives():
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				# Check for exploring multiple areas objective
				if objective.type == "explore" and objective.target == "campus_quad" and not objective.completed:
					var visited_count = 0
					var required_count = 3  # Require at least 3 areas to be visited
					
					# Count visited areas in campus_quad
					if area_exploration.has("campus_quad"):
						visited_count = area_exploration["campus_quad"].visited_areas.size()
					
					# Update progress tracking
					if not objective.has("progress"):
						objective.progress = 0
					
					if objective.progress != visited_count:
						objective.progress = visited_count
						objective_updated.emit(quest_id, i, visited_count, required_count)
					
					# Complete the objective if enough areas visited
					if visited_count >= required_count:
						objective.completed = true
						quest_updated.emit(quest_id)
						
						if debug: print("Completed campus exploration objective: ", 
							objective.description if objective.has("description") else "Explore the campus")
						
						# Check if quest is now complete
						check_quest_completion(quest_id)

# Called when all areas in a location have been explored
func on_area_exploration_completed(location_id):
	if debug: print("All areas explored in: ", location_id)
	
	# Check for any objectives that involve exploring the entire location
	_check_explore_objectives(location_id)

# Check for objectives that require exploring a location
func _check_explore_objectives(location_id):
	var any_objectives_found = false
	
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		
		if quest.has("objectives"):
			for i in range(quest.objectives.size()):
				var objective = quest.objectives[i]
				
				# Check for location exploration objectives
				if objective.type == "explore" and objective.target == location_id and not objective.completed:
					objective.completed = true
					any_objectives_found = true
					
					objective_updated.emit(quest_id, i, 1, 1)
					quest_updated.emit(quest_id)
					
					if debug: print("Completed exploration objective for location: ", location_id)
					
					# Check if quest is now complete
					check_quest_completion(quest_id)
	
	if debug and not any_objectives_found:
		print("No exploration objectives found for location: ", location_id)
