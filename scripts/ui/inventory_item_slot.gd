extends Panel

signal slot_clicked(item_id)
signal slot_hovered(item_id, item_data)
signal slot_unhovered()
signal drag_started(item_id, item_data, from_slot)
signal drag_ended(dropped_on_slot)

const scr_debug : bool = false
var debug
var item_id = null
var item_data = null
var slot_index = 0  # To identify this slot
var is_dragging = false

# References to UI elements
@onready var item_count = $ItemCount
@onready var item_icon = $ItemIcon

func _ready():
	debug = scr_debug or GameController.sys_debug 
	# Connect signals
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	item_count.add_theme_constant_override("outline_size", 3)
	# Start with empty slot
	clear_slot()
	
	# Make sure we can detect mouse events on the entire slot
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Debug item presence
	if debug: print(GameState.script_name_tag(self) + "Item icon node exists: " + str(item_icon != null))

func clear_slot():
	item_id = null
	item_data = null
	
	# Reset visuals
	item_count.text = ""
	item_count.visible = false
	
	# Clear the item icon
	if item_icon:
		item_icon.color = Color(0.2, 0.2, 0.2, 0.5)
		# Remove any texture if it was set
		if item_icon.has_node("TextureRect"):
			var texture_rect = item_icon.get_node("TextureRect")
			texture_rect.texture = null
			texture_rect.visible = false
	
	# Force redraw
	queue_redraw()

func set_item(id, data):
	if debug: print(GameState.script_name_tag(self) + "Setting item: " + str(id))
	item_id = id
	item_data = data
	
	# Display item count if more than 1
	if item_count and data and data.has("amount"):
		# Always display the count, even if it's 1
		item_count.text = str(int(data.amount))
		item_count.visible = true
	elif item_count:
		item_count.visible = false
	
	# Update the item icon
	update_item_icon()
	
	# Force redraw
	queue_redraw()

func get_item_texture(item_id):
	print(GameState.script_name_tag(self) + "Trying to load texture for item_id: ", item_id)
	var texture = null
	
	# First attempt: Try to get from inventory system templates
	if InventorySystem: #Engine.has_singleton("InventorySystem"):
		print(GameState.script_name_tag(self) + "InventorySystem singleton found")
		var inventory_system = InventorySystem #Engine.get_singleton("InventorySystem")
		
		if inventory_system.has_method("get_item_template"):
			print(GameState.script_name_tag(self) + "get_item_template method exists")
			var template = inventory_system.get_item_template(item_id)
			
			if template:
				print(GameState.script_name_tag(self) + "Template found for item: ", item_id)
				if template.has("image_path"):
					var path = template.image_path
					print(GameState.script_name_tag(self) + "Image path from template: ", path)
					
					if ResourceLoader.exists(path):
						print(GameState.script_name_tag(self) + "Image file exists at path: ", path)
						texture = load(path)
						print(GameState.script_name_tag(self) + "Texture loaded successfully from template path")
						return texture
					else:
						print(GameState.script_name_tag(self) + "WARNING: Image file does not exist at path: ", path)
				else:
					print(GameState.script_name_tag(self) + "Template has no image_path property")
			else:
				print(GameState.script_name_tag(self) + "No template found for item: ", item_id)
		else:
			print(GameState.script_name_tag(self) + "get_item_template method doesn't exist")
	else:
		print(GameState.script_name_tag(self) + "InventorySystem singleton not found")
	
	# Second attempt: Try direct paths as fallback
	#var direct_paths = { 
#		"common_lichen1": "res://assets/images/items/common_lichen2.png",
#		"rare_lichen1": "res://assets/images/items/rare_lichen1.png",
#		"lichenology_book": "res://assets/images/items/lichenology_book.png",
#		"energy_drink": "res://assets/images/items/energy_drink.png"
		# Add more as needed for testing
	#}
	
	#if direct_paths.has(item_id) and ResourceLoader.exists(direct_paths[item_id]):
	#	print(GameState.script_name_tag(self) + "Loading texture directly for " + item_id)
	#	texture = load(direct_paths[item_id])
	#	return texture
	
	print(GameState.script_name_tag(self) + "Could not find texture through any method for: ", item_id)
	return null

func update_item_icon():
	if debug: print(GameState.script_name_tag(self) + "update_item_icon running")
	if not item_icon:
		if debug: print(GameState.script_name_tag(self) + "Error: Item icon node not found")
		return
		
	if item_id == null:
		# Empty slot
		item_icon.color = Color(0.2, 0.2, 0.2, 0.5)
		return
		
	# Get the texture
	print(GameState.script_name_tag(self) + "calling texture for " + item_id)
	var texture = get_item_texture(item_id)
	
	if texture:
		if debug: print(GameState.script_name_tag(self) + "Found texture for " + item_id)
		if not item_icon.has_node("TextureRect"):
			var texture_rect = TextureRect.new()
			texture_rect.name = "TextureRect"
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL  
			texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			texture_rect.anchors_preset = Control.PRESET_FULL_RECT
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item_icon.add_child(texture_rect)
		
		var texture_rect = item_icon.get_node("TextureRect")
		texture_rect.texture = texture
		texture_rect.visible = true
		item_icon.color = Color(1, 1, 1, 1)  # Set to transparent
	else:
		if debug: print(GameState.script_name_tag(self) + "No texture found for item: " + item_id)
		# Remove any existing texture rect
		if item_icon.has_node("TextureRect"):
			item_icon.get_node("TextureRect").visible = false
			
		# Set fallback color
		item_icon.color = Color(0.5, 0.5, 0.5, 1.0)

func _draw():
	# Note: We're now handling the drawing in update_item_icon() 
	# This _draw() method is kept for backward compatibility
	pass

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only start drag if we have an item
			if item_id:
				is_dragging = true
				emit_signal("drag_started", item_id, item_data, self)
			
			# Always emit click for selection
			emit_signal("slot_clicked", item_id)

func _on_mouse_entered():
	if item_id:
		emit_signal("slot_hovered", item_id, item_data)
	
	# Visual feedback with a simple color change
	modulate = Color(1.2, 1.2, 1.2)  # Slightly brighter

func _on_mouse_exited():
	emit_signal("slot_unhovered")
	
	# Reset to normal
	modulate = Color(1.0, 1.0, 1.0)  # Normal brightness
