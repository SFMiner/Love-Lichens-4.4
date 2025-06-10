# CameraRollHelper.gd
# Helper script for integrating the Camera Roll App with other systems
extends Node

const scr_debug := true
var debug := false

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug

# Add an image to the camera roll
func add_image(image_id: String, image_path: String, caption: String, tags: String = "", source: String = "Player") -> bool:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("add_image_from_script"):
		return camera_app.add_image_from_script(image_id, image_path, image_path, caption, tags, source)
	else:
		if debug: print("CameraRollHelper: Could not find Camera Roll App to add image")
		return false

# Add an image with separate thumbnail and full image paths
func add_image_with_thumbnail(image_id: String, thumbnail_path: String, full_image_path: String, caption: String, tags: String = "", source: String = "Player") -> bool:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("add_image"):
		var image_data = {
			"thumbnail_path": thumbnail_path,
			"full_image_path": full_image_path,
			"caption": caption,
			"tags": tags,
			"source": source
		}
		return camera_app.add_image(image_id, image_data)
	else:
		if debug: print("CameraRollHelper: Could not find Camera Roll App to add image")
		return false

# Remove an image from the camera roll
func remove_image(image_id: String) -> bool:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("remove_image"):
		return camera_app.remove_image(image_id)
	else:
		if debug: print("CameraRollHelper: Could not find Camera Roll App to remove image")
		return false

# Check if an image exists
func has_image(image_id: String) -> bool:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("has_image"):
		return camera_app.has_image(image_id)
	return false

# Get image data
func get_image_data(image_id: String) -> Dictionary:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("get_image_data"):
		return camera_app.get_image_data(image_id)
	return {}

# Get images by tag
func get_images_by_tag(tag: String) -> Array:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("get_images_by_tag"):
		return camera_app.get_images_by_tag(tag)
	return []

# Get images by source
func get_images_by_source(source: String) -> Array:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("get_images_by_source"):
		return camera_app.get_images_by_source(source)
	return []

# Get total image count
func get_image_count() -> int:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("get_image_count"):
		return camera_app.get_image_count()
	return 0

# Get all images
func get_all_images() -> Dictionary:
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("get_all_images"):
		return camera_app.get_all_images()
	return {}

