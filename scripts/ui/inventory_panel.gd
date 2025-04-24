
# inventory_panel.gd
extends Control

const scr_debug :bool = false
var debug : bool

# Reference to inventory system
var inventory_system
var current_selected_item_id = null
var item_slots = []
var grid_container

# Item position tracking to maintain order
var item_positions = {}  # key: item_id, value: slot_index

# Simple tooltip components
var tooltip_visible = false
var tooltip_panel
var tooltip_label
var tooltip_description

# Constants for grid layout
const GRID_COLUMNS = 8
const GRID_ROWS = 3
const MAX_ITEMS = GRID_COLUMNS * GRID_ROWS

# Drag and drop variables
var drag_item_id = null
var drag_item_data = null
var drag_source_slot = null
var drag_preview = null
var is_dragging = false

# Item slot scene reference - will be loaded in _ready
var item_slot_scene = null

func _ready():
	debug = scr_debug or GameController.sys_debug
	if debug: print("Inventory panel initializing...")
	
	# Set proper visibility and process modes for pausing
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false  # Start hidden
	
	# Make sure we're on top of other UI layers
	if get_parent() is CanvasLayer:
		get_parent().layer = 100
	
	# Get reference to the inventory system
	inventory_system = get_node_or_null("/root/InventorySystem")
	
	if not inventory_system:
		if debug: print("ERROR: InventorySystem not found!")
		# Continue anyway, we might find it later
	else:
		if debug: print("InventorySystem found and connected")
	
	# Try to load the item slot scene
	if ResourceLoader.exists("res://scenes/ui/inventory_item_slot.tscn"):
		if debug: print("Loading inventory_item_slot.tscn")
		item_slot_scene = load("res://scenes/ui/inventory_item_slot.tscn")
		if not item_slot_scene:
			if debug: print("ERROR: Failed to load inventory_item_slot.tscn")
			# Try an alternative path
			if ResourceLoader.exists("res://inventory_item_slot.tscn"):
				item_slot_scene = load("res://inventory_item_slot.tscn")
				if debug: print("Loaded inventory_item_slot.tscn from alternative path")
	else:
		if debug: print("ERROR: Could not find inventory_item_slot.tscn")
		# Try an alternative path
		if ResourceLoader.exists("res://inventory_item_slot.tscn"):
			item_slot_scene = load("res://inventory_item_slot.tscn")
			if debug: print("Loaded inventory_item_slot.tscn from alternative path")
	
	# Get reference to the grid container
	grid_container = $MarginContainer/VBoxContainer/GridContainer
	if not grid_container:
		if debug: print("ERROR: GridContainer not found!")
		return
	
	# Connect to inventory signals if inventory system is available
	if inventory_system:
		# Disconnect any existing connections first
		if inventory_system.item_added.is_connected(_on_item_added):
			inventory_system.item_added.disconnect(_on_item_added)
		
		if inventory_system.item_removed.is_connected(_on_item_removed):
			inventory_system.item_removed.disconnect(_on_item_removed)
			
		if inventory_system.item_used.is_connected(_on_item_used):
			inventory_system.item_used.disconnect(_on_item_used)
		
		# Now connect signals
		inventory_system.item_added.connect(_on_item_added)
		inventory_system.item_removed.connect(_on_item_removed)
		inventory_system.item_used.connect(_on_item_used)
	
	# Connect UI signals
	var close_button = $MarginContainer/VBoxContainer/HBoxContainer/CloseButton
	if close_button:
		if close_button.pressed.is_connected(_on_close_button_pressed):
			close_button.pressed.disconnect(_on_close_button_pressed)
		close_button.pressed.connect(_on_close_button_pressed)
	else:
		if debug: print("WARNING: Close button not found")
	
	var filter_button = $MarginContainer/VBoxContainer/HBoxContainer/FilterButton
	if filter_button:
		if filter_button.item_selected.is_connected(_on_filter_selected):
			filter_button.item_selected.disconnect(_on_filter_selected)
		filter_button.item_selected.connect(_on_filter_selected)
	else:
		if debug: print("WARNING: Filter button not found")
	
	# Set up item use and drop buttons
	var use_button = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer2/UseButton
	if use_button:
		if use_button.pressed.is_connected(_on_use_button_pressed):
			use_button.pressed.disconnect(_on_use_button_pressed)
		use_button.pressed.connect(_on_use_button_pressed)
	else:
		if debug: print("WARNING: Use button not found")
	
	var drop_button = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer2/DropButton
	if drop_button:
		if drop_button.pressed.is_connected(_on_drop_button_pressed):
			drop_button.pressed.disconnect(_on_drop_button_pressed)
		drop_button.pressed.connect(_on_drop_button_pressed)
	else:
		if debug: print("WARNING: Drop button not found")
	
	# Create grid slots if we have the item slot scene
	if item_slot_scene:
		create_grid_slots()
	else:
		if debug: print("ERROR: Cannot create grid slots without item_slot_scene")
	
	# Create a simple tooltip directly in the scene
	create_simple_tooltip()
	
	# Set up to process input (for dragging and tooltip)
	set_process_input(true)
	
	if debug: print("Inventory panel initialization completed")

