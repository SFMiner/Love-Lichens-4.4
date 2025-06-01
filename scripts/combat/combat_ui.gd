# combat_ui.gd
extends CanvasLayer

# Signals
signal action_selected(action)
signal retreat_requested

enum State { IDLE, WAITING_FOR_TARGET, RESOLVING_ACTION }


# References to UI elements
@onready var combat_panel = $CombatPanel
@onready var player_health_bar = $CombatPanel/PlayerPanel/HealthBar  # Updated path
@onready var player_health_percent = $CombatPanel/PlayerPanel/HealthPercent
@onready var player_stamina_bar = $CombatPanel/PlayerPanel/StaminaBar  # Match the scene's name
@onready var player_stamina_percent = $CombatPanel/PlayerPanel/StaminaPercent
@onready var opponent_list = $CombatPanel/OpponentPanel/OpponentList
@onready var action_buttons = $CombatPanel/ActionPanel/ActionButtons
@onready var status_label = $CombatPanel/StatusPanel/StatusLabel
@onready var retreat_button = $CombatPanel/ActionPanel/RetreatButton
@onready var combat_manager = get_node_or_null("/root/CombatManager")


# Combat state
var current_action
var current_player = null
var current_opponents = []
var is_player_turn = false
var ui_state = State.IDLE

func _ready():
	# Hide UI initially
	combat_panel.visible = false
	
	# Connect to combat manager signals
	if combat_manager:
		combat_manager.combat_started.connect(_on_combat_started)
		combat_manager.combat_ended.connect(_on_combat_ended)
		combat_manager.turn_started.connect(_on_turn_started)
		combat_manager.turn_ended.connect(_on_turn_ended)
	
	# Connect buttons
	retreat_button.pressed.connect(_on_retreat_button_pressed)

func initialize_combat(player, opponents):
	# Store references
	current_player = player
	
	# Handle both single opponent and array of opponents
	if opponents is Array:
		current_opponents = opponents
	else:
		current_opponents = [opponents]
	
	# Show UI and update displays
	show_combat_ui()
	update_player_stats()
	update_opponent_list()
	
	# Connect health signals if needed
	_connect_health_signals()
	
	# Show initial message
	status_label.text = "Combat started!"

func _connect_health_signals():
	if current_player and current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(func(_current, _maximum): update_player_stats()):
			current_player.health_changed.connect(func(_current, _maximum): update_player_stats())
	
	if current_player and current_player.has_signal("stamina_changed"):
		if not current_player.stamina_changed.is_connected(func(_current, _maximum): update_player_stats()):
			current_player.stamina_changed.connect(func(_current, _maximum): update_player_stats())

# Show the combat UI
func show_combat_ui():
	combat_panel.visible = true

# Hide the combat UI
func hide_combat_ui():
	combat_panel.visible = false

# Update the player's health and stamina display
func update_player_stats():
	if current_player:
		player_health_bar.max_value = current_player.max_health
		player_health_bar.value = current_player.current_health
		player_stamina_bar.max_value = current_player.max_stamina
		player_stamina_bar.value = current_player.current_stamina
		
		# Update health percentage label
		var health_percent = int((float(current_player.current_health) / current_player.max_health) * 100)
		player_health_percent.text = str(health_percent) + "%"
		
		# Update stamina percentage label
		var stamina_percent = int((float(current_player.current_stamina) / current_player.max_stamina) * 100)
		player_stamina_percent.text = str(stamina_percent) + "%"

# Update the opponent list and their stats
func update_opponent_list():
	# Clear previous list
	for child in opponent_list.get_children():
		child.queue_free()
	
	# Add each opponent
	for opponent in current_opponents:
		# Create opponent entry
		var opponent_entry = preload("res://scenes/ui/combat/opponent_entry.tscn").instantiate()
		opponent_list.add_child(opponent_entry)
		
		# Set opponent info
		opponent_entry.set_opponent(opponent)
		
		# Connect to selection signal
		opponent_entry.opponent_selected.connect(_on_opponent_selected)

