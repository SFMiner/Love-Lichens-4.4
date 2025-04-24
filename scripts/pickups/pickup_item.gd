# pickup_item.gd
extends Area2D

signal item_picked_up(item_id, item_data)

@export var item_id: String = ""
@export var item_amount: int = 1
@export var auto_pickup: bool = false
@export var pickup_range: float = 50.0

# Keep these as fallbacks in case template loading fails
@export_group("Fallback Data (Only used if template loading fails)")
@export var fallback_name: String = ""
@export var fallback_description: String = ""
@export var fallback_category: int = 0
@export var fallback_tags: Array[String] = []

const item_type : int = 2
const scr_debug :bool = false
static var debug

var item_data = {}
var item_icon_system
var item_template = null
var label_node

func _ready():
	debug = scr_debug or GameController.sys_debug 
	add_to_group("interactable")
	if debug: print("Pickup item added to interactable group: ", item_id)
	
	# Get label node reference
	label_node = $Label
	
	# Setup collision
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = pickup_range
		collision.shape = shape
		add_child(collision)
	
	# Load item data from template
	load_from_template()
	
	# Initialize item data
	update_item_data()
	
	# Try to load the icon system
	if ResourceLoader.exists("res://scripts/ui/inventory_item_icons.gd"):
		item_icon_system = load("res://scripts/ui/inventory_item_icons.gd")
	
	# Load the texture from template
	update_item_texture()
	
	# Auto-pickup if enabled and player is in the scene
	if auto_pickup:
		# Wait a frame to ensure scene is fully loaded
		await get_tree().process_frame
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) <= pickup_range:
			interact()

# Load item data from the template
func load_from_template():
	if debug: print("Loading template data for item: ", item_id)
	
	if item_id.is_empty():
		if debug: print("ERROR: No item_id specified")
		return
	
	# Get inventory system
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		if debug: print("ERROR: Could not get InventorySystem")
		return
	
	# Get item template from inventory system
	item_template = inventory_system.get_item_template(item_id)
	if not item_template:
		if debug: print("WARNING: No template found for item: ", item_id, ", using fallback values")

func update_item_texture():
	if not $TextureRect:
		if debug: print("ERROR: TextureRect not found")
		return
	
	var texture_path = ""
	
	# Get the texture path from the template
	if item_template and item_template.has("image_path"):
		texture_path = item_template.image_path
		if debug: print("Using texture path from template: ", texture_path)
	
	# Load the texture
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		$TextureRect.texture = load(texture_path)
		if debug: print("Loaded texture from: ", texture_path)
		
		# Adjust texture rect size to match texture
		if $TextureRect.texture:
			var tex_size = $TextureRect.texture.get_size()
			$TextureRect.size = tex_size
			$TextureRect.position = Vector2(-tex_size.x/2, -tex_size.y/2)  # Center it
	else:
		if debug: print("WARNING: No valid texture found for item: ", item_id)
		
	# Update the label with item name
	if label_node:
		label_node.text = item_data.name if item_data.has("name") else item_id
		if debug: print("Updated label text to: ", label_node.text)

func update_item_data():
	# Start with empty item data
	item_data = {
		"id": item_id,
		"amount": item_amount
	}
	
	# If we have a template, use it as the base
	if item_template:
		# Copy all fields from template
		for key in item_template:
			item_data[key] = item_template[key]
			
		# Override amount with our specific amount
		item_data["amount"] = item_amount
		
		if debug: print("Item data updated from template: ", item_id)
	else:
		# Use fallback values
		item_data["name"] = fallback_name if not fallback_name.is_empty() else item_id
		item_data["description"] = fallback_description
		item_data["category"] = fallback_category
		
		# Add tags to item data if available
		if fallback_tags.size() > 0:
			item_data["tags"] = fallback_tags.duplicate()
			
		if debug: print("Item data updated from fallback values: ", item_id)

func _draw():
	# Draw a visual representation of the item
	if $TextureRect and $TextureRect.texture:
		# If we have a texture, no need to draw anything
		return
	
	# Draw a visual representation of the item
	if item_icon_system:
		var rect = Rect2(Vector2(-20, -20), Vector2(40, 40))
		var category = item_data.category if item_data.has("category") else 0
		item_icon_system.draw_item_icon(self, rect, item_id, category)
	else:
		# Fallback if icon system isn't available
		draw_circle(Vector2.ZERO, 10, Color(0.9, 0.7, 0.2))

func interact():
	if debug: print("Player interacting with item: ", item_id)
	
	# Get inventory system
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		# Try to add to inventory - using item_data directly since it should now be complete
		if inventory_system.add_item(item_id, item_amount):
			if debug: print("Item added to inventory: ", item_id)
			
			# Emit signal
			item_picked_up.emit(item_id, item_data)
			
			# Remove from world
			queue_free()
		else:
			if debug: print("Failed to add item to inventory: ", item_id)
	else:
		if debug: print("ERROR: InventorySystem not found!")

# Static method to create a pickup item in the world
static func create_in_world(parent, new_position, new_item_id, custom_data=null):
	# Create new pickup item
	var pickup = load("res://scenes/pickups/pickup_item.tscn")
	if pickup:
		var instance = pickup.instantiate()
		instance.item_id = new_item_id
		
		# Set amount if provided
		if custom_data and custom_data.has("amount"):
			instance.item_amount = custom_data.amount
		
		# Set position
		instance.global_position = new_position
		
		# Add to parent
		parent.add_child(instance)
		
		# Let the normal initialization handle the rest
		if debug: print("Created pickup item in world: ", new_item_id)
		return instance
	else:
		if debug: print("ERROR: Failed to load pickup_item.tscn")
		return null
