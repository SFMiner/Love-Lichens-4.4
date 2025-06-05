# inventory_system.gd
extends Node

# Inventory System for Love & Lichens
# Manages player's items, including books, quest items, consumables, and equipment

signal item_added(item_id, item_data)
signal item_removed(item_id, amount)
signal item_used(item_id)

# Player's inventory - dictionary of items
const scr_debug : bool = false
var debug

# Item templates storage
# Key: item_id, Value: item data including amount
var inventory = {}

# Item templates - loaded from JSON
var item_templates = {}
var item_templates_loaded = false

# Tag-based organization
# key: tag_name, value: array of item_ids with that tag
var item_tags = {}

# Item categories
enum ItemCategory {
	BOOK,
	QUEST_ITEM,
	CONSUMABLE,
	EQUIPMENT
}

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print(GameState.script_name_tag(self) + "Inventory System initialized")
	# Load item templates from JSON
	_load_item_templates()
	
	# Debug: Check if any items are in inventory at startup
	if debug: print(GameState.script_name_tag(self) + "Initial inventory count: ", inventory.size())

	# Register with DialogueManager
	if Engine.has_singleton("DialogueManager"):
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		dialogue_manager.register_variable("InventorySystem", self)

# Load item templates from JSON file
func _load_item_templates():
	if item_templates_loaded:
		if debug: print(GameState.script_name_tag(self) + "Templates already loaded, skipping.")
		return
		
	var file_path = "res://data/items/item_templates.json"
	if debug: print(GameState.script_name_tag(self) + "Attempting to load item templates from: ", file_path)
	
	if not FileAccess.file_exists(file_path):
		if debug: print(GameState.script_name_tag(self) + "ERROR: Item templates file not found at path: ", file_path)
		# Try alternate paths
		var alternate_paths = [
			"res://item_templates.json",
			"user://item_templates.json",
			"res://data/item_templates.json"
		]
		
		for alt_path in alternate_paths:
			if debug: print(GameState.script_name_tag(self) + "Trying alternate path: ", alt_path)
			if FileAccess.file_exists(alt_path):
				file_path = alt_path
				print(GameState.script_name_tag(self) + "Found item templates at: ", file_path)
				break
		
		if not FileAccess.file_exists(file_path):
			if debug: print(GameState.script_name_tag(self) + "ERROR: Could not find item templates file in any location")
			return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Could not open item templates file")
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Failed to parse item templates JSON: ", json.get_error_message())
		return
		
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self) + "ERROR: Item templates JSON is not a dictionary")
		return
		
	item_templates = data
	item_templates_loaded = true
	if debug: print(GameState.script_name_tag(self) + "Loaded ", item_templates.size(), " item templates")
	
	# Print template info for debugging
	if debug: print(GameState.script_name_tag(self) + "Available templates: ", item_templates.keys())
	for item_id in item_templates:
		var template = item_templates[item_id]
		if template.has("image_path"):
			if debug: print(GameState.script_name_tag(self) + "Item: ", item_id, " has image path: ", template.image_path)
			# Check if the image exists
			if ResourceLoader.exists(template.image_path):
				if debug: print(GameState.script_name_tag(self) + "  Image exists at path")
			else:
				if debug: print(GameState.script_name_tag(self) + "  WARNING: Image does not exist at path: ", template.image_path)
		else:
			if debug: print(GameState.script_name_tag(self) + "Item: ", item_id, " has no image path")
			
		# Debug print for tags
		if template.has("tags"):
			if debug: print(GameState.script_name_tag(self) + "Item: ", item_id, " has tags: ", template.tags)

