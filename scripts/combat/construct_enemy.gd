# construct_enemy.gd
extends ConstructCombatant

@export var construct_name := "Animated Object"
@export var construct_color := Color(0.7, 0.5, 0.3, 1.0)
@export var construct_size := Vector2(64, 64)
@export var is_combat_active := true
@export var detection_radius := 150.0

# Reference to the ColorRect
@onready var visual = $"."
@onready var detection_area = $DetectionArea
@onready var interaction_area = $InteractionArea
@onready var name_label = $NameLabel

# Combat initialization flag
var combat_initialized := false
var player_detected := false

func _ready():
	# Set up visual appearance
	visual.color = construct_color
	visual.custom_minimum_size = construct_size
	visual.size = construct_size
	
	# Set up collision
	var collision_shape = $CollisionShape2D
	if collision_shape:
		var shape = RectangleShape2D.new()
		shape.size = construct_size
		collision_shape.shape = shape
	
	# Set up detection area
	if detection_area:
		var detection_shape = detection_area.get_node("CollisionShape2D")
		if detection_shape:
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = detection_radius
			detection_shape.shape = circle_shape
		
		# Connect detection signals
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Set up interaction area
	if interaction_area:
		var interaction_shape = interaction_area.get_node("CollisionShape2D")
		if interaction_shape:
			var shape = RectangleShape2D.new()
			shape.size = construct_size * 1.2  # Slightly larger than visual
			interaction_shape.shape = shape
		
		# Connect interaction signals
		interaction_area.input_event.connect(_on_interaction_area_input_event)
	
	# Set up name label
	if name_label:
		name_label.text = construct_name
	
	# Set combat stats based on configuration
	max_health = 30
	current_health = max_health
	defense = 5
	strength = 8
	speed = 5
	material_type = "wood"  # Default material
	
	# Set up combat signals
	health_changed.connect(_on_health_changed)
	status_effect_applied.connect(_on_status_effect_applied)
	status_effect_removed.connect(_on_status_effect_removed)
	
	# Mark initialization complete
	combat_initialized = true

func _process(delta):
	# Check if player is detected and combat should start
	if player_detected and is_combat_active and not is_defeated():
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# Make sure player is still in detection range
			var distance = global_position.distance_to(player.global_position)
			if distance <= detection_radius:
				# Start combat
				start_combat_with_player()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_detected = true
		name_label.modulate = Color(1, 0.3, 0.3)

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_detected = false
		name_label.modulate = Color(1, 1, 1)

func _on_interaction_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= detection_radius:
				start_combat_with_player()

func start_combat_with_player():
	if is_combat_active and not is_defeated():
		is_combat_active = false  # Prevent multiple combat starts
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var combat_manager = get_node_or_null("/root/CombatManager")
			if combat_manager:
				combat_manager.start_combat(player, self)
				print(GameState.script_name_tag(self) + "Combat started with " + construct_name)

func interact():
	# Handle player interaction
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= detection_radius * 1.5:
			start_combat_with_player()

func _on_health_changed(current, maximum):
	# Update appearance based on health
	var health_percent = float(current) / maximum
	
	if health_percent <= 0.25:
		visual.color = construct_color.darkened(0.6)
	elif health_percent <= 0.5:
		visual.color = construct_color.darkened(0.3)
	else:
		visual.color = construct_color
	
	# Update label to show health
	name_label.text = construct_name + " (" + str(current) + "/" + str(maximum) + ")"

func _on_status_effect_applied(effect_id):
	# Visual feedback for status effects
	$StatusEffects.visible = true
	var status_label = Label.new()
	status_label.text = effect_id
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$StatusEffects.add_child(status_label)

func _on_status_effect_removed(effect_id):
	# Remove status effect label
	for child in $StatusEffects.get_children():
		if child is Label and child.text == effect_id:
			child.queue_free()
			break
	
	# Hide status effects container if empty
	if $StatusEffects.get_child_count() == 0:
		$StatusEffects.visible = false

# Override defeat handler
func handle_defeat(is_nonlethal):
	super.handle_defeat(is_nonlethal)
	
	# Reactivate combat after recovery time
	await get_tree().create_timer(30.0).timeout
	if is_instance_valid(self) and not is_queued_for_deletion():
		is_combat_active = true
