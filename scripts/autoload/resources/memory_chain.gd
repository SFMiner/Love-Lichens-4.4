extends Resource
class_name MemoryChain

@export var id: String
@export var character_id: String
@export var steps: Array[MemoryTrigger] = []
@export var relationship_reward: int = 0 
@export var completed_tag: String = ""

# Current progress in this memory chain
var current_step: int = 0

func get_current_trigger() -> MemoryTrigger:
	if current_step >= steps.size():
		return null
	return steps[current_step]

func advance() -> bool:
	if current_step < steps.size() - 1:
		current_step += 1
		return true
	
	# If this was the last step in the chain
	if not completed_tag.is_empty():
		GameState.set_tag(completed_tag)
		
	# Apply relationship reward if applicable
	if relationship_reward > 0 and not character_id.is_empty():
		# Assume the relationship system is implemented and accessible
		if RelationshipSystem:
			RelationshipSystem.modify_relationship(character_id, relationship_reward)
	
	return false # No more steps to advance

func is_completed() -> bool:
	return current_step >= steps.size() - 1 and not completed_tag.is_empty() and GameState.has_tag(completed_tag)

func reset() -> void:
	current_step = 0