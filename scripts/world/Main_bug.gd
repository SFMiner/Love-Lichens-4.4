extends Node2D

@onready var area_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var butterfly_scene = preload("res://scenes/world/Butterfly.tscn")

const scr_debug = false
var debug 

func _ready():
	debug = scr_debug or GameController.sys_debug
	var poly_points = _get_area_global_points()
	var bounds = _get_polygon_bounds(poly_points)

	for i in 5:
		var b = butterfly_scene.instantiate()

		var attempt = 0
		var max_attempts = 50
		while attempt < max_attempts:
			var candidate = Vector2(
				randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
				randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
			)
			if Geometry2D.is_point_in_polygon(candidate, poly_points):
				b.position = candidate
				break
			attempt += 1

		add_child(b)
		b.set_flight_area(area_polygon)
		if debug: print("Spawned butterfly ", i, " at ", b.position)

func _get_area_global_points() -> Array:
	var global_points = []
	for p in area_polygon.polygon:
		global_points.append(area_polygon.to_global(p))
	return global_points
	
func _get_polygon_bounds(points: Array) -> Rect2:
	if points.is_empty():
		return Rect2()

	var rect = Rect2(points[0], Vector2.ZERO)
	for p in points:
		rect = rect.expand(p)
	return rect
