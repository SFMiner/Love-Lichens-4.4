extends Node

# Relationship System manages the player's relationships with NPCs
# Tracks relationship levels, affinity, and special interactions

signal relationship_changed(character_id, old_level, new_level)

# Relationship levels
enum RelationshipLevel {STRANGER, ACQUAINTANCE, FRIEND, CLOSE_FRIEND, ROMANTIC}

# Dictionary to store relationships with all NPCs
# Key: character_id, Value: relationship data
var relationships = {}
var scr_debug : bool = false
var debug : bool

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self) + "Relationship System initialized")
	# Load relationship data
	
func initialize_relationship(character_id, character_name):
	if relationships.has(character_id):
		return
		
	relationships[character_id] = {
		"name": character_name,
		"level": RelationshipLevel.STRANGER,
		"affinity": 0,  # Number that increases with positive interactions
		"key_moments": [],  # Special interactions that unlock deeper relationships
		"flags": {}  # Custom flags for relationship-specific events
	}
	
func get_relationship_level(character_id):
	if not relationships.has(character_id):
		return RelationshipLevel.STRANGER
		
	return relationships[character_id]["level"]
	
func get_relationship_name(level):
	match level:
		RelationshipLevel.STRANGER: return "Stranger"
		RelationshipLevel.ACQUAINTANCE: return "Acquaintance"
		RelationshipLevel.FRIEND: return "Friend"
		RelationshipLevel.CLOSE_FRIEND: return "Close Friend"
		RelationshipLevel.ROMANTIC: return "Romantic Interest"
		_: return "Unknown"
		
func increase_affinity(character_id, amount):
	if not relationships.has(character_id):
		initialize_relationship(character_id, "Unknown")
		
	relationships[character_id]["affinity"] += amount
	
	# Check if this should trigger a relationship level increase
	check_relationship_level_up(character_id)
	
func check_relationship_level_up(character_id):
	if not relationships.has(character_id):
		return
		
	var data = relationships[character_id]
	var current_level = data["level"]
	var affinity = data["affinity"]
	
	# Thresholds for level-ups
	# In a real game, these would be more complex and also require key_moments
	var thresholds = {
		RelationshipLevel.STRANGER: 10,      # 10 affinity to become acquaintance
		RelationshipLevel.ACQUAINTANCE: 30,  # 30 affinity to become friend
		RelationshipLevel.FRIEND: 60,        # 60 affinity to become close friend
		RelationshipLevel.CLOSE_FRIEND: 100  # 100 affinity to become romantic
	}
	
	# Don't attempt to level up if already at max level
	if current_level == RelationshipLevel.ROMANTIC:
		return
		
	# Check if affinity crosses threshold
	if affinity >= thresholds[current_level]:
		var new_level = current_level + 1
		update_relationship_level(character_id, new_level)
		
func update_relationship_level(character_id, new_level):
	if not relationships.has(character_id):
		return
		
	var old_level = relationships[character_id]["level"]
	relationships[character_id]["level"] = new_level
	
	if debug: print(GameState.script_name_tag(self) + "Relationship with ", character_id, " changed from ", 
		get_relationship_name(old_level), " to ", get_relationship_name(new_level))
	
	relationship_changed.emit(character_id, old_level, new_level)
	
	# Notify the character if they exist in the scene
	var npc = get_node_or_null("/root/CurrentScene/" + character_id)
	if npc and npc.has_method("update_relationship"):
		npc.update_relationship(new_level)
		
func add_key_moment(character_id, moment_id):
	if not relationships.has(character_id):
		return
		
	if not moment_id in relationships[character_id]["key_moments"]:
		relationships[character_id]["key_moments"].append(moment_id)
		if debug: print(GameState.script_name_tag(self) + "Added key moment: ", moment_id, " for character: ", character_id)
		
func has_key_moment(character_id, moment_id):
	if not relationships.has(character_id):
		return false
		
	return moment_id in relationships[character_id]["key_moments"]
	
func set_flag(character_id, flag_name, value):
	if not relationships.has(character_id):
		return
		
	relationships[character_id]["flags"][flag_name] = value
	
func get_flag(character_id, flag_name):
	if not relationships.has(character_id) or not relationships[character_id]["flags"].has(flag_name):
		return null
		
	return relationships[character_id]["flags"][flag_name]
	
# Save/Load System Integration
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"relationships": relationships.duplicate(true)
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected relationship data for ", relationships.size(), " characters")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for relationship system load")
		return false
	
	# Restore all relationship data
	if data.has("relationships"):
		relationships = data.relationships.duplicate(true)
		
		# Emit relationship change signals for any relationships that exist
		for character_id in relationships:
			var relationship = relationships[character_id]
			var level = relationship.get("level", RelationshipLevel.STRANGER)
			relationship_changed.emit(character_id, RelationshipLevel.STRANGER, level)
		
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored relationships for ", relationships.size(), " characters")
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Relationship system restoration complete")
	return true
