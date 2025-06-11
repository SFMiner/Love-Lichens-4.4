extends Control

@onready var app_panel: Control = $PhoneCase/PhoneScreen/PhoneShell/VBoxContainer/AppPanel
@onready var phone_shell: MarginContainer = $PhoneCase/PhoneScreen/PhoneShell
@onready var back_button: Button = $PhoneCase/BackButton
@onready var app_grid: GridContainer = $PhoneCase/PhoneScreen/PhoneShell/VBoxContainer/AppGrid
@onready var phone_icons: HBoxContainer = $PhoneCase/PhoneScreen/PhoneShell/VBoxContainer/PhoneIcons

# Phone state variables for save/load system
var current_app: String = ""
var notifications: Array = []
var app_settings: Dictionary = {}

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

const APP_SCRIPT_PATHS = {
	"Messages": "res://scenes/ui/phone/apps/MessagesApp.gd",
	"Discord": "res://scenes/ui/phone/apps/DiscordApp.gd", # Updated path
	"SocialFeed": "res://scenes/ui/phone/apps/SocialFeedApp.gd", # Assuming this exists or is placeholder
	"Journal": "res://scenes/ui/phone/apps/JournalApp.gd", # Assuming this exists or is placeholder
	"Email": "res://scenes/ui/phone/apps/EmailApp.gd", # Updated path
	"Grades": "res://scenes/ui/phone/apps/GradesApp.gd", # Assuming this exists or is placeholder
	"CameraRoll": "res://scenes/ui/phone/apps/CameraRollApp.gd",
	"Spore": "res://scenes/ui/phone/apps/SporeApp.gd", # Assuming this exists or is placeholder
	"Snake": "res://scenes/ui/phone/apps/SnakeApp.gd"
	}

const scr_debug : bool = false
var debug: bool = false

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug 
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
				if debug: print(GameState.script_name_tag(self) + "Warning: No scene path defined for button: ", button_name)
				
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
		if debug: print(GameState.script_name_tag(self) + "Error: Could not load app scene: ", app_scene_path)
		return # Don't change visibility if scene loading failed

	# Visibility changes
	phone_icons.hide()
	app_grid.hide()
	app_panel.show()
	back_button.show()

func _on_back_button_pressed():
	# Unload current app
	if app_panel.get_child_count() > 0:
		for child in app_panel.get_children():
			child.queue_free()

	# Visibility changes
	phone_shell.show()
	app_grid.show()
	app_panel.hide()
	back_button.hide()

# Placeholder for future use if needed
# func open_messages_app():
#     _on_app_button_pressed(APP_SCENE_PATHS["AppButton_Messages"])


func _on_app_panel_resized() -> void:
	app_panel = $PhoneCase/PhoneScreen/PhoneShell/VBoxContainer/AppPanel

	if debug: print(GameState.script_name_tag(self) + "AppPanel.size = ", str(app_panel.size))   # Replace with function body.
	
# Save/Load System Integration for Phone Apps
func get_save_data_original():
	var save_data = {
		"phone_apps": {}
	}
	
	# Discord App Data
	var discord_app = get_node_or_null("DiscordApp")
	if discord_app and discord_app.has_method("get_save_data"):
		save_data.phone_apps["discord"] = discord_app.get_save_data()
	elif discord_app:
		# Fallback for basic Discord data
		var messages = [] if not discord_app.has("messages") else discord_app.messages
		var channels = {} if not discord_app.has("channels") else discord_app.channels
		var read_status = {} if not discord_app.has("read_status") else discord_app.read_status
		var current_channel = "" if not discord_app.has("current_channel") else discord_app.current_channel
		
		save_data.phone_apps["discord"] = {
			"messages": messages,
			"channels": channels,
			"read_status": read_status,
			"current_channel": current_channel
		}
	
	# Email App Data
	var email_app = get_node_or_null("EmailApp")
	if email_app and email_app.has_method("get_save_data"):
		save_data.phone_apps["email"] = email_app.get_save_data()
	elif email_app:
		# Fallback for basic email data
		var inbox = [] if not email_app.has("inbox") else email_app.inbox
		var sent = [] if not email_app.has("sent") else email_app.sent
		var drafts = [] if not email_app.has("drafts") else email_app.drafts
		var read_emails = [] if not email_app.has("read_emails") else email_app.read_emails
		
		save_data.phone_apps["email"] = {
			"inbox": inbox,
			"sent": sent,
			"drafts": drafts,
			"read_emails": read_emails
		}
	
	# Journal App Data
	var journal_app = get_node_or_null("JournalApp")
	if journal_app and journal_app.has_method("get_save_data"):
		save_data.phone_apps["journal"] = journal_app.get_save_data()
	elif journal_app:
		# Fallback for basic journal data
		var entries = [] if not journal_app.has("entries") else journal_app.entries
		var categories = [] if not journal_app.has("categories") else journal_app.categories
		var bookmarks = [] if not journal_app.has("bookmarks") else journal_app.bookmarks
		var last_entry_date = "" if not journal_app.has("last_entry_date") else journal_app.last_entry_date
		
		save_data.phone_apps["journal"] = {
			"entries": entries,
			"categories": categories,
			"bookmarks": bookmarks,
			"last_entry_date": last_entry_date
		}
	
	# Snake App Data - currently the only working app
	var snake_app = get_node_or_null("SnakeApp")
	if snake_app and snake_app.has_method("get_save_data"):
		save_data.phone_apps["snake"] = snake_app.get_save_data()
	elif snake_app:
		# Fallback for basic snake data
		var high_score = 0 if not snake_app.has("high_score") else snake_app.high_score
		
		save_data.phone_apps["snake"] = {
			"high_score": high_score
		}
	
	# Phone UI state - since no properties are declared, we'll just use empty defaults
	save_data["phone_ui"] = {
		"current_app": "", # The currently active app (if any)
		"notifications": [], # Any pending notifications
		"app_settings": {}  # App-specific settings
	}
	
	# Print debug info
	if debug: print(GameState.script_name_tag(self) + "PhoneScene: Collected phone app data")
	return save_data

