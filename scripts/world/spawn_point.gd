# spawn_point.gd
extends Marker2D

# This class defines a spawn point for the player in a scene

@export var spawn_id: String = "default" # Identifier for this spawn point
@export var spawn_direction: Vector2 = Vector2(0, 1) # Direction player will face when spawning here
@export var is_default: bool = false # Whether this is the default spawn point for this scene

func _ready():
	# Add to the spawn_point group
	add_to_group("spawn_point")
	
	# If this is the default spawn point and no ID is set, set it to "default"
	if is_default and spawn_id.is_empty():
		spawn_id = "default"
	
	# Draw an icon in the editor
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	# Only draw in the editor
	if not Engine.is_editor_hint():
		return
	
	# Draw a marker showing the spawn point
	var color = Color(0, 1, 0, 0.7) # Green semi-transparent
	draw_circle(Vector2.ZERO, 10, color)
	
	# Draw an arrow showing the spawn direction
	var arrow_length = 20
	var arrow_point = spawn_direction.normalized() * arrow_length
	var arrow_width = 5
	
	draw_line(Vector2.ZERO, arrow_point, color, 2)
	
	# Draw arrow head
	var left_point = arrow_point + (spawn_direction.normalized().rotated(3 * PI / 4) * arrow_width)
	var right_point = arrow_point + (spawn_direction.normalized().rotated(-3 * PI / 4) * arrow_width)
	
	var points = PackedVector2Array([arrow_point, left_point, right_point])
	draw_colored_polygon(points, color)
	
	# Draw the ID as text
	var font_color = Color(1, 1, 1)
	draw_string(Control.new().get_theme_default_font(), 
		Vector2(15, -5), 
		spawn_id, 
		HORIZONTAL_ALIGNMENT_LEFT,
		-1, 
		12, 
		font_color)
