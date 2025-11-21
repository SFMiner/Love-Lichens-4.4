extends Node

# Centralized debug printing system
# Respects both global sys_debug and individual scr_debug settings

# Print debug message if debugging is enabled
static func print_debug(source: Object, method: String, message: String) -> void:
	var should_print = false

	# Check global debug setting
	if "sys_debug" in GameController and GameController.sys_debug:
		should_print = true

	# Check script-level debug setting
	if source.get("scr_debug"):
		should_print = true

	if should_print:
		print(GameState.script_name_tag(source, method) + message)

# Print warning (always shows)
static func print_warning(source: Object, method: String, message: String) -> void:
	push_warning(GameState.script_name_tag(source, method) + message)

# Print error (always shows)
static func print_error(source: Object, method: String, message: String) -> void:
	push_error(GameState.script_name_tag(source, method) + message)