func create_simple_tooltip():
	if debug: print("Creating tooltip...")
	
	# Create a simple panel as tooltip
	tooltip_panel = Panel.new()
	tooltip_panel.size = Vector2(200, 100)
	tooltip_panel.visible = false
	tooltip_panel.z_index = 1000
	
	# Create a background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 1.0, 0.5, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	# Create a VBox
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(180, 0)
	
	# Add padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	# Create labels
	tooltip_label = Label.new()
	tooltip_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	tooltip_label.add_theme_font_size_override("font_size", 16)
	
	tooltip_description = Label.new()
	tooltip_description.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	tooltip_description.custom_minimum_size = Vector2(180, 0)
	tooltip_description.autowrap_mode = true
	
	# Add separator
	var separator = HSeparator.new()
	
	# Build the hierarchy
	vbox.add_child(tooltip_label)
	vbox.add_child(separator)
	vbox.add_child(tooltip_description)
	margin.add_child(vbox)
	tooltip_panel.add_child(margin)
	
	# Add to scene
	add_child(tooltip_panel)
	
	if debug: print("Tooltip created successfully")

func create_grid_slots():
	if debug: print("Creating grid slots...")
	
	# Make sure we have the item slot scene
	if not item_slot_scene:
		if debug: print("ERROR: Cannot create grid slots - item_slot_scene is null")
		return
	
	# Make sure we have the grid container
	if not grid_container:
		if debug: print("ERROR: Cannot create grid slots - grid_container is null")
		return
	
	# Clear any existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	item_slots.clear()
	
	if debug: print("Creating " + str(MAX_ITEMS) + " inventory slots...")
	
	# Create grid of slots
	for i in range(MAX_ITEMS):
		var slot = item_slot_scene.instantiate()
		if not slot:
			if debug: print("ERROR: Failed to instantiate item slot")
			continue
			
		slot.slot_index = i  # Assign unique index for identification
		grid_container.add_child(slot)
		item_slots.append(slot)
		
		# Connect signals - first check if the slot has the required signals
		if slot.has_signal("slot_clicked"):
			# Connect signals safely
			if not slot.slot_clicked.is_connected(_on_slot_clicked):
				slot.connect("slot_clicked", _on_slot_clicked)
			
			if not slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.connect("slot_hovered", _on_slot_hovered)
				
			if not slot.slot_unhovered.is_connected(_on_slot_unhovered):
				slot.connect("slot_unhovered", _on_slot_unhovered)
				
			if not slot.drag_started.is_connected(_on_drag_started):
				slot.connect("drag_started", _on_drag_started)
				
			if not slot.drag_ended.is_connected(_on_drag_ended):
				slot.connect("drag_ended", _on_drag_ended)
		else:
			if debug: print("WARNING: Slot missing required signals")
	
	if debug: print(str(item_slots.size()) + " inventory slots created")

