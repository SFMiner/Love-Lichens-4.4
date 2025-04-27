# combatant.gd
extends CharacterBody2D
class_name Combatant

signal health_changed(current, maximum)
signal stamina_changed(current, maximum)
signal status_effect_applied(effect)
signal status_effect_removed(effect)

# Basic combat stats
@export var max_health := 100
@export var max_stamina := 100
@export var speed := 10
@export var strength := 10
@export var defense := 10
@export var willpower := 10

# Current state
var current_health: int
var current_stamina: int
var is_retreating := false
var status_effects := {}
var debug

var is_moving = false
var was_moving : bool
var is_running = false
var is_jumping = false
var jump_timer = 0.0
var last_direction = Vector2(0, 1) # Default facing down
var last_animation = "idle" # Default facing down
var anim_direction = "down"  # for animation strings
var animator = null
var base_speed = 250.0
var run_speed_multiplier = 1.5  # Player moves faster when running
var last_position = Vector2.ZERO

func _ready():
	# Common initialization
	current_health = max_health
	current_stamina = max_stamina
	animator = get_node_or_null("CharacterAnimator")
	print("CharacterAnimator for " + get_character_id() + " is " + animator.name)
	last_position = position
	

func get_character_id():
	pass
	# overridden in descendents

func update_anim_direction():
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			anim_direction = "right" 
		else:
			anim_direction = "left"
	else:
		if last_direction.y > 0:
			anim_direction = "down" 
		else:
			anim_direction = "up"
			
			
func process_jumping(delta):
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0:
			is_jumping = false
			last_animation = ""  # Reset animation state when jump ends

func face_target(target):
	var direction = get_direction_to_target(target.position)
	change_facing(direction)


func get_direction_to_target(target_position: Vector2) -> String:
	var to_target = (target_position - global_position).normalized()
	
	if abs(to_target.x) > abs(to_target.y):
		return "right" if to_target.x > 0 else "left"
	else:
		return "down" if to_target.y > 0 else "up"

func change_facing(direction):
	pass #stun overridden in descendents

func update_animation(input_vector):
	if is_jumping:
		# Jump animation already set in begin_jump()
		return
		
	if input_vector != Vector2.ZERO:
		var old_direction = anim_direction
		update_anim_direction()
		
		# Choose animation type based on running state
		var anim_type = ""
		if is_running:
			anim_type = "run"
		else:
			anim_type = "walk"
		
		# Only update animation if direction changed or animation type changed
		if old_direction != anim_direction or last_animation != anim_type or !was_moving:
			if debug: print("Setting " + anim_type + " animation - dir: " + anim_direction)
			animator.set_animation(anim_type, anim_direction, get_character_id())
			last_animation = anim_type
	elif last_animation != "idle":
		# Only set idle if we're not already idle
		if debug: print("Setting idle animation - current anim: " + last_animation)
		animator.set_animation("idle", anim_direction, get_character_id())
		last_animation = "idle"

func update_position_tracking():
	if position != last_position:
		last_position = position
		z_index = int(global_position.y)

func begin_jump():
	is_jumping = true
	jump_timer = 1.2  # JUMP_DURATION 
	update_anim_direction()
	animator.set_animation("jump", anim_direction, get_character_id())

# Combat type - override in subclasses
func get_combatant_type():
	return CombatManager.CombatantType.NPC


# Get calculated initiative for combat turn order
func get_initiative():
	# Base initiative is speed plus a bit of randomness
	var base_initiative = speed + randi() % 5
	
	# Apply modifiers from status effects
	for effect in status_effects.values():
		if effect.has("initiative_mod"):
			base_initiative += effect.initiative_mod
	
	return base_initiative

# Check if combatant is defeated
func is_defeated():
	var defeated = current_health <= 0 or is_retreating
	print(name, " is_defeated? ", defeated, " | HP: ", current_health)
	return defeated
	
# Take damage with nonlethal option
func take_damage(amount, is_nonlethal=true):
	var actual_damage = calculate_damage(amount)
	
	# Apply damage
	current_health = max(0, current_health - actual_damage)
	
	# Emit signal for UI updates
	health_changed.emit(current_health, max_health)
	
	# Check for defeat
	if current_health <= 0:
		on_defeat(is_nonlethal)
	
	return actual_damage

