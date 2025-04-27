# combat_manager.gd
extends Node

signal combat_started(player, opponent)
signal combat_ended(winner, loser)
signal turn_started(character)
signal turn_ended(character)

enum CombatResult {VICTORY, DEFEAT, RETREAT, DRAW}
enum CombatantType {PLAYER, NPC, CREATURE, CONSTRUCT}

# Enum for combat state machine
enum CombatState { 
	WAITING_TO_START,      # Initial state
	PLAYER_TURN_ACTIVE,    # Player is deciding action 
	PLAYER_ACTION_PROCESSING, # Processing player's action
	NPC_TURN_ACTIVE,       # NPC is deciding/performing action
	NPC_ACTION_PROCESSING, # Processing NPC's action
	TURN_ENDING            # Turn is ending, about to switch
}

# Current combat state
var is_combat_active = false
var current_combatants = []
var current_turn_index = 0
var turn_order = []
var waiting_for_player_action = false  # Flag to track if we're waiting for player action
var current_combat_state = CombatState.WAITING_TO_START  # Current state in state machine

# Combat options
var allow_retreat = true
var is_nonlethal = true

func _ready():
	pass

# Start combat between player and opponent(s)
func start_combat(player, opponents):
	if is_combat_active:
		end_current_combat(CombatResult.DRAW)
	
	is_combat_active = true
	current_combatants = [player]
	
	# Handle single opponent or array of opponents
	if opponents is Array:
		current_combatants.append_array(opponents)
	else:
		current_combatants.append(opponents)
	
	# Determine turn order based on speed/initiative
	_calculate_turn_order()
	
	# Emit signal that combat has started
	combat_started.emit(player, opponents)

	print("Combatants in this battle:")
	for c in current_combatants:
		print("- ", c.name, " | Defeated?: ", c.is_defeated())

	print("Turn order:")
	for t in turn_order:
		print("- ", t.name)

	
	# Start first turn
	start_next_turn()

# Calculate turn order based on speed/initiative
func _calculate_turn_order():
	turn_order = []
	
	# Sort combatants by initiative (speed + random factor)
	var temp_combatants = current_combatants.duplicate()
	temp_combatants.sort_custom(func(a, b): return a.get_initiative() > b.get_initiative())
	
	turn_order = temp_combatants
	current_turn_index = 0

# Start the next character's turn
func start_next_turn():
	if not is_combat_active or turn_order.is_empty():
		return
	
	var current_character = turn_order[current_turn_index]
	
	# Skip defeated characters
	if current_character.is_defeated():
		advance_turn()
		return
	
	# Signal that this character's turn is starting
	turn_started.emit(current_character)
	
	# Determine state based on character type
	if current_character.get_combatant_type() == CombatantType.PLAYER:
		# Set player turn state
		current_combat_state = CombatState.PLAYER_TURN_ACTIVE
		waiting_for_player_action = true
		
		print("Combat Manager: PLAYER'S TURN - State changed to PLAYER_TURN_ACTIVE")
		print("Combat Manager: Waiting for player to select an action...")
		
		# We STOP HERE - the next action will come from player input
		# The UI will handle player input and eventually call end_turn()
	else:
		# Set NPC turn state
		current_combat_state = CombatState.NPC_TURN_ACTIVE
		print("Combat Manager: NPC'S TURN - State changed to NPC_TURN_ACTIVE")
		
		# For NPCs, we handle their turn automatically
		handle_npc_turn(current_character)
		
		# IMPORTANT: handle_npc_turn contains its own call to end_turn()
		# No need to call advance_turn() here

# End the current character's turn
func end_turn():
	if not is_combat_active:
		print("Combat Manager: end_turn called but combat is not active")
		return
	
	# Get the character whose turn is ending
	var current_character = turn_order[current_turn_index]
	var character_type = current_character.get_combatant_type()
	
	print("Combat Manager: end_turn called for " + current_character.name + " in state " + str(current_combat_state))
	
	# Validate state transitions
	if character_type == CombatantType.PLAYER:
		# Verify we're in a valid state to end player's turn
		if current_combat_state != CombatState.PLAYER_TURN_ACTIVE and current_combat_state != CombatState.PLAYER_ACTION_PROCESSING:
			print("Combat Manager: ERROR - Invalid state to end player turn: " + str(current_combat_state))
			return
	else:
		# Verify we're in a valid state to end NPC's turn
		if current_combat_state != CombatState.NPC_TURN_ACTIVE and current_combat_state != CombatState.NPC_ACTION_PROCESSING:
			print("Combat Manager: ERROR - Invalid state to end NPC turn: " + str(current_combat_state))
			return
	
	# Change to TURN_ENDING state
	current_combat_state = CombatState.TURN_ENDING
#	print("Combat Manager: State changed to TURN_ENDING")
#	print("Combat Manager: Ending turn for " + current_character.name)
	
	# Reset the waiting flag when turn actually ends
	waiting_for_player_action = false
	
	# Signal that the turn is ending
	turn_ended.emit(current_character)
	
	# Wait a moment for turn-end effects to process
	await get_tree().create_timer(0.5).timeout
	
	# Move to the next character
	advance_turn()

