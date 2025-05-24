extends Control

# Updated node paths after PhoneCase and new PhoneScreen restructuring
@onready var phone_case: PanelContainer = $PhoneCase
@onready var phone_screen: PanelContainer = $PhoneCase/PhoneScreen # This is the new, inset screen area
@onready var app_panel: Control = $PhoneCase/PhoneScreen/AppPanel
@onready var phone_shell: PanelContainer = $PhoneCase/PhoneScreen/PhoneShell
@onready var back_button: Button = $PhoneCase/BackButton # Now a child of PhoneCase
@onready var app_grid: GridContainer = $PhoneCase/PhoneScreen/PhoneShell/AppGrid

# Dictionary mapping button names to their scene paths
const APP_SCENE_PATHS = {
	"AppButton_Messages": "res://scenes/ui/phone/apps/MessagesApp.tscn",
	"AppButton_Discord": "res://scenes/ui/phone/apps/DiscordApp.tscn", # Updated path
	"AppButton_SocialFeed": "res://scenes/ui/phone/apps/SocialFeedApp.tscn", # Assuming this exists or is placeholder
	"AppButton_Journal": "res://scenes/ui/phone/apps/JournalApp.tscn", # Assuming this exists or is placeholder
	"AppButton_Email": "res://scenes/ui/phone/apps/EmailApp.tscn", # Updated path
	"AppButton_Grades": "res://scenes/ui/phone/apps/GradesApp.tscn", # Assuming this exists or is placeholder
	"AppButton_CameraRoll": "res://scenes/ui/phone/apps/CameraRollApp.tscn",
	"AppButton_Spore": "res://scenes/ui/phone/apps/SporeApp.tscn" # Assuming this exists or is placeholder
}

func _ready():
	# Initial visibility
	app_panel.hide()
	phone_shell.show()
	back_button.hide()

	# Connect app button signals
	for button_node in app_grid.get_children():
		if button_node is Button:
			var button: Button = button_node
			var button_name: String = button.name
			if APP_SCENE_PATHS.has(button_name):
				var app_scene_path: String = APP_SCENE_PATHS[button_name]
				# Ensure the callable is correctly formed for binding arguments
				button.pressed.connect(Callable(self, "_on_app_button_pressed").bind(app_scene_path))
			else:
				print("Warning: No scene path defined for button: ", button_name)
				
	# Connect back button signal
	back_button.pressed.connect(Callable(self, "_on_back_button_pressed"))

	# Set initial PhoneScreen color (e.g., home screen color)
	set_screen_color(Color(0.85, 0.85, 0.85)) # Default home screen gray


func set_screen_color(new_color: Color):
	if phone_screen:
		# Ensure we are working with a StyleBoxFlat, duplicating if it's a default theme stylebox
		var style_box_to_modify = phone_screen.get_theme_stylebox("panel")
		var new_style_box: StyleBoxFlat

		if style_box_to_modify is StyleBoxFlat:
			# If it's already a StyleBoxFlat, duplicate it to avoid modifying a shared resource
			# unless it's already an override (unique instance).
			# A more robust check would be to see if it's a theme override already.
			# For simplicity here, we duplicate if it's a StyleBoxFlat.
			# If it's already an override, this makes a copy of the override.
			new_style_box = style_box_to_modify.duplicate(true) as StyleBoxFlat
		else:
			# If it's not a StyleBoxFlat (e.g., nil, or some other StyleBox type from theme)
			# or if we want to ensure it's always a fresh StyleBoxFlat:
			new_style_box = StyleBoxFlat.new()

		if new_style_box: # Should always be true if StyleBoxFlat.new() was called
			new_style_box.bg_color = new_color
			phone_screen.add_theme_stylebox_override("panel", new_style_box)
		else:
			# This case should ideally not be reached if StyleBoxFlat.new() works.
			print_debug("PhoneScreen: Could not create or duplicate a StyleBoxFlat for 'panel'. Cannot set color.")
	else:
		print_debug("PhoneScreen node not found. Cannot set screen color.")


func _on_app_button_pressed(app_scene_path: String):
	# Conceptual: Set a default background color when an app is opened
	set_screen_color(Color(0.9, 0.9, 0.9)) # Light gray for apps

	# Unload current app if one exists
	if app_panel.get_child_count() > 0:
		for child in app_panel.get_children():
			child.queue_free()

	# Load new app
	var app_scene_res = load(app_scene_path)
	if app_scene_res:
		var app_instance = app_scene_res.instantiate()
		# Ensure the app instance expands to fill the AppPanel
		app_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		app_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
		app_panel.add_child(app_instance)
	else:
		print("Error: Could not load app scene: ", app_scene_path)
		return # Don't change visibility if scene loading failed

	# Visibility changes
	app_panel.show()
	back_button.show()
	phone_shell.hide()

func _on_back_button_pressed():
	# Conceptual: Reset background color when returning to app grid
	set_screen_color(Color(0.85, 0.85, 0.85)) # Default home screen gray

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

# Branch refresh commit.
# Activating branch for GitHub push 03-18 10:00
