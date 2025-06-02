# Enhanced look_at_system.gd
extends Node

signal object_examined(object_id: String, description: String)
signal memory_triggered_by_look(memory_tag: String)

const scr_debug: bool = true
var debug

# Currently examined object
var current_target = null
var examination_history: Array = []

func _ready():
	var fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self, fname) + "Look-At System initialized")
	
	# Test memory system connection
#	call_deferred("test_memory_system_connection")

# Add this to GameController._ready() temporarily:
func find_old_character_system_references():
	print("=== CHECKING FOR OLD CHARACTER SYSTEM REFERENCES ===")
	
	# Check if old autoloads still exist
	var old_loader = get_node_or_null("/root/CharacterDataLoader")
	if old_loader:
		print("⚠️ CharacterDataLoader still exists - remove from autoloads")
	else:
		print("✅ CharacterDataLoader removed")
	
	# Check if NPCs are self-contained
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.character_id == "":
			print("⚠️ NPC missing character_id: ", npc.name)
		elif npc.observable_features.is_empty():
			print("⚠️ NPC missing observable features: ", npc.character_id)
		else:
			print("✅ NPC properly configured: ", npc.character_id)
	
	print("=== END CHECK ===")

func test_memory_system_connection():
	var fname = "test_memory_system_connection"
	if debug:
		print(GameState.script_name_tag(self, fname) + "=== LOOK-AT SYSTEM DEBUG ===")
		var memory_system = get_node_or_null("/root/MemorySystem")
		if memory_system:
			print(GameState.script_name_tag(self, fname) + "✓ MemorySystem found")
			if memory_system.has_method("trigger_look_at"):
				print(GameState.script_name_tag(self, fname) + "✓ trigger_look_at method exists")
			else:
				print(GameState.script_name_tag(self, fname) + "✗ trigger_look_at method missing")
		else:
			print(GameState.script_name_tag(self, fname) + "✗ MemorySystem not found")
		
		var notification_system = get_node_or_null("/root/NotificationSystem")
		if notification_system:
			print(GameState.script_name_tag(self, fname) + "✓ NotificationSystem found")
		else:
			print(GameState.script_name_tag(self, fname) + "✗ NotificationSystem not found")
		print(GameState.script_name_tag(self, fname) + "=============================")

# Main look-at function
func look_at(target) -> String:
	var fname = "look_at"
	if not target:
		return ""
	
	if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Starting examination of ", target.name)
	
	var description = ""
	var object_id = ""
	
	# Get object ID first - try multiple fields
	if "character_id" in target and target.character_id != "":
		object_id = target.character_id
	elif "interaction_id" in target and target.interaction_id != "":
		object_id = target.interaction_id  
	elif "id" in target:
		object_id = target.id
	else:
		object_id = target.name
	
	if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Object ID determined as: ", object_id)
	
	# Get base description
	if target.has_method("get_look_description"):
		description = target.get_look_description()
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Got description from get_look_description(): ", description)
	elif "description" in target and target.description != "":
		description = target.description
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Got description from description property: ", description)
	elif "character_name" in target and target.character_name != "":
		description = "You see " + target.character_name + "."
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Generated description from character_name: ", description)
	elif "display_name" in target:
		description = "You see " + target.display_name + "."
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Generated description from display_name: ", description)
	else:
		description = "You see " + target.name + "."
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Generated generic description: ", description)
	
	# Check for observable features BEFORE showing base description
	var feature_descriptions = _check_observable_features(target)
	if not feature_descriptions.is_empty():
		description += "\n\n" + feature_descriptions
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Added feature descriptions")
	
	# Show the complete description
	_show_examination_result(description)
	
	# Now trigger memory system
	var memory_system = get_node_or_null("/root/MemorySystem")
	if memory_system:
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Found MemorySystem, triggering memories")
		
		# Try multiple ID formats
		var ids_to_try = [
			object_id,
			object_id.to_lower()
		]
		
		# For NPCs, also try without special prefixes
		if target.is_in_group("npc"):
			ids_to_try.append(target.name)
			ids_to_try.append(target.name.to_lower())
		
		var memory_triggered = false
		for trigger_id in ids_to_try:
			if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Trying memory trigger for ID: ", trigger_id)
			if memory_system.trigger_look_at(trigger_id):
				memory_triggered_by_look.emit(trigger_id)
				memory_triggered = true
				if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Memory triggered successfully for: ", trigger_id)
			else:
				if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Memory not triggered for: ", trigger_id)
		
		if not memory_triggered and debug:
			print(GameState.script_name_tag(self, fname) + "LOOK AT: No memories triggered for any ID variant")
	else:
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: ERROR - MemorySystem not found!")
	
	# Record examination
	_record_examination(object_id, description, target)
	
	# Emit examination signal
	object_examined.emit(object_id, description)
	
	return description

