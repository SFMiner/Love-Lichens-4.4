# combat_initializer.gd
extends Node

# This script should be attached to a node in your scene to ensure combat works
var initialized = false
var combat_manager_script = preload("res://scripts/combat/combat_manager.gd")
var combat_ui_scene = preload("res://scenes/ui/combat/combat_ui.tscn")

func _ready():
	if initialized:
		return
		
	print("Initializing combat system...")

	# Check if CombatManager already exists
	var combat_manager = get_node_or_null("/root/CombatManager")
	if not combat_manager:
		# Create and add combat manager
		combat_manager = combat_manager_script.new()
		combat_manager.name = "CombatManager"
		get_tree().root.add_child(combat_manager)
		print("Combat Manager created")
	else:
		print("Combat Manager already exists")
	
	# Check if CombatUI already exists
	var combat_ui = get_node_or_null("/root/CombatUI")
	if not combat_ui:
		# Create and add combat UI
		combat_ui = combat_ui_scene.instantiate()
		combat_ui.name = "CombatUI"
		get_tree().root.add_child(combat_ui)
		print("Combat UI created")
		
		
		call_deferred("_connect_ui_signals", combat_ui, combat_manager)
				
	initialized = true
	print("Combat system initialized for scene: ", get_tree().current_scene.name)

func _connect_ui_signals(combat_ui, combat_manager):
	# This runs after the UI is fully initialized
	# Check if the UI script has the expected signals
	if combat_ui.has_signal("action_selected"):
		combat_ui.action_selected.connect(_on_action_selected.bind(combat_ui, combat_manager))
	else:
		print("WARNING: CombatUI missing action_selected signal")
		
	if combat_ui.has_signal("retreat_requested"):
		combat_ui.retreat_requested.connect(_on_retreat_requested.bind(combat_manager))
	else:
		print("WARNING: CombatUI missing retreat_requested signal")


func _on_action_selected(action, combat_ui, combat_manager):
	print("Combat initializer: Player selected action - " + action.type)
	
	# Ensure we're in the correct state to process player actions
	if combat_manager.current_combat_state != combat_manager.CombatState.PLAYER_TURN_ACTIVE:
		print("Combat initializer: ERROR - Received player action in invalid state: " + 
			str(combat_manager.current_combat_state))
		return
		
	# Verify it's actually the player's turn
	var player = combat_manager.current_combatants[0]
	var current_character = combat_manager.turn_order[combat_manager.current_turn_index]
	
	if player != current_character:
		print("Combat initializer: ERROR - Received player action but it's not player's turn!")
		return
		
	# Transition to action processing state
	combat_manager.current_combat_state = combat_manager.CombatState.PLAYER_ACTION_PROCESSING
	print("Combat initializer: State changed to PLAYER_ACTION_PROCESSING")
	
	# Process player action visually
	combat_ui.process_player_action(action)
	
	# Wait for visual processing to complete
	# This coroutine approach ensures we wait for the visual effects
	await combat_ui.get_tree().create_timer(1.2).timeout
	
	print("Combat initializer: Action processing complete, ending player turn")
	
	# End the turn after action is processed
	if combat_manager.current_combat_state == combat_manager.CombatState.PLAYER_ACTION_PROCESSING:
		combat_manager.end_turn()
	else:
		print("Combat initializer: WARNING - Not ending turn, state has already changed to: " + 
			str(combat_manager.current_combat_state))

func _on_retreat_requested(combat_manager):
	# Try to retreat
	var player = combat_manager.current_combatants[0]
	if player:
		combat_manager.attempt_retreat(player)
