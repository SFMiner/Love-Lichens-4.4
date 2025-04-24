# message_board.gd
extends Area2D

# Base script for all message boards in the game
# Matches the pattern used in npc.gd

signal interaction_started(board_id)
signal interaction_ended(board_id)

@export var character_id: String = "message_board"
@export var character_name: String = "Bulletin Board"
@export var interactable: bool = true
@export var initial_dialogue_title: String = "start"

# Data
var dialogue_system

func _ready():
	print("MessageBoard initialized: ", character_id)
	add_to_group("interactable")
	add_to_group("z_Objects")  # Important for your z-indexing system
	$Label.visible = false
	
	# Get reference to the dialogue system
	dialogue_system = get_node_or_null("/root/DialogSystem")
	if not dialogue_system:
		print("WARNING: DialogSystem not found!")
	
	# Make sure the collision shape is enabled
	for child in get_children():
		if child is CollisionShape2D:
			if not child.disabled:
				print("Collision shape for ", character_id, " is enabled")
			else:
				print("Enabling collision shape for ", character_id)
				child.disabled = false
				
	# Set z-index based on y position (same as your other objects)
	z_index = position.y

func interact():
	if not interactable:
		print(character_name, " is not interactable")
		return
		
	print("Interacting with: ", character_name)
	interaction_started.emit(character_id)
	
	# Start dialogue using the Dialogue Manager
	if dialogue_system:
		var result = dialogue_system.start_dialog(character_id, initial_dialogue_title)
		if result:
			print("Dialogue started successfully")
		else:
			print("Failed to start dialogue!")
			show_notification("You read various announcements on the bulletin board.")
	else:
		print("Dialogue system not found!")
		show_notification("You read various announcements on the bulletin board.")

func show_notification(message):
	var notification_system = get_node_or_null("/root/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(message)
	else:
		print(message)
		
func end_interaction():
	interaction_ended.emit(character_id)
