# item_effects_system.gd
extends Node

# Item Effects System for Love & Lichens
# Manages the effects of items when used, equipped, or applied

signal effect_applied(effect_id, target, potency)
signal effect_removed(effect_id, target)
signal temporary_effect_updated(effect_id, target, turns_remaining)

# Effect categories
enum EffectType {
	STAT_BOOST,         # Modifies a player's attribute temporarily
	RELATIONSHIP_BOOST, # Increases relationship with an NPC
	UNLOCK_AREA,        # Unlocks access to a new area
	QUEST_PROGRESS,     # Advances a quest
	KNOWLEDGE_GAIN,     # Adds an entry to the player's knowledge base
	CONSUMABLE_HEAL,    # Restores player health/energy
	EQUIP_PASSIVE       # Passive effect while equipped
}
 
var scr_debug : bool = false
var debug : bool
# Dictionary of active temporary effects
# Key: unique_effect_id, Value: effect data including duration, etc.
var active_effects = {}

# Reference to other game systems
var inventory_system
var relationship_system
var player

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self) + "Item Effects System initialized")
	
	player = get_player()
	# Get references to other systems
	inventory_system = get_node_or_null("/root/InventorySystem")
	relationship_system = get_node_or_null("/root/RelationshipSystem")
	
	# Connect to inventory signals if available
	if inventory_system:
		inventory_system.item_used.connect(_on_item_used)
		if debug: print(GameState.script_name_tag(self) + "Connected to InventorySystem signals")
	else:
		if debug: print(GameState.script_name_tag(self) + "WARNING: InventorySystem not found!")
	
	# Connect to game events that would advance time
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		# These methods would need to be implemented in GameController
		if game_controller.has_signal("turn_completed"):
			game_controller.turn_completed.connect(_on_turn_completed)
		if game_controller.has_signal("day_advanced"):
			game_controller.day_advanced.connect(_on_day_advanced)
		if debug: print(GameState.script_name_tag(self) + "Connected to GameController signals")

# Handle when an item is used through the inventory system
func _on_item_used(item_id):
	apply_item_effects(item_id)

# Apply effects for a specific item
func apply_item_effects(item_id):
	if not inventory_system:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Cannot apply effects, InventorySystem not found")
		return false
	
	# Get item data
	var item_data = inventory_system.get_item_data(item_id)
	if not item_data:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Item data not found for ", item_id)
		return false
	
	# Check if item has effects defined
	if not item_data.has("effects") or item_data.effects.size() == 0:
		if debug: print(GameState.script_name_tag(self) + "Item has no defined effects: ", item_id)
		return false
	
	# Process each effect
	var effects_applied = 0
	
	for effect in item_data.effects:
		if apply_effect(effect, item_id):
			effects_applied += 1
	
	if debug: print(GameState.script_name_tag(self) + "Applied ", effects_applied, " effects from item: ", item_id)
	return effects_applied > 0

# Apply a specific effect
func apply_effect(effect, source_item_id):
	if not effect.has("type") or not effect.has("target"):
		if debug: print(GameState.script_name_tag(self) + "ERROR: Effect missing required fields")
		return false
	
	var effect_type = effect.type
	var target = effect.target
	var potency = effect.potency if effect.has("potency") else 1.0
	var duration = effect.duration if effect.has("duration") else 0
	var effect_id = source_item_id + "_" + target + "_" + str(effect_type)
	
	if debug: print(GameState.script_name_tag(self) + "Applying effect: ", effect_id, " with potency ", potency)
	
	# Handle different effect types
	match effect_type:
		EffectType.STAT_BOOST:
			_apply_stat_boost(target, potency, duration, effect_id)
		
		EffectType.RELATIONSHIP_BOOST:
			_apply_relationship_boost(target, potency, effect_id)
		
		EffectType.UNLOCK_AREA:
			_apply_area_unlock(target, effect_id)
		
		EffectType.QUEST_PROGRESS:
			_apply_quest_progress(target, potency, effect_id)
		
		EffectType.KNOWLEDGE_GAIN:
			_apply_knowledge_gain(target, effect_id)
		
		EffectType.CONSUMABLE_HEAL:
			_apply_consumable_heal(target, potency, effect_id)
		
		EffectType.EQUIP_PASSIVE:
			_apply_equip_passive(target, potency, effect_id)
		
		_:
			if debug: print(GameState.script_name_tag(self) + "ERROR: Unknown effect type: ", effect_type)
			return false
	
	# Register as an active effect if it has a duration
	if duration > 0:
		register_temporary_effect(effect_id, effect_type, target, potency, duration)
	
	# Emit signal that an effect was applied
	effect_applied.emit(effect_id, target, potency)
	return true

