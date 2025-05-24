extends Control

@onready var header_label: Label = $AppMarginContainer/MainVBox/HeaderHBox/HeaderLabel
@onready var back_to_grid_button: Button = $AppMarginContainer/MainVBox/HeaderHBox/BackToGridButton

@onready var thumbnails_grid_scroll: ScrollContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ThumbnailsGridScroll
@onready var thumbnails_grid: GridContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ThumbnailsGridScroll/ThumbnailsGrid
@onready var image_view_panel: VBoxContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ImageViewPanel
@onready var image_texture_rect: TextureRect = $AppMarginContainer/MainVBox/ContentSwitchControl/ImageViewPanel/ImageTextureRect
@onready var caption_label: Label = $AppMarginContainer/MainVBox/ContentSwitchControl/ImageViewPanel/CaptionLabel
@onready var metadata_label: Label = $AppMarginContainer/MainVBox/ContentSwitchControl/ImageViewPanel/MetadataLabel

# Placeholder for Godot icon path (default project icon)
const PLACEHOLDER_ICON_PATH = "res://icon.svg" # Or any other placeholder image

# Mock data for images
var images_data = [
    {
        "id": "img1",
        "thumbnail_path": PLACEHOLDER_ICON_PATH, # Path to thumbnail image
        "full_image_path": PLACEHOLDER_ICON_PATH, # Path to full image
        "caption": "A wild Godot appears!",
        "timestamp": "2024-03-15 10:00:00",
        "tags": ["godot", "engine", "icon"],
        "source": "Project Files"
    },
    {
        "id": "img2",
        "thumbnail_path": PLACEHOLDER_ICON_PATH,
        "full_image_path": PLACEHOLDER_ICON_PATH,
        "caption": "Another majestic Godot.",
        "timestamp": "2024-03-16 12:30:00",
        "tags": ["icon", "logo", "dev"],
        "source": "Generated"
    },
    {
        "id": "img3",
        "thumbnail_path": PLACEHOLDER_ICON_PATH,
        "full_image_path": PLACEHOLDER_ICON_PATH,
        "caption": "The icon, observed.",
        "timestamp": "2024-03-17 15:45:00",
        "tags": ["art", "placeholder"],
        "source": "Screenshot"
    }
]

var current_image_id = null

func _ready():
    back_to_grid_button.connect("pressed", Callable(self, "_on_back_to_grid_button_pressed"))
    populate_thumbnails_grid()
    show_thumbnails_grid()

func populate_thumbnails_grid():
    # Clear any existing thumbnails
    for child in thumbnails_grid.get_children():
        child.queue_free()

    for image_info in images_data:
        var thumbnail_button = TextureButton.new()
        thumbnail_button.texture_normal = load(image_info["thumbnail_path"])
        thumbnail_button.custom_minimum_size = Vector2(80, 80) # Adjust as needed
        thumbnail_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
        thumbnail_button.ignore_texture_size = false # Use custom_minimum_size
        thumbnail_button.connect("pressed", Callable(self, "_on_thumbnail_selected").bind(image_info["id"]))
        thumbnails_grid.add_child(thumbnail_button)

func _on_thumbnail_selected(image_id: String):
    current_image_id = image_id
    var image_info = null
    for img in images_data:
        if img["id"] == image_id:
            image_info = img
            break
    
    if image_info:
        load_image_view(image_info)
        show_image_view()
    else:
        printerr("Image data not found for id: " + image_id)

func load_image_view(image_info: Dictionary):
    image_texture_rect.texture = load(image_info["full_image_path"])
    caption_label.text = image_info["caption"]
    metadata_label.text = "%s | %s | %s" % [image_info["timestamp"], ", ".join(image_info["tags"]), image_info["source"]]
    header_label.text = image_info["caption"] if image_info["caption"].length() < 20 else image_info["caption"].substr(0, 17) + "..."


func show_thumbnails_grid():
    thumbnails_grid_scroll.visible = true
    image_view_panel.visible = false
    back_to_grid_button.visible = false
    header_label.text = "Camera Roll"

func show_image_view():
    thumbnails_grid_scroll.visible = false
    image_view_panel.visible = true
    back_to_grid_button.visible = true
    # HeaderLabel is updated in load_image_view

func _on_back_to_grid_button_pressed():
    show_thumbnails_grid()
