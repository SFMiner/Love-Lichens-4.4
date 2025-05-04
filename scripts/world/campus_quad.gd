extends Node2D

# Campus Quad scene script
# Initializes the level and manages scene-specific logic
const scr_debug :bool = false
var debug
var scene_item_num : int = 0
var visit_areas = {}
var all_areas_visited = false
var camera_limit_right = 3050	
var camera_limit_bottom = 3050
var camera_limit_left = 0
var camera_limit_top = 0
var zoom_factor = 1
@onready var player = $Player
@onready var construct_spawner = $ConstructSpawner
@onready var combat_manager = get_node_or_null("/root/CombatManager")
@onready var camera = get_node_or_null("Camerad2D")
	 

func _ready():
	var debug_label = $CanvasLayer/GameInfo
	debug = scr_debug or GameController.sys_debug 
			
	player = $Player
	if debug:
		if debug_label:
			if player and player.interactable_object:
				debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nCan interact with: " + player.interactable_object.name
			else:
				debug_label.text = "Love & Lichens - Demo\nUse WASD or arrow keys to move\nPress E or Space to interact with NPCs\n\nNo interactable object nearby"
				
	player.set_camera_limits(camera_limit_right, camera_limit_bottom, camera_limit_left, camera_limit_top, zoom_factor)


	if construct_spawner:
		if debug:print("Setting up construct spawner")
		# Clear any existing positions to avoid duplicates
		construct_spawner.spawn_positions.clear()
		
		# Add spawn positions
		construct_spawner.add_spawn_position(Vector2(1730, 800))  # Player's position
		construct_spawner.add_spawn_position(Vector2(1730, 1000))  # Near player
		
		# If auto_spawn is false, manually trigger spawning
		if not construct_spawner.auto_spawn:
			construct_spawner.spawn()
			
		# Verify spawning worked
		await get_tree().process_frame
		var constructs = get_tree().get_nodes_in_group("construct_enemies")
		if debug:print("Constructs after spawning: ", constructs.size())
		
	
	print("Campus Quad scene initialized")
	# Set up the scene components
	setup_player()
	setup_npcs()
	setup_items()
	
	# Initialize necessary systems
	initialize_systems()
	for child in get_node_or_null('z_Objects').get_children():
		if "z_index" in child:
			child.add_to_group('z_Objects')
			child.z_index = child.global_position.y
	
	# Find and set up visitable areas
	setup_visit_areas()
	
	# Notify quest system that player is in campus quad
	await get_tree().create_timer(0.2).timeout
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and quest_system.has_method("on_location_entered"):
		quest_system.on_location_entered("campus_quad")
		if debug:print("Notified quest system of location: campus_quad")


func _input(event):
	# Debug key to force start combat (press F2)
	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed:
		if debug:print("F2 pressed - starting test combat")
		
		# Ensure constructs exist
		var constructs = get_tree().get_nodes_in_group("construct_enemies")
		if constructs.size() == 0:
			if debug:print("No constructs found, spawning test constructs")
			spawn_test_constructs()
			# Wait a frame for constructs to initialize
			await get_tree().process_frame
			constructs = get_tree().get_nodes_in_group("construct_enemies")
		
		if debug:print("Number of constructs found: ", constructs.size())
		
		# Get player reference
		player = $Player
		if not player:
			if debug:print("ERROR: Player not found!")
			return
			
		# Initialize player combat stats
		ensure_player_combat_ready()
		
		# Force the combat UI to show first
		var combat_ui = get_node_or_null("/root/CombatUI")
		if combat_ui:
			if debug:print("Found CombatUI, making it visible")
			
			# Force the combat panel to be visible
			var combat_panel = combat_ui.get_node_or_null("CombatPanel")
			if combat_panel:
				combat_panel.visible = true
				if debug:print("Made combat panel visible")
			
			# Try to initialize combat through the best available method
			if combat_ui.has_method("initialize_combat"):
				combat_ui.initialize_combat(player, constructs)
				if debug:print("Combat initialized via initialize_combat method")
			elif combat_ui.has_method("set_player"):
				combat_ui.set_player(player)
				if combat_ui.has_method("set_opponents"):
					combat_ui.set_opponents(constructs)
				if debug:print("Combat initialized via set_player/set_opponents methods")
			else:
				# Try to set properties directly
				if "current_player" in combat_ui:
					combat_ui.current_player = player
					if debug:print("Set current_player property directly")
				
				if "current_opponents" in combat_ui:
					combat_ui.current_opponents = constructs
					if debug:print("Set current_opponents property directly")
				
				# Fallback to combat manager if needed
				if combat_manager:
					combat_manager.current_combatants = [player] + constructs
					if debug:print("Set combatants via CombatManager")
			
			# Update UI displays if methods exist
			if combat_ui.has_method("update_player_stats"):
				combat_ui.update_player_stats()
				if debug:print("Updated player stats in UI")
				
			if combat_ui.has_method("update_opponent_list"):
				combat_ui.update_opponent_list()
				if debug:print("Updated opponent list in UI")
				
			# Show a status message
			var status_label = combat_ui.get_node_or_null("CombatPanel/StatusPanel/StatusLabel")
			if status_label:
				status_label.text = "Combat started!"
				if debug:print("Set status message")
		else:
			if debug:print("CombatUI not found")
			
		# Now start the actual combat
		if combat_manager and player and constructs.size() > 0:
			# If combat manager exists, properly start combat
			if combat_manager.has_method("start_combat"):
				combat_manager.start_combat(player, constructs)
				if debug:print("Combat started via CombatManager.start_combat")
			else:
				# Directly simulate combat for testing
				if debug:print("Simulating combat turn")
				var construct = constructs[0]
				
				# Make construct attack player
				var damage = 5
				player.current_health -= damage
				if debug: print(construct.name + " attacked player for " + str(damage) + " damage!")
				if debug: print("Player health: " + str(player.current_health) + "/" + str(player.max_health))
				
				# Update the UI to show the change
				if combat_ui and combat_ui.has_method("update_player_stats"):
					combat_ui.update_player_stats()
		else:
			if debug: print("Cannot start combat - missing component")