# Register a temporary effect with a duration
func register_temporary_effect(effect_id, type, target, potency, duration):
	if active_effects.has(effect_id):
		# If already active, just reset/extend the duration
		active_effects[effect_id].turns_remaining = duration
		if debug: print(GameState.script_name_tag(self) + "Reset duration for existing effect: ", effect_id)
	else:
		# Create a new temporary effect
		active_effects[effect_id] = {
			"type": type,
			"target": target,
			"potency": potency,
			"turns_remaining": duration
		}
		if debug: print(GameState.script_name_tag(self) + "Registered new temporary effect: ", effect_id, " for ", duration, " turns")

# Remove a temporary effect
func remove_temporary_effect(effect_id):
	if active_effects.has(effect_id):
		var effect = active_effects[effect_id]
		
		# Reverse the effect
		match effect.type:
			EffectType.STAT_BOOST:
				_remove_stat_boost(effect.target, effect.potency, effect_id)
			
			EffectType.EQUIP_PASSIVE:
				_remove_equip_passive(effect.target, effect.potency, effect_id)
			
			# Other effect types may not need removal logic
			_:
				pass
		
		# Remove from active effects
		active_effects.erase(effect_id)
		if debug: print(GameState.script_name_tag(self) + "Removed temporary effect: ", effect_id)
		
		# Emit signal
		effect_removed.emit(effect_id, effect.target)

# Update active effects when a turn is completed
func _on_turn_completed():
	var effects_to_remove = []
	
	# Update remaining turns for all active effects
	for effect_id in active_effects:
		active_effects[effect_id].turns_remaining -= 1
		
		# Check if the effect has expired
		if active_effects[effect_id].turns_remaining <= 0:
			effects_to_remove.append(effect_id)
		else:
			# Emit update signal
			temporary_effect_updated.emit(
				effect_id,
				active_effects[effect_id].target,
				active_effects[effect_id].turns_remaining
			)
	
	# Remove expired effects
	for effect_id in effects_to_remove:
		remove_temporary_effect(effect_id)

# Update effects when a day advances - reduces duration by multiple turns
func _on_day_advanced():
	var effects_to_remove = []
	var turns_per_day = 8  # Adjust based on your game's design
	
	# Update remaining turns for all active effects
	for effect_id in active_effects:
		active_effects[effect_id].turns_remaining -= turns_per_day
		
		# Check if the effect has expired
		if active_effects[effect_id].turns_remaining <= 0:
			effects_to_remove.append(effect_id)
		else:
			# Emit update signal
			temporary_effect_updated.emit(
				effect_id,
				active_effects[effect_id].target,
				active_effects[effect_id].turns_remaining
			)
	
	# Remove expired effects
	for effect_id in effects_to_remove:
		remove_temporary_effect(effect_id)

# Manually advance effects (for custom time progression)
func advance_effects(turns = 1):
	var effects_to_remove = []
	
	# Update remaining turns for all active effects
	for effect_id in active_effects:
		active_effects[effect_id].turns_remaining -= turns
		
		# Check if the effect has expired
		if active_effects[effect_id].turns_remaining <= 0:
			effects_to_remove.append(effect_id)
		else:
			# Emit update signal
			temporary_effect_updated.emit(
				effect_id,
				active_effects[effect_id].target,
				active_effects[effect_id].turns_remaining
			)
	
	# Remove expired effects
	for effect_id in effects_to_remove:
		remove_temporary_effect(effect_id)

# Implementation of different effect types
func _apply_stat_boost(stat_name, potency, duration, effect_id):
	if not player:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Player not found for stat boost")
		return
	
	if debug: print(GameState.script_name_tag(self) + "Applying stat boost: ", stat_name, " +", potency)
	
	# Implement based on your player stats system
	# This is a placeholder implementation
	if player.has_method("modify_stat"):
		player.modify_stat(stat_name, potency)
	elif player.has_method("add_status_effect"):
		player.add_status_effect(stat_name, potency, duration)
	else:
		# Fallback - modify a property directly if it exists
		if player.get(stat_name) != null:
			player.set(stat_name, player.get(stat_name) + potency)
			if debug: print(GameState.script_name_tag(self) + "Applied stat boost directly: ", stat_name)
		else:
			if debug: print(GameState.script_name_tag(self) + "WARNING: Could not apply stat boost, no handler found")

func _remove_stat_boost(stat_name, potency, effect_id):
	if not player:
		return
	
	if debug: print(GameState.script_name_tag(self) + "Removing stat boost: ", stat_name, " -", potency)
	
	# Implement based on your player stats system
	if player.has_method("modify_stat"):
		player.modify_stat(stat_name, -potency)
	elif player.has_method("remove_status_effect"):
		player.remove_status_effect(stat_name)
	else:
		# Fallback - modify property directly
		if player.get(stat_name) != null:
			player.set(stat_name, player.get(stat_name) - potency)
		else:
			if debug: print(GameState.script_name_tag(self) + "WARNING: Could not remove stat boost")

