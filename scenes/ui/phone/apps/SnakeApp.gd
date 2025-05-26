extends Control

const CELL_SIZE = Vector2(20, 20)
const GRID_WIDTH = 15 # GameArea width (300) / CELL_SIZE.x (20)
const GRID_HEIGHT = 20 # GameArea height (400) / CELL_SIZE.y (20)

enum SnakeGameState { START_SCREEN, PLAYING, GAME_OVER }
enum Direction { UP, DOWN, LEFT, RIGHT }

@onready var start_screen: Control = $StartScreen
@onready var game_area: ColorRect = $GameArea
@onready var game_over_screen: Control = $GameOverScreen
@onready var score_label: Label = $GameOverScreen/GameOverButtons/ScoreLabel

# Game State Variables
var snake_body: Array[Vector2] = []
var food_pos: Vector2
var current_direction: Direction = Direction.RIGHT # Default starting direction
var score: int = 0
var current_game_state: SnakeGameState = SnakeGameState.START_SCREEN
var time_since_last_move: float = 0.0
const MOVE_INTERVAL: float = 0.2 # Seconds between moves, adjust for speed (0.2 is faster for testing)

var food_node: ColorRect = null # To hold the food display node
var snake_nodes: Array[ColorRect] = [] # To hold snake segment display nodes

func _ready():
	show_start_screen()
	# Connect button signals
	# Ensure these paths are correct based on SnakeApp.tscn
	var start_button = $StartScreen/StartScreenButton/StartButton
	if start_button:
		if not start_button.pressed.is_connected(start_game): # Check if not already connected
			start_button.pressed.connect(start_game)

	var play_again_button = $GameOverScreen/GameOverButtons/PlayAgainButton
	if play_again_button:
		if not play_again_button.pressed.is_connected(start_game): # Check if not already connected
			play_again_button.pressed.connect(start_game)


func show_start_screen():
	current_game_state = SnakeGameState.START_SCREEN
	start_screen.show()
	game_area.hide()
	game_over_screen.hide()
	clear_game_elements() # Clear any old game drawings from game_area

func show_game_over_screen():
	current_game_state = SnakeGameState.GAME_OVER
	game_over_screen.show()
	game_area.hide()
	start_screen.hide()
	score_label.text = "Score: " + str(score)
	clear_game_elements() # Clear game drawings from game_area

func start_game():
	current_game_state = SnakeGameState.PLAYING
	start_screen.hide()
	game_over_screen.hide()
	game_area.show()

	clear_game_elements() # Clear previous game elements before starting new

	score = 0
	# Ensure GRID_WIDTH/2 and GRID_HEIGHT/2 are integers if Vector2 expects ints, or use float values
	snake_body = [Vector2(floor(GRID_WIDTH / 2.0), floor(GRID_HEIGHT / 2.0))]
	current_direction = Direction.RIGHT # Default starting direction
	time_since_last_move = 0.0

	# Initialize snake_nodes array
	snake_nodes = []

	spawn_food()
	draw_game_elements() # Initial draw of food and snake

func _process(delta: float):
	if current_game_state == SnakeGameState.PLAYING:
		time_since_last_move += delta
		if time_since_last_move >= MOVE_INTERVAL:
			time_since_last_move = 0.0 # Reset timer
			move_snake()
			# check_collisions() is implicitly called within move_snake or immediately after a conceptual move
			# draw_game_elements() is called at the end of move_snake if successful

func _unhandled_input(event: InputEvent):
	if current_game_state != SnakeGameState.PLAYING:
		return # Only process input if game is active

	if event.is_action_pressed("ui_right"):
		if current_direction != Direction.LEFT: # Prevent moving directly opposite
			current_direction = Direction.RIGHT
	elif event.is_action_pressed("ui_left"):
		if current_direction != Direction.RIGHT:
			current_direction = Direction.LEFT
	elif event.is_action_pressed("ui_up"):
		if current_direction != Direction.DOWN:
			current_direction = Direction.UP
	elif event.is_action_pressed("ui_down"):
		if current_direction != Direction.UP:
			current_direction = Direction.DOWN

