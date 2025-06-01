extends Node2D

var speed: float = 75.0
var rest_chance: float = 0.01
var rest_duration: float = 2.0
var flight_polygon: CollisionPolygon2D = null

@onready var timer: Timer = $Timer
@onready var anim : AnimationPlayer = $AnimationPlayer
var velocity = Vector2.ZERO
var resting = false
var ready_to_move = false
const scr_debug :bool = false
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug 
	timer.timeout.connect(_resume_moving)
	if debug: print(GameState.script_name_tag(self) + "[DEBUG] Sprite frame: ", $Sprite2D.frame)
	if debug: print(GameState.script_name_tag(self) + "[DEBUG] Sprite size: ", $Sprite2D.texture.get_size())
	if debug: print(GameState.script_name_tag(self) + "[DEBUG] Sprite visible: ", $Sprite2D.visible)
	if debug: print(GameState.script_name_tag(self) + "[DEBUG] Global position: ", global_position)

func set_flight_area(area: CollisionPolygon2D):
	flight_polygon = area
	_new_direction()
	ready_to_move = true  

func _process(delta):
	if not ready_to_move:
		return

	if debug: print(GameState.script_name_tag(self) + "Moving: ", name, " pos: ", position, " vel: ", velocity)

	if resting:
		anim.play("resting")
		return
	else:
		anim.play("flying")
	
	if randf() < rest_chance:
		resting = true
		velocity = Vector2.ZERO
		timer.start(rest_duration)

	var new_position = position + velocity * delta
	if _is_within_flight_area(new_position):
		position = new_position
	else:
		_new_direction()

func _new_direction():
	velocity = Vector2.RIGHT.rotated(randf() * TAU) * speed

func _resume_moving():
	resting = false
	_new_direction()

func _is_within_flight_area(pos: Vector2) -> bool:
	if not flight_polygon:
		return true

	var adjusted_polygon := []
	for p in flight_polygon.polygon:
		adjusted_polygon.append(p + flight_polygon.position)

	return Geometry2D.is_point_in_polygon(pos, adjusted_polygon)
