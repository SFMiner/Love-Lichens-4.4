# Create a new file: quest_debug_commands.gd

extends Node

# This script provides console commands to test quest system functionality

const debug = true

func _ready():
	# Register console commands if using a console system
	print("Quest debug commands initialized")

# Call this function from a console or debug menu
func complete_objective(quest_id, objective_index):
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		var result = quest_system.debug_complete_objective(quest_id, objective_index)
		if result:
			print("Successfully completed objective ", objective_index, " for quest ", quest_id)
		else:
			print("Failed to complete objective")
	else:
		print("Quest system not found!")

# Print all quest information
func print_quests():
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system.debug_print_all_quests()
	else:
		print("Quest system not found!")

# Force trigger a location event
func trigger_location(location_id):
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system.on_location_entered(location_id)
		print("Triggered location: ", location_id)
	else:
		print("Quest system not found!")

# Force trigger a talk event
func trigger_talk(npc_id):
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system._check_talk_objectives(npc_id)
		print("Triggered talk with: ", npc_id)
	else:
		print("Quest system not found!")

# Force trigger a gather event
func trigger_gather(item_id, count=1):
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system._check_gather_objectives(item_id, count)
		print("Triggered gather for item: ", item_id, " count: ", count)
	else:
		print("Quest system not found!")
