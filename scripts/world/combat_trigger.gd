# combat_trigger.gd
extends Area2D

# Type of combat trigger
@export_enum("On Enter", "On Interact", "On Event") var trigger_type = 0
@export var npc_combatants = []  # List of NodePaths to NPCs that will join the combat
@export var trigger_once = true  # Whether this trigger should only activate once
@export var trigger_active = true  # Whether this trigger is currently active
@export var trigger_event_name = ""  # Event name for "On Event" trigger type

var triggered = false

func _ready():
	add_to_group("combat_trigger")
	
	# Set up collision
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.extents = Vector2(50, 50)
		collision.shape = shape
		add_child(collision)
	
	# Connect signals based on trigger type
	match trigger_type:
		0:  # On Enter
			body_entered.connect(_on_body_entered)
		1:  # On Interact
			pass  # Will be connected externally
	
	# Connect to event bus for "On Event" trigger type
	if trigger_type == 2 and trigger_event_name != "":
		var event_bus = get_node_or_null("/root/EventBus")
		if event_bus and event_bus.has_signal(trigger_event_name):
			event_bus.connect(trigger_event_name, _on_event_triggered)

func _on_body_entered(body):
	if triggered and trigger_once:
		return
		
	if not trigger_active:
		return
		
	if body.is_in_group("player"):
		# Start combat
		await get_tree().process_frame
		start_combat(body)

func interact():
	if triggered and trigger_once:
		return
		
	if not trigger_active:
		return
		
	# Find player
	var player = get_node_or_null("../Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if player:
		# Start combat
		start_combat(player)

func _on_event_triggered():
	if triggered and trigger_once:
		return
		
	if not trigger_active:
		return
		
	# Find player
	var player = get_node_or_null("../Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if player:
		# Start combat
		start_combat(player)

func start_combat(player):
	# Get all NPC combatants
	var opponents = []
	
	for npc_path in npc_combatants:
		var npc = get_node_or_null(npc_path)
		if npc and not npc.is_defeated():
			opponents.append(npc)
	
	# Don't start combat if no opponents
	if opponents.size() == 0:
		return
	
	# Get combat manager
	var combat_manager = get_node_or_null("/root/CombatManager")
	if combat_manager:
		combat_manager.start_combat(player, opponents)
		
		# Mark as triggered
		triggered = true
		
		# If trigger once, disable this trigger
		if trigger_once:
			trigger_active = false
			
			# Optional: make this area non-interactive
			collision_layer = 0
			collision_mask = 0