func setup_player():
	player = $Player
	if player:
		if debug: print("Player found in scene")
		# Make sure the player's input settings are correct
		if not InputMap.has_action("interact"):
			print("Adding 'interact' action to InputMap")
			InputMap.add_action("interact")
			var event = InputEventKey.new()
			event.keycode = KEY_E
			InputMap.action_add_event("interact", event)
		else:
			if debug: print("'interact' action already exists in InputMap")
	else:
		if debug: print("ERROR: Player not found in scene!")

func setup_visit_areas():
	# Find all Area2D nodes in the "visitable_area" group
	var areas = get_tree().get_nodes_in_group("visitable_area")
	if debug: print("Found " + str(areas.size()) + " visitable areas in the scene")
	
	# Set up tracking for each area
	for area in areas:
		# Store the area in our tracking dict
		visit_areas[area.name] = {
			"visited": false,
			"area": area
		}
		
		# Connect the body_entered signal if not already connected
		if not area.body_entered.is_connected(_on_visit_area_entered):
			area.body_entered.connect(_on_visit_area_entered.bind(area.name))

func setup_npcs():
	# Setup Professor Moss
	var professor_moss = $ProfessorMoss
	if professor_moss:
		if debug: print("Professor Moss found in scene")
		# Ensure Professor Moss has the correct collision settings
		if professor_moss.get_collision_layer() != 2:
			if debug: print("Setting Professor Moss collision layer to 2")
			professor_moss.set_collision_layer(2)
	else:
		if debug: print("ERROR: Professor Moss not found in scene!")
	
	# Find and setup all NPCs
	var npcs = get_tree().get_nodes_in_group("interactable")
	if debug: print("Found ", npcs.size(), " interactable NPCs in scene")

func setup_items():
	pass
	#var interactables = get_tree().get_nodes_in_group("interactable")
	# Placeholder for interactable setup
				 
func initialize_systems():
	# Get references to necessary systems
	var dialog_system = get_node_or_null("/root/DialogSystem")
	var relationship_system = get_node_or_null("/root/RelationshipSystem")
	
	if dialog_system:
		if debug: print("Dialog System found")
	else:
		if debug: print("WARNING: Dialog System not found! Adding a temporary one.")
		var new_dialog_system = Node.new()
		new_dialog_system.name = "DialogSystem"
		new_dialog_system.set_script(load("res://scripts/systems/dialog_system.gd"))
		get_tree().root.add_child(new_dialog_system)
	
	if relationship_system:
		if debug: print("Relationship System found")
		
		# Initialize relationship with Professor Moss if needed
		if not relationship_system.relationships.has("professor_moss"):
			if debug: print("Initializing relationship with Professor Moss")
			relationship_system.initialize_relationship("professor_moss", "Professor Moss")
	else:
		if debug: print("WARNING: Relationship System not found")