func refresh_inventory():
	if debug: print("Refreshing inventory...")
	
	if not inventory_system:
		if debug: print("ERROR: Cannot refresh - inventory_system is null")
		return
	
	if item_slots.size() == 0:
		if debug: print("ERROR: Cannot refresh - no item slots available")
		return
		
	# Get current filter
	var filter_button = $MarginContainer/VBoxContainer/HBoxContainer/FilterButton
	if not filter_button:
		if debug: print("ERROR: Filter button not found")
		return
		
	var filter_idx = filter_button.selected
	
	# Get all items
	var all_items = inventory_system.get_all_items()
	
	# Apply filtering
	var filtered_items = {}
	
	match filter_idx:
		0: # All Items
			filtered_items = all_items
		1: # Books
			if inventory_system.has_method("get_items_by_category"):
				filtered_items = inventory_system.get_items_by_category(inventory_system.ItemCategory.BOOK)
			else:
				if debug: print("ERROR: get_items_by_category method not found")
				filtered_items = all_items
		2: # Quest Items
			if inventory_system.has_method("get_items_by_category"):
				filtered_items = inventory_system.get_items_by_category(inventory_system.ItemCategory.QUEST_ITEM)
			else:
				if debug: print("ERROR: get_items_by_category method not found")
				filtered_items = all_items
		3: # Consumables
			if inventory_system.has_method("get_items_by_category"):
				filtered_items = inventory_system.get_items_by_category(inventory_system.ItemCategory.CONSUMABLE)
			else:
				if debug: print("ERROR: get_items_by_category method not found")
				filtered_items = all_items
		4: # Equipment
			if inventory_system.has_method("get_items_by_category"):
				filtered_items = inventory_system.get_items_by_category(inventory_system.ItemCategory.EQUIPMENT)
			else:
				if debug: print("ERROR: get_items_by_category method not found")
				filtered_items = all_items
	
	# Save current item positions before clearing slots
	var current_positions = {}
	for slot_index in range(item_slots.size()):
		var slot = item_slots[slot_index]
		if slot and slot.item_id:
			current_positions[slot.item_id] = slot_index
	
	# Update our item_positions with current positions for existing items
	for item_id in current_positions:
		item_positions[item_id] = current_positions[item_id]
	
	# Reset all slots
	for slot in item_slots:
		if slot:
			slot.clear_slot()
	
	# Track which slots are already assigned
	var used_slots = []
	
	# First, place items that have a saved position
	for item_id in filtered_items:
		if item_positions.has(item_id):
			var slot_index = item_positions[item_id]
			
			# Ensure the slot index is valid and not already used
			if slot_index < item_slots.size() and not slot_index in used_slots:
				var item = filtered_items[item_id]
				if item_slots[slot_index]:
					item_slots[slot_index].set_item(item_id, item)
					used_slots.append(slot_index)
	
	# Now place remaining items in first available slots
	for item_id in filtered_items:
		if not item_positions.has(item_id):
			# Find first available slot
			for slot_index in range(item_slots.size()):
				if not slot_index in used_slots:
					var item = filtered_items[item_id]
					if item_slots[slot_index]:
						item_slots[slot_index].set_item(item_id, item)
						item_positions[item_id] = slot_index
						used_slots.append(slot_index)
						break
	
	# Remove any item_positions entries for items that no longer exist
	var items_to_remove = []
	for item_id in item_positions:
		if not filtered_items.has(item_id):
			items_to_remove.append(item_id)
	
	for item_id in items_to_remove:
		item_positions.erase(item_id)
	
	# Hide item description until an item is selected
	var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
	if description_panel:
		if not current_selected_item_id or not filtered_items.has(current_selected_item_id):
			description_panel.visible = false
			current_selected_item_id = null
	
	if debug: print("Inventory refreshed with " + str(filtered_items.size()) + " items")

func _on_close_button_pressed():
	if debug: print("Close button pressed")
	
	# Hide tooltip
	if tooltip_panel:
		tooltip_panel.visible = false
		tooltip_visible = false
	
	# Reset all slot highlights
	for slot in item_slots:
		if slot:
			slot.modulate = Color(1, 1, 1)
	
	# Hide panel and unpause game
	toggle_visibility()

func _on_slot_clicked(item_id):
	if debug: print("Slot clicked with item_id: ", item_id)
	
	# Deselect any previously selected slot
	for slot in item_slots:
		if slot:
			slot.modulate = Color(1, 1, 1)
	
	if item_id:
		select_item(item_id)
		
		# Highlight the slot that was clicked
		for slot in item_slots:
			if slot and slot.item_id == item_id:
				slot.modulate = Color(1.3, 1.3, 0.8)  # Yellowish highlight
				break
	else:
		# Clicked on empty slot
		var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
		if description_panel:
			description_panel.visible = false
		current_selected_item_id = null

