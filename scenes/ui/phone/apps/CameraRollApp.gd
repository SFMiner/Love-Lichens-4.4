extends Control

@onready var thumbnails_grid: GridContainer = $ThumbnailsGrid
@onready var image_view_panel: Panel = $ImageViewPanel
@onready var full_image_view: TextureRect = $ImageViewPanel/FullImageView
@onready var caption_label: Label = $ImageViewPanel/CaptionLabel
@onready var timestamp_label: Label = $ImageViewPanel/MetadataPanel/TimestampLabel
@onready var tags_label: Label = $ImageViewPanel/MetadataPanel/TagsLabel
@onready var source_label: Label = $ImageViewPanel/MetadataPanel/SourceLabel
@onready var image_back_button: Button = $ImageViewPanel/ImageBackButton

# Placeholder for image data. In a real app, this would come from a data source.
var test_image_data = [
	{
		"thumbnail_path": "res://icon.svg", # Placeholder
		"full_image_path": "res://icon.svg",  # Placeholder
		"caption": "Mysterious Lichen (Test Data)",
		"timestamp": "2024-03-15",
		"tags": "#lichen, #forest, #discovery",
		"source": "Player"
	},
	{
		"thumbnail_path": "res://icon.svg", # Placeholder
		"full_image_path": "res://icon.svg",  # Placeholder
		"caption": "Ancient Oak Tree (Test Data)",
		"timestamp": "2024-03-14",
		"tags": "#tree, #nature, #old",
		"source": "Friend"
	},
	{
		"thumbnail_path": "res://icon.svg", # Placeholder
		"full_image_path": "res://icon.svg",  # Placeholder
		"caption": "Flowing Creek (Test Data)",
		"timestamp": "2024-03-16",
		"tags": "#water, #creek, #serene",
		"source": "System"
	}
]

func _ready():
	image_view_panel.hide()
	thumbnails_grid.show()
	
	# Example call to load images based on tags.
	# In a real scenario, these tags might come from game state or player progression.
	load_images_by_tags(["player_photos", "event_forest_encounter"])
	
	image_back_button.pressed.connect(_on_image_back_button_pressed)

func _populate_thumbnail_grid(image_data_array: Array):
	"""
	Internal function to clear and populate the thumbnail grid from an array of image data.
	"""
	# Clear existing thumbnails
	for child in thumbnails_grid.get_children():
		child.queue_free()
		
	for image_data in image_data_array:
		var thumb_button = TextureButton.new()
		var thumb_texture = load(image_data.get("thumbnail_path", "res://icon.svg")) # Default to icon.svg if path missing
		thumb_button.texture_normal = thumb_texture
		thumb_button.ignore_texture_size = false
		thumb_button.custom_minimum_size = Vector2(100, 100)
		thumb_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		thumb_button.pressed.connect(Callable(self, "_on_thumbnail_pressed").bind(image_data))
		thumbnails_grid.add_child(thumb_button)

func load_images_by_tags(tags: Array):
	"""
	Loads and displays images based on a set of tags.
	
	TODO: This function will be updated to:
	1. Query a central ContentProvider/DataManager singleton using the provided 'tags'.
	2. The ContentProvider would return an array of image metadata objects 
	   (similar in structure to 'test_image_data').
	3. This app would then call '_populate_thumbnail_grid' with the fetched data.
	
	For now, it uses the placeholder 'test_image_data'.
	The 'tags' parameter is currently logged but not used for filtering test data.
	"""
	print("CameraRollApp: Attempting to load images with tags: ", tags)
	
	# --- Placeholder Content ---
	# In the future, 'test_image_data' will be replaced by data fetched via ContentProvider
	_populate_thumbnail_grid(test_image_data) 
	# --- End Placeholder Content ---

func set_image_data(image_data_array: Array):
	"""
	(Conceptual) This function would be called by a ContentProvider or DataManager
	after it has asynchronously fetched image data.
	
	It would then process this data by populating the thumbnail grid.
	For now, it just prints the received data and calls the population logic.
	"""
	print("CameraRollApp: Received image data: ", image_data_array)
	_populate_thumbnail_grid(image_data_array)


func _on_thumbnail_pressed(image_data: Dictionary):
	thumbnails_grid.hide()
	image_view_panel.show()
	
	full_image_view.texture = load(image_data.get("full_image_path", "res://icon.svg")) # Default to icon.svg
	caption_label.text = image_data.get("caption", "No caption")
	timestamp_label.text = "Date: " + image_data.get("timestamp", "Unknown")
	tags_label.text = "Tags: " + image_data.get("tags", "None")
	source_label.text = "Source: " + image_data.get("source", "Unknown")

func _on_image_back_button_pressed():
	image_view_panel.hide()
	thumbnails_grid.show()
	
	# Optional: Clear the large image to free memory if needed
	full_image_view.texture = null
