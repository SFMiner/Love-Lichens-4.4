class_name CustomDialogueTestScene2 extends Node2D

const DialogueSettings = preload("./settings.gd")
const DialogueResource = preload("./dialogue_resource.gd")

@onready var title: String = DialogueSettings.get_user_value("run_title")
@onready var resource: DialogueResource = load(DialogueSettings.get_user_value("run_resource_path"))

func _ready():
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	if dialogue_manager:
		print("Found DialogueManager singleton")
	else:
		print("Failed to find DialogueManager singleton!")
		
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	print("About to show dialogue balloon")
	dialogue_manager.show_dialogue_balloon(resource, title if not title.is_empty() else resource.first_title)
	print("Dialogue balloon called")
	
	if not Engine.is_embedded_in_editor:
		var window: Window = get_viewport()
		var screen_index: int = DisplayServer.get_primary_screen()
		window.position = Vector2(DisplayServer.screen_get_position(screen_index)) + (DisplayServer.screen_get_size(screen_index) - window.size) * 0.5
		window.mode = Window.MODE_WINDOWED

	# Get the DialogueManager singleton and show the dialogue

func _enter_tree() -> void:
	DialogueSettings.set_user_value("is_running_test_scene", false)

func _on_dialogue_ended(_resource: DialogueResource):
	get_tree().quit()
