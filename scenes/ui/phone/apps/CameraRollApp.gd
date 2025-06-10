extends Control

const THUMB_SIZE: int = 80

@onready var thumbnails_grid: FlowContainer = $MarginContainer/ThumbnailsGrid
@onready var image_view_panel: Panel = %ImageViewPanel
@onready var full_image_view: TextureRect = %FullImageView
@onready var caption_label: Label = %CaptionLabel
@onready var timestamp_label: Label = %MetadataPanel/TimestampLabel
@onready var tags_label: Label = %MetadataPanel/TagsLabel
@onready var source_label: Label = %MetadataPanel/SourceLabel
@onready var image_back_button: Button = %ImageBackButton

# State management
var all_images: Dictionary = {}
var filtered_images: Array = []

const scr_debug := true
var debug := false

func _ready():
	debug = scr_debug or GameController.sys_debug
	print("Camera App Loaded")
	# Initialize camera roll data structure in GameState if it doesn't exist
	if not GameState.phone_apps.has("camera_roll_app_entries"):
		GameState.phone_apps["camera_roll_app_entries"] = {}
	
	# Load images from GameState
	load_images_from_gamestate()
	
	# Setup UI
	image_view_panel.hide()
	thumbnails_grid.show()
	
	# Connect signals
	image_back_button.pressed.connect(Callable(self, "_on_image_back_button_pressed"))
	
	# Load all images by default
	load_images_by_tags([])
	
	if debug: print("CameraRollApp: Ready with ", all_images.size(), " images")

func load_images_from_gamestate():
	const _fname : String = "load_images_from_gamestate"
	"""Load all images from GameState storage"""
	if debug: print(GameState.script_name_tag(self, _fname) + "camera_roll_app_entries = ", str(GameState.phone_apps["camera_roll_app_entries"]))

	all_images = GameState.phone_apps["camera_roll_app_entries"]

	if debug: print(GameState.script_name_tag(self, _fname) + "CameraRollApp: Loaded ", all_images.size(), " images from GameState")

func save_images_to_gamestate():
	"""Save all images to GameState storage"""
	GameState.phone_apps["camera_roll_app_entries"] = all_images
	if debug: print("CameraRollApp: Saved ", all_images.size(), " images to GameState")

func add_image(image_id: String, image_data: Dictionary) -> bool:
	"""
	Add a new image to the camera roll.
	
	image_data should contain:
	- thumbnail_path: String
	- full_image_path: String
	- caption: String
	- timestamp: String (optional, will use current time if not provided)
	- tags: String (comma-separated tags)
	- source: String (who took/added the photo)
	"""
	if image_id in all_images:
		if debug: print("CameraRollApp: Image with ID ", image_id, " already exists")
		return false
	
	# Ensure required fields exist
	var processed_data = {
		"image_id": image_id,
		"thumbnail_path": image_data.get("thumbnail_path", "res://icon.svg"),
		"full_image_path": image_data.get("full_image_path", "res://icon.svg"),
		"caption": image_data.get("caption", "No caption"),
		"timestamp": image_data.get("timestamp", TimeSystem.format_game_time("Mmmm dd, yyyy") if TimeSystem else "Unknown Date"),
		"tags": image_data.get("tags", ""),
		"source": image_data.get("source", "Unknown")
	}
	
	all_images[image_id] = processed_data
	save_images_to_gamestate()
	
	# Refresh display if we're showing all images or if this image matches current filter
	refresh_current_view()
	
	if debug: print("CameraRollApp: Added image: ", image_id, " - ", processed_data.caption)
	return true

func remove_image(image_id: String) -> bool:
	"""Remove an image from the camera roll"""
	if not image_id in all_images:
		if debug: print("CameraRollApp: Image with ID ", image_id, " not found")
		return false
	
	all_images.erase(image_id)
	save_images_to_gamestate()
	refresh_current_view()
	
	if debug: print("CameraRollApp: Removed image: ", image_id)
	return true

func get_image_data(image_id: String) -> Dictionary:
	"""Get image data by ID"""
	return all_images.get(image_id, {})

func has_image(image_id: String) -> bool:
	"""Check if an image exists in the camera roll"""
	return image_id in all_images

func get_all_images() -> Dictionary:
	"""Get all images in the camera roll"""
	return all_images.duplicate(true)

func load_images_by_tags(tags: Array):
	"""
	Loads and displays images based on a set of tags.
	If tags array is empty, shows all images.
	"""
	if debug: print("CameraRollApp: Loading images with tags: ", tags)
	
	filtered_images.clear()
	
	if tags.size() == 0:
		# Show all images
		for image_id in all_images.keys():
			filtered_images.append(all_images[image_id])
	else:
		# Filter by tags
		for image_id in all_images.keys():
			var image_data = all_images[image_id]
			var image_tags = image_data.get("tags", "").to_lower()
			
			var matches = false
			for tag in tags:
				if image_tags.contains(tag.to_lower()):
					matches = true
					break
			
			if matches:
				filtered_images.append(image_data)
	
	_populate_thumbnail_grid(filtered_images)
	if debug: print("CameraRollApp: Displaying ", filtered_images.size(), " images")

