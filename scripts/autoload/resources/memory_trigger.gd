# memory_trigger.gd
class_name MemoryTrigger
extends Resource

# Trigger types enum (matching MemorySystem)
enum TriggerType {
	LOOK_AT,
	ITEM_ACQUIRED,
	LOCATION_VISITED,
	DIALOGUE_CHOICE,
	QUEST_COMPLETED,
	CHARACTER_RELATIONSHIP,
	TIME_PASSED,
	ITEM_USED,
	NPC_TALKED_TO
}

# Trigger properties
@export var id: String = ""
@export var trigger_type: TriggerType = TriggerType.LOOK_AT
@export var target_id: String = ""
@export var unlock_tag: String = ""
@export var description: String = ""
@export var dialogue_title: String = ""
@export var condition_tags: Array[String] = []

# Advanced trigger properties
@export var requires_multiple_triggers: bool = false
@export var trigger_count_required: int = 1
@export var time_window_seconds: float = 0.0  # 0 = no time limit
@export var cooldown_seconds: float = 0.0

# State tracking
var trigger_count: int = 0
var first_trigger_time: float = 0.0
var last_trigger_time: float = 0.0
var is_triggered: bool = false

func get_is_triggered(check_target_id: String) -> bool:
	# Check if target matches
	if not _target_matches(check_target_id):
		return false
	
	# Check conditions
	if not _conditions_met():
		return false
	
	# Check cooldown
	if cooldown_seconds > 0.0:
		var current_time = Time.get_unix_time_from_system()
		if current_time - last_trigger_time < cooldown_seconds:
			return false
	
	# Handle multiple trigger requirement
	if requires_multiple_triggers:
		return _handle_multiple_triggers()
	
	return true

func _target_matches(check_target_id: String) -> bool:
	# Exact match
	if target_id == check_target_id:
		return true
	
	# Wildcard support
	if target_id.ends_with("*"):
		var prefix = target_id.substr(0, target_id.length() - 1)
		return check_target_id.begins_with(prefix)
	
	# Pattern matching for special cases
	if target_id.contains("|"):
		var alternatives = target_id.split("|")
		return check_target_id in alternatives
	
	return false

func _conditions_met() -> bool:
	for condition_tag in condition_tags:
		if not GameState.has_tag(condition_tag):
			return false
	return true

func _handle_multiple_triggers() -> bool:
	trigger_count += 1
	var current_time = Time.get_unix_time_from_system()
	
	if trigger_count == 1:
		first_trigger_time = current_time
	
	last_trigger_time = current_time
	
	# Check time window
	if time_window_seconds > 0.0:
		if current_time - first_trigger_time > time_window_seconds:
			# Reset if outside time window
			trigger_count = 1
			first_trigger_time = current_time
			return false
	
	# Check if we've hit the required count
	if trigger_count >= trigger_count_required:
		is_triggered = true
		return true
	
	return false

func reset():
	trigger_count = 0
	first_trigger_time = 0.0
	last_trigger_time = 0.0
	is_triggered = false

func get_trigger_info() -> Dictionary:
	return {
		"id": id,
		"type": TriggerType.keys()[trigger_type],
		"target": target_id,
		"description": description,
		"conditions": condition_tags,
		"progress": trigger_count if requires_multiple_triggers else (1 if is_triggered else 0),
		"required": trigger_count_required if requires_multiple_triggers else 1
	}