func _on_slot_hovered(item_id, item_data):
	if item_id and item_data:
		# Show our simple tooltip
		if tooltip_panel and tooltip_label and tooltip_description:
			# Set text
			tooltip_label.text = item_data.name if item_data.has("name") else "Unknown Item"
			
			var desc = ""
			if item_data.has("description"):
				desc = item_data.description
				if desc.length() > 80:
					desc = desc.substr(0, 77) + "..."
			else:
				desc = "No description available."
			
			tooltip_description.text = desc
			
			# Position near mouse
			var mouse_pos = get_global_mouse_position()
			tooltip_panel.global_position = Vector2(mouse_pos.x + 15, mouse_pos.y + 15)
			
			# Make sure tooltip is sized correctly
			tooltip_panel.size.x = 200
			tooltip_panel.size.y = 0  # Let it auto-size vertically
			
			# Show tooltip
			tooltip_panel.visible = true
			tooltip_visible = true
			
			if debug: print("Tooltip showing for: ", item_id)

func _on_slot_unhovered():
	# Hide tooltip
	if tooltip_panel:
		tooltip_panel.visible = false
		tooltip_visible = false

func select_item(item_id):
	if debug: print("Selecting item: ", item_id)
	
	# Store the currently selected item ID
	current_selected_item_id = item_id
	
	# Get item data
	if not inventory_system:
		if debug: print("ERROR: Cannot select item - inventory_system is null")
		return
		
	var all_items = inventory_system.get_all_items()
	if all_items.has(item_id):
		var item = all_items[item_id]
		if debug: print("Item found in inventory: ", item.name if item.has("name") else "Unknown")
		
		# Update item description
		var item_name_label = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/ItemName
		if item_name_label:
			item_name_label.text = item.name if item.has("name") else "Unknown Item"
			
		var item_desc_label = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/ItemDescription
		if item_desc_label:
			item_desc_label.text = item.description if item.has("description") else "No description available."
		
		# Get the icon node and custom draw its icon using our icon system
		var icon = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer/ItemIcon
		if icon:
			# Set custom draw function for the icon
			if not icon.has_meta("draw_connected"):
				icon.set_meta("draw_connected", true)
				icon.draw.connect(_on_item_icon_draw.bind(icon, item_id, item.category if item.has("category") else 0))
			else:
				# Disconnect previous draw signal to avoid multiple connections
				var connections = icon.get_signal_connection_list("draw")
				for connection in connections:
					if connection.callable.get_method() == "_on_item_icon_draw":
						icon.draw.disconnect(connection.callable)
				
				# Connect new draw signal
				icon.draw.connect(_on_item_icon_draw.bind(icon, item_id, item.category if item.has("category") else 0))
				
			# Force redraw
			icon.queue_redraw()
		
		# Enable/disable use button based on whether item is usable
		var can_use = false
		if item.has("category"):
			can_use = item.category == inventory_system.ItemCategory.CONSUMABLE or \
					 item.category == inventory_system.ItemCategory.BOOK
		
		var use_button = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer2/UseButton
		if use_button:
			use_button.disabled = not can_use
			use_button.visible = true
		
		# Enable/disable drop button based on whether item is droppable
		var can_drop = true
		if item.has("category"):
			can_drop = item.category != inventory_system.ItemCategory.QUEST_ITEM
			
		var drop_button = $MarginContainer/VBoxContainer/ItemDescriptionPanel/MarginContainer/VBoxContainer/HBoxContainer2/DropButton
		if drop_button:
			drop_button.disabled = not can_drop
			drop_button.visible = true
		
		# Make entire panel visible and ensure its drawn correctly
		var panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
		if panel:
			panel.visible = true
			panel.show()
			panel.queue_redraw()
			
			if debug: print("Description panel made visible")
		
		# Force the buttons to update
		if use_button:
			use_button.queue_redraw()
		if drop_button:
			drop_button.queue_redraw()

func _on_use_button_pressed():
	if current_selected_item_id and inventory_system:
		if debug: print("Using item: ", current_selected_item_id)
		inventory_system.use_item(current_selected_item_id)
		
		# Don't refresh the whole inventory, the _on_item_used signal will handle it