func refresh_current_view():
	"""Refresh the current view with updated data"""
	load_images_from_gamestate()
	# Re-apply current filter (this is a simplified approach)
	load_images_by_tags([])

func _populate_thumbnail_grid(image_data_array: Array):
	"""Internal function to clear and populate the thumbnail grid from an array of image data."""
	# Clear existing thumbnails
	for child in thumbnails_grid.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	for image_data in image_data_array:
		var thumb_button = TextureButton.new()
		var thumb_path = image_data.get("thumbnail_path", "res://icon.svg")
		
		# Load texture safely
		var thumb_texture = null
		if ResourceLoader.exists(thumb_path):
			thumb_texture = load(thumb_path)
		else:
			thumb_texture = load("res://icon.svg")  # Fallback
			if debug: print("CameraRollApp: Could not load thumbnail: ", thumb_path)
		
		thumb_button.texture_normal = thumb_texture
		thumb_button.ignore_texture_size = true
		thumb_button.custom_minimum_size = Vector2(THUMB_SIZE, THUMB_SIZE)
		thumb_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		thumb_button.pressed.connect(Callable(self, "_on_thumbnail_pressed").bind(image_data))
		thumbnails_grid.add_child(thumb_button)

func _on_thumbnail_pressed(image_data: Dictionary):
	thumbnails_grid.hide()
	image_view_panel.show()
	
	var full_image_path = image_data.get("full_image_path", "res://icon.svg")
	
	# Load full image safely
	var full_texture = null
	if ResourceLoader.exists(full_image_path):
		full_texture = load(full_image_path)
	else:
		full_texture = load("res://icon.svg")  # Fallback
		if debug: print("CameraRollApp: Could not load full image: ", full_image_path)
	
	full_image_view.texture = full_texture
	caption_label.text = image_data.get("caption", "No caption")
	timestamp_label.text = "Date: " + image_data.get("timestamp", "Unknown")
	tags_label.text = "Tags: " + image_data.get("tags", "None")
	source_label.text = "Source: " + image_data.get("source", "Unknown")

func _on_image_back_button_pressed():
	image_view_panel.hide()
	thumbnails_grid.show()
	
	# Optional: Clear the large image to free memory if needed
	full_image_view.texture = null

# Function to be called by other scripts to add images
func add_image_from_script(image_id: String, thumbnail_path: String, full_image_path: String, caption: String, tags: String = "", source: String = "Player") -> bool:
	"""
	Simplified function for other scripts to add images.
	Returns true if successful, false if image already exists.
	"""
	var image_data = {
		"thumbnail_path": thumbnail_path,
		"full_image_path": full_image_path,
		"caption": caption,
		"tags": tags,
		"source": source
	}
	
	return add_image(image_id, image_data)

# Functions for quest/dialogue system integration
func add_quest_image(quest_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image related to a quest"""
	var image_id = "quest_" + quest_id + "_" + str(Time.get_unix_time_from_system())
	return add_image_from_script(image_id, image_path, image_path, caption, tags, "Quest System")

func add_dialogue_image(character_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image shared through dialogue"""
	var image_id = "dialogue_" + character_id + "_" + str(Time.get_unix_time_from_system())
	return add_image_from_script(image_id, image_path, image_path, caption, tags, character_id.capitalize())

func add_discovery_image(location: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image discovered at a location"""
	var image_id = "discovery_" + location + "_" + str(Time.get_unix_time_from_system())
	return add_image_from_script(image_id, image_path, image_path, caption, tags, "Discovery")

# Save/load functionality for phone app data
func get_save_data() -> Dictionary:
	"""Get save data for the camera roll"""
	return {
		"images": all_images.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	"""Load save data for the camera roll"""
	if data.has("images"):
		all_images = data["images"]
		GameState.phone_apps["camera_roll_app_entries"] = all_images
		refresh_current_view()
		if debug: print("CameraRollApp: Loaded save data with ", all_images.size(), " images")

# Utility functions
func get_images_by_tag(tag: String) -> Array:
	"""Get all images that contain a specific tag"""
	var matching_images = []
	for image_id in all_images.keys():
		var image_data = all_images[image_id]
		var image_tags = image_data.get("tags", "").to_lower()
		if image_tags.contains(tag.to_lower()):
			matching_images.append(image_data)
	return matching_images

func get_images_by_source(source: String) -> Array:
	"""Get all images from a specific source"""
	var matching_images = []
	for image_id in all_images.keys():
		var image_data = all_images[image_id]
		if image_data.get("source", "").to_lower() == source.to_lower():
			matching_images.append(image_data)
	return matching_images

func get_image_count() -> int:
	"""Get total number of images in camera roll"""
	return all_images.size()

func clear_all_images():
	"""Clear all images (for new game or reset)"""
	all_images.clear()
	save_images_to_gamestate()
	refresh_current_view()
	if debug: print("CameraRollApp: Cleared all images")
