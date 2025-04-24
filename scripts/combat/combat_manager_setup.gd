# combat_manager_setup.gd
extends Node

# This scene should be included in your autoload main scene

@onready var combat_manager = preload("res://scripts/combat/combat_manager.gd").new()
@onready var combat_ui = preload("res://scenes/ui/combat/combat_ui.tscn").instantiate()


func _ready():
	# Set up combat manager
	combat_manager.name = "CombatManager"
	add_child(combat_manager)
	
	# Set up combat UI
	combat_ui.name = "CombatUI"
	add_child(combat_ui)
	
	# Connect UI signals to manager
	combat_ui.action_selected.connect(_on_action_selected)
	combat_ui.retreat_requested.connect(_on_retreat_requested)
	
	print("Combat system initialized")

func _on_action_selected(action):
	# Process player action in UI
	combat_ui.process_player_action(action)

func _on_retreat_requested():
	# Try to retreat
	var player = combat_manager.current_combatants[0]
	combat_manager.attempt_retreat(player)
