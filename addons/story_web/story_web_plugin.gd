# story_web_plugin.gd
@tool
extends EditorPlugin

var editor_scene
var dock_button

func _enter_tree():
	# Check if StoryWeb is already registered in project settings
	var auto_loads = ProjectSettings.get_setting("autoload")
	var already_registered = false
	
	if auto_loads:
		for key in auto_loads:
			if key == "StoryWeb":
				already_registered = true
				break
	
	# Only register if not already in project settings
	if not already_registered:
		add_autoload_singleton("StoryWeb", "res://addons/story_web/story_web_system.gd")
	
	# Need to wait a bit for the autoload to be fully initialized
	await get_tree().process_frame
	await get_tree().process_frame  # Add an extra frame wait for safety
	
	# Instance the editor scene
	editor_scene = preload("res://addons/story_web/story_web_editor.tscn").instantiate()
	
	# Important: First add to dock and THEN connect signals and make it visible
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, editor_scene)
	
	# Wait for the scene to be properly added to the tree
	await get_tree().process_frame
	
	# Let Godot handle initialization and signal connections automatically
	# The scene will initialize itself when added to the tree
	
	print("Story Web Plugin initialized")

func _exit_tree():
	# Remove StoryWeb system from autoload
	remove_autoload_singleton("StoryWeb")
	
	# Remove Story Web editor from the dock
	if editor_scene:
		remove_control_from_docks(editor_scene)
		editor_scene.queue_free()
	
	print("Story Web Plugin shut down")

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Story Web"

func _get_plugin_icon():
	# Use a default icon if custom one doesn't exist
	if ResourceLoader.exists("res://addons/story_web/icons/plugin_icon.png"):
		return preload("res://addons/story_web/icons/plugin_icon.png")
	else:
		return null