func load_save_data_original(data):
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self) + "PhoneScene: ERROR: Invalid data type for phone apps load")
		return false
	
	# Restore Discord App
	if data.has("phone_apps") and data.phone_apps.has("discord"):
		var discord_app = get_node_or_null("DiscordApp")
		if discord_app and discord_app.has_method("load_save_data"):
			discord_app.load_save_data(data.phone_apps.discord)
		elif discord_app:
			# Fallback restoration
			var discord_data = data.phone_apps.discord
			if discord_data.has("messages") and discord_app.has("messages"):
				discord_app.messages = discord_data.messages
			if discord_data.has("channels") and discord_app.has("channels"):
				discord_app.channels = discord_data.channels
			if discord_data.has("read_status") and discord_app.has("read_status"):
				discord_app.read_status = discord_data.read_status
			if discord_data.has("current_channel") and discord_app.has("current_channel"):
				discord_app.current_channel = discord_data.current_channel
	
	# Restore Email App
	if data.has("phone_apps") and data.phone_apps.has("email"):
		var email_app = get_node_or_null("EmailApp")
		if email_app and email_app.has_method("load_save_data"):
			email_app.load_save_data(data.phone_apps.email)
		elif email_app:
			# Fallback restoration
			var email_data = data.phone_apps.email
			if email_data.has("inbox") and email_app.has("inbox"):
				email_app.inbox = email_data.inbox
			if email_data.has("sent") and email_app.has("sent"):
				email_app.sent = email_data.sent
			if email_data.has("drafts") and email_app.has("drafts"):
				email_app.drafts = email_data.drafts
			if email_data.has("read_emails") and email_app.has("read_emails"):
				email_app.read_emails = email_data.read_emails
	
	# Restore Journal App
	if data.has("phone_apps") and data.phone_apps.has("journal"):
		var journal_app = get_node_or_null("JournalApp")
		if journal_app and journal_app.has_method("load_save_data"):
			journal_app.load_save_data(data.phone_apps.journal)
		elif journal_app:
			# Fallback restoration
			var journal_data = data.phone_apps.journal
			if journal_data.has("entries") and journal_app.has("entries"):
				journal_app.entries = journal_data.entries
			if journal_data.has("categories") and journal_app.has("categories"):
				journal_app.categories = journal_data.categories
			if journal_data.has("bookmarks") and journal_app.has("bookmarks"):
				journal_app.bookmarks = journal_data.bookmarks
			if journal_data.has("last_entry_date") and journal_app.has("last_entry_date"):
				journal_app.last_entry_date = journal_data.last_entry_date
	
	# Restore Snake App (the working app)
	if data.has("phone_apps") and data.phone_apps.has("snake"):
		var snake_app = get_node_or_null("SnakeApp")
		if snake_app and snake_app.has_method("load_save_data"):
			snake_app.load_save_data(data.phone_apps.snake)
		elif snake_app:
			# Fallback restoration
			var snake_data = data.phone_apps.snake
			if snake_data.has("high_score") and snake_app.has("high_score"):
				snake_app.high_score = snake_data.high_score
	
	# Restore Phone UI state
	if data.has("phone_ui"):
		var ui_data = data.phone_ui
		if ui_data.has("current_app"):
			current_app = ui_data.current_app
		if ui_data.has("notifications"):
			notifications = ui_data.notifications
		if ui_data.has("app_settings"):
			app_settings = ui_data.app_settings
	
	if debug: print(GameState.script_name_tag(self) + "PhoneScene: Phone apps restoration complete")
	return true

