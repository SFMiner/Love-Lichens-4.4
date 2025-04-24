extends Node

# Category colors
const CATEGORY_COLORS = {
	0: Color(0.6, 0.2, 0.9, 1.0),    # BOOK
	1: Color(1.0, 0.9, 0.2, 1.0),    # QUEST_ITEM
	2: Color(0.3, 0.6, 1.0, 1.0),    # CONSUMABLE
	3: Color(1.0, 0.3, 0.3, 1.0)     # EQUIPMENT
}

# Special item colors
const ITEM_COLORS = {
	"rare_lichen": Color(0.2, 1.0, 0.4, 1.0),
	"moss_key": Color(1.0, 0.8, 0.2, 1.0),
	"energy_drink": Color(0.0, 0.8, 0.8, 1.0)
}

# Shape types
enum ShapeType {
	SQUARE,
	TRIANGLE,
	CIRCLE,
	HEXAGON,
	STAR
}

# Default shapes by category
const CATEGORY_SHAPES = {
	0: ShapeType.SQUARE,   # BOOK
	1: ShapeType.STAR,     # QUEST_ITEM
	2: ShapeType.CIRCLE,   # CONSUMABLE
	3: ShapeType.TRIANGLE  # EQUIPMENT
}

# Special item shapes
const ITEM_SHAPES = {
	"energy_drink": ShapeType.HEXAGON
}

# Get item color
static func get_item_color(item_id, category):
	if ITEM_COLORS.has(item_id):
		return ITEM_COLORS[item_id]
	
	var cat_int = category
	if typeof(category) == TYPE_FLOAT:
		cat_int = int(category)
	elif typeof(category) == TYPE_STRING and category.is_valid_int():
		cat_int = category.to_int()
	
	if CATEGORY_COLORS.has(cat_int):
		return CATEGORY_COLORS[cat_int]
	
	return Color(0.5, 0.5, 0.5, 1.0)

# Get item shape
static func get_item_shape(category, item_id = "unknown"):
	if item_id != "unknown" and ITEM_SHAPES.has(item_id):
		return ITEM_SHAPES[item_id]
	
	var cat_int = category
	if typeof(category) == TYPE_FLOAT:
		cat_int = int(category)
	elif typeof(category) == TYPE_STRING and category.is_valid_int():
		cat_int = category.to_int()
	
	if CATEGORY_SHAPES.has(cat_int):
		return CATEGORY_SHAPES[cat_int]
	
	return ShapeType.SQUARE

# Draw the item icon
static func draw_item_icon(canvas_item, rect, item_id, category):
	# Get texture from IconSystem singleton
	var texture = null
	if Engine.has_singleton("IconSystem"):
		var icon_system = Engine.get_singleton("IconSystem")
		texture = icon_system.get_cached_texture(item_id)
	
	if texture != null:
		# Draw texture
		var margin = 2
		var draw_rect = Rect2(
			rect.position.x + margin,
			rect.position.y + margin,
			rect.size.x - (margin * 2),
			rect.size.y - (margin * 2)
		)
		
		# Subtle background
		canvas_item.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.2))
		
		# Draw texture
		canvas_item.draw_texture_rect(texture, draw_rect, false)
	else:
		# Fall back to shapes
		var color = get_item_color(item_id, category)
		var shape = get_item_shape(category, item_id)
		
		# Get dimensions
		var width = rect.size.x
		var height = rect.size.y
		var center = rect.position + rect.size / 2
		var size = min(width, height) * 0.8
		
		# Background
		canvas_item.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.1))
		
		# Draw based on shape type
		match shape:
			ShapeType.CIRCLE:
				canvas_item.draw_circle(center, size / 2 + 1, Color(0, 0, 0, 0.5))
				canvas_item.draw_circle(center, size / 2, color)
			
			ShapeType.SQUARE:
				var half_size = size / 2
				var square_rect = Rect2(center.x - half_size, center.y - half_size, size, size)
				canvas_item.draw_rect(square_rect, color)
			
			ShapeType.TRIANGLE:
				var points = PackedVector2Array([
					Vector2(center.x, center.y - size / 2),
					Vector2(center.x - size / 2, center.y + size / 2),
					Vector2(center.x + size / 2, center.y + size / 2)
				])
				canvas_item.draw_polygon(points, [color])
			
			ShapeType.HEXAGON:
				var points = []
				for i in range(6):
					var angle = 2 * PI * i / 6 - PI / 2
					var point = center + Vector2(cos(angle), sin(angle)) * size / 2
					points.append(point)
				canvas_item.draw_polygon(PackedVector2Array(points), [color])
			
			ShapeType.STAR:
				var points = []
				var inner_radius = size / 4
				var outer_radius = size / 2
				
				for i in range(10):
					var angle = 2 * PI * i / 10 - PI / 2
					var radius = outer_radius if i % 2 == 0 else inner_radius
					var point = center + Vector2(cos(angle), sin(angle)) * radius
					points.append(point)
				
				canvas_item.draw_polygon(PackedVector2Array(points), [color])
