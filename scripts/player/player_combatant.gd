# player_combatant.gd
extends Combatant
class_name PlayerCombatant

signal combat_reward_earned(amount)
signal gained_experience(amount)

# Player-specific stats
@export var experience := 0
@export var level := 1
@export var experience_to_next_level := 100


# func _ready():
	

func initialize_stats():
	if max_health == 0:
		max_health = 100
	current_health = max_health
	
	if max_stamina == 0:
		max_stamina = 50
	current_stamina = max_stamina

	print("Stats initialized: HP", current_health, "/", max_health, 
		  " | SP", current_stamina, "/", max_stamina)

# Override combat type
func get_combatant_type():
	return CombatManager.CombatantType.PLAYER

# Override defeat handling
func handle_defeat(is_nonlethal):
	
	if is_nonlethal:
		# Player is knocked out, not dead
		current_health = 1
		current_stamina = 5
		
		# Apply consequences of defeat
		apply_defeat_consequences()
	else:
		# This shouldn't happen with nonlethal combat but just in case
		current_health = 1
		current_stamina = 1
		apply_defeat_consequences(true)  # Severe consequences

# Apply consequences from being defeated
func apply_defeat_consequences(is_severe=false):
	# Lose some money
	var wallet = get_node_or_null("Wallet")
	if wallet:
		var money_lost = wallet.get_current_money() * (0.2 if is_severe else 0.1)
		wallet.remove_money(money_lost)
	
	# Possibly lose some items
	var inventory = get_node_or_null("Inventory")
	if inventory and is_severe:
		# Lose some random non-essential items
		var items = inventory.get_all_items()
		var non_essential_items = []
		
		for item_id in items:
			var item = items[item_id]
			if not item.has("is_essential") or not item.is_essential:
				non_essential_items.append(item_id)
		
		if non_essential_items.size() > 0:
			# Lose 1-2 random non-essential items
			var item_loss_count = randi() % 2 + 1
			for i in range(min(item_loss_count, non_essential_items.size())):
				var random_index = randi() % non_essential_items.size()
				var random_item = non_essential_items[random_index]
				inventory.remove_item(random_item, 1)
				non_essential_items.remove_at(random_index)
	
	# Apply temporary status effects
	apply_status_effect("bruised", {
		"name": "Bruised",
		"description": "You're bruised from your defeat.",
		"strength_mod": -2,
		"speed_mod": -2,
		"duration": 180.0  # 3 minutes of game time
	})

# Override reward reception
func receive_combat_rewards(amount):
	# Add experience
	var experience_gained = amount
	experience += experience_gained
	gained_experience.emit(experience_gained)
	
	# Check for level up
	check_level_up()
	
	# Add money/items as needed
	var wallet = get_node_or_null("Wallet")
	if wallet:
		var money_gained = amount * 2  # Simple conversion
		wallet.add_money(money_gained)
	
	combat_reward_earned.emit(amount)

# Check if player levels up
func check_level_up():
	if experience >= experience_to_next_level:
		level_up()

# Handle level up
func level_up():
	level += 1
	experience -= experience_to_next_level
	
	# Increase experience needed for next level
	experience_to_next_level = int(experience_to_next_level * 1.5)
	
	# Increase stats
	max_health += 10
	max_stamina += 5
	strength += 2
	defense += 2
	speed += 1
	willpower += 1
	
	# Restore health and stamina
	current_health = max_health
	current_stamina = max_stamina
	
	# Emit signals
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)
