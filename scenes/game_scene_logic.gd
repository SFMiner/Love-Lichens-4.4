extends Node

# Main logic for the game.tscn scene.
# This script can interact with the GameController autoload globally (e.g., GameController.some_method())
# and manage the child nodes of game.tscn.
@onready var phone_scene_instance: Control = $PhoneCanvasLayer/PhoneSceneInstance
@onready var phone_toggle_button: Button = $CanvasLayer/PhoneToggleButton
const scr_debug : bool = false
var debug 

func _ready():
	print("game.tscn main logic ready.")
	debug = scr_debug or GameController.sys_debug
	# Example: Accessing the autoload GameController
	# if GameController:
	#     GameController.perform_some_initialization_if_needed()

	if phone_toggle_button:
		phone_toggle_button.pressed.connect(_on_phone_toggle_button_pressed)
	else:
		if debug: print("GameController: PhoneToggleButton not found at path /root/Game/CanvasLayer/PhoneToggleButton")

	if not phone_scene_instance:
		if debug: print("GameController: PhoneSceneInstance not found at path /root/Game/PhoneCanvasLayer/PhoneSceneInstance")
	elif phone_scene_instance: # Explicitly ensure phone is hidden on _ready
		phone_scene_instance.visible = false
		GameController.is_phone_active = false # Added line
		if debug: print("GameController: Ensured PhoneSceneInstance is hidden on _ready.")
# Add these new methods

# Public method to be called after a game load
func hide_phone_ui_on_load():
	if phone_scene_instance:
		phone_scene_instance.visible = false
		GameController.is_phone_active = false # Added line
		# If PhoneScene had an internal reset function, call it here too
		# e.g., phone_scene_instance.reset_to_home_screen() 
		if debug: print("GameController: Phone UI hidden and reset due to game load.")
	else:
		if debug: print("GameController: PhoneSceneInstance not found, cannot hide on load.")

# Add other game scene specific logic here if needed in the future.

func _on_phone_toggle_button_pressed():
	if phone_scene_instance:
		phone_scene_instance.visible = not phone_scene_instance.visible
		GameController.is_phone_active = phone_scene_instance.visible # Added line
		if debug: print("Phone visibility toggled to: ", phone_scene_instance.visible)
	else:
		if debug: print("PhoneSceneInstance is null, cannot toggle visibility.")
