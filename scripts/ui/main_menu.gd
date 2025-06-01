extends Control

# Main Menu script for Love & Lichens
# Handles menu navigation and game initialization

var game_controller

const scr_debug:bool = false
var debug : bool

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print(GameState.script_name_tag(self) + "Main Menu initialized")
	# Get reference to game controller - it should be an autoload
	game_controller = get_node_or_null("/root/GameController")
	if debug: print(GameState.script_name_tag(self) + "GameController found as Autoload" if game_controller else "ERROR: GameController not found!")

	# Connect menu button signals
	$MenuButtons/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MenuButtons/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$MenuButtons/OptionsButton.pressed.connect(_on_options_pressed)
	$MenuButtons/CreditsButton.pressed.connect(_on_credits_pressed)
	$MenuButtons/QuitButton.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	# Use node path to directly access GameController, not our stored reference
	# This ensures we're getting the actual autoload instance
	if debug: print(GameState.script_name_tag(self) + "New game selected")
	
	# Get GameController
	game_controller = get_node_or_null("/root/GameController")
	if not game_controller:
		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found!")
		return
	
	# First, directly hide this menu to match load game behavior
	visible = false
	
	# Then start new game
	game_controller.start_new_game()
#	if debug: print(GameState.script_name_tag(self) + "New game selected")
#	# We'll try different ways to access the GameController
#	if Engine.has_singleton("GameController"):
#		if debug: print(GameState.script_name_tag(self) + "Using GameController singleton")
#		var GameController = Engine.get_singleton("GameController")
#		GameController.start_new_game()
#	elif get_node_or_null("/root/GameController"):
#		if debug: print(GameState.script_name_tag(self) + "Using node path to access GameController")
#		get_node("/root/GameController").start_new_game()
#	else:
#		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found - did you add it as an Autoload in Project Settings?")

func _on_load_game_pressed():
	# Get the save/load system
	var save_load_system = get_node_or_null("/root/SaveLoadSystem")
	
	if save_load_system:
		# Show load game UI
		# For now, load slot 0 as a test
		save_load_system.load_game(0)
	else:
		if debug: print(GameState.script_name_tag(self) + "ERROR: SaveLoadSystem not found for load game")
#	if debug: print(GameState.script_name_tag(self) + "Load game selected - showing load game screen")
	# In a complete implementation, this would show a load game dialog
	# For now, just load from slot 0
	
	# We'll try different ways to access the GameController
#	if Engine.has_singleton("GameController"):
#		if debug: print(GameState.script_name_tag(self) + "Using GameController singleton")
#		var GameController = Engine.get_singleton("GameController")
#		GameController.load_game(0)
#	elif get_node_or_null("/root/GameController"):
#		if debug: print(GameState.script_name_tag(self) + "Using node path to access GameController")
#		get_node("/root/GameController").load_game(0)
#	else:
#		if debug: print(GameState.script_name_tag(self) + "ERROR: GameController not found - did you add it as an Autoload in Project Settings?")

func _on_options_pressed():
	if debug: print(GameState.script_name_tag(self) + "Options selected")
#	if debug: print(GameState.script_name_tag(self) + "Options selected - options screen not implemented yet")
	# This would show an options menu

func _on_credits_pressed():
	if debug: print(GameState.script_name_tag(self) + "Credits selected - credits screen not implemented yet")
	# This would show credits

func _on_quit_pressed():
	if debug: print(GameState.script_name_tag(self) + "Quit selected")
#	if debug: print(GameState.script_name_tag(self) + "Quit selected - exiting game")
	get_tree().quit()
