# cutscene_manager.gd - Fixed version
extends Node

signal movement_started(character_id, target)
signal movement_completed(character_id)

const scr_debug : bool = false
var debug

# Dictionary to track active movements
var active_movements = {}

var movement_queue = {}  # Dictionary of character_id -> Array of movement commands
var processing_movement_queue = false

func _ready():
	print(GameState.script_name_tag(self) + "CutsceneManager initialized and ready!")
	debug = scr_debug or GameController.sys_debug

func _process(delta):
	# Process ongoing movements
	var completed_movements = []
	
	for character_id in active_movements:
		var movement_data = active_movements[character_id]
		var character = movement_data.character
		
		if not is_instance_valid(character):
			if debug: print(GameState.script_name_tag(self) + "Character no longer valid: ", character_id)
			completed_movements.append(character_id)
			continue
			
		# Process movement
		var finished = _process_movement(character_id, movement_data, delta)
		if finished:
			if debug: print(GameState.script_name_tag(self) + "Movement completed for: ", character_id)
			completed_movements.append(character_id)
			movement_completed.emit(character_id)
	
	# Clean up completed movements
	for character_id in completed_movements:
		active_movements.erase(character_id)

func _process_movement(character_id, movement_data, delta):
	var character = movement_data.character
	var target_position = movement_data.target_position
	var speed = movement_data.speed
	
	# Calculate direction and distance
	var direction = (target_position - character.global_position).normalized()
	var distance = character.global_position.distance_to(target_position)
	
	# Check if we're done
	var stop_distance = movement_data.get("stop_distance", 10.0)
	if distance <= stop_distance:
		if debug: print(GameState.script_name_tag(self) + "Reached destination")
		return true
	
	# Move the character
	if character.has_method("move_and_slide"):
		# If it's a CharacterBody2D
		character.velocity = direction * speed
		character.move_and_slide()
	else:
		# If it's a regular Node2D
		character.global_position += direction * speed * delta
	
	# Update animation if needed
	var animation = movement_data.get("animation", "walk")
	_update_animation(character, direction, animation)
	
	return false

func _update_animation(character, direction, animation_type):
	# Set the character's animation based on the movement direction
	if character.has_method("set_animation"):
		# Custom method in your character scripts
		character.set_animation(animation_type, direction)
	elif character.has_method("play_animation"):
		# Another possible method in your character scripts
		character.play_animation(animation_type)
	elif character.has_node("AnimationPlayer"):
		# Direct animation control
		var anim_player = character.get_node("AnimationPlayer")
		
		# Determine direction suffix
		var dir_suffix = ""
		if abs(direction.x) > abs(direction.y):
			dir_suffix = "_right" if direction.x > 0 else "_left"
		else:
			dir_suffix = "_down" if direction.y > 0 else "_up"
		
		# Try to play the animation
		var anim_name = animation_type + dir_suffix
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		elif anim_player.has_animation(animation_type):
			anim_player.play(animation_type)

func move_character(character_id, target, animation="walk", speed=100, stop_distance=0, time=null):
	print(GameState.script_name_tag(self) + "MOVE CHARACTER CALLED: ", character_id, " to ", target)
	
	# Find the character node using GameState
	var character
	var game_state = GameState  # Direct reference to autoload
	
	if character_id == "player":
		character = game_state.get_player()
	else:
		character = game_state.get_npc_by_id(character_id)
	
	if not character:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Character not found: ", character_id)
		return false
	
	if debug: print(GameState.script_name_tag(self) + "Found character: ", character)
	
	# Calculate target position
	var target_position = _determine_target_position(target)
	
	if target_position == Vector2.ZERO:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Could not determine target position")
		return false
	
	if debug: print(GameState.script_name_tag(self) + "Target position: ", target_position)
	
	# Calculate speed
	var actual_speed = speed
	if time != null and time > 0:
		var distance = character.global_position.distance_to(target_position)
		actual_speed = distance / float(time)
	
	# Set up movement data
	var movement_data = {
		"character": character,
		"target_position": target_position,
		"speed": actual_speed,
		"animation": animation,
		"stop_distance": float(stop_distance)
	}
	
	# Start the movement
	active_movements[character_id] = movement_data
	print(GameState.script_name_tag(self) + "Movement started for: ", character_id, " with data: ", movement_data)
	movement_started.emit(character_id, target_position)
	
	return true

func _determine_target_position(target):
	# Calculate target position based on different input types
	var game_state = GameState  # Direct reference to autoload
	
	if target is Vector2:
		return target
		
	if target is String:
		# If target is "player", find player position
		if target == "player":
			var player = game_state.get_player()
			return player.global_position if player else Vector2.ZERO
		
		# Check if target is another character
		var target_char = game_state.get_npc_by_id(target)
		if target_char:
			return target_char.global_position
		
		# Check if it's a marker
		var marker = game_state.get_marker_by_id(target)
		if marker:
			return marker.global_position
	
	elif target is Node2D:
		return target.global_position
	
	# If we can't determine the position, return zero vector
	return Vector2.ZERO