# Check for observable features on NPCs or complex objects
func _check_observable_features(target) -> String:
	var fname = "_check_observable_features"
	print(GameState.script_name_tag(self, fname) + "=== CHECK OBSERVABLE FEATURES DEBUG ===")
	print(GameState.script_name_tag(self, fname) + "Target: ", target.name)
	print(GameState.script_name_tag(self, fname) + "Target character_id: ", target.get("character_id"))#, "NO_CHARACTER_ID"))
	
	if not "observable_features" in target:
		print(GameState.script_name_tag(self, fname) + "ERROR: No observable_features property found on target")
		print(GameState.script_name_tag(self, fname) + "Available target properties:")
		for property in target.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				print(GameState.script_name_tag(self, fname) + "  - ", property.name)
		return ""
	
	var feature_descriptions = []
	var observable_features = target.observable_features
	
	print(GameState.script_name_tag(self, fname) + "observable_features type: ", typeof(observable_features))
	print(GameState.script_name_tag(self, fname) + "observable_features size: ", observable_features.size())
	print(GameState.script_name_tag(self, fname) + "observable_features keys: ", observable_features.keys())
	
	for feature_id in observable_features:
		var feature = observable_features[feature_id]
		print(GameState.script_name_tag(self, fname) + "Checking feature: ", feature_id)
		print(GameState.script_name_tag(self, fname) + "  Feature data: ", feature)
		print(GameState.script_name_tag(self, fname) + "  Feature type: ", typeof(feature))
		
		if typeof(feature) != TYPE_DICTIONARY:
			print(GameState.script_name_tag(self, fname) + "  ERROR: Feature is not a dictionary")
			continue
		
		print(GameState.script_name_tag(self, fname) + "  Feature observed: ", feature.get("observed", "NO_OBSERVED_FIELD"))
		print(GameState.script_name_tag(self, fname) + "  Can observe: ", _can_observe_feature(target, feature_id, feature))
		
		# Check if we can observe this feature
		if _can_observe_feature(target, feature_id, feature):
			print(GameState.script_name_tag(self, fname) + "  Attempting to observe feature: ", feature_id)
			
			if target.has_method("observe_feature"):
				var feature_desc = target.observe_feature(feature_id)
				print(GameState.script_name_tag(self, fname) + "  observe_feature returned: '", feature_desc, "'")
				
				if not feature_desc.is_empty():
					feature_descriptions.append(feature_desc)
					print(GameState.script_name_tag(self, fname) + "  Added feature description to list")
					
					# Trigger memory for specific feature
					var memory_system = get_node_or_null("/root/MemorySystem")
					if memory_system and "character_id" in target:
						var feature_trigger_id = target.character_id + "_" + feature_id
						print(GameState.script_name_tag(self, fname) + "  Triggering feature memory: ", feature_trigger_id)
						var memory_triggered = memory_system.trigger_look_at(feature_trigger_id)
						print(GameState.script_name_tag(self, fname) + "  Memory trigger result: ", memory_triggered)
			else:
				print(GameState.script_name_tag(self, fname) + "  ERROR: Target does not have observe_feature method")
		else:
			print(GameState.script_name_tag(self, fname) + "  Cannot observe feature (conditions not met)")
	
	var result = "\n".join(feature_descriptions)
	print(GameState.script_name_tag(self, fname) + "Final feature descriptions: '", result, "'")
	print(GameState.script_name_tag(self, fname) + "=== END CHECK OBSERVABLE FEATURES DEBUG ===")
	return result

func _can_observe_feature(target, feature_id: String, feature: Dictionary) -> bool:
	var fname = "_can_observe_feature"
	# Check if already observed (unless it has repeat description)
	if feature.get("observed", false) and not feature.has("repeat_description"):
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Feature already observed: ", feature_id)
		return false
	
	# Check condition tags
	if feature.has("condition_tags"):
		for condition_tag in feature.condition_tags:
			if not GameState.has_tag(condition_tag):
				if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Feature condition not met: ", condition_tag)
				return false
	
	# Check relationship requirements
	if feature.has("relationship_requirement"):
		var relationship_system = get_node_or_null("/root/RelationshipSystem")
		if relationship_system and "character_id" in target:
			var current_level = relationship_system.get_relationship_score(target.character_id)
			if current_level < feature.relationship_requirement:
				if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Relationship too low for feature: ", feature_id)
				return false
	
	return true

func _show_examination_result(description: String):
	var fname = "_show_examination_result"
	if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Showing examination result: ", description)
	
	# Try notification system first
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(description)
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: Showed notification via NotificationSystem")
	else:
		# Fallback: Create a simple popup
		if debug: print(GameState.script_name_tag(self, fname) + "LOOK AT: NotificationSystem not found, creating popup")
		_create_simple_popup(description)

func _create_simple_popup(text: String):
	var fname = "_create_simple_popup"
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	popup.title = "Examination"
	popup.size = Vector2(400, 200)
	
	# Add to scene
	get_tree().root.add_child(popup)
	popup.popup_centered()
	
	# Clean up when closed
	popup.visibility_changed.connect(func():
		if not popup.visible:
			popup.queue_free()
	)

