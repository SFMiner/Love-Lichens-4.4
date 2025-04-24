# npc_combatant.gd
extends Combatant
class_name NPCCombatant

# NPC-specific properties
@export var aggression := 0.5  # 0.0 to 1.0 - how likely to attack vs defend/retreat
@export var combat_rewards := {"experience": 10, "money": 20}
@export var loot_table := []  # Items that might drop when defeated
@export var retreat_threshold := 0.3  # Will try to retreat when health below this percentage
@export var can_be_pacified := true  # Can be talked down instead of fought
@export var relationship_change_on_defeat := -10  # How relationship changes if player defeats this NPC
@onready var combat_manager = get_node_or_null("/root/CombatManager")
# Override combat type
func get_combatant_type():
	# Default is NPC, override in subclasses for creatures/constructs
	return CombatManager.CombatantType.NPC

# AI implementation for combat turns
func take_combat_turn():
	# Get combat manager
	if not combat_manager:
		return
	
	# Get player (assuming first combatant is player)
	var player = combat_manager.current_combatants[0]
	if not player or player.is_defeated():
		return
	
	# Check if should retreat
	var health_percentage = float(current_health) / max_health
	if health_percentage <= retreat_threshold and can_retreat():
		# Try to retreat
		combat_manager.attempt_retreat(self)
		return
	
	# Decide action based on aggression and current state
	if randf() < aggression:
		# Choose offensive action
		perform_offensive_action(player)
	else:
		# Choose defensive/support action
		perform_defensive_action()

# Try to retreat based on NPC type
func can_retreat():
	# Base implementation - some NPCs might not retreat
	return true

# Perform offensive action
func perform_offensive_action(target):
	print("perform_offensive_action called.")
	# Simple implementation - just do a basic attack
	var action = { "type": "attack" }
	
	# Check if we have any offensive skills available
	var offensive_skills = get_available_offensive_skills()
	if offensive_skills.size() > 0 and randf() < 0.4:  # 40% chance to use a skill
		var skill_index = randi() % offensive_skills.size()
		action = offensive_skills[skill_index]
	
	# Perform the chosen action
	var result = perform_combat_action(target, action)
	
	# Get combat manager
	if combat_manager:
		# Automatically end turn after a delay
		await get_tree().create_timer(1.0).timeout
		combat_manager.end_turn()

# Perform defensive action
func perform_defensive_action():
	# Simple implementation - apply a defensive status or heal
	var action = null
	
	# Check if health is low
	var health_percentage = float(current_health) / max_health
	if health_percentage < 0.5:
		# Try to heal or improve defense
		if has_healing_item():
			action = { "type": "item", "item_id": get_healing_item_id() }
		else:
			# Apply defensive stance
			apply_status_effect("defensive_stance", {
				"name": "Defensive Stance",
				"description": "Increased defense, reduced offense",
				"defense_mod": 5,
				"strength_mod": -2,
				"duration": 10.0  # 10 seconds
			})
	else:
		# Apply buff or debuff
		if randf() < 0.5:  # 50% chance for buff vs debuff
			# Buff self
			apply_status_effect("combat_focus", {
				"name": "Combat Focus",
				"description": "Increased accuracy and speed",
				"speed_mod": 3,
				"duration": 15.0
			})
		else:
			# Try to debuff player
			if combat_manager:
				var player = combat_manager.current_combatants[0]
				
				var debuff_action = {
					"type": "skill",
					"stamina_cost": 15,
					"effects": [
						{
							"type": "status",
							"id": "intimidated",
							"data": {
								"name": "Intimidated",
								"description": "Reduced willpower and strength",
								"willpower_mod": -3,
								"strength_mod": -2,
								"duration": 12.0
							}
						}
					]
				}
				
				perform_combat_action(player, debuff_action)
	
	# Get combat manager
	if combat_manager:
		# Automatically end turn after a delay
		await get_tree().create_timer(1.0).timeout
		combat_manager.end_turn()