func reset():
	for key in GameState.phone_apps:
		GameState.phone_apps[key].clear()
	for key in APP_SCRIPT_PATHS.keys():
		var script = load(APP_SCRIPT_PATHS[key])
		if script.has_method("clear_data"):
			script.clear_data()
	
func load_save_data(data : Dictionary):
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self) + "PhoneScene: ERROR: Invalid data type for phone apps load")
		return false
	GameState.phone_apps = data
	# Restore Discord App
	if debug: print(GameState.script_name_tag(self) + "saved phone data for reload = ", str(data))
	if data.has("phone_apps") and data.phone_apps.has("discord"):
		var discord_app = get_node_or_null("DiscordApp")
		if discord_app and discord_app.has_method("load_save_data"):
			discord_app.load_save_data(data.phone_apps.discord)
		elif discord_app:
			# Fallback restoration
			var discord_data = data.phone_apps.discord
			if discord_data.has("messages") and discord_app.has("messages"):
				discord_app.messages = discord_data.messages
			if discord_data.has("channels") and discord_app.has("channels"):
				discord_app.channels = discord_data.channels
			if discord_data.has("read_status") and discord_app.has("read_status"):
				discord_app.read_status = discord_data.read_status
			if discord_data.has("current_channel") and discord_app.has("current_channel"):
				discord_app.current_channel = discord_data.current_channel
	
	# Restore Email App
	if data.has("phone_apps") and data.phone_apps.has("email"):
		var email_app = get_node_or_null("EmailApp")
		if email_app and email_app.has_method("load_save_data"):
			email_app.load_save_data(data.phone_apps.email)
		elif email_app:
			# Fallback restoration
			var email_data = data.phone_apps.email
			if email_data.has("inbox") and email_app.has("inbox"):
				email_app.inbox = email_data.inbox
			if email_data.has("sent") and email_app.has("sent"):
				email_app.sent = email_data.sent
			if email_data.has("drafts") and email_app.has("drafts"):
				email_app.drafts = email_data.drafts
			if email_data.has("read_emails") and email_app.has("read_emails"):
				email_app.read_emails = email_data.read_emails
	
	# Restore Journal App
	if data.has("phone_apps") and data.phone_apps.has("journal"):
		var journal_app = get_node_or_null("JournalApp")
		if journal_app and data.has("journal_app_entries"):
			journal_app._refresh_list()
#		if journal_app and journal_app.has_method("load_save_data"):
#			journal_app.load_save_data(data.phone_apps.journal)
			
#		elif journal_app:
			# Fallback restoration
#			var journal_data = data.phone_apps.journal
#			if journal_data.has("entries") and journal_app.has("entries"):
#				journal_app.entries = journal_data.entries
#			if journal_data.has("categories") and journal_app.has("categories"):
#				journal_app.categories = journal_data.categories
#			if journal_data.has("bookmarks") and journal_app.has("bookmarks"):
#				journal_app.bookmarks = journal_data.bookmarks
#			if journal_data.has("last_entry_date") and journal_app.has("last_entry_date"):
#				journal_app.last_entry_date = journal_data.last_entry_date
	
	# Restore Snake App (the working app)
	if data.has("phone_apps") and data.phone_apps.has("snake"):
		var snake_app = get_node_or_null("SnakeApp")
		if snake_app and snake_app.has_method("load_save_data"):
			snake_app.load_save_data(data.phone_apps.snake)
		elif snake_app:
			# Fallback restoration
			var snake_data = data.phone_apps.snake
			if snake_data.has("high_score") and snake_app.has("high_score"):
				snake_app.high_score = snake_data.high_score
	
	# Restore Phone UI state
	if data.has("phone_ui"):
		var ui_data = data.phone_ui
		if ui_data.has("current_app"):
			current_app = ui_data.current_app
		if ui_data.has("notifications"):
			notifications = ui_data.notifications
		if ui_data.has("app_settings"):
			app_settings = ui_data.app_settings
	
	if debug: print(GameState.script_name_tag(self) + "PhoneScene: Phone apps restoration complete")
	return true


func get_save_data():
	return GameState.phone_apps
