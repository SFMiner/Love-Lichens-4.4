extends Control

# Node references
@onready var phone_case: PanelContainer = $PhoneCase
@onready var phone_screen: PanelContainer = $PhoneCase/PhoneScreen
@onready var phone_shell: PanelContainer = $PhoneCase/PhoneScreen/PhoneShell
@onready var app_grid: GridContainer = $PhoneCase/PhoneScreen/PhoneShell/AppGrid
@onready var app_panel: Control = $PhoneCase/PhoneScreen/AppPanel
@onready var back_button: Button = $PhoneCase/BackButton

# App scene paths (adjust paths as needed when apps are created)
const APP_PATHS = {
    "Messages": "res://scenes/ui/phone/apps/MessagesApp.tscn",
    "CameraRoll": "res://scenes/ui/phone/apps/CameraRollApp.tscn",
    "Email": "res://scenes/ui/phone/apps/EmailApp.tscn",
    "Discord": "res://scenes/ui/phone/apps/DiscordApp.tscn",
    "SocialFeed": "res://scenes/ui/phone/apps/SocialFeedApp.tscn",
    "Journal": "res://scenes/ui/phone/apps/JournalApp.tscn",
    "Grades": "res://scenes/ui/phone/apps/GradesApp.tscn",
    "Spore": "res://scenes/ui/phone/apps/SporeApp.tscn",
}

# Screen colors
const HOME_SCREEN_COLOR = Color(0.85, 0.85, 0.85)
const APP_OPEN_COLOR = Color(0.9, 0.9, 0.9)

var current_app_instance: Node = null

func _ready():
    # Set initial screen color
    phone_screen.get_theme_stylebox("panel").set_bg_color(HOME_SCREEN_COLOR)

    # Populate AppGrid with buttons
    for app_name in APP_PATHS:
        var app_button = Button.new()
        app_button.text = app_name
        app_button.custom_minimum_size = Vector2(80, 80) # Adjust size as needed
        app_button.connect("pressed", Callable(self, "_on_app_button_pressed").bind(APP_PATHS[app_name]))
        app_grid.add_child(app_button)

    # Connect BackButton
    back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

func _on_app_button_pressed(app_scene_path: String):
    print("Attempting to load app: " + app_scene_path)
    # Free any existing app
    if current_app_instance:
        app_panel.remove_child(current_app_instance)
        current_app_instance.queue_free()
        current_app_instance = null

    # Load the new app scene
    var app_scene = load(app_scene_path)
    if app_scene:
        current_app_instance = app_scene.instantiate()
        app_panel.add_child(current_app_instance)
        # Make the app instance fill the AppPanel
        current_app_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
        current_app_instance.set_offsets_preset(Control.PRESET_FULL_RECT)


        # Update UI visibility and color
        phone_shell.visible = false
        app_panel.visible = true
        phone_screen.get_theme_stylebox("panel").set_bg_color(APP_OPEN_COLOR)
        back_button.visible = true
    else:
        printerr("Failed to load app scene: " + app_scene_path)
        # Optionally, show an error message to the player or return to home
        _return_to_home_screen()


func _on_back_button_pressed():
    _return_to_home_screen()

func _return_to_home_screen():
    if current_app_instance:
        app_panel.remove_child(current_app_instance)
        current_app_instance.queue_free()
        current_app_instance = null

    phone_shell.visible = true
    app_panel.visible = false
    phone_screen.get_theme_stylebox("panel").set_bg_color(HOME_SCREEN_COLOR)
    # back_button.visible = false # Keep back button visible as it's part of phone case

func clear_current_app():
    if current_app_instance:
        app_panel.remove_child(current_app_instance)
        current_app_instance.queue_free()
        current_app_instance = null
    app_panel.visible = false
    phone_shell.visible = true
    phone_screen.get_theme_stylebox("panel").set_bg_color(HOME_SCREEN_COLOR)

# Call this function if an app fails to load, or if an app needs to close itself
# and there's no specific "back to app list" button within the app itself.
func go_home():
    _return_to_home_screen()