# Move to the next turn in the order
func advance_turn():
	# This function advances to the next turn in the rotation
	# It's called at the end of each character's turn
	
	if current_combat_state != CombatState.TURN_ENDING:
		print("Combat Manager: WARNING - advance_turn called in incorrect state: " + str(current_combat_state))
	
	# Transition back to waiting state
	current_combat_state = CombatState.WAITING_TO_START
	print("Combat Manager: State changed to WAITING_TO_START")
	
	var previous_character = turn_order[current_turn_index]
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	var next_character = turn_order[current_turn_index]
	
	print("Combat Manager: Advancing turn from " + previous_character.name + " to " + next_character.name)
	
	# If we've completed a full round, check for combat end conditions
	if current_turn_index == 0:
		print("Combat Manager: Completed full round, checking combat state")
		check_combat_state()
	
	# If combat is still active, start the next turn
	if is_combat_active:
		print("Combat Manager: Starting next turn for " + next_character.name)
		start_next_turn()

# Handle automated NPC turns
func handle_npc_turn(npc):
	print("Combat Manager: Handling turn for NPC " + npc.name)
	
	# Verify we're in the correct state
	if current_combat_state != CombatState.NPC_TURN_ACTIVE:
		print("Combat Manager: ERROR - handle_npc_turn called in incorrect state: " + str(current_combat_state))
	
	# Transition to NPC action processing state
	current_combat_state = CombatState.NPC_ACTION_PROCESSING
	print("Combat Manager: State changed to NPC_ACTION_PROCESSING")
	
	# Allow NPCs to make decisions based on their AI
	npc.take_combat_turn()
	
	# End the NPC's turn after a short delay for visual clarity
	print("Combat Manager: NPC " + npc.name + " acted, waiting before ending turn")
	await get_tree().create_timer(1.0).timeout
	
	# Only end the turn if combat is still active
	if is_combat_active:
		print("Combat Manager: Ending NPC " + npc.name + "'s turn")
		end_turn()
	else:
		print("Combat Manager: Combat ended during NPC " + npc.name + "'s turn")

# Check if combat should end
func check_combat_state():
	var player = current_combatants[0]  # Assuming player is always first in the array
	var opponents = current_combatants.slice(1)
	
	# Check if all opponents are defeated
	var all_opponents_defeated = true
	for opponent in opponents:
		if not opponent.is_defeated():
			all_opponents_defeated = false
			break
	
	if all_opponents_defeated:
		end_current_combat(CombatResult.VICTORY)
		return
	
	# Check if player is defeated
	if player.is_defeated():
		end_current_combat(CombatResult.DEFEAT)
		return

# End the current combat
func end_current_combat(result):
	if not is_combat_active:
		return
	
	is_combat_active = false
	
	var player = current_combatants[0]
	var opponents = current_combatants.slice(1)
	
	match result:
		CombatResult.VICTORY:
			handle_victory(player, opponents)
		CombatResult.DEFEAT:
			handle_defeat(player, opponents)
		CombatResult.RETREAT:
			handle_retreat(player if player.is_retreating else opponents)
		CombatResult.DRAW:
			# Handle draw condition
			pass
	
	# Emit signal that combat has ended
	combat_ended.emit(
		player if result == CombatResult.VICTORY else opponents,
		opponents if result == CombatResult.VICTORY else player
	)
	
	# Reset combat state
	current_combatants = []
	turn_order = []
	current_turn_index = 0

# Handle player victory
func handle_victory(player, opponents):
	# Award experience, items, etc.
	var total_reward = 0
	
	for opponent in opponents:
		# Calculate rewards
		var reward = opponent.get_defeat_reward()
		total_reward += reward
		
		# Handle opponent defeat (retreat or unconscious)
		opponent.handle_defeat(is_nonlethal)
	
	# Give rewards to player
	player.receive_combat_rewards(total_reward)

# Handle player defeat
func handle_defeat(player, opponents):
	# Player wakes up later with consequences
	player.handle_defeat(is_nonlethal)
	
	# Trigger appropriate game event for defeat
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller and game_controller.has_method("handle_player_defeat"):
		game_controller.handle_player_defeat()

# Handle retreat
func handle_retreat(retreating_party):
	if retreating_party is Array:
		for character in retreating_party:
			character.retreat_from_combat()
	else:
		retreating_party.retreat_from_combat()

# Allow a combatant to attempt retreat
func attempt_retreat(character):
	if not allow_retreat:
		return false
	
	# Calculate retreat success chance
	var success_chance = character.get_retreat_chance()
	
	if randf() <= success_chance:
		character.is_retreating = true
		end_current_combat(CombatResult.RETREAT)
		return true
	else:
		# Failed retreat uses up the turn
		end_turn()
		return false

# Process a combat action
func process_combat_action(attacker, target, action):
	if not is_combat_active:
		return
	
	# Let the attacker perform their action on the target
	var result = attacker.perform_combat_action(target, action)
	
	# Check if the target is now defeated
	if target.is_defeated():
		check_combat_state()