func _on_visit_area_entered(body, area_name):
	if not body.is_in_group("player"):
		return
		
	if debug: print("Player entered area: " + area_name)
	
	# Mark as visited
	if visit_areas.has(area_name):
		# If already visited, no need to process again
		if visit_areas[area_name].visited:
			if debug: print("Area already visited: " + area_name)
			return
			
		visit_areas[area_name].visited = true
		if debug: print("Marked area as visited: " + area_name)
		
		# Change visual indicator to show it's been visited
		var area = visit_areas[area_name].area
		var indicator = area.find_child("VisualIndicator") # Name your ColorRect or Sprite2D this
		if indicator:
			if indicator is ColorRect:
				indicator.color = Color(0.0, 1.0, 0.0, 0.5) # Change to green
			elif indicator is Sprite2D:
				indicator.modulate = Color(0.0, 1.0, 0.0, 0.5)
		
		# Check if we've visited all areas
		var all_visited = check_all_areas_visited()
		if debug: print("All areas visited: ", all_visited)
		
		# Notify quest system
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system:
			if quest_system.has_method("on_area_visited"):
				if debug: print("Calling quest_system.on_area_visited with ", area_name, " and campus_quad")
				quest_system.on_area_visited(area_name, "campus_quad")
				
			# If all areas visited, also notify for a complete exploration
			if all_visited and quest_system.has_method("on_area_exploration_completed"):
				if debug: print("Calling quest_system.on_area_exploration_completed with campus_quad")
				quest_system.on_area_exploration_completed("campus_quad")

func check_all_areas_visited():
	# Return early if we already know all areas are visited
	if all_areas_visited:
		return true
		
	for area_name in visit_areas:
		if not visit_areas[area_name].visited:
			return false
	
	# If we get here, all areas have been visited
	all_areas_visited = true
	if debug: print("All areas in campus quad have been visited!")
	return true
	
func spawn_test_constructs():
	if debug: print("Spawning test constructs manually")
	
	# Create two constructs directly
	for i in range(2):
		# Create a CharacterBody2D as the base
		var construct = CharacterBody2D.new()
		construct.name = "TestConstruct" + str(i+1)
		
		# Add a ColorRect as visual representation 
		var visual = ColorRect.new()
		visual.color = Color(0.7, 0.5, 0.3) if i == 0 else Color(0.5, 0.3, 0.7)
		visual.size = Vector2(64, 64)
		visual.position = Vector2(-32, -32)  # Center the rect
		construct.add_child(visual)
		
		# Add a collision shape
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 32
		collision.shape = shape
		construct.add_child(collision)
		
		# Add a label for the name
		var label = Label.new()
		label.text = "Construct " + str(i+1)
		label.position = Vector2(-40, -50)
		construct.add_child(label)
		
		# Position the construct in the world
		construct.global_position = Vector2(1169 + i * 150, 1112)
		
		# Add basic combat stats directly
		construct.set_script(load("res://scripts/combat/construct_combatant.gd"))
		
		# Set up combat stats after the script is attached
		if construct.has_method("_ready"):
			# Add to scene first so ready can run
			add_child(construct)
			# Now add to group and manually configure
			construct.add_to_group("construct_enemies")
			
			# Set basic stats manually
			construct.max_health = 30
			construct.current_health = 30
			construct.max_stamina = 50
			construct.current_stamina = 50
			construct.strength = 8
			construct.defense = 5
			construct.speed = 5
			
			# Add visual health bar
			construct.add_visual_health_bar()
			
			if debug: print("Created test construct at position ", construct.global_position)
		else:
			if debug: print("ERROR: Failed to attach script to construct")


# Helper function to add combat properties to player if needed
func _add_combat_properties_to_player():
	if debug: print("Adding combat properties to player")
	
	# Add combat properties if they don't exist
	if not player.get("max_health"):
		player.max_health = 100
	if not player.get("current_health"):
		player.current_health = player.max_health
	if not player.get("max_stamina"):
		player.max_stamina = 100
	if not player.get("current_stamina"):
		player.current_stamina = player.max_stamina
	if not player.get("strength"):
		player.strength = 15
	if not player.get("defense"):
		player.defense = 10
	if not player.get("speed"):
		player.speed = 12
	if not player.get("willpower"):
		player.willpower = 10
	if not player.get("status_effects"):
		player.status_effects = {}
	
	# Add signal declarations if they don't exist
	if not player.has_signal("health_changed"):
		player.add_user_signal("health_changed", ["current", "maximum"])
	if not player.has_signal("stamina_changed"):
		player.add_user_signal("stamina_changed", ["current", "maximum"])
	
	# Add required methods if they don't exist
	if not player.has_method("get_combatant_type"):
		player.get_combatant_type = func(): return 0
	
	if not player.has_method("is_defeated"):
		player.is_defeated = func(): return player.current_health <= 0
	
	if not player.has_method("get_initiative"):
		player.get_initiative = func(): return player.speed + randi() % 5
	
	if not player.has_method("take_damage"):
		player.take_damage = func(amount, _is_nonlethal=true):
			var damage_reduction = player.defense / 100.0
			var actual_damage = amount * (1 - damage_reduction)
			actual_damage = max(1, int(actual_damage))
			player.current_health = max(0, player.current_health - actual_damage)
			player.emit_signal("health_changed", player.current_health, player.max_health)
			return actual_damage
	
	if not player.has_method("perform_attack"):
		player.perform_attack = func(target, action):
			var base_damage = player.strength
			var actual_damage = target.take_damage(base_damage, true)
			player.current_stamina = max(0, player.current_stamina - 5)
			player.emit_signal("stamina_changed", player.current_stamina, player.max_stamina)
			return {"success": true, "damage": actual_damage}
	
	if debug: print("Player combat properties added successfully")

