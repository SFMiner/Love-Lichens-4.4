class_name ErrorHandler
extends RefCounted

# Standardized error handling for Love & Lichens

enum ErrorLevel { INFO, WARNING, ERROR, CRITICAL }

# Log an error with appropriate severity
static func log_error(level: ErrorLevel, source: String, message: String) -> void:
	var prefix := ""
	match level:
		ErrorLevel.INFO:
			prefix = "[INFO]"
		ErrorLevel.WARNING:
			prefix = "[WARN]"
		ErrorLevel.ERROR:
			prefix = "[ERROR]"
		ErrorLevel.CRITICAL:
			prefix = "[CRITICAL]"

	var full_message := "%s %s: %s" % [prefix, source, message]

	match level:
		ErrorLevel.INFO:
			print(full_message)
		ErrorLevel.WARNING:
			push_warning(full_message)
		ErrorLevel.ERROR:
			push_error(full_message)
		ErrorLevel.CRITICAL:
			push_error(full_message)
			# Could trigger safe shutdown or recovery here

# Validate that a node exists
static func validate_node(node: Node, expected_path: String, source: String) -> bool:
	if not node:
		log_error(ErrorLevel.ERROR, source, "Node not found at path: " + expected_path)
		return false
	return true

# Validate that an object has a required method
static func validate_method(obj: Object, method_name: String, source: String) -> bool:
	if not obj:
		log_error(ErrorLevel.ERROR, source, "Cannot validate method on null object")
		return false
	if not obj.has_method(method_name):
		log_error(ErrorLevel.WARNING, source, "Object missing expected method: " + method_name)
		return false
	return true
