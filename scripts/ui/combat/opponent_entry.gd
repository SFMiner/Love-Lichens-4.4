# opponent_entry.gd
extends HBoxContainer

signal opponent_selected(opponent)

var opponent_data = null

@onready var name_label = $NameLabel
@onready var health_bar = $HealthBar

func _ready():
	# Connect to button press
	$TargetButton.pressed.connect(_on_target_button_pressed)
	print(name + " is _ready.")
func set_opponent(opponent):
	opponent_data = opponent
	
	# Set name label
	name_label.text = opponent.name
	
	# Set health bar
	health_bar.max_value = opponent.max_health
	health_bar.value = opponent.current_health
	
	# Set health percentage label
	var health_percent = int((float(opponent.current_health) / opponent.max_health) * 100)
	$HealthPercent.text = str(health_percent) + "%"
	
	# Connect to health changed signal
	if not opponent.health_changed.is_connected(_on_opponent_health_changed):
		opponent.health_changed.connect(_on_opponent_health_changed)
	
	# Update appearance based on opponent status
	update_appearance()

func _on_opponent_health_changed(current, maximum):
	# Update health bar
	health_bar.max_value = maximum
	health_bar.value = current
	
	# Update health percentage label
	var health_percent = int((float(current) / maximum) * 100)
	$HealthPercent.text = str(health_percent) + "%"
	
	# Update appearance
	update_appearance()

func update_appearance():
	print("update_appearance called")
	if opponent_data.is_defeated():
		# Show as defeated
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		$StatusIcon.texture = preload("res://assets/icons/defeated_icon.png")
		$StatusIcon.visible = true
		$TargetButton.disabled = true
	elif opponent_data.is_retreating:
		# Show as retreating
		modulate = Color(0.7, 0.7, 1.0, 0.8)
		$StatusIcon.texture = preload("res://assets/icons/retreating_icon.png")
		$StatusIcon.visible = true
		$TargetButton.disabled = true
	else:
		# Normal state
		modulate = Color(1, 1, 1, 1)
		$StatusIcon.visible = false
		$TargetButton.disabled = false
		
		# Check for status effects
		if opponent_data.status_effects.size() > 0:
			$StatusIcon.texture = preload("res://assets/icons/status_icon.png")
			$StatusIcon.visible = true

func highlight_for_targeting(enabled):
	if enabled:
		# Add a highlight effect
		$Background.color = Color(0.9, 0.7, 0.3, 0.3)
		$Background.visible = true
		$TargetButton.icon = preload("res://assets/icons/target_icon.png")
	else:
		# Remove highlight
		$Background.visible = false
		$TargetButton.icon = null

func _on_target_button_pressed():
	# Emit signal with this opponent
	opponent_selected.emit(opponent_data)
