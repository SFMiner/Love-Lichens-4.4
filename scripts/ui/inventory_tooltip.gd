extends Panel

@onready var item_name_label = $MarginContainer/VBoxContainer/ItemName
@onready var item_desc_label = $MarginContainer/VBoxContainer/ItemDescription

const scr_debug : bool = false
var debug: bool
var current_item_id = null

func _ready():
	debug = scr_debug or GameController.sys_debug
	# Hide tooltip initially
	visible = false
	
	# Make tooltip follow mouse
	set_process(true)

func _process(delta):
	if visible:
		# Position tooltip near mouse but ensure it stays on screen
		var mouse_pos = get_viewport().get_mouse_position()
		var tooltip_size = size
		var viewport_size = get_viewport_rect().size
		
		# Calculate ideal position (slightly offset from mouse)
		var pos_x = mouse_pos.x + 15
		var pos_y = mouse_pos.y + 15
		
		# Adjust if tooltip would go off screen
		if pos_x + tooltip_size.x > viewport_size.x:
			pos_x = mouse_pos.x - tooltip_size.x - 5
		
		if pos_y + tooltip_size.y > viewport_size.y:
			pos_y = mouse_pos.y - tooltip_size.y - 5
		
		# Set position
		global_position = Vector2(pos_x, pos_y)
		
		# Ensure we're visible and on top
		visible = true
		z_index = 100

func show_tooltip(item_id, item_data):
	if not item_data:
		hide_tooltip()
		return
	
	current_item_id = item_id
	
	# Set item name and description
	if item_data.has("name"):
		item_name_label.text = item_data.name
	else:
		item_name_label.text = "Unknown Item"
		
	if item_data.has("description"):
		# Shorten description for tooltip
		var desc = item_data.description
		if desc.length() > 100:
			desc = desc.substr(0, 97) + "..."
		item_desc_label.text = desc
	else:
		item_desc_label.text = "No description available."
	
	# Adjust size based on content
	custom_minimum_size = Vector2(200, 0)
	item_desc_label.custom_minimum_size = Vector2(200, 0)
	size.y = 0  # Reset height to let it adjust to content
	
	# Make tooltip visible and bring to front
	visible = true
	z_index = 100
	
	# Print debug info
	if debug: print("Showing tooltip for: ", item_id, " - ", item_data.name if item_data.has("name") else "Unknown")

func hide_tooltip():
	current_item_id = null
	visible = false
