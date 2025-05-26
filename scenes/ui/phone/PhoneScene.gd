extends Control

@onready var app_panel: Control = $PhoneCase/PhoneScreen/AppPanel
@onready var phone_shell: MarginContainer = $PhoneCase/PhoneScreen/PhoneShell
@onready var back_button: Button = $PhoneCase/BackButton
@onready var app_grid: GridContainer = $PhoneCase/PhoneScreen/PhoneShell/VBoxContainer/AppGrid

# Dictionary mapping button names to their scene paths
const APP_SCENE_PATHS = {
	"AppButton_Messages": "res://scenes/ui/phone/apps/MessagesApp.tscn",
	"AppButton_Discord": "res://scenes/ui/phone/apps/DiscordApp.tscn", # Updated path
	"AppButton_SocialFeed": "res://scenes/ui/phone/apps/SocialFeedApp.tscn", # Assuming this exists or is placeholder
	"AppButton_Journal": "res://scenes/ui/phone/apps/JournalApp.tscn", # Assuming this exists or is placeholder
	"AppButton_Email": "res://scenes/ui/phone/apps/EmailApp.tscn", # Updated path
	"AppButton_Grades": "res://scenes/ui/phone/apps/GradesApp.tscn", # Assuming this exists or is placeholder
	"AppButton_CameraRoll": "res://scenes/ui/phone/apps/CameraRollApp.tscn",
	"AppButton_Spore": "res://scenes/ui/phone/apps/SporeApp.tscn", # Assuming this exists or is placeholder
	"AppButton_Snake": "res://scenes/ui/phone/apps/SnakeApp.tscn"
}

func _ready():
	# Initial visibility
	app_panel.hide()
	phone_shell.show()
	back_button.hide()

	# Connect app button signals
	for button_node in app_grid.get_children():
		if button_node is BaseButton: # Corrected to BaseButton for TextureButtons
			var button: BaseButton = button_node # Type hint updated
			var button_name: String = button.name
			if APP_SCENE_PATHS.has(button_name):
				var app_scene_path: String = APP_SCENE_PATHS[button_name]
				# Ensure the callable is correctly formed for binding arguments
				button.pressed.connect(Callable(self, "_on_app_button_pressed").bind(app_scene_path))
			else:
				print("Warning: No scene path defined for button: ", button_name)
				
	# Connect back button signal
	back_button.pressed.connect(Callable(self, "_on_back_button_pressed"))

func _on_app_button_pressed(app_scene_path: String):
	# Unload current app if one exists
	if app_panel.get_child_count() > 0:
		for child in app_panel.get_children():
			child.queue_free()

	# Load new app
	var app_scene_res = load(app_scene_path)
	if app_scene_res:
		var app_instance = app_scene_res.instantiate()
		app_panel.add_child(app_instance)
	else:
		print("Error: Could not load app scene: ", app_scene_path)
		return # Don't change visibility if scene loading failed

	# Visibility changes
	app_panel.show()
	back_button.show()
	phone_shell.hide()

func _on_back_button_pressed():
	# Unload current app
	if app_panel.get_child_count() > 0:
		for child in app_panel.get_children():
			child.queue_free()

	# Visibility changes
	phone_shell.show()
	app_panel.hide()
	back_button.hide()

# Placeholder for future use if needed
# func open_messages_app():
#     _on_app_button_pressed(APP_SCENE_PATHS["AppButton_Messages"])


func _on_app_panel_resized() -> void:
	print(str(app_panel.size))   # Replace with function body.