func _on_drop_button_pressed_old():
	if current_selected_item_id and inventory_system:
		if debug: print("Dropping item: ", current_selected_item_id)
		inventory_system.remove_item(current_selected_item_id, 1)
		
		# Don't refresh the whole inventory, the _on_item_removed signal will handle it

func _on_filter_selected(index):
	refresh_inventory()

func _on_item_added(item_id, item_data):
	if debug: print("Item added signal received: ", item_id)
	refresh_inventory()
	# Re-select item if it was the current selection
	if item_id == current_selected_item_id:
		select_item(item_id)

func _on_item_removed(item_id, amount):
	if debug: print("Item removed signal received: ", item_id, " amount: ", amount)
	var was_selected = (item_id == current_selected_item_id)
	
	# Check if the item is completely removed
	if inventory_system and !inventory_system.has_item(item_id):
		# Clean up position tracking for this item
		item_positions.erase(item_id)
	
	refresh_inventory()
	
	# Hide description panel if the selected item was removed
	if was_selected and inventory_system and !inventory_system.has_item(item_id):
		var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
		if description_panel:
			description_panel.visible = false
		current_selected_item_id = null

func _on_item_used(item_id):
	if debug: print("Item used signal received: ", item_id)
	var was_selected = (item_id == current_selected_item_id)
	
	# Check if the item was completely used up
	if inventory_system and !inventory_system.has_item(item_id):
		# Clean up position tracking for this item
		item_positions.erase(item_id)
	
	refresh_inventory()
	
	# Re-select item if it was the current selection and still exists
	if was_selected and inventory_system and inventory_system.has_item(item_id):
		select_item(item_id)
	# Hide description panel if the item was used up
	elif was_selected and inventory_system and !inventory_system.has_item(item_id):
		var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
		if description_panel:
			description_panel.visible = false
		current_selected_item_id = null

# Handle showing/hiding the inventory
func toggle_visibility():
	visible = !visible
	
	# Pause/unpause the game
	get_tree().paused = visible
	
	if visible:
		# Refresh inventory when showing
		refresh_inventory()
		# Clear any existing selection
		current_selected_item_id = null
		var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
		if description_panel:
			description_panel.visible = false
		
		# Make sure tooltips are hidden
		if tooltip_panel:
			tooltip_panel.visible = false
			tooltip_visible = false
		
		# Reset all slot highlights
		for slot in item_slots:
			if slot:
				slot.modulate = Color(1, 1, 1)
	else:
		# Hide tooltip when closing inventory
		if tooltip_panel:
			tooltip_panel.visible = false
			tooltip_visible = false
			
		# Reset all slot highlights
		for slot in item_slots:
			if slot:
				slot.modulate = Color(1, 1, 1)
	
	if debug: print("Inventory panel visibility: ", visible)

# Custom draw function for item icons in the description panel
# Custom draw function for item icons in the description panel
func _on_item_icon_draw(icon_control, item_id, category):
	var icon_size = icon_control.size
	var rect = Rect2(Vector2(0, 0), icon_size)
	
	# Safely load the icon system
	var icon_system_path = "res://scripts/ui/inventory_item_icons.gd"
	if ResourceLoader.exists(icon_system_path):
		var icon_system = load(icon_system_path)
		if icon_system and icon_system.has_method("draw_item_icon"):
			icon_system.draw_item_icon(icon_control, rect, item_id, category)
		else:
			# Draw fallback icon
			icon_control.draw_rect(rect, Color(0.3, 0.5, 0.3, 1.0))
	else:
		# Draw fallback icon
		icon_control.draw_rect(rect, Color(0.3, 0.5, 0.3, 1.0))

# Drag and drop handlers
func _on_drag_started(item_id, item_data, source_slot):
	if debug: print("Started dragging item: ", item_id)
	drag_item_id = item_id
	drag_item_data = item_data
	drag_source_slot = source_slot
	is_dragging = true
	
	# Create a visual drag preview
	create_drag_preview()
	
	# Set the inventory panel to process input events so we can track mouse
	set_process_input(true)

# This is now only used if the slot itself emits the signal - our main handling is in _input
func _on_drag_ended(target_slot):
	# Most drag ending is now handled in _input and _handle_drag_end
	# This is just a fallback
	if debug: print("_on_drag_ended called directly - should not happen normally")
	cleanup_drag()