func _apply_relationship_boost(character_id, potency, effect_id):
	if not relationship_system:
		if debug: print(GameState.script_name_tag(self) + "ERROR: RelationshipSystem not found for relationship boost")
		return
	
	if debug: print(GameState.script_name_tag(self) + "Increasing affinity with ", character_id, " by ", potency)
	relationship_system.increase_affinity(character_id, potency)

func _apply_area_unlock(area_id, effect_id):
	# This would be implemented based on how you track unlocked areas
	if debug: print(GameState.script_name_tag(self) + "Unlocking area: ", area_id)
	
	# Example - could set a flag in a global GameState object
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		if game_controller.has_method("unlock_area"):
			game_controller.unlock_area(area_id)
		else:
			# You might need to implement this method in GameController
			if debug: print(GameState.script_name_tag(self) + "WARNING: No unlock_area method in GameController")
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found for area unlock")

func _apply_quest_progress(quest_id, step, effect_id):
	if debug: print(GameState.script_name_tag(self) + "Advancing quest: ", quest_id, " to step ", step)
	
	# Get reference to quest system
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		if quest_system.has_method("advance_quest"):
			quest_system.advance_quest(quest_id, step)
		else:
			if debug: print(GameState.script_name_tag(self) + "WARNING: No advance_quest method in QuestSystem")
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: QuestSystem not found for quest progress")

func _apply_knowledge_gain(knowledge_id, effect_id):
	if debug: print(GameState.script_name_tag(self) + "Adding knowledge: ", knowledge_id)
	
	# This would depend on how you track player knowledge
	# Could be added to a Dictionary in GameController or a separate KnowledgeSystem
	var game_controller = get_node_or_null("/root/GameController")
	if game_controller:
		if game_controller.has_method("add_knowledge"):
			game_controller.add_knowledge(knowledge_id)
		else:
			if debug: print(GameState.script_name_tag(self) + "WARNING: No add_knowledge method in GameController")
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found for knowledge gain")

func _apply_consumable_heal(stat_name, amount, effect_id):
	if not player:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Player not found for consumable heal")
		return
	
	if debug: print(GameState.script_name_tag(self) + "Healing ", stat_name, " by ", amount)
	
	# Implement based on your player health/energy system
	if player.has_method("heal"):
		player.heal(stat_name, amount)
	elif player.has_method("restore_stat"):
		player.restore_stat(stat_name, amount)
	else:
		# Fallback - modify property directly
		if player.get(stat_name) != null:
			var current = player.get(stat_name)
			var max_stat = player.get("max_" + stat_name) if player.get("max_" + stat_name) != null else 100
			player.set(stat_name, min(current + amount, max_stat))
			if debug: print(GameState.script_name_tag(self) + "Applied healing directly: ", stat_name, " to ", player.get(stat_name))
		else:
			if debug: print(GameState.script_name_tag(self) + "WARNING: Could not apply healing, no handler found")

func _apply_equip_passive(stat_name, potency, effect_id):
	# Similar to stat boost but for equipped items
	_apply_stat_boost(stat_name, potency, 0, effect_id)
	if debug: print(GameState.script_name_tag(self) + "Applied equip passive effect to ", stat_name)

func _remove_equip_passive(stat_name, potency, effect_id):
	# Similar to removing stat boost
	_remove_stat_boost(stat_name, potency, effect_id)
	if debug: print(GameState.script_name_tag(self) + "Removed equip passive effect from ", stat_name)

# Helper function to find the player in the scene
func get_player():
	
	# Try various paths to find the player
	player = get_node_or_null("/root/CurrentScene/Player")
	if not player:
		player = get_node_or_null("/root/Game/CurrentScene/Player")
	
	# If still not found, search for it in the scene
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	return player

# Get data for a specific temporary effect
func get_effect_data(effect_id):
	if active_effects.has(effect_id):
		return active_effects[effect_id]
	return null

# Get all active effects
func get_all_active_effects():
	return active_effects

# Get all active effects of a specific type
func get_effects_by_type(effect_type):
	var filtered_effects = {}
	
	for effect_id in active_effects:
		if active_effects[effect_id].type == effect_type:
			filtered_effects[effect_id] = active_effects[effect_id]
	
	return filtered_effects

# Get all active effects for a specific target
func get_effects_for_target(target):
	var filtered_effects = {}
	
	for effect_id in active_effects:
		if active_effects[effect_id].target == target:
			filtered_effects[effect_id] = active_effects[effect_id]
	
	return filtered_effects

# Save active effects for game save system
func save_active_effects():
	var save_data = {}
	
	for effect_id in active_effects:
		save_data[effect_id] = active_effects[effect_id].duplicate()
	
	return save_data

# Load active effects from game save data
func load_active_effects(save_data):
	active_effects.clear()
	
	for effect_id in save_data:
		active_effects[effect_id] = save_data[effect_id]
	
	if debug: print(GameState.script_name_tag(self) + "Loaded ", active_effects.size(), " active effects from save data")