func spawn_food():
	var new_food_pos: Vector2
	var valid_pos = false
	while not valid_pos:
		new_food_pos = Vector2(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
		valid_pos = true
		for segment in snake_body:
			if segment == new_food_pos:
				valid_pos = false
				break
	food_pos = new_food_pos
	# The actual drawing of food is handled by draw_game_elements,
	# which might be called after spawn_food (e.g., in start_game or after eating)

func move_snake():
	if snake_body.is_empty(): return # Safety check

	var new_head_pos = snake_body.front() # Get current head position
	# Calculate new head position based on direction
	match current_direction:
		Direction.UP:
			new_head_pos.y -= 1
		Direction.DOWN:
			new_head_pos.y += 1
		Direction.LEFT:
			new_head_pos.x -= 1
		Direction.RIGHT:
			new_head_pos.x += 1

	# Wall collision check
	if new_head_pos.x < 0 or new_head_pos.x >= GRID_WIDTH or        new_head_pos.y < 0 or new_head_pos.y >= GRID_HEIGHT:
		show_game_over_screen()
		return

	# Self-collision check: Check if the new head position collides with any existing segment
	# This must be done BEFORE adding the new head if the snake hasn't grown,
	# or by checking against all but the very last segment if it has grown.
	# A simpler way is to check against all segments *before* adding the new head,
	# and if it's not eating food, the tail will be popped later.
	for i in range(snake_body.size()):
		# If snake eats food, it grows, so new head can't be where current head is.
		# If snake doesn't eat food, tail is removed, so new head can't be where current head is.
		# The main concern is collision with other parts of the body.
		if snake_body[i] == new_head_pos:
			show_game_over_screen()
			return

	snake_body.push_front(new_head_pos) # Add new head

	if new_head_pos == food_pos:
		score += 1
		spawn_food() # New food will be drawn in the next draw_game_elements call
		# Don't pop_back tail, snake grows
	else:
		snake_body.pop_back() # Remove tail if no food eaten

	draw_game_elements() # Redraw snake and food after successful move and potential growth/food respawn

func clear_game_elements():
	# Clear food node
	if food_node != null && is_instance_valid(food_node):
		game_area.remove_child(food_node)
		food_node.queue_free()
		food_node = null

	# Clear snake segment nodes
	for segment_node in snake_nodes:
		if segment_node != null && is_instance_valid(segment_node):
			game_area.remove_child(segment_node)
			segment_node.queue_free()
	snake_nodes.clear()


func draw_game_elements():
	# It's more efficient to clear specific elements (old snake, old food)
	# rather than everything in game_area if other UI elements were there.
	# The current clear_game_elements handles this well.

	# First, clear the old drawings
	# If food_node exists, remove it before redrawing (or update position)
	if food_node != null && is_instance_valid(food_node):
		game_area.remove_child(food_node)
		food_node.queue_free()
		food_node = null

	# If snake_nodes exist, remove them before redrawing (or update positions)
	for sn_node in snake_nodes: # Use a different variable name to avoid conflict
		if sn_node != null && is_instance_valid(sn_node):
			game_area.remove_child(sn_node)
			sn_node.queue_free()
	snake_nodes.clear()


	# Draw food
	food_node = ColorRect.new()
	food_node.size = CELL_SIZE
	food_node.position = food_pos * CELL_SIZE
	food_node.color = Color.RED 
	game_area.add_child(food_node)

	# Draw snake
	for i in range(snake_body.size()):
		var segment_pos = snake_body[i]
		var segment_rect = ColorRect.new() # Renamed from segment_node to avoid conflict
		segment_rect.size = CELL_SIZE
		segment_rect.position = segment_pos * CELL_SIZE
		if i == 0: # Head
			segment_rect.color = Color.GREEN_YELLOW # Corrected line
		else: # Body
			segment_rect.color = Color.GREEN
		game_area.add_child(segment_rect)
		snake_nodes.append(segment_rect)

# Input handling (_input function) and button connections 
# (e.g., $StartScreen/StartButton.pressed.connect(start_game))
# will be added in subsequent steps.
# Remember to connect StartButton and PlayAgainButton's 'pressed' signal 
# to the 'start_game' method in the Godot Editor or in _ready().
# Also, implement the _input function for controlling the snake.