func create_drag_preview():
	# Remove any existing preview
	if drag_preview:
		drag_preview.queue_free()
	
	# Create a new control to show as preview
	drag_preview = Control.new()
	drag_preview.custom_minimum_size = Vector2(48, 48)
	drag_preview.size = Vector2(48, 48)
	
	# Make it follow the mouse position
	add_child(drag_preview)
	
	# Set up drawing
	drag_preview.draw.connect(_on_drag_preview_draw)

func _on_drag_preview_draw():
	if drag_preview and drag_item_id and drag_item_data:
		var icon_system_path = "res://scripts/ui/inventory_item_icons.gd"
		if ResourceLoader.exists(icon_system_path):
			var icon_system = load(icon_system_path)
			if icon_system and icon_system.has_method("draw_item_icon"):
				var rect = Rect2(Vector2(0, 0), drag_preview.size)
				# Make sure category exists and is valid
				var category = 0
				if drag_item_data.has("category"):
					category = drag_item_data.category
				icon_system.draw_item_icon(drag_preview, rect, drag_item_id, category)
			else:
				# Draw fallback icon
				var rect = Rect2(Vector2(0, 0), drag_preview.size)
				drag_preview.draw_rect(rect, Color(0.3, 0.5, 0.3, 1.0))
		else:
			# Draw fallback icon
			var rect = Rect2(Vector2(0, 0), drag_preview.size)
			drag_preview.draw_rect(rect, Color(0.3, 0.5, 0.3, 1.0))

func cleanup_drag():
	is_dragging = false
	drag_item_id = null
	drag_item_data = null
	drag_source_slot = null
	
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		if debug: print("UI cancel detected in inventory panel")
		toggle_visibility()
		get_viewport().set_input_as_handled()
		
	# Update tooltip position if visible
	if tooltip_visible and tooltip_panel:
		var mouse_pos = get_global_mouse_position()
		tooltip_panel.global_position = Vector2(mouse_pos.x + 15, mouse_pos.y + 15)
	
	# Handle drag preview if dragging
	if is_dragging and drag_preview:
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2
		drag_preview.queue_redraw()
		
		# Check for mouse button release to end drag
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Find slot under cursor
			var mouse_pos = get_global_mouse_position()
			var target_slot = get_slot_at_position(mouse_pos)
			
			if target_slot:
				if debug: print("Ending drag on slot under cursor: ", target_slot.slot_index)
				_handle_drag_end(target_slot)
			else:
				if debug: print("No slot under cursor, dropping back to source")
				if drag_source_slot:
					_handle_drag_end(drag_source_slot)
				
			# Clean up
			cleanup_drag()

# Find which slot is under a given position
func get_slot_at_position(pos):
	for slot in item_slots:
		if slot:
			var slot_rect = Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(pos):
				return slot
	return null

# Handle the drop operation at the end of a drag
func _handle_drag_end(target_slot):
	if not drag_source_slot or not drag_item_id:
		return
		
	if debug: print("Handling drag end. Source: ", drag_source_slot.slot_index, 
		", Target: ", target_slot.slot_index)
	
	# If dropped on a different slot than source
	if target_slot != drag_source_slot:
		# If target slot has an item, swap them
		if target_slot.item_id:
			if debug: print("Swapping items between different slots")
			swap_items(drag_source_slot, target_slot)
		else:
			# Move item to empty slot
			if debug: print("Moving item to empty slot")
			move_item(drag_source_slot, target_slot)
			
		# Re-select the item in its new location
		select_item(drag_item_id)
		
		# Highlight the new slot
		for slot in item_slots:
			if slot:
				slot.modulate = Color(1, 1, 1)
		target_slot.modulate = Color(1.3, 1.3, 0.8)  # Yellowish highlight
	else:
		if debug: print("Dropped on same slot - no changes made")

