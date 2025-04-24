extends Node

# IconSystem singleton handles loading and caching item textures

const scr_debug : bool = false
var debug
# Cache for loaded textures to avoid loading the same texture multiple times
var texture_cache = {}

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print("IconSystem initialized")

# Get a cached texture or load it if not already cached
func get_cached_texture(item_id):
	# Return cached texture if available
	if texture_cache.has(item_id):
		return texture_cache[item_id]
	
	# Try to load texture
	var texture = null
	if Engine.has_singleton("InventorySystem"):
		var inventory_system = Engine.get_singleton("InventorySystem")
		
		# Get item template
		if inventory_system.has_method("get_item_template"):
			var template = inventory_system.get_item_template(item_id)
			if template and template.has("image_path") and template.image_path.length() > 0:
				var texture_path = template.image_path
				
				if debug: print("Loading texture from: " + texture_path + " for item: " + item_id)
				
				if ResourceLoader.exists(texture_path):
					texture = load(texture_path)
					if debug: print("Successfully loaded texture for: " + item_id)
				else:
					if debug: print("Texture path does not exist: " + texture_path)
	
	# Cache the result (even if null)
	texture_cache[item_id] = texture
	return texture

# Load a texture for an item
func load_texture_for_item(item_id):
	if Engine.has_singleton("InventorySystem"):
		var inventory_system = Engine.get_singleton("InventorySystem")
		
		# Check if the inventory system has an item template with an image path
		if inventory_system.has_method("get_item_template"):
			var template = inventory_system.get_item_template(item_id)
			if template and template.has("image_path") and template.image_path.length() > 0:
				# Try to load the texture from the specified path
				var texture_path = template.image_path
				
				if debug: print("Attempting to load texture from: ", texture_path)
				
				if ResourceLoader.exists(texture_path):
					var texture = load(texture_path)
					if texture:
						if debug: print("Successfully loaded texture for ", item_id)
						return texture
					else:
						if debug: print("Failed to load texture from path: ", texture_path)
				else:
					if debug: print("Texture path does not exist: ", texture_path)
	
	if debug: print("No texture found for item: ", item_id)
	return null

# Clear the texture cache
func clear_cache():
	texture_cache.clear()
	if debug: print("Texture cache cleared")