# Helper function to ensure constructs have required combat methods
func _ensure_construct_combat_methods(construct):
	if debug: print("Ensuring combat methods for construct: " + construct.name)
	
	# Add combat properties if they don't exist
	if not construct.get("max_health"):
		construct.max_health = 30
	if not construct.get("current_health"):
		construct.current_health = construct.max_health
	if not construct.get("max_stamina"):
		construct.max_stamina = 50
	if not construct.get("current_stamina"):
		construct.current_stamina = construct.max_stamina
	if not construct.get("strength"):
		construct.strength = 8
	if not construct.get("defense"):
		construct.defense = 5
	if not construct.get("speed"):
		construct.speed = 5
	if not construct.get("status_effects"):
		construct.status_effects = {}
	
	# Add signal declarations if they don't exist
	if not construct.has_signal("health_changed"):
		construct.add_user_signal("health_changed", ["current", "maximum"])
	
	# Add required methods if they don't exist
	if not construct.has_method("get_combatant_type"):
		construct.get_combatant_type = func(): return 2  # CONSTRUCT type
	
	if not construct.has_method("is_construct"):
		construct.is_construct = func(): return true
	
	if not construct.has_method("is_defeated"):
		construct.is_defeated = func(): return construct.current_health <= 0
	
	if not construct.has_method("get_initiative"):
		construct.get_initiative = func(): return construct.speed + randi() % 5
	
	if not construct.has_method("take_damage"):
		construct.take_damage = func(amount, _is_nonlethal=true):
			var damage_reduction = construct.defense / 100.0
			var actual_damage = amount * (1 - damage_reduction)
			actual_damage = max(1, int(actual_damage))
			construct.current_health = max(0, construct.current_health - actual_damage)
			construct.emit_signal("health_changed", construct.current_health, construct.max_health)
			
			# Change color based on health
			var visual = construct.get_node_or_null("@ColorRect@")
			if visual:
				var health_percent = float(construct.current_health) / construct.max_health
				if health_percent <= 0.25:
					visual.color = visual.color.darkened(0.6)
				elif health_percent <= 0.5:
					visual.color = visual.color.darkened(0.3)
			
			return actual_damage
	
	if not construct.has_method("perform_attack"):
		construct.perform_attack = func(target, action):
			var base_damage = construct.strength
			var actual_damage = target.take_damage(base_damage, true)
			return {"success": true, "damage": actual_damage}
	
	if not construct.has_method("take_combat_turn"):
		construct.take_combat_turn = func():
			print(construct.name + " taking combat turn")
			if combat_manager and combat_manager.current_combatants.size() > 0:
				player = combat_manager.current_combatants[0]
				if player and not player.is_defeated():
					construct.perform_attack(player, {})
					print(construct.name + " attacked player for damage")
	
	if debug: print("Construct combat methods added successfully")

func ensure_player_combat_ready():
	# Ensure player has necessary signals
	if not player.has_signal("health_changed"):
		player.add_user_signal("health_changed", ["current", "maximum"])
	
	if not player.has_signal("stamina_changed"):
		player.add_user_signal("stamina_changed", ["current", "maximum"])
	
	# Ensure player has necessary stats
	if not player.get("max_health"):
		player.max_health = 100
	
	if not player.get("current_health"):
		player.current_health = player.max_health
	
	if not player.get("max_stamina"):
		player.max_stamina = 100
	
	if not player.get("current_stamina"):
		player.current_stamina = player.max_stamina
	
	if not player.get("strength"):
		player.strength = 15
		
	if not player.get("defense"):
		player.defense = 10
		
	if not player.get("speed"):
		player.speed = 12
	
	if not player.get("status_effects"):
		player.status_effects = {}
	
	if debug: print("Player combat stats initialized")