func play_animation(character_id, animation_name):
	if debug: print(GameState.script_name_tag(self) + "PLAY ANIMATION CALLED: ", character_id, " animation: ", animation_name)
	
	# Find the character node using GameState
	var character
	var game_state = GameState  # Direct reference to autoload
	
	if character_id == "player":
		character = game_state.get_player()
	else:
		var npcs = GameState.get_current_npcs()
		if debug: print(GameState.script_name_tag(self) + "Current NPCs:" + str(npcs))
		character = game_state.get_npc_by_id(character_id)
	
	if not character:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Character not found for animation: ", character_id)
		return false
		
	if debug: print(GameState.script_name_tag(self) + "Found character for animation: ", character)
	
	if character.has_node("Sprite2D"):
		var sprite = character.get_node("Sprite2D")
		if debug: print(GameState.script_name_tag(self) + "Sprite info - texture: ", sprite.texture, 
			", hframes: ", sprite.hframes, 
			", vframes: ", sprite.vframes, 
			", frame: ", sprite.frame)
		
		# Check if texture is actually loaded
		if sprite.texture == null:
			if debug: print(GameState.script_name_tag(self) + "ERROR: No texture loaded for sprite!")
			
			# Try to load a default texture
			var texture_path = "res://assets/character_sprites/" + character_id + "/standard/idle.png"
			if ResourceLoader.exists(texture_path):
				sprite.texture = load(texture_path)
				print(GameState.script_name_tag(self) + "Loaded fallback texture: ", texture_path)
	
	# Try different animation methods
	if character.has_method("play_animation"):
		character.play_animation(animation_name)
		if debug: print(GameState.script_name_tag(self) + "Called play_animation method")
		return true
	elif character.has_method("set_animation"):
		character.set_animation(animation_name, Vector2.ZERO)
		if debug: print(GameState.script_name_tag(self) + "Called set_animation method")
		return true
	elif character.has_node("AnimationPlayer"):
		var anim_player = character.get_node("AnimationPlayer")
		if anim_player.has_animation(animation_name):
			anim_player.play(animation_name)
			if debug: print(GameState.script_name_tag(self) + "Played animation through AnimationPlayer")
			return true
		else:
			if debug: print(GameState.script_name_tag(self) + "Animation not found in AnimationPlayer: ", animation_name)
	
	# Create a simple visual effect for simple sprites
	# Fixed: Use create_tween() method properly
	var tween = get_tree().create_tween()
	if animation_name == "jump" or animation_name == "jump_down":
		tween.tween_property(character, "position:y", character.position.y - 20, 0.2)
		tween.tween_property(character, "position:y", character.position.y, 0.2)
		if debug: print(GameState.script_name_tag(self) + "Created simple jump tween animation")
	else:
		tween.tween_property(character, "modulate", Color(1.5, 1.5, 1.5), 0.2)
		tween.tween_property(character, "modulate", Color(1, 1, 1), 0.2)
		if debug: print(GameState.script_name_tag(self) + "Created simple highlight tween animation")
	
	return true

func wait_for_movements():
	if debug: print(GameState.script_name_tag(self) + "Wait for movements called, active movements: ", active_movements.size())
	
	# If no movements, return immediately
	if active_movements.size() == 0:
		return true
	
	# Return the signal to await
	return movement_completed

func move_character_to_marker(character_id, marker_id, run=false):
	if debug: print(GameState.script_name_tag(self) + "Moving character ", character_id, " to marker ", marker_id)
	
	# Find the character
	var character
	if character_id == "player":
		character = GameState.get_player()
	else:
		character = GameState.get_npc_by_id(character_id)
		
	if not character:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Character not found: ", character_id)
		return false
	
	# Find the marker
	var marker = GameState.get_marker_by_id(marker_id)
	if not marker:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Marker not found: ", marker_id)
		return false
	
	# Get target position
	var target_position = marker.global_position
	
	# Set up movement data
	var movement_data = {
		"character": character,
		"target": marker_id,  
		"target_position": target_position,  # Add this to match what _process_movement expects
		"speed": character.base_speed * (1.5 if run else 1.0),
		"animation": "run" if run else "walk",
		"stop_distance": 10.0,
		"is_navigating": true
	}
	
	# Start navigation
	var navigation_manager = get_node_or_null("/root/NavigationManager")
	if navigation_manager:
		navigation_manager.navigate_character(character, target_position, run)
	
	# Add to active movements
	active_movements[character_id] = movement_data
	
	# Emit signal
	movement_started.emit(character_id, marker_id)
	return true



func _on_navigation_completed(character):
	# Find which character completed navigation
	var character_id = ""
	for id in active_movements.keys():
		if active_movements[id].character == character:
			character_id = id
			break
	
	if character_id.is_empty():
		return
	
	# Mark movement as complete
	if debug: print(GameState.script_name_tag(self) + "Character ", character_id, " completed navigation")
	
	# Remove from active movements
	active_movements.erase(character_id)
	
	# Emit completion signal
	movement_completed.emit(character_id)

func queue_movement(character_id, marker_id, run=false):
	if not movement_queue.has(character_id):
		movement_queue[character_id] = []
	
	movement_queue[character_id].append({
		"marker_id": marker_id,
		"run": run
	})
	
	# Start processing the queue if not already processing
	if processing_movement_queue:
		call_deferred("_process_movement_queue")
