class_name SaveDataMigrator
extends RefCounted

# Save data migration system for Love & Lichens
# Handles converting old save formats to current version

const CURRENT_VERSION = 2

# Migrate save data from any version to current
static func migrate_save_data(data: Dictionary) -> Dictionary:
	if not data.has("save_format_version"):
		# Version 1 didn't have version field
		data["save_format_version"] = 1

	var version = data.get("save_format_version", 1)

	# Apply migrations sequentially
	while version < CURRENT_VERSION:
		data = _migrate_to_next_version(data, version)
		version += 1
		data["save_format_version"] = version

	return data

# Migrate from one version to the next
static func _migrate_to_next_version(data: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		1:
			return _migrate_v1_to_v2(data)
		# Add more migrations as needed
		_:
			push_warning("Unknown save version: " + str(from_version))
			return data

# Migrate from version 1 to version 2
static func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	# Fix the navigation typo issue
	if data.has("navigtion"):
		data["navigation"] = data["navigtion"]
		data.erase("navigtion")

	# Add any new required fields
	if not data.has("play_time"):
		data["play_time"] = 0

	# Add pickup system data if missing
	if not data.has("pickup_system"):
		data["pickup_system"] = {}

	return data

# Validate save data structure
static func validate_save_data(data: Dictionary) -> bool:
	# Check for required fields
	var required_fields = ["save_format_version", "save_date"]
	for field in required_fields:
		if not data.has(field):
			push_error("Save data missing required field: " + field)
			return false

	return true
