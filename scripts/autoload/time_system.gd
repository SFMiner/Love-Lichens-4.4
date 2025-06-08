extends Node

signal time_of_day_changed()#d_time: int, new_time: int)
signal day_changed()#old_day: int, new_day: int)
signal month_changed()#old_month: int, new_month: int)
signal year_changed()#old_year: int, new_year: int)

enum TimeOfDay {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT
}

# Time tracking
var current_day: int = 19
var current_month: int = 8
var current_year: int = 2024
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
const scr_debug : bool = false
var debug: bool = false

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug 

	if debug:
		print(GameState.script_name_tag(self) + "TimeSystem initialized on " + get_formatted_date())

	var result = format_game_time("mm/dd - h:nn", "-3h -20n")
	print("""format_game_time("mm/dd - h:nn", "-3h -20n") = """ + result)

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
		print(GameState.script_name_tag(self) + "Time of day: %s → %s" %
			[_get_time_name(old), _get_time_name(current_time_of_day)])
	emit_signal("time_of_day_changed", old, current_time_of_day)

	# rollover to next day
	if old == TimeOfDay.NIGHT and current_time_of_day == TimeOfDay.MORNING:
		advance_day()

func advance_day() -> void:
	var old_day = current_day
	current_day += 1
	if debug:
		print(GameState.script_name_tag(self) + "Day: %d → %d" % [old_day, current_day])
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
		print(GameState.script_name_tag(self) + "Month: %s → %s" %
			[month_names[old_mon - 1], month_names[current_month - 1]])
	emit_signal("month_changed", old_mon, current_month)

func _rollover_year() -> void:
	var old_year = current_year
	current_year += 1
	if debug:
		print(GameState.script_name_tag(self) + "Year: %d → %d" % [old_year, current_year])
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

func format_game_time(format_string: String, offset_string: String = "") -> String:
	var _fname = "format_game_time"

	# 1. Convert current game time into total minutes
	var total_minutes := (
		current_year * 12 * 30 * 24 * 60 +
		(current_month - 1) * 30 * 24 * 60 +
		(current_day - 1) * 24 * 60 +
		time_accumulator
	)
	
# 2. Parse offset string like "-1d 3h 2n"
	if offset_string != "":
		var regex := RegEx.new()
		regex.compile("^([+-]?)(\\d+)([hdnmy])$")

		var offset_tokens := offset_string.strip_edges().split(" ")
		print ("offset_tokens = " + str(offset_tokens))
		for token in offset_tokens:
			if token == "":
				print ("tonken == '': continuing")
				continue
			var result := regex.search(token)
			
			if result:

				print ("result.get_string(1) = " + result.get_string(1))
				print ("result.get_string(2) = " + result.get_string(2))
				print ("result.get_string(3) = " + result.get_string(3))
				
				var sign := -1 if result.get_string(1) == "-" else 1
				sign
				var value := int(result.get_string(2)) * sign
				print("value = " + str(value))
				var unit := result.get_string(3)
				print("unit = " + unit)
				
				match unit:
					"n":
						total_minutes += value
					"h":
						total_minutes += value * 60
					"d":
						total_minutes += value * 24 * 60
					"m":
						total_minutes += value * 30 * 24 * 60
					"y":
						total_minutes += value * 12 * 30 * 24 * 60
				print("total_minutes based on result: " + str(total_minutes))
			else:
				push_warning("Unrecognized time offset token: %s" % token)
	else:
		print("Formatting current date.")

	# 3. Convert total minutes back to Y/M/D/h/m
	var minutes := int(total_minutes) % 60
	print("minutes = " + str(minutes))
	var hours := int(total_minutes / 60) % 24
	print("hours = " + str(hours))
	var days_total := int(total_minutes / (24 * 60))
	print("days_total = " + str(days_total))
	var day := (days_total % 30) + 1
	print("day = " + str(day))
	var months_total := int(days_total / 30)
	print("months_total = " + str(months_total))
	var month := (months_total % 12) + 1
	print("month = " + str(month))
	var year := int(months_total / 12)
	print("year = " + str(year))

# "Mmm dd, 'yy - hh:mm"

	var month_names := [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]
	var month_name: String = month_names[month - 1]
	var month_abbr: String = month_name.substr(0, 3)

	print("str(month) " + str(month))
	print("str(month).pad_zeros(2) " + str(month).pad_zeros(2))
	
	# 4. Replace formatting tokens
	var replacements := {
		"MMMM": month_name.to_upper(),
		"mmmm": month_name.to_lower(),
		"Mmmm": month_name.capitalize(),
		"MMM": month_abbr.to_upper(),
		"mmm": month_abbr.to_lower(),
		"Mmm": month_abbr.capitalize(),
		"MM": str(month).pad_zeros(2),
		"mm": str(month).pad_zeros(2),
		"M": str(month),
		"m": str(month),
		"dd": str(day).pad_zeros(2),
		"d": str(day),
		"yyyy": str(year),
		"YYYY": str(year),
		"yy": str(year % 100).pad_zeros(2),
		"YY": str(year % 100).pad_zeros(2),
		"y": str(year % 100),
		"Y": str(year % 100),
		"hh": str(hours).pad_zeros(2),
		"h": str(hours),
		"nn": str(minutes).pad_zeros(2),
		"n": str(minutes),
	}
	print("format_string = Mmm dd, 'yy - hh:mm, -1d 3h 2n")
	

	# Sort by length descending to prioritize longer tokens first
	var keys := replacements.keys()
	keys.sort_custom(func(a, b): return b.length() - a.length())

	# Compile regex for each token to prevent nested substitution
	for key in keys:
		var regex := RegEx.new()
		regex.compile("\\b" + key + "\\b")  # Match full token only
		format_string = regex.sub(format_string, replacements[key])
		print("   format_string [" + key + "] = " + format_string)

	return format_string


# Time scaling
func set_time_scale(s: float) -> void:
	time_scale = max(0.0, s)
	if debug:
		print(GameState.script_name_tag(self) + "Time scale set to %f" % time_scale)

func get_time_scale() -> float:
	return time_scale

func pause_time() -> void:
	time_scale = 0.0
	if debug:
		print(GameState.script_name_tag(self) + "Time paused")

func resume_time() -> void:
	time_scale = 1.0
	if debug:
		print(GameState.script_name_tag(self) + "Time resumed")

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
		print(GameState.script_name_tag(self) + "Loaded time: " + get_formatted_date())