# Calculate actual damage based on defense and other factors
func calculate_damage(base_damage):
	var damage_reduction = defense / 100.0  # Convert to percentage
	var actual_damage = base_damage * (1 - damage_reduction)
	
	# Minimum damage is 1
	return max(1, int(actual_damage))

# Method to handle what happens when defeated
func on_defeat(is_nonlethal):
	if is_nonlethal and not is_construct():
		# Just knocked out, not dead
		pass
	else:
		# Actually defeated/destroyed
		pass

# Check if this is a construct/object that can be destroyed
func is_construct():
	return get_combatant_type() == CombatManager.CombatantType.CONSTRUCT

# Handle being defeated (different for player vs. NPCs)
func handle_defeat(is_nonlethal):
	# Base implementation - override in subclasses
	if is_nonlethal and not is_construct():
		# Set up for recovery
		current_health = 1
	else:
		# Actually destroyed/defeated
		queue_free()

# Retreat from combat
func retreat_from_combat():
	is_retreating = true

# Get retreat success chance
func get_retreat_chance():
	# Base chance is 50% + speed advantage
	var base_chance = 0.5
	
	# Find opponent with highest speed
	var combat_manager = get_node_or_null("/root/CombatManager")
	if combat_manager:
		var opponent_speed = 0
		for combatant in combat_manager.current_combatants:
			if combatant != self and combatant.speed > opponent_speed:
				opponent_speed = combatant.speed
		
		# Calculate speed advantage (or disadvantage)
		var speed_difference = speed - opponent_speed
		var speed_modifier = speed_difference / 100.0  # Convert to percentage
		
		return clamp(base_chance + speed_modifier, 0.1, 0.9)  # Between 10% and 90%
	
	return base_chance

# Get reward for defeating this combatant
func get_defeat_reward():
	# Base implementation - override in subclasses
	return 10  # Default reward value

# Receive rewards from combat
func receive_combat_rewards(amount):
	# Base implementation - override in subclasses
	pass

# Apply a status effect
func apply_status_effect(effect_id, effect_data):
	status_effects[effect_id] = effect_data
	
	# Apply immediate effects
	if effect_data.has("immediate_health"):
		current_health = clamp(current_health + effect_data.immediate_health, 0, max_health)
		health_changed.emit(current_health, max_health)
	
	if effect_data.has("immediate_stamina"):
		current_stamina = clamp(current_stamina + effect_data.immediate_stamina, 0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)
	
	# Signal that effect was applied
	status_effect_applied.emit(effect_id)
	
	# Set up duration if temporary
	if effect_data.has("duration") and effect_data.duration > 0:
		# Set up timer to remove effect
		var timer = get_tree().create_timer(effect_data.duration)
		timer.timeout.connect(func(): remove_status_effect(effect_id))

# Remove a status effect
func remove_status_effect(effect_id):
	if status_effects.has(effect_id):
		status_effects.erase(effect_id)
		status_effect_removed.emit(effect_id)

# Perform a combat action on a target
func perform_combat_action(target, action):
	print(name + " attacked ", target.name)
	match action.type:
		"attack":
			return perform_attack(target, action)
		"skill":
			return perform_skill(target, action)
		"item":
			return use_item(target, action)
	
	return false

# Basic attack implementation
func perform_attack(target, action):
	# Calculate base damage
	var base_damage = strength + (action.damage if action.has("damage") else 0)
	
	# Apply damage to target
	var actual_damage = target.take_damage(base_damage, true)  # Default to nonlethal
	
	# Use stamina
	current_stamina = max(0, current_stamina - (action.stamina_cost if action.has("stamina_cost") else 5))
	stamina_changed.emit(current_stamina, max_stamina)
	
	return {
		"success": true,
		"damage": actual_damage
	}

