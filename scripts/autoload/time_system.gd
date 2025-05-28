extends Node

signal time_of_day_changed(old_time: int, new_time: int)
signal day_changed(old_day: int, new_day: int)
signal month_changed(old_month: int, new_month: int)
signal year_changed(old_year: int, new_year: int)

enum TimeOfDay {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT
}

# Time tracking
var current_day: int = 1
var current_month: int = 1
var current_year: int = 1
var current_time_of_day: TimeOfDay = TimeOfDay.MORNING

var day_names: Array = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var month_names: Array = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

# Game speed settings
var day_duration: float = 240.0  # real seconds for a full day cycle
var time_scale: float = 1.0      # multiplier for speeding up/slowing down time

# Internal tracking
var time_accumulator: float = 0.0
var debug: bool = true

func _ready() -> void:
	if debug:
		print("TimeSystem initialized on " + get_formatted_date())

func _process(delta: float) -> void:
	time_accumulator += delta * time_scale
	var segment = day_duration / 4.0
	if time_accumulator >= segment:
		advance_time_of_day()
		time_accumulator -= segment

func advance_time_of_day() -> void:
	var old = current_time_of_day
	current_time_of_day = (current_time_of_day + 1) % 4
	if debug:
		print("Time of day: %s → %s" %
			[_get_time_name(old), _get_time_name(current_time_of_day)])
	emit_signal("time_of_day_changed", old, current_time_of_day)

	# rollover to next day
	if old == TimeOfDay.NIGHT and current_time_of_day == TimeOfDay.MORNING:
		advance_day()

func advance_day() -> void:
	var old_day = current_day
	current_day += 1
	if debug:
		print("Day: %d → %d" % [old_day, current_day])
	emit_signal("day_changed", old_day, current_day)

	var dim = _days_in_month(current_year, current_month)
	if current_day > dim:
		_rollover_month()

	# update GameState if present
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.game_data.current_day = current_day
		gs.game_data.current_month = current_month
		gs.game_data.current_year = current_year

func _rollover_month() -> void:
	current_day = 1
	var old_mon = current_month
	current_month += 1
	if current_month > 12:
		_rollover_year()
	if debug:
		print("Month: %s → %s" %
			[month_names[old_mon - 1], month_names[current_month - 1]])
	emit_signal("month_changed", old_mon, current_month)

func _rollover_year() -> void:
	var old_year = current_year
	current_year += 1
	if debug:
		print("Year: %d → %d" % [old_year, current_year])
	emit_signal("year_changed", old_year, current_year)

func _days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if _is_leap_year(year):
				return 29
			else:
				return 28
		_:
			return 30

func _is_leap_year(y: int) -> bool:
	if y % 400 == 0:
		return true
	if y % 100 == 0:
		return false
	return y % 4 == 0

# Manual advancement
func force_advance_time(periods: int = 1) -> void:
	for i in range(periods):
		advance_time_of_day()

func force_advance_day(days: int = 1) -> void:
	for i in range(days):
		advance_day()

# Sleep until a given TimeOfDay
func sleep_until(target: TimeOfDay) -> int:
	var now = current_time_of_day
	var to_advance: int
	if target <= now:
		to_advance = 4 - now + target
	else:
		to_advance = target - now
	for i in range(to_advance):
		advance_time_of_day()
	return to_advance

# Time-of-day helpers
func _get_time_name(t: TimeOfDay) -> String:
	match t:
		TimeOfDay.MORNING:
			return "Morning"
		TimeOfDay.AFTERNOON:
			return "Afternoon"
		TimeOfDay.EVENING:
			return "Evening"
		TimeOfDay.NIGHT:
			return "Night"
		_:
			return "Unknown"

func get_time_name() -> String:
	return _get_time_name(current_time_of_day)

func get_day_name() -> String:
	return day_names[(current_day - 1) % 7]

func get_formatted_date() -> String:
	return "%s %d, Year %d — %s" % [
		month_names[current_month - 1],
		current_day,
		current_year,
		get_time_name()
	]

# Time scaling
func set_time_scale(s: float) -> void:
	time_scale = max(0.0, s)
	if debug:
		print("Time scale set to %f" % time_scale)

func get_time_scale() -> float:
	return time_scale

func pause_time() -> void:
	time_scale = 0.0
	if debug:
		print("Time paused")

func resume_time() -> void:
	time_scale = 1.0
	if debug:
		print("Time resumed")

# Save/load
func save_data() -> Dictionary:
	return {
		"day": current_day,
		"month": current_month,
		"year": current_year,
		"time_of_day": current_time_of_day,
		"accumulator": time_accumulator
	}

func load_data(data: Dictionary) -> void:
	if data.has("day"):
		current_day = data.day
	if data.has("month"):
		current_month = data.month
	if data.has("year"):
		current_year = data.year
	if data.has("time_of_day"):
		current_time_of_day = data.time_of_day
	if data.has("accumulator"):
		time_accumulator = data.accumulator
	if debug:
		print("Loaded time: " + get_formatted_date())
