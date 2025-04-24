# graph_connection.gd
extends Node2D

# Represents a connection between story elements in the graph view

var from_node = null
var to_node = null
var connection_data = null

# Line appearance
var line_width = 2
var line_color = Color(0.7, 0.7, 0.7)
var arrow_size = 10
var label_font_size = 12
var label_color = Color(1, 1, 1)
var label_bg_color = Color(0, 0, 0, 0.5)

# Connection colors by type
const CONNECTION_COLORS = {
	0: Color(1.0, 0.5, 0.0),  # AFFECTS
	1: Color(0.0, 0.7, 0.0),  # DEPENDS_ON
	2: Color(0.0, 0.5, 1.0),  # REVEALS
	3: Color(1.0, 0.8, 0.0),  # FORESHADOWS
	4: Color(1.0, 0.0, 0.0),  # CONTRADICTS
	5: Color(0.7, 0.7, 0.7)   # RELATED_TO
}

# Store the connection type names for labels
const CONNECTION_TYPE_NAMES = {
	0: "Affects",
	1: "Depends On",
	2: "Reveals",
	3: "Foreshadows",
	4: "Contradicts",
	5: "Related To"
}

func _ready():
	# Set up connections to nodes for redrawing when they move
	if from_node and from_node.has_signal("dragged"):
		from_node.dragged.connect(_on_node_dragged)
	
	if to_node and to_node.has_signal("dragged"):
		to_node.dragged.connect(_on_node_dragged)
	
	# Set color based on connection type if available
	if connection_data and CONNECTION_COLORS.has(connection_data.type):
		line_color = CONNECTION_COLORS[connection_data.type]

func _draw():
	if not from_node or not to_node or not connection_data:
		return
	
	# Get node positions
	var start_pos = from_node.position
	var end_pos = to_node.position
	
	# Calculate direction vector
	var direction = (end_pos - start_pos).normalized()
	
	# Adjust start and end points to begin/end at node borders
	var from_radius = from_node.node_radius
	var to_radius = to_node.node_radius
	
	start_pos += direction * from_radius
	end_pos -= direction * to_radius
	
	# Draw the line
	draw_line(start_pos, end_pos, line_color, line_width)
	
	# Draw arrowhead
	_draw_arrow(end_pos, direction)
	
	# Draw connection type label
	_draw_connection_label(start_pos, end_pos)

func _draw_arrow(pos, direction):
	# Calculate perpendicular vector
	var perp = Vector2(-direction.y, direction.x) * arrow_size * 0.5
	
	# Calculate three points of the arrow
	var point1 = pos
	var point2 = pos - direction * arrow_size + perp
	var point3 = pos - direction * arrow_size - perp
	
	# Draw the arrowhead
	var points = PackedVector2Array([point1, point2, point3])
	draw_colored_polygon(points, line_color)

func _draw_connection_label(start_pos, end_pos):
	if not connection_data:
		return
	
	# Get connection type name
	var type_name = CONNECTION_TYPE_NAMES[connection_data.type] if CONNECTION_TYPE_NAMES.has(connection_data.type) else "?"
	
	# Position label at midpoint
	var mid_pos = (start_pos + end_pos) / 2
	
	# Draw label background
	var font = Control.new().get_font("font", "Label")
	var text_size = font.get_string_size(type_name)
	var text_rect = Rect2(mid_pos.x - text_size.x / 2 - 2, mid_pos.y - text_size.y / 2 - 2, 
						text_size.x + 4, text_size.y + 4)
	draw_rect(text_rect, label_bg_color)
	
	# Draw label text
	draw_string(font, mid_pos - Vector2(text_size.x / 2, -text_size.y / 4), type_name, 
		HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_color)

func _on_node_dragged(node, position):
	# Redraw the connection when either connected node moves
	queue_redraw()

# Public method to trigger redraw - called from graph_node script when nodes move
func update_position():
	queue_redraw()