# Show available actions based on player's available options
func show_available_actions():
	# Clear previous buttons
	for child in action_buttons.get_children():
		child.queue_free()
	
	if not current_player:
		return
	
	# Add attack button
	var attack_button = Button.new()
	attack_button.text = "Attack"
	attack_button.pressed.connect(func(): _on_action_button_pressed("attack"))
	action_buttons.add_child(attack_button)
	
	# Add defend button
	var defend_button = Button.new()
	defend_button.text = "Defend"
	defend_button.pressed.connect(func(): _on_action_button_pressed("defend"))
	action_buttons.add_child(defend_button)
	
	# Only add skill buttons if the method exists
	if current_player.has_method("get_available_skills"):
		var skills = current_player.get_available_skills()
		for skill in skills:
			var skill_button = Button.new()
			skill_button.text = skill.name
			
			# Disable if not enough stamina
			if skill.stamina_cost > current_player.current_stamina:
				skill_button.disabled = true
				skill_button.tooltip_text = "Not enough stamina"
			
			skill_button.pressed.connect(func(): _on_action_button_pressed("skill", skill))
			action_buttons.add_child(skill_button)
	
	# Only add item buttons if the method exists
	if current_player.has_method("get_combat_usable_items"):
		var items = current_player.get_combat_usable_items()
		for item in items:
			var item_button = Button.new()
			item_button.text = "Use " + item.name
			item_button.pressed.connect(func(): _on_action_button_pressed("item", item))
			action_buttons.add_child(item_button)
	else:
		# Always add at least an item placeholder
		var item_button = Button.new()
		item_button.text = "Items"
		item_button.pressed.connect(func(): status_label.text = "No usable items available")
		item_button.disabled = true
		action_buttons.add_child(item_button)

# Show target selection for an action
func show_target_selection(action_type, action_data=null):
	# Store the action for when target is selected
	current_action = {
		"type": action_type,
		"data": action_data
	}
	
	# Highlight opponents to indicate they can be targeted
	for i in range(opponent_list.get_child_count()):
		var opponent_entry = opponent_list.get_child(i)
		opponent_entry.highlight_for_targeting(true)
	
	# Show targeting hint
	status_label.text = "Select a target"
	
	# Disable action buttons while selecting target
	for child in action_buttons.get_children():
		child.disabled = true
	
	retreat_button.disabled = true

# Cancel target selection
func cancel_target_selection():
	# Clear current action
	current_action = null
	
	# Remove highlights
	for i in range(opponent_list.get_child_count()):
		var opponent_entry = opponent_list.get_child(i)
		opponent_entry.highlight_for_targeting(false)
	
	# Clear targeting hint
	status_label.text = "Your turn"
	
	# Re-enable action buttons
	for child in action_buttons.get_children():
		child.disabled = false
	
	# Reset retreat button state
	if combat_manager:
		retreat_button.disabled = not combat_manager.allow_retreat

# Handle when the player selects an opponent to target
func _on_opponent_selected(opponent):
	if current_action:
		# Found the opponent object
		var target_opponent = null
		for opp in current_opponents:
			if opp.name == opponent.name:
				target_opponent = opp
				break
		
		if target_opponent:
			# Emit action selected signal with target
			action_selected.emit({
				"type": current_action.type,
				"data": current_action.data,
				"target": target_opponent
			})
			
			# Reset targeting state
			cancel_target_selection()
	else:
		# Just showing opponent details
		status_label.text = opponent.name + ": " + str(opponent.current_health) + "/" + str(opponent.max_health)

# Handle combat start
func _on_combat_started(player, opponents):
	current_player = player
	
	# Handle both single opponent and multiple opponents
	if opponents is Array:
		current_opponents = opponents
	else:
		current_opponents = [opponents]
	
	# Show UI
	show_combat_ui()
	
	# Update displays
	update_player_stats()
	update_opponent_list()
	
	# Show initial message
	status_label.text = "Combat started!"
	
	# Connect to player health/stamina signals
	if not player.health_changed.is_connected(func(_current, _maximum): update_player_stats()):
		player.health_changed.connect(func(_current, _maximum): update_player_stats())
	
	if not player.stamina_changed.is_connected(func(_current, _maximum): update_player_stats()):
		player.stamina_changed.connect(func(_current, _maximum): update_player_stats())

# Handle combat end
func _on_combat_ended(winner, loser):
	# Show result message
	if winner is Array:
		# Check if player is in the loser array or not in the winner array
		var player_won = false
		
		if current_player in winner:
			player_won = true
		elif loser is Array and current_player in loser:
			player_won = false
		else:
			# Fallback check - if player isn't explicitly identified
			player_won = current_player.current_health > 0
		
		if player_won:
			status_label.text = "Victory!"
		else:
			status_label.text = "Defeat!"
	else:
		# Original single object comparison
		if winner == current_player:
			status_label.text = "Victory!"
		else:
			status_label.text = "Defeat!"
	
	# Hide UI after a delay
	await get_tree().create_timer(2.0).timeout
	hide_combat_ui()
	
	# Reset state
	current_player = null
	current_opponents = []
	is_player_turn = false
	
	