# Quest system integration functions
func add_quest_image(quest_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image related to a quest completion or discovery"""
	var image_id = "quest_" + quest_id + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #quest, #" + quest_id, "Quest System")

# Dialogue system integration functions
func add_dialogue_shared_image(character_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image shared by a character through dialogue"""
	var image_id = "shared_" + character_id + "_" + str(Time.get_unix_time_from_system())
	var character_name = _get_character_display_name(character_id)
	return add_image(image_id, image_path, caption, tags + ", #shared, #" + character_id, character_name)

# Location/discovery system integration
func add_discovery_image(location_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image discovered at a specific location"""
	var image_id = "discovery_" + location_id + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #discovery, #" + location_id, "Discovery")

# Player photography functions
func add_player_photo(image_path: String, caption: String, location: String = "", tags: String = "") -> bool:
	"""Add a photo taken by the player"""
	var image_id = "player_photo_" + str(Time.get_unix_time_from_system())
	var full_tags = "#player_photo"
	if location != "":
		full_tags += ", #" + location
	if tags != "":
		full_tags += ", " + tags
	
	return add_image(image_id, image_path, caption, full_tags, "Adam")

# Research/science integration
func add_research_image(research_type: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image related to research or scientific discovery"""
	var image_id = "research_" + research_type + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #research, #science, #" + research_type, "Research")

# Social media integration (for future social feed app)
func add_social_image(image_path: String, caption: String, poster: String, tags: String = "") -> bool:
	"""Add an image from social media"""
	var image_id = "social_" + poster + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #social, #" + poster.to_lower(), poster)

# Event/memory system integration
func add_memory_image(memory_tag: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image associated with a specific memory or event"""
	var image_id = "memory_" + memory_tag + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #memory, #" + memory_tag, "Memory")

# Relationship system integration
func add_friendship_image(character_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image showing friendship/relationship moment"""
	var image_id = "friendship_" + character_id + "_" + str(Time.get_unix_time_from_system())
	var character_name = _get_character_display_name(character_id)
	return add_image(image_id, image_path, caption, tags + ", #friendship, #" + character_id, character_name)

# Achievement/milestone system integration
func add_achievement_image(achievement_id: String, image_path: String, caption: String, tags: String = "") -> bool:
	"""Add an image commemorating an achievement"""
	var image_id = "achievement_" + achievement_id + "_" + str(Time.get_unix_time_from_system())
	return add_image(image_id, image_path, caption, tags + ", #achievement, #" + achievement_id, "Achievement")

# Email/Messages app integration
func share_image_to_email(image_id: String, recipient: String, subject: String, message: String) -> bool:
	"""Share an image via email (when email app supports attachments)"""
	var image_data = get_image_data(image_id)
	if image_data.is_empty():
		if debug: print("CameraRollHelper: Image not found for sharing: ", image_id)
		return false
	
	# TODO: Integrate with EmailApp when it supports image attachments
	if debug: print("CameraRollHelper: Would share image ", image_id, " to ", recipient, " via email")
	return true

func share_image_to_messages(image_id: String, recipient: String) -> bool:
	"""Share an image via text message (when messages app supports attachments)"""
	var image_data = get_image_data(image_id)
	if image_data.is_empty():
		if debug: print("CameraRollHelper: Image not found for sharing: ", image_id)
		return false
	
	# TODO: Integrate with MessagesApp when it supports image attachments
	if debug: print("CameraRollHelper: Would share image ", image_id, " to ", recipient, " via messages")
	return true

# Get the Camera Roll App instance
func _get_camera_roll_app():
	# Try various paths to find the Camera Roll App
	var paths = [
		"/root/Game/PhoneCanvasLayer/PhoneSceneInstance/CameraRollApp",
		"/root/PhoneScene/CameraRollApp",
		"/root/Game/PhoneScene/CameraRollApp"
	]
	
	for path in paths:
		var app = get_node_or_null(path)
		if app:
			return app
	
	# Search the scene tree for CameraRollApp
	var found_apps = get_tree().get_nodes_in_group("camera_roll_app")
	if found_apps.size() > 0:
		return found_apps[0]
	
	# Last resort: find by class name
	var all_nodes = get_tree().get_nodes_in_group("phone_apps")
	for node in all_nodes:
		if node.get_script() and "CameraRollApp" in str(node.get_script().get_path()):
			return node
	
	return null

# Convert character ID to display name
func _get_character_display_name(character_id: String) -> String:
	var name_mapping = {
		"poison": "Poison",
		"erik": "Erik",
		"professor_moss": "Prof. Moss",
		"kitty": "Kitty",
		"dusty": "Dusty",
		"li": "Li"
	}
	
	return name_mapping.get(character_id, character_id.capitalize())

# Batch operations
func add_multiple_images(images_data: Array) -> int:
	"""Add multiple images at once. Returns number of successfully added images."""
	var success_count = 0
	for image_info in images_data:
		if typeof(image_info) == TYPE_DICTIONARY:
			var id = image_info.get("id", "")
			var path = image_info.get("path", "")
			var caption = image_info.get("caption", "")
			var tags = image_info.get("tags", "")
			var source = image_info.get("source", "Player")
			
			if id != "" and path != "":
				if add_image(id, path, caption, tags, source):
					success_count += 1
	
	if debug: print("CameraRollHelper: Added ", success_count, " out of ", images_data.size(), " images")
	return success_count

# Search and filter functions
func search_images_by_caption(search_term: String) -> Array:
	"""Search images by caption text"""
	var matching_images = []
	var all_images = get_all_images()
	
	for image_id in all_images.keys():
		var image_data = all_images[image_id]
		var caption = image_data.get("caption", "").to_lower()
		if caption.contains(search_term.to_lower()):
			matching_images.append(image_data)
	
	return matching_images

# Statistics and analytics
func get_images_statistics() -> Dictionary:
	"""Get statistics about the camera roll"""
	var all_images = get_all_images()
	var stats = {
		"total_images": all_images.size(),
		"sources": {},
		"tags": {},
		"recent_images": 0  # Images from last 7 days
	}
	
	var current_time = Time.get_unix_time_from_system()
	var week_ago = current_time - (7 * 24 * 60 * 60)  # 7 days in seconds
	
	for image_id in all_images.keys():
		var image_data = all_images[image_id]
		
		# Count by source
		var source = image_data.get("source", "Unknown")
		stats.sources[source] = stats.sources.get(source, 0) + 1
		
		# Count tags
		var tags = image_data.get("tags", "")
		var tag_list = tags.split(",")
		for tag in tag_list:
			var clean_tag = tag.strip_edges()
			if clean_tag != "":
				stats.tags[clean_tag] = stats.tags.get(clean_tag, 0) + 1
	
	return stats

# Clear functions for new game
func clear_all_images():
	"""Clear all images (for new game or reset)"""
	var camera_app = _get_camera_roll_app()
	if camera_app and camera_app.has_method("clear_all_images"):
		camera_app.clear_all_images()
		if debug: print("CameraRollHelper: Cleared all images")

# Initialize with starter content
func initialize_starter_images():
	"""Add some starter images for a new game"""
	var starter_images = [
		{
			"id": "starter_campus",
			"path": "res://icon.svg",  # Replace with actual campus image path
			"caption": "First day at Millennial College!",
			"tags": "#campus, #first_day, #college",
			"source": "Adam"
		},
		{
			"id": "starter_dorm",
			"path": "res://icon.svg",  # Replace with actual dorm image path
			"caption": "My new dorm room",
			"tags": "#dorm, #room, #home",
			"source": "Adam"
		}
	]
	
	var added_count = add_multiple_images(starter_images)
	if debug: print("CameraRollHelper: Added ", added_count, " starter images")
