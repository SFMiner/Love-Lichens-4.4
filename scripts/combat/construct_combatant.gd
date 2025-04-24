# construct_combatant.gd
extends NPCCombatant
class_name ConstructCombatant

# Specific properties for constructs
@export var is_destructible := true
@export var material_type := "wood"  # wood, stone, metal, etc.
@export var weakness_types := []  # damage types this construct is weak to

# Override combat type
func get_combatant_type():
	return CombatManager.CombatantType.CONSTRUCT

# Override is_construct check
func is_construct():
	return true

# Override damage calculation to account for material type
func calculate_damage(base_damage):
	var actual_damage = base_damage
	
	# Apply defense reduction
	var damage_reduction = defense / 100.0
	actual_damage = base_damage * (1 - damage_reduction)
	
	# Check damage type against weaknesses
	var attacker = get_tree().get_nodes_in_group("current_attacker")
	if attacker.size() > 0:
		var damage_type = attacker[0].get_current_damage_type()
		if damage_type in weakness_types:
			# Weak to this damage type, take 50% more damage
			actual_damage *= 1.5
	
	# Different materials have different base resistances
	match material_type:
		"wood":
			# Wood is vulnerable to fire, normal otherwise
			pass
		"stone":
			# Stone has high physical resistance
			if not "piercing" in weakness_types:
				actual_damage *= 0.7
		"metal":
			# Metal has very high physical resistance
			if not "piercing" in weakness_types and not "blunt" in weakness_types:
				actual_damage *= 0.5
	
	# Ensure minimum damage is 1
	return max(1, int(actual_damage))

# Override defeat handling since constructs can be destroyed
func handle_defeat(is_nonlethal):
	# Constructs can be fully destroyed even in nonlethal combat
	if is_destructible:
		# Spawn drops
		drop_loot()
		
		# Play destruction animation/effects
		play_destruction_effect()
		
		# Remove from scene
		queue_free()
	else:
		# Indestructible construct just gets disabled
		current_health = 1
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		collision_layer = 0
		collision_mask = 0
		
		# Notify that it's disabled
		var label = Label.new()
		label.text = "Disabled"
		label.position = Vector2(0, -50)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		
		# Constructs don't retreat
		is_retreating = false

# Play destruction effect based on material
func play_destruction_effect():
	# Create particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 30
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	
	# Set particle color based on material
	match material_type:
		"wood":
			particles.color = Color(0.6, 0.4, 0.2)
		"stone":
			particles.color = Color(0.7, 0.7, 0.7)
		"metal":
			particles.color = Color(0.8, 0.8, 0.9)
	
	# Add to parent before self is deleted
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Set up timer to clean up particles
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): particles.queue_free())
	
	# Play sound effect
	match material_type:
		"wood":
			# Play wood breaking sound
			pass
		"stone":
			# Play stone crumbling sound
			pass
		"metal":
			# Play metal crashing sound
			pass

# Override retreat - constructs don't retreat
func can_retreat():
	return false