func _record_examination(object_id: String, description: String, target):
	var fname = "_record_examination"
	var examination_record = {
		"object_id": object_id,
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
		"location": _get_current_location(),
		"target_type": _get_target_type(target)
	}
	
	examination_history.append(examination_record)
	
	# Keep history manageable
	if examination_history.size() > 100:
		examination_history.pop_front()

func _get_target_type(target) -> String:
	var fname = "_get_target_type"
	if target.is_in_group("npc"):
		return "npc"
	elif target.is_in_group("interactable"):
		return "interactable"
	elif target.is_in_group("item"):
		return "item"
	else:
		return "object"

func _get_current_location() -> String:
	var fname = "_get_current_location"
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and "current_location" in game_controller:
		return game_controller.current_location
	return ""


# Advanced examination functions
func examine_area(area_name: String) -> String:
	var fname = "examine_area"
	if debug: print(GameState.script_name_tag(self, fname) + "Examining area: ", area_name)
	
	# Trigger area-based memories
	var memory_system = get_node_or_null("/root/MemorySystem")
	if memory_system:
		memory_system.trigger_look_at("area:" + area_name)
	
	# Record area examination
	_record_examination("area:" + area_name, "Examined " + area_name, null)
	
	return "You examine " + area_name

func get_examination_history() -> Array:
	var fname = "get_examination_history"
	return examination_history.duplicate()

func has_examined(object_id: String) -> bool:
	var fname = "has_examined"
	for record in examination_history:
		if record.object_id == object_id:
			return true
	return false

func get_examination_count(object_id: String) -> int:
	var fname = "get_examination_count"
	var count = 0
	for record in examination_history:
		if record.object_id == object_id:
			count += 1
	return count

# Context-aware examination
func look_at_with_context(target, context: String = "") -> String:
	var fname = "look_at_with_context"
	if not target:
		return ""
	
	var base_description = look_at(target)
	
	# Add context-specific observations
	if not context.is_empty():
		var context_description = _get_context_description(target, context)
		if not context_description.is_empty():
			base_description += "\n\n" + context_description
	
	return base_description

func _get_context_description(target, context: String) -> String:
	var fname = "_get_context_description"
	# Handle different examination contexts
	match context:
		"investigate":
			return _get_investigation_description(target)
		"memory":
			return _get_memory_related_description(target)
		"quest":
			return _get_quest_related_description(target)
		"relationship":
			return _get_relationship_description(target)
		_:
			return ""



func _get_investigation_description(target) -> String:
	var fname = "_get_investigation_description"
	# Provide more detailed descriptions for investigation
	if target.has_method("get_investigation_description"):
		return target.get_investigation_description()
	
	# Default investigation behavior
	var details = []
	
	if "size" in target:
		details.append("It appears to be " + str(target.size) + " in size.")
	
	if "material" in target:
		details.append("It seems to be made of " + target.material + ".")
	
	if "condition" in target:
		details.append("Its condition appears " + target.condition + ".")
	
	return "\n".join(details)

func _get_memory_related_description(target) -> String:
	var fname = "_get_memory_related_description"
	# Check if this object relates to any discovered memories
	var memory_system = get_node_or_null("/root/MemorySystem")
	if not memory_system:
		return ""
	
	var object_id = target.get("character_id", target.get("interaction_id", target.name))
	var related_memories = []
	
	# Check discovered memories for connections
	var discovered = memory_system.get_discovered_memories()
	for memory_tag in discovered:
		if memory_tag.contains(object_id) or object_id.contains(memory_tag):
			related_memories.append(memory_tag)
	
	if not related_memories.is_empty():
		return "This reminds you of: " + ", ".join(related_memories)
	
	return ""

func _get_quest_related_description(target) -> String:
	var fname = "_get_quest_related_description"
	# Check if this object is related to any active quests
	var quest_system = get_node_or_null("/root/QuestSystem")
	if not quest_system:
		return ""
	
	var active_quests = quest_system.get_active_quests()
	var object_id = target.get("character_id", target.get("interaction_id", target.name))
	
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		if quest.has("objectives"):
			for objective in quest.objectives:
				if objective.has("target") and objective.target == object_id:
					if not objective.get("completed", false):
						return "This seems relevant to your quest: " + quest.get("title", quest_id)
	
	return ""

func _get_relationship_description(target) -> String:
	var fname = "_get_relationship_description"
	# Provide relationship-aware descriptions for NPCs
	if not target.is_in_group("npc") or not "character_id" in target:
		return ""
	
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	if not relationship_system:
		return ""
	
	var relationship_level = relationship_system.get_relationship_score(target.character_id)
	var level_name = relationship_system.get_relationship_name(relationship_level)
	
	match level_name:
		"Stranger":
			return "You don't know much about this person."
		"Acquaintance":
			return "You're getting to know this person better."
		"Friend":
			return "This person seems comfortable around you."
		"Close Friend":
			return "You have a strong bond with this person."
		"Romantic":
			return "There's a special connection between you two."
		_:
			return ""