# Check if NPC has a healing item
func has_healing_item():
	var inventory = get_node_or_null("Inventory")
	if inventory:
		# Look for healing items in inventory
		return inventory.has_item_with_tag("healing")
	return false

# Get healing item ID
func get_healing_item_id():
	var inventory = get_node_or_null("Inventory")
	if inventory:
		# Get first healing item found
		var items = inventory.get_items_by_tag("healing")
		if items.size() > 0:
			return items[0]
	return ""

# Get available offensive skills
func get_available_offensive_skills():
	# Simple implementation - return hardcoded skills
	# In a real implementation, this would be based on the NPC's available skills
	return [
		{
			"type": "skill",
			"name": "Power Strike",
			"stamina_cost": 15,
			"effects": [
				{
					"type": "damage",
					"value": strength * 1.5
				}
			]
		},
		{
			"type": "skill",
			"name": "Disorienting Blow",
			"stamina_cost": 20,
			"effects": [
				{
					"type": "damage",
					"value": strength * 0.8
				},
				{
					"type": "status",
					"id": "disoriented",
					"data": {
						"name": "Disoriented",
						"description": "Reduced accuracy and speed",
						"speed_mod": -3,
						"duration": 10.0
					}
				}
			]
		}
	]

# Override defeat handling
func handle_defeat(is_nonlethal):
	if is_construct() or not is_nonlethal:
		# Constructs get destroyed
		queue_free()
		return
	
	# For living NPCs, they get knocked out or retreat
	if randf() < 0.7:  # 70% chance to be knocked out vs retreat
		# Knocked out
		current_health = 1
		
		# Apply knocked out visual effect
		modulate = Color(0.7, 0.7, 0.7)
		
		# Disable collision and interaction temporarily
		collision_layer = 0
		collision_mask = 0
		
		# Set up recovery timer
		var recovery_time = 60.0  # Recover after 60 seconds
		var timer = get_tree().create_timer(recovery_time)
		timer.timeout.connect(func(): recover_from_defeat())
	else:
		# Retreat
		retreat_from_combat()

# Recover from being defeated
func recover_from_defeat():
	# Restore partial health and stamina
	current_health = max_health * 0.5
	current_stamina = max_stamina * 0.5
	
	# Restore visual appearance
	modulate = Color(1, 1, 1)
	
	# Restore collision and interaction
	collision_layer = 2  # Interaction layer
	collision_mask = 0
	
	# Emit signals
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)

# Override retreat behavior
func retreat_from_combat():
	is_retreating = true
	
	# Move away from combat area
	var retreat_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var retreat_distance = 200
	var retreat_position = global_position + retreat_direction * retreat_distance
	
	# Create a tween to move away
	var tween = create_tween()
	tween.tween_property(self, "global_position", retreat_position, 2.0)
	tween.tween_callback(func(): modulate.a = 0)
	tween.tween_callback(func(): queue_free())

# Get reward for defeating this NPC
func get_defeat_reward():
	return combat_rewards.experience

# Drop loot when defeated
func drop_loot():
	# Spawn items from loot table with probabilities
	for loot_entry in loot_table:
		if loot_entry.has("item_id") and loot_entry.has("probability"):
			if randf() <= loot_entry.probability:
				# Spawn item in world
				var item_id = loot_entry.item_id
				var amount = 1
				if loot_entry.has("amount_min") and loot_entry.has("amount_max"):
					amount = randi() % (loot_entry.amount_max - loot_entry.amount_min + 1) + loot_entry.amount_min
				
				# Call a helper function to spawn item
				spawn_item_drop(item_id, amount)

# Spawn item drop in the world
func spawn_item_drop(item_id, amount):
	# This would be implemented with your item system
	if has_node("/root/InventorySystem"):
		var inventory_system = get_node("/root/InventorySystem")
		if inventory_system.has_method("create_item_in_world"):
			inventory_system.create_item_in_world(get_parent(), global_position, item_id, {"amount": amount})
			
