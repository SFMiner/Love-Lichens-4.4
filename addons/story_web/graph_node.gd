# graph_node.gd
extends Node2D

# Represents a story element in the graph view

var element = null
var is_selected = false
var is_dragging = false
var drag_offset = Vector2.ZERO

# Node appearance
var node_radius = 40
var node_color = Color(0.5, 0.5, 0.5)
var title_font_size = 14
var title_color = Color(1, 1, 1)
var border_color = Color(0.8, 0.8, 0.8)
var border_width = 2
var selected_border_color = Color(1, 1, 0)
var selected_border_width = 3

# Node colors by type
const NODE_COLORS = {
	0: Color(0.2, 0.6, 1.0),  # CHARACTER
	1: Color(0.8, 0.2, 0.2),  # QUEST
	2: Color(0.2, 0.8, 0.2),  # LOCATION
	3: Color(0.8, 0.8, 0.2),  # ITEM
	4: Color(0.8, 0.2, 0.8),  # EVENT
	5: Color(0.2, 0.8, 0.8),  # KNOWLEDGE
	6: Color(0.6, 0.6, 0.6)   # NOTE
}

# Type icons
var type_icons = {
	0: preload("res://addons/story_web/icons/character_icon.PNG"),  # CHARACTER
	1: preload("res://addons/story_web/icons/quest_icon.PNG"),      # QUEST
	2: preload("res://addons/story_web/icons/location_icon.PNG"),   # LOCATION
	3: preload("res://addons/story_web/icons/item-icon.PNG"),       # ITEM
	4: preload("res://addons/story_web/icons/event_icon.PNG"),      # EVENT
	5: preload("res://addons/story_web/icons/knowledge_icon.PNG"),  # KNOWLEDGE
	6: preload("res://addons/story_web/icons/note_icon.PNG")        # NOTE
}

signal node_selected(node)
signal node_double_clicked(node)
signal dragged(node, position)

func _ready():
	# Set up the node appearance
	if element != null:
		# Set color based on element type if available
		if NODE_COLORS.has(element.type):
			node_color = NODE_COLORS[element.type]

func _draw():
	if element == null:
		return
	
	# Draw node circle
	var border = selected_border_width if is_selected else border_width
	var b_color = selected_border_color if is_selected else border_color
	
	# Draw border
	draw_circle(Vector2.ZERO, node_radius + border, b_color)
	
	# Draw main circle
	draw_circle(Vector2.ZERO, node_radius, node_color)
	
	# Draw type icon if available
	if type_icons.has(element.type):
		var icon = type_icons[element.type]
		var icon_size = Vector2(node_radius, node_radius) * 1.0
		var icon_pos = -icon_size / 2
		draw_texture_rect(icon, Rect2(icon_pos, icon_size), false)
	
	# Draw element title
	var title_font = Control.new().get_font("font", "Label")
	var title_pos = Vector2(0, node_radius + 15)
	
	# Add a background to the text for better readability
	var text_size = title_font.get_string_size(element.title)
	var text_rect = Rect2(title_pos.x - text_size.x / 2 - 2, title_pos.y - text_size.y - 2, 
						text_size.x + 4, text_size.y + 4)
	draw_rect(text_rect, Color(0, 0, 0, 0.5))
	
	# Draw the text
	draw_string(title_font, title_pos, element.title, 
		HORIZONTAL_ALIGNMENT_CENTER, -1, title_font_size, title_color)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Single click
				is_selected = true
				queue_redraw()
				node_selected.emit(self)
				
				# Start dragging
				is_dragging = true
				drag_offset = event.position - position
				
				# Handle double click
				if event.double_click:
					node_double_clicked.emit(self)
			else:
				# Release
				is_dragging = false
	
	elif event is InputEventMouseMotion:
		if is_dragging:
			position = event.position - drag_offset
			dragged.emit(self, position)

func set_selected(selected):
	is_selected = selected
	queue_redraw()

func get_element_id():
	if element != null:
		return element.id
	return null

# Override _input to handle dragging
func _input(event):
	if event is InputEventMouseMotion:
		if is_dragging:
			position = get_viewport().get_mouse_position() - drag_offset
			dragged.emit(self, position)
			# Force all connections to redraw
			for connection in get_parent().get_children():
				if connection.has_method("update_position"):
					connection.update_position()
