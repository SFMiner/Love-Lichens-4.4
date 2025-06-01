# memory_chain.gd
class_name MemoryChain
extends Resource

# Memory chain properties
@export var id: String = ""
@export var character_id: String = ""
@export var relationship_reward: int = 0
@export var completed_tag: String = ""
@export var description: String = ""

# Chain state
var steps: Array[MemoryTrigger] = []
var current_step_index: int = 0
var is_completed: bool = false

func get_current_trigger() -> MemoryTrigger:
	if current_step_index < steps.size() and not is_completed:
		return steps[current_step_index]
	return null

func advance() -> bool:
	if is_completed:
		return false
	
	current_step_index += 1
	
	if current_step_index >= steps.size():
		is_completed = true
		return false
	
	return true

func reset():
	current_step_index = 0
	is_completed = false
	
	# Reset all trigger states
	for trigger in steps:
		trigger.reset()

func get_progress() -> Dictionary:
	return {
		"current_step": current_step_index,
		"total_steps": steps.size(),
		"completed": is_completed,
		"progress_percent": float(current_step_index) / float(steps.size()) * 100.0
	}

func add_step(trigger: MemoryTrigger):
	steps.append(trigger)

func can_advance() -> bool:
	var current_trigger = get_current_trigger()
	if not current_trigger:
		return false
	
	# Check if all conditions are met
	for condition_tag in current_trigger.condition_tags:
		if not GameState.has_tag(condition_tag):
			return false
	
	return true
