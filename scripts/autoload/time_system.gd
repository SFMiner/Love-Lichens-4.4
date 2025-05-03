# time_system.gd
extends Node

signal day_changed(old_day, new_day)
signal time_of_day_changed(old_time, new_time)
signal week_changed(old_week, new_week)

const STARTUP_MESSAGE = "*** TimeSystem AutoLoad Starting ***"

enum TimeOfDay {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT
}

# Time tracking
var current_day: int = 1
var current_week: int = 1
var current_time_of_day: TimeOfDay = TimeOfDay.MORNING
var days_names: Array = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

# Game speed settings
var day_duration: float = 240.0  # seconds in real-time for a full day cycle
var time_scale: float = 1.0  # for speeding up/slowing down time

# Internal tracking
var time_accumulator: float = 0.0
var debug: bool = true

func _ready():
	print(STARTUP_MESSAGE)
	if debug: print("TimeSystem initialized on day %d (%s), %s" % [current_day, get_day_name(), get_time_name()])

func _process(delta):
	# Advance time based on real time and time scale
	time_accumulator += delta * time_scale
	
	# Calculate how much time makes up a time-of-day segment
	var segment_duration = day_duration / 4.0
	
	# Check if we need to advance time of day
	if time_accumulator >= segment_duration:
		advance_time_of_day()
		time_accumulator -= segment_duration

func advance_time_of_day():
	var old_time = current_time_of_day
	
	# Advance to the next time of day
	current_time_of_day = (current_time_of_day + 1) % 4
	
	if debug: print("Time of day changed from " + _get_time_name_from_enum(old_time) + 
		" to " + _get_time_name_from_enum(current_time_of_day))
		
	time_of_day_changed.emit(old_time, current_time_of_day)
	
	# If we went from NIGHT to MORNING, advance to the next day
	if old_time == TimeOfDay.NIGHT and current_time_of_day == TimeOfDay.MORNING:
		advance_day()

func advance_day():
	var old_day = current_day
	current_day += 1
	
	if debug: print("Day advanced from " + str(old_day) + " to " + str(current_day))
	
	# Check for week change - if the current day number divided by 7 has no remainder
	# that means we're on a new week (as we're counting from day 1)
	if current_day % 7 == 1:
		var old_week = current_week
		current_week += 1
		if debug: print("Week advanced from " + str(old_week) + " to " + str(current_week))
		week_changed.emit(old_week, current_week)
	
	day_changed.emit(old_day, current_day)
	
	# Update GameState with the new day information
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.game_data.current_day = current_day

# Manual time advancement (for testing or game mechanics)
func force_advance_time(periods: int = 1):
	for i in range(periods):
		advance_time_of_day()

func force_advance_day(days: int = 1):
	for i in range(days):
		advance_day()

# Sleep until a specific time of day
func sleep_until(target_time: TimeOfDay) -> int:
	print("Sleep until called: Current time: " + get_time_name() + ", Target time: " + _get_time_name_from_enum(target_time))
	
	var periods_to_advance = 0
	
	if target_time <= current_time_of_day:
		# Target is tomorrow (we need to go through night and into the next day)
		periods_to_advance = 4 - current_time_of_day + target_time
	else:
		# Target is today
		periods_to_advance = target_time - current_time_of_day
	
	print("Will advance " + str(periods_to_advance) + " time periods")
	
	# Actually advance the time
	for i in range(periods_to_advance):
		advance_time_of_day()
	
	print("After sleep, new time is: " + get_time_name() + ", Day: " + str(current_day) + ", Week: " + str(current_week))
	
	return periods_to_advance

# Add helper function to get the name for a TimeOfDay enum value
func _get_time_name_from_enum(time_enum: TimeOfDay) -> String:
	match time_enum:
		TimeOfDay.MORNING: return "Morning"
		TimeOfDay.AFTERNOON: return "Afternoon"
		TimeOfDay.EVENING: return "Evening" 
		TimeOfDay.NIGHT: return "Night"
		_: return "Unknown"
# Set/get time scale
func set_time_scale(new_scale: float):
	time_scale = max(0.0, new_scale)  # Ensure non-negative
	print("Time scale set to: %.2f" % time_scale)

func get_time_scale() -> float:
	return time_scale

func pause_time():
	time_scale = 0.0
	print("Time paused")

func resume_time():
	time_scale = 1.0
	print("Time resumed")

# Save/load system integration
func save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"current_week": current_week,
		"current_time_of_day": current_time_of_day,
		"time_accumulator": time_accumulator
	}

func load_data(data: Dictionary) -> void:
	if data.has("current_day"):
		current_day = data.current_day
	
	if data.has("current_week"):
		current_week = data.current_week
		
	if data.has("current_time_of_day"):
		current_time_of_day = data.current_time_of_day
		
	if data.has("time_accumulator"):
		time_accumulator = data.time_accumulator
		
	print("Loaded time data: %s" % get_formatted_date())
	
# Getters for current time info
func get_day_name() -> String:
	return days_names[(current_day - 1) % 7]

func get_time_name() -> String:
	match current_time_of_day:
		TimeOfDay.MORNING: return "Morning"
		TimeOfDay.AFTERNOON: return "Afternoon"
		TimeOfDay.EVENING: return "Evening"
		TimeOfDay.NIGHT: return "Night"
		_: return "Unknown"

func get_day_of_week() -> int:
	return (current_day - 1) % 7

func get_formatted_date() -> String:
	return "Day %d (Week %d), %s, %s" % [current_day, current_week, get_day_name(), get_time_name()]

# Save/load system integration