func add_item(item_id, amount = 1, custom_data = null):
	if debug: print(GameState.script_name_tag(self) + "Attempting to add item: ", item_id)
	if not item_id:
		return false
		
	# Create the item entry if it doesn't exist
	if not inventory.has(item_id):
		# Get item data from templates
		var item_data = get_item_data(item_id)
		if not item_data:
			if debug: print(GameState.script_name_tag(self) + "Error: Item data not found for ", item_id)
			return false
			
		item_data["amount"] = amount
		
		# If custom data is provided, merge it with the template
		if custom_data:
			for key in custom_data:
				item_data[key] = custom_data[key]
		
		inventory[item_id] = item_data
		
		# Register tags for this item
		_register_item_tags(item_id, item_data)
	else:
		# Increase amount for existing item
		inventory[item_id]["amount"] += amount
	
	if debug: print(GameState.script_name_tag(self) + "Added ", amount, "x ", item_id, " to inventory")
	item_added.emit(item_id, inventory[item_id])
	return true
	
func remove_item(item_id, amount = 1):
	if not inventory.has(item_id) or inventory[item_id]["amount"] < amount:
		return false
		
	inventory[item_id]["amount"] -= amount
	
	# Remove the entry if amount reaches 0
	if inventory[item_id]["amount"] <= 0:
		var item_data = inventory[item_id]
		
		# Unregister tags before removing the item
		_unregister_item_tags(item_id, item_data)
		
		inventory.erase(item_id)
		item_removed.emit(item_id, amount)
		if debug: print(GameState.script_name_tag(self) + "Removed ", item_id, " from inventory (amount reached 0)")
	else:
		item_removed.emit(item_id, amount)
		if debug: print(GameState.script_name_tag(self) + "Removed ", amount, "x ", item_id, " from inventory")
		
	return true
	
func use_item(item_id):
	if not inventory.has(item_id):
		return false
		
	var item = inventory[item_id]
	
	# Process item use based on its category
	match item["category"]:
		ItemCategory.CONSUMABLE:
			if debug: print(GameState.script_name_tag(self) + "Used consumable: ", item_id)
			# The effects will be applied via the ItemEffectsSystem
			# which connects to our item_used signal
			remove_item(item_id)
			
		ItemCategory.BOOK:
			if debug: print(GameState.script_name_tag(self) + "Reading book: ", item_id)
			# Books might give knowledge effects without being consumed
			
		ItemCategory.EQUIPMENT:
			if debug: print(GameState.script_name_tag(self) + "Equipping item: ", item_id)
			# Equipment would be handled differently - might need an equip function
			# Rather than being consumed, equipment applies effects while equipped
			
		ItemCategory.QUEST_ITEM:
			if debug: print(GameState.script_name_tag(self) + "Using quest item: ", item_id)
			# Quest items might trigger quest advancement without being consumed
			
		_:
			if debug: print(GameState.script_name_tag(self) + "Item cannot be used directly: ", item_id)
			return false
			
	item_used.emit(item_id)
	return true
	
func has_item(item_id, amount = 1):
	return inventory.has(item_id) and inventory[item_id]["amount"] >= amount
	
func get_item_count(item_id):
	if not inventory.has(item_id):
		return 0
	return inventory[item_id]["amount"]
	
func get_all_items():
	return inventory
	
func get_items_by_category(category):
	var filtered_items = {}
	for item_id in inventory:
		if inventory[item_id]["category"] == category:
			filtered_items[item_id] = inventory[item_id]
	return filtered_items

# Get items by tag
func get_items_by_tag(tag_name):
	var matching_items = {}
	
	for item_id in inventory:
		var item = inventory[item_id]
		if item.has("tags") and tag_name in item.tags:
			matching_items[item_id] = item
			
	return matching_items
	
# Also add a count function to count items by tag
func count_items_by_tag(tag_name):
	var count = 0
	var items = get_items_by_tag(tag_name)
	
	for item_id in items:
		count += items[item_id].amount
		
	return count

# Check if player has a specific amount of items with a given tag
func has_items_with_tag(tag, amount = 1):
	return count_items_by_tag(tag) >= amount

# Register tags for a given item
func _register_item_tags(item_id, item_data):
	if not item_data.has("tags"):
		return
		
	for tag in item_data.tags:
		# Initialize tag entry if it doesn't exist
		if not item_tags.has(tag):
			item_tags[tag] = []
			
		# Add item to this tag if not already present
		if not item_id in item_tags[tag]:
			item_tags[tag].append(item_id)
			if debug: print(GameState.script_name_tag(self) + "Registered item ", item_id, " with tag: ", tag)