func swap_items(slot1, slot2):
	# Get the items from both slots
	var item1_id = slot1.item_id
	var item1_data = slot1.item_data.duplicate() if slot1.item_data else null
	var item2_id = slot2.item_id
	var item2_data = slot2.item_data.duplicate() if slot2.item_data else null
	
	if debug: print("Swapping items: ", item1_id, " and ", item2_id)
	
	# Swap the items in the slots (visually)
	slot1.clear_slot()
	slot2.clear_slot()
	
	if item2_id:
		slot1.set_item(item2_id, item2_data)
		# Update position tracking
		item_positions[item2_id] = slot1.slot_index
	
	if item1_id:
		slot2.set_item(item1_id, item1_data)
		# Update position tracking
		item_positions[item1_id] = slot2.slot_index
	
	if debug: print("Swapped items between slots ", slot1.slot_index, " and ", slot2.slot_index)

func move_item(source_slot, target_slot):
	# Get item data
	var item_id = source_slot.item_id
	var item_data = source_slot.item_data.duplicate() if source_slot.item_data else null
	
	if !item_id:
		if debug: print("No item to move from slot ", source_slot.slot_index)
		return
	
	if debug: print("Moving item ", item_id, " from slot ", source_slot.slot_index, " to slot ", target_slot.slot_index)
	
	# Clear both slots first
	source_slot.clear_slot()
	target_slot.clear_slot()
	
	# Set item to new slot
	target_slot.set_item(item_id, item_data)
	
	# Update position tracking
	item_positions[item_id] = target_slot.slot_index
	
	if debug: print("Moved item from slot ", source_slot.slot_index, " to slot ", target_slot.slot_index)


func _on_drop_button_pressed():
	if current_selected_item_id and inventory_system:
		if debug: print("Dropping item: ", current_selected_item_id)
		
		# Check if item exists and get its data
		if not inventory_system.has_item(current_selected_item_id):
			if debug: print("Item no longer exists in inventory")
			refresh_inventory()
			return
			
		# Get item data BEFORE removing from inventory
		var item_data = inventory_system.get_item_data(current_selected_item_id)
		if not item_data:
			if debug: print("Could not get item data")
			return
			
		# Make a copy of relevant item data
		var item_data_copy = {
			"id": current_selected_item_id,
			"name": item_data.name if item_data.has("name") else "Unknown Item",
			"description": item_data.description if item_data.has("description") else "",
			"category": item_data.category if item_data.has("category") else 0
		}
		
		# Get the player
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			if debug: print("Player not found")
			return
			
		# Calculate drop position
		var drop_pos = player.global_position
		if is_instance_valid(player) and player.get("last_direction") != null:
			drop_pos += player.last_direction.normalized() * 40
			
		# Only remove from inventory if we have all the prerequisites for creating the pickup
		if inventory_system.remove_item(current_selected_item_id, 1):
			if debug: print("Item removed from inventory, creating pickup")
			
			# Get current scene
			var current_scene = player.get_parent()
			
			# Create pickup scene
			var pickup_scene = load("res://scenes/pickups/pickup_item.tscn")
			if pickup_scene:
				var pickup = pickup_scene.instantiate()
				pickup.item_id = item_data_copy.id
				pickup.item_name = item_data_copy.name
				pickup.item_description = item_data_copy.description
				pickup.item_category = item_data_copy.category
				pickup.item_amount = 1
				
				pickup.global_position = drop_pos
				current_scene.add_child(pickup)
				if debug: print("Created pickup item in world: ", item_data_copy.id)
			else:
				if debug: print("ERROR: Could not load pickup_item.tscn")
		else:
			if debug: print("Failed to remove item from inventory")
			
		# Always refresh inventory
		refresh_inventory()
	else:
		if debug: print("No item selected or inventory system not found")

# Reset the inventory panel state
func reset():
	if debug: print("Resetting inventory panel state")
	
	# Clear the current selection
	current_selected_item_id = null
	
	# Clear item positions tracking
	item_positions.clear()
	
	# Reset all slots
	for slot in item_slots:
		if slot:
			slot.clear_slot()
			slot.modulate = Color(1, 1, 1)
	
	# Hide description panel
	var description_panel = $MarginContainer/VBoxContainer/ItemDescriptionPanel
	if description_panel:
		description_panel.visible = false
		
	# Hide tooltip
	if tooltip_panel:
		tooltip_panel.visible = false
		tooltip_visible = false
	
	if debug: print("Inventory panel reset completed")
	
	# Refresh to ensure UI state matches inventory system state
	refresh_inventory()