# Skill implementation
func perform_skill(target, action):
	# Skills have more complex effects but cost more stamina
	if action.has("stamina_cost") and current_stamina < action.stamina_cost:
		return {
			"success": false,
			"reason": "not_enough_stamina"
		}
	
	# Apply skill effects
	var result = {
		"success": true,
		"effects": []
	}
	
	# Handle different skill types
	if action.has("effects"):
		for effect in action.effects:
			match effect.type:
				"damage":
					var damage = effect.value
					var actual_damage = target.take_damage(damage, true)
					result.effects.append({
						"type": "damage",
						"value": actual_damage
					})
				"heal":
					var heal = effect.value
					target.current_health = min(target.current_health + heal, target.max_health)
					target.health_changed.emit(target.current_health, target.max_health)
					result.effects.append({
						"type": "heal",
						"value": heal
					})
				"status":
					target.apply_status_effect(effect.id, effect.data)
					result.effects.append({
						"type": "status",
						"id": effect.id
					})
	
	# Use stamina
	current_stamina = max(0, current_stamina - action.stamina_cost)
	stamina_changed.emit(current_stamina, max_stamina)
	
	return result

# Item use implementation
func use_item(target, action):
	# Check if item exists in inventory
	var inventory = get_node_or_null("Inventory")
	if not inventory or not inventory.has_item(action.item_id, 1):
		return {
			"success": false,
			"reason": "no_item"
		}
	
	# Use the item
	var result = {
		"success": true,
		"effects": []
	}
	
	# Apply item effects
	if action.has("effects"):
		for effect in action.effects:
			match effect.type:
				"damage":
					var damage = effect.value
					var actual_damage = target.take_damage(damage, true)
					result.effects.append({
						"type": "damage",
						"value": actual_damage
					})
				"heal":
					var heal = effect.value
					target.current_health = min(target.current_health + heal, target.max_health)
					target.health_changed.emit(target.current_health, target.max_health)
					result.effects.append({
						"type": "heal",
						"value": heal
					})
				"status":
					target.apply_status_effect(effect.id, effect.data)
					result.effects.append({
						"type": "status",
						"id": effect.id
					})
	
	# Remove item from inventory
	inventory.remove_item(action.item_id, 1)
	
	return result

# Override this in NPCs to implement AI behavior
func take_combat_turn():
	# Base implementation does nothing
	pass


# Add this function to player.gd
func add_visual_health_bar():
	# Check if health bar already exists
	if has_node("HealthBar"):
		print("Health bar already exists")
		return
		
	# Create a ProgressBar for health
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100  # Start with full health
	health_bar.size = Vector2(50, 8)
	health_bar.position = Vector2(-25, -80)  # Position above player
	
	# Style the health bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.1, 0.8, 0.2, 0.8)  # Green
	style_fill.corner_radius_top_left = 2
	style_fill.corner_radius_top_right = 2
	style_fill.corner_radius_bottom_left = 2
	style_fill.corner_radius_bottom_right = 2
	
	health_bar.add_theme_stylebox_override("background", style_bg)
	health_bar.add_theme_stylebox_override("fill", style_fill)
	
	# Add to player
	add_child(health_bar)
	
	# Connect to health change signals if we have them
	var item_effects_system = get_node_or_null("/root/ItemEffectsSystem")
	if item_effects_system and item_effects_system.has_signal("health_changed"):
		item_effects_system.health_changed.connect(_on_health_changed)
	
	print("Added health bar to " + name)
	
# Add this function to player.gd as well
func _on_health_changed(current, maximum):
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		
		# Change color based on health level
		var style_fill = StyleBoxFlat.new()
		
		if current < maximum * 0.25:
			# Low health - red
			style_fill.bg_color = Color(0.8, 0.1, 0.1, 0.8)
		elif current < maximum * 0.5:
			# Medium health - orange
			style_fill.bg_color = Color(0.8, 0.5, 0.1, 0.8)
		else:
			# Good health - green
			style_fill.bg_color = Color(0.1, 0.8, 0.2, 0.8)
			
		style_fill.corner_radius_top_left = 2
		style_fill.corner_radius_top_right = 2
		style_fill.corner_radius_bottom_left = 2
		style_fill.corner_radius_bottom_right = 2
		
		health_bar.add_theme_stylebox_override("fill", style_fill)