# Unregister tags when an item is removed
func _unregister_item_tags(item_id, item_data):
	if not item_data.has("tags"):
		return
		
	for tag in item_data.tags:
		if item_tags.has(tag) and item_id in item_tags[tag]:
			item_tags[tag].erase(item_id)
			if debug: print(GameState.script_name_tag(self) + "Unregistered item ", item_id, " from tag: ", tag)
			
			# Remove the tag entry if it's empty
			if item_tags[tag].size() == 0:
				item_tags.erase(tag)
				if debug: print(GameState.script_name_tag(self) + "Removed empty tag: ", tag)

# Get item data for an item, either from inventory or templates
func get_item_data(item_id):
	# Try to get from inventory first
	if inventory.has(item_id):
		return inventory[item_id]
	
	# If not in inventory, try to get template data
	return _load_item_template(item_id)

# Get item template data from the loaded templates
func _load_item_template(item_id):
	if not item_templates_loaded:
		if debug: print(GameState.script_name_tag(self) + "Loading item templates for: " + item_id)
		_load_item_templates()
	
	if item_templates.has(item_id):
		if debug: print(GameState.script_name_tag(self) + "Found template for: " + item_id)
		return item_templates[item_id]
	else:
		if debug: print(GameState.script_name_tag(self) + "WARNING: No template found for item: " + item_id)
		return null

# Public method that calls the private method
func get_item_template(item_id):
	if debug: print(GameState.script_name_tag(self) + "get_item_template called for: ", item_id)
	
	if not item_templates_loaded:
		print(GameState.script_name_tag(self) + "Templates not loaded, loading now...")
		_load_item_templates()
	
	if debug: print(GameState.script_name_tag(self) + "Available templates after loading: ", item_templates.keys())
	
	if item_templates.has(item_id):
		if debug: print(GameState.script_name_tag(self) + "Found template for: ", item_id)
		return item_templates[item_id]
	else:
		if debug: print(GameState.script_name_tag(self) + "WARNING: No template found for item: ", item_id)
		return null
		
# Clear all items from inventory
func clear_inventory():
	if debug: print(GameState.script_name_tag(self) + "Clearing all items from inventory")
	
	# Track which items were removed for signaling
	var removed_items = inventory.keys()
	
	# Clear the inventory dictionary
	inventory.clear()
	
	# Clear item tags
	item_tags.clear()
	
	# Emit signals for each removed item
	for item_id in removed_items:
		item_removed.emit(item_id, 1)
		
	if debug: print(GameState.script_name_tag(self) + "Inventory cleared successfully")
	return true

# Save/Load System Integration
func get_save_data():
	var _fname = "get_save_data"
	var save_data = {
		"inventory": inventory.duplicate(true),
		"item_tags": item_tags.duplicate(true),
		"item_templates_loaded": item_templates_loaded
	}
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Collected inventory data: ", inventory.size(), " items, ", item_tags.size(), " tag categories")
	return save_data

func load_save_data(data):
	var _fname = "load_save_data"
	if typeof(data) != TYPE_DICTIONARY:
		if debug: print(GameState.script_name_tag(self, _fname) + "ERROR: Invalid data type for inventory load")
		return false
	
	# Restore inventory items
	if data.has("inventory"):
		inventory = data.inventory.duplicate(true)
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", inventory.size(), " inventory items")
	
	# Restore item tags organization  
	if data.has("item_tags"):
		item_tags = data.item_tags.duplicate(true)
		if debug: print(GameState.script_name_tag(self, _fname) + "Restored ", item_tags.size(), " item tag categories")
	
	# Restore template loading state
	if data.has("item_templates_loaded"):
		item_templates_loaded = data.item_templates_loaded
	
	# Emit signals for any items that were restored
	for item_id in inventory:
		var item_data = inventory[item_id]
		item_added.emit(item_id, item_data)
	
	if debug: print(GameState.script_name_tag(self, _fname) + "Inventory restoration complete")
	return true