# Handle turn start
func _on_turn_started(character):
	# Check if it's the player's turn
	is_player_turn = (character == current_player)
	
	# Update UI based on whose turn it is
	if is_player_turn:
		# It's the player's turn - enable actions and update UI
		status_label.text = "Your turn - select an action"
		show_available_actions()
		
		# Make sure all action buttons are enabled
		for child in action_buttons.get_children():
			child.disabled = false
		
		# Enable retreat if allowed
		if combat_manager:
			retreat_button.disabled = not combat_manager.allow_retreat
		
		print(GameState.script_name_tag(self) + "UI: Player's turn - actions enabled")
	else:
		# It's an opponent's turn - disable player actions
		status_label.text = character.name + "'s turn"
		
		# Disable player action buttons during opponent turns
		for child in action_buttons.get_children():
			child.disabled = true
		
		retreat_button.disabled = true
		
		print(GameState.script_name_tag(self) + "UI: " + character.name + "'s turn - player actions disabled")
	
	# Update displays
	update_player_stats()
	update_opponent_list()

# Handle turn end
func _on_turn_ended(character):
	print(GameState.script_name_tag(self) + "UI: Turn ended for " + character.name)
	
	# Reset UI state to IDLE
	ui_state = State.IDLE
	
	# Update displays
	update_player_stats()
	update_opponent_list()
	
	# If it was the player's turn, add a visual indicator
	if character == current_player:
		status_label.text = "Turn complete - enemies acting..."
	else:
		status_label.text = character.name + " finished turn"

# Handle action button press
func _on_action_button_pressed(action_type, action_data=null):
	if is_player_turn and ui_state == State.IDLE:
		ui_state = State.WAITING_FOR_TARGET
		show_target_selection(action_type, action_data)

# Handle retreat button press
func _on_retreat_button_pressed():
	if is_player_turn:
		retreat_requested.emit()

# Process the action from player
func process_player_action(action):
	ui_state = State.RESOLVING_ACTION

	if combat_manager and current_player:
		match action.type:
			"attack":
				# Basic attack
				var result = current_player.perform_attack(action.target, {})
				
				# Show attack result
				status_label.text = "Dealt " + str(result.damage) + " damage!"
				
				# Pause for visual effect
				await get_tree().create_timer(1.0).timeout
				
			"skill":
				# Skill use
				var skill_data = action.data
				var skill_action = {
					"type": "skill",
					"stamina_cost": skill_data.stamina_cost,
					"effects": skill_data.effects
				}
				
				var result = current_player.perform_skill(action.target, skill_action)
				
				# Show skill result
				if result.success:
					var effect_text = ""
					for effect in result.effects:
						match effect.type:
							"damage":
								effect_text += "Dealt " + str(effect.value) + " damage! "
							"heal":
								effect_text += "Healed " + str(effect.value) + " HP! "
							"status":
								effect_text += "Applied " + effect.id + "! "
					
					status_label.text = effect_text
				else:
					status_label.text = "Skill failed: " + result.reason
				
				# Pause for visual effect
				await get_tree().create_timer(1.0).timeout
				
			"item":
				# Item use
				var item_data = action.data
				var item_action = {
					"type": "item",
					"item_id": item_data.id,
					"effects": item_data.effects
				}
				
				var result = current_player.use_item(action.target, item_action)
				
				# Show item use result
				if result.success:
					var effect_text = "Used " + item_data.name + "! "
					for effect in result.effects:
						match effect.type:
							"damage":
								effect_text += "Dealt " + str(effect.value) + " damage! "
							"heal":
								effect_text += "Healed " + str(effect.value) + " HP! "
							"status":
								effect_text += "Applied " + effect.id + "! "
					
					status_label.text = effect_text
				else:
					status_label.text = "Item use failed: " + result.reason
				
				# Pause for visual effect
				await get_tree().create_timer(1.0).timeout
				
	# Return to idle state
	ui_state = State.IDLE
	

# This function has been replaced by the updated process_player_action
# and is kept here for reference only
#func process_player_action_old(action):
#	pass
