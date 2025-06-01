extends Node
class_name MemoryTagLinter

# Data structures to hold parsed information
var memory_tags = {}  # tag_name -> {file: "", step_id: "", description: ""}
var dialogue_tag_checks = {}  # tag_name -> [file_paths...]
var dialogue_tag_sets = {}  # tag_name -> [file_paths...]
var character_features = {}  # feature_id -> {character: "", target_id: "", memory_tag: ""}
var look_at_targets = {}  # target_id -> {file: "", step_id: "", description: ""}

# File paths
const MEMORY_DIR = "res://data/memories/"
const DIALOGUE_DIR = "res://data/dialogues/"
const CHARACTER_DIR = "res://data/characters/"
const QUEST_DIR = "res://data/quests/"
const MEMORY_SCAN_DIRS := [MEMORY_DIR, CHARACTER_DIR]
const ALL_DATA_DIRS := [MEMORY_DIR, CHARACTER_DIR, DIALOGUE_DIR, QUEST_DIR]

const scr_debug : bool = false
var debug 

func _ready():
	debug = scr_debug or GameController.sys_debug

func _run():
	var _fname = "_run"
	if debug: print(GameState.script_name_tag(self, _fname) + "🔍 Starting Memory Tag Linter...")
	if debug: print(GameState.script_name_tag(self, _fname) + "=".repeat(60))
	
	# Clear previous data
	_clear_data()
	
	# Collect data from all sources
	_collect_memory_tags()
	_parse_dialogue_files()
	_parse_character_files()
	
	# Export memory registry to JSON file
	_export_memory_registry()
	
	# Generate validation report
	_generate_report()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "🏁 Linting complete!")

func _clear_data():
	var _fname = "_clear_data"
	memory_tags.clear()
	dialogue_tag_checks.clear()
	dialogue_tag_sets.clear()
	character_features.clear()
	look_at_targets.clear()

# ============================================================================
# MEMORY TAG COLLECTION
# ============================================================================

func _collect_memory_tags():
	var _fname = "_collect_memory_tags"
	if debug: print(GameState.script_name_tag(self, _fname) + "📁 Collecting memory tags from memory and character files...")

	var files_found := []
	var dir : DirAccess  # Declare outside the loop for compatibility

	for dir_path in MEMORY_SCAN_DIRS:
		dir = DirAccess.open(dir_path)
		if not dir:
			if debug: print(GameState.script_name_tag(self, _fname) + "❌ Could not open directory: " + dir_path)
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json") and not dir.current_is_dir():
				files_found.append(dir_path + file_name)
			file_name = dir.get_next()

	if debug: print(GameState.script_name_tag(self, _fname) + "   🔍 Found " + str(files_found.size()) + " JSON files: " + str(files_found))

	for file_path in files_found:
		_parse_memory_file(file_path)

	if debug: print(GameState.script_name_tag(self, _fname) + "   📊 Total memory tags collected: " + str(memory_tags.size()))

func _parse_memory_file(file_path: String):
	var _fname = "_parse_memory_file"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Could not open file: " + file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Failed to parse JSON: " + file_path + " - " + json.get_error_message())
		return
	
	var data = json.data
	if debug: print(GameState.script_name_tag(self, _fname) + "   📄 Processing: " + file_path.get_file() + " (type: " + str(typeof(data)) + ")")
	
	# Handle different JSON root structures
	if typeof(data) == TYPE_ARRAY:
		# Array format (like poison.json)
		if debug: print(GameState.script_name_tag(self, _fname) + "      📋 Array format detected")
		for item in data:
			if typeof(item) == TYPE_DICTIONARY:
				_parse_memory_chain_item(item, file_path)
	elif typeof(data) == TYPE_DICTIONARY:
		if "memory_chains" in data:
			if debug: print(GameState.script_name_tag(self, _fname) + "      📚 Character memory_chains format detected")
			var character_id = data.get("id", "")
			for chain in data.memory_chains:
				if typeof(chain) == TYPE_DICTIONARY:
					if not chain.has("character_id"):
						chain["character_id"] = character_id
					_parse_memory_chain_item(chain, file_path)
		else:
			if debug: print(GameState.script_name_tag(self, _fname) + "      📝 Individual memories format detected")
			for memory_id in data:
				if memory_id.begins_with("_"):
					continue
				var memory_data = data[memory_id]
				if typeof(memory_data) == TYPE_DICTIONARY:
					_extract_tags_from_step(memory_data, file_path, memory_id)
					if memory_data.get("trigger_type", -1) == 0:
						var target_id = memory_data.get("target_id", "")
						if target_id != "":
							look_at_targets[target_id] = {
								"file": file_path,
								"step_id": memory_id,
								"description": memory_data.get("description", "")
							}
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Unsupported JSON format in: " + file_path)

func _parse_memory_chain_item(chain_item: Dictionary, file_path: String):
	var _fname = "_parse_memory_chain_item"
	var chain_id = chain_item.get("id", "unknown_chain")
	if debug: print(GameState.script_name_tag(self, _fname) + "      🔗 Processing chain: " + chain_id)
	
	# Extract tags from the chain item itself
	_extract_tags_from_step(chain_item, file_path, chain_id)
	
	# Process steps if they exist
	if chain_item.has("steps"):
		var steps = chain_item.steps
		if typeof(steps) == TYPE_ARRAY:
			var char_id = chain_item.get("character_id", "")
			if debug: print(GameState.script_name_tag(self, _fname) + "in step of spes loop, looking at chatracter_id:", char_id)
			for step in steps:
				if typeof(step) == TYPE_DICTIONARY:
					var step_id = step.get("id", "unknown_step")

					# Inject character_id if not already present
					if not "character_id" in step:
						step["character_id"] = char_id

					_extract_tags_from_step(step, file_path, chain_id + "." + step_id)

func _extract_tags_from_step(step_data: Dictionary, file_path: String, step_id: String):
	var _fname = "_extract_tags_from_step"
	# Handle unlock_tag as either string or array
	var unlock_tags = []
	var unlock_tag_value = step_data.get("unlock_tag", "")
	
	if typeof(unlock_tag_value) == TYPE_STRING and unlock_tag_value != "":
		unlock_tags.append(unlock_tag_value)
	elif typeof(unlock_tag_value) == TYPE_ARRAY:
		for tag in unlock_tag_value:
			if typeof(tag) == TYPE_STRING and tag != "":
				unlock_tags.append(tag)
	
	# Also check for completed_tag (used in some chain formats)
	var completed_tag = step_data.get("completed_tag", "")
	if typeof(completed_tag) == TYPE_STRING and completed_tag != "":
		unlock_tags.append(completed_tag)
	elif typeof(completed_tag) == TYPE_ARRAY:
		for tag in completed_tag:
			if typeof(tag) == TYPE_STRING and tag != "":
				unlock_tags.append(tag)
	
	# Store all found tags
	for tag in unlock_tags:
		if tag != "":
			memory_tags[tag] = {
				"file": file_path,
				"step_id": step_id,
				"description": step_data.get("description", ""),
				"trigger_type": step_data.get("trigger_type", -1),
				"target_id": step_data.get("target_id", ""),
				"character_id": step_data.get("character_id", ""),
				"dialogue_title": step_data.get("dialogue_title", ""),
				"condition_tags": step_data.get("condition_tags", [])
			}
			if debug: print(GameState.script_name_tag(self, _fname) + "      🏷️  Found tag: " + tag)

# ============================================================================
# MEMORY REGISTRY EXPORT
# ============================================================================

func _export_memory_registry():
	var _fname = "_export_memory_registry"
	if debug: print(GameState.script_name_tag(self, _fname) + "📄 Exporting memory tag registry...")
	
	var registry = {}
	
	# Clean and format the memory tags data
	for tag_name in memory_tags:
		var memory_data = memory_tags[tag_name]
		
		# Create cleaned entry with only relevant fields
		var registry_entry = {
			"trigger_type": memory_data.get("trigger_type", -1),
			"target_id": memory_data.get("target_id", ""),
			"description": memory_data.get("description", ""),
			"character_id": memory_data.get("character_id", ""),
			"condition_tags": memory_data.get("condition_tags", [])
		}
		
		# Only include dialogue_title if it exists and is not empty
		var dialogue_title = memory_data.get("dialogue_title", "")
		if dialogue_title != "":
			registry_entry["dialogue_title"] = dialogue_title
		
		registry[tag_name] = registry_entry
	
	# Convert to JSON and save
	var json_string = JSON.stringify(registry, "\t")
	var file = FileAccess.open("res://data/generated/memory_tag_registry.json", FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		print(GameState.script_name_tag(self, _fname) + "   ✅ Memory registry saved to: memory_tag_registry.json")
		print(GameState.script_name_tag(self, _fname) + "   📊 Exported " + str(registry.size()) + " memory tags")
	else:
		print(GameState.script_name_tag(self, _fname) + "   ❌ Failed to create memory_tag_registry.json file")

# ============================================================================
# DIALOGUE FILE PARSING
# ============================================================================

func _parse_dialogue_files():
	var _fname = "_parse_dialogue_files"
	if debug: print(GameState.script_name_tag(self, _fname) + "💬 Parsing dialogue files for tag usage...")
	
	var dir = DirAccess.open(DIALOGUE_DIR)
	if not dir:
		if debug: print(GameState.script_name_tag(self, _fname) + "❌ Could not open dialogue directory: " + DIALOGUE_DIR)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".dialogue") and not dir.current_is_dir():
			var file_path = DIALOGUE_DIR + file_name
			_parse_dialogue_file(file_path)
		file_name = dir.get_next()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "   Found " + str(dialogue_tag_checks.size()) + " tag checks")
	if debug: print(GameState.script_name_tag(self, _fname) + "   Found " + str(dialogue_tag_sets.size()) + " tag sets")

func _parse_dialogue_file(file_path: String):
	var _fname = "_parse_dialogue_file"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Could not open dialogue file: " + file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Parse tag checks: [if DialogSystem.can_unlock("tag_name")]
	var check_regex = RegEx.new()
	check_regex.compile('\\[if\\s+DialogSystem\\.can_unlock\\s*\\(\\s*["\']([^"\']+)["\']\\s*\\)\\]')
	
	var check_results = check_regex.search_all(content)
	for result in check_results:
		var tag_name = result.get_string(1)
		if not dialogue_tag_checks.has(tag_name):
			dialogue_tag_checks[tag_name] = []
		dialogue_tag_checks[tag_name].append(file_path)
	
	# Parse tag sets: do DialogSystem.unlock_memory("tag_name")
	var set_regex1 = RegEx.new()
	set_regex1.compile('do\\s+DialogSystem\\.unlock_memory\\s*\\(\\s*["\']([^"\']+)["\']\\s*\\)')
	
	var set_results1 = set_regex1.search_all(content)
	for result in set_results1:
		var tag_name = result.get_string(1)
		if not dialogue_tag_sets.has(tag_name):
			dialogue_tag_sets[tag_name] = []
		dialogue_tag_sets[tag_name].append(file_path)
	
	# Parse tag sets: do GameState.set_tag("tag_name")
	var set_regex2 = RegEx.new()
	set_regex2.compile('do\\s+GameState\\.set_tag\\s*\\(\\s*["\']([^"\']+)["\']\\s*\\)')
	
	var set_results2 = set_regex2.search_all(content)
	for result in set_results2:
		var tag_name = result.get_string(1)
		if not dialogue_tag_sets.has(tag_name):
			dialogue_tag_sets[tag_name] = []
		dialogue_tag_sets[tag_name].append(file_path)

# ============================================================================
# CHARACTER FILE PARSING
# ============================================================================

func _parse_character_files():
	var _fname = "_parse_character_files"
	if debug: print(GameState.script_name_tag(self, _fname) + "👥 Parsing character files for observable features...")
	
	var dir = DirAccess.open(CHARACTER_DIR)
	if not dir:
		if debug: print(GameState.script_name_tag(self, _fname) + "❌ Could not open character directory: " + CHARACTER_DIR)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var file_path = CHARACTER_DIR + file_name
			_parse_character_file(file_path)
		file_name = dir.get_next()
	
	if debug: print(GameState.script_name_tag(self, _fname) + "   Found " + str(character_features.size()) + " observable features")

func _parse_character_file(file_path: String):
	var _fname = "_parse_character_file"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Could not open character file: " + file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		if debug: print(GameState.script_name_tag(self, _fname) + "⚠️  Failed to parse character JSON: " + file_path)
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	var character_id = data.get("id", "")
	var observable_features = data.get("observable_features", {})
	
	for feature_id in observable_features:
		var feature = observable_features[feature_id]
		if typeof(feature) == TYPE_DICTIONARY:
			var memory_tag = feature.get("memory_tag", "")
			var target_id = character_id + "_" + feature_id  # Typical pattern
			
			character_features[feature_id] = {
				"character": character_id,
				"target_id": target_id,
				"memory_tag": memory_tag,
				"description": feature.get("description", ""),
				"file": file_path
			}

# ============================================================================
# REPORT GENERATION
# ============================================================================

func _generate_report():
	var _fname = "_generate_report"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n📊 VALIDATION REPORT")
	if debug: print(GameState.script_name_tag(self, _fname) + "=".repeat(60))
	
	# Collect all tag names from all sources
	var all_dialogue_tags = {}
	for tag in dialogue_tag_checks:
		all_dialogue_tags[tag] = true
	for tag in dialogue_tag_sets:
		all_dialogue_tags[tag] = true
	
	# Report: Valid tags
	_report_valid_tags(all_dialogue_tags)
	
	# Report: Tags used in dialogue but missing from memory files
	_report_missing_memory_tags(all_dialogue_tags)
	
	# Report: Tags defined in memory files but unused
	_report_unused_memory_tags(all_dialogue_tags)
	
	# Report: Observable features without matching LOOK_AT targets
	_report_unmatched_features()
	
	# Summary statistics
	_report_summary()

func _report_valid_tags(all_dialogue_tags: Dictionary):
	var _fname = "_report_valid_tags"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n✅ VALID TAGS")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	
	var valid_count = 0
	for tag in all_dialogue_tags:
		if memory_tags.has(tag):
			valid_count += 1
			var memory_info = memory_tags[tag]
			if debug: print(GameState.script_name_tag(self, _fname) + "   " + tag + " (" + memory_info.file.get_file() + ")")
	
	if valid_count == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   No valid tags found")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "   Total: " + str(valid_count) + " valid tags")

func _report_missing_memory_tags(all_dialogue_tags: Dictionary):
	var _fname = "_report_missing_memory_tags"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n⚠️  TAGS USED IN DIALOGUE BUT MISSING FROM MEMORY FILES")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	
	var missing_count = 0
	for tag in all_dialogue_tags:
		if not memory_tags.has(tag):
			missing_count += 1
			if debug: print(GameState.script_name_tag(self, _fname) + "   ❌ " + tag)
			
			# Show where it's used
			if dialogue_tag_checks.has(tag):
				for file_path in dialogue_tag_checks[tag]:
					if debug: print(GameState.script_name_tag(self, _fname) + "      🔍 Checked in: " + file_path.get_file())
			
			if dialogue_tag_sets.has(tag):
				for file_path in dialogue_tag_sets[tag]:
					if debug: print(GameState.script_name_tag(self, _fname) + "      ✏️  Set in: " + file_path.get_file())
	
	if missing_count == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ✅ All dialogue tags have corresponding memory definitions")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "   Total: " + str(missing_count) + " missing tags")

func _report_unused_memory_tags(all_dialogue_tags: Dictionary):
	var _fname = "_report_unused_memory_tags"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n⚠️  TAGS DEFINED IN MEMORY FILES BUT UNUSED")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	
	var unused_count = 0
	for tag in memory_tags:
		if not all_dialogue_tags.has(tag):
			unused_count += 1
			var memory_info = memory_tags[tag]
			if debug: print(GameState.script_name_tag(self, _fname) + "   🗃️  " + tag)
			if debug: print(GameState.script_name_tag(self, _fname) + "      📁 Defined in: " + memory_info.file.get_file() + " (" + memory_info.step_id + ")")
			if memory_info.description != "":
				if debug: print(GameState.script_name_tag(self, _fname) + "      📝 Description: " + memory_info.description)
	
	if unused_count == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ✅ All memory tags are used in dialogue")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "   Total: " + str(unused_count) + " unused tags")

func _report_unmatched_features():
	var _fname = "_report_unmatched_features"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n🧩 OBSERVABLE FEATURES WITHOUT MATCHING LOOK_AT TARGETS")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	
	var unmatched_count = 0
	for feature_id in character_features:
		var feature = character_features[feature_id]
		var target_id = feature.target_id
		
		# Check if there's a LOOK_AT target for this feature
		var found_target = false
		
		# Try multiple target ID patterns
		var target_patterns = [
			target_id,
			feature.character + "_" + feature_id,
			feature.character + target_id,
			feature_id
		]
		
		for pattern in target_patterns:
			if look_at_targets.has(pattern):
				found_target = true
				break
		
		if not found_target:
			unmatched_count += 1
			if debug: print(GameState.script_name_tag(self, _fname) + "   🔍 " + feature_id + " (character: " + feature.character + ")")
			if debug: print(GameState.script_name_tag(self, _fname) + "      📁 Defined in: " + feature.file.get_file())
			if debug: print(GameState.script_name_tag(self, _fname) + "      🎯 Expected target_id: " + target_id)
			if feature.memory_tag != "":
				if debug: print(GameState.script_name_tag(self, _fname) + "      🏷️  Memory tag: " + feature.memory_tag)
			if feature.description != "":
				if debug: print(GameState.script_name_tag(self, _fname) + "      📝 Description: " + feature.description)
	
	if unmatched_count == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ✅ All observable features have matching LOOK_AT targets")
	else:
		if debug: print(GameState.script_name_tag(self, _fname) + "   Total: " + str(unmatched_count) + " unmatched features")

func _report_summary():
	var _fname = "_report_summary"
	if debug: print(GameState.script_name_tag(self, _fname) + "\n📈 SUMMARY")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	if debug: print(GameState.script_name_tag(self, _fname) + "   Memory tags defined: " + str(memory_tags.size()))
	if debug: print(GameState.script_name_tag(self, _fname) + "   Tags checked in dialogue: " + str(dialogue_tag_checks.size()))
	if debug: print(GameState.script_name_tag(self, _fname) + "   Tags set in dialogue: " + str(dialogue_tag_sets.size()))
	if debug: print(GameState.script_name_tag(self, _fname) + "   Observable features: " + str(character_features.size()))
	if debug: print(GameState.script_name_tag(self, _fname) + "   LOOK_AT targets: " + str(look_at_targets.size()))
	
	# Calculate health metrics
	var all_dialogue_tags = {}
	for tag in dialogue_tag_checks:
		all_dialogue_tags[tag] = true
	for tag in dialogue_tag_sets:
		all_dialogue_tags[tag] = true
	
	var valid_tags = 0
	var missing_tags = 0
	var unused_tags = 0
	
	for tag in all_dialogue_tags:
		if memory_tags.has(tag):
			valid_tags += 1
		else:
			missing_tags += 1
	
	for tag in memory_tags:
		if not all_dialogue_tags.has(tag):
			unused_tags += 1
	
	if debug: print(GameState.script_name_tag(self, _fname) + "\n🎯 HEALTH METRICS")
	if debug: print(GameState.script_name_tag(self, _fname) + "-".repeat(30))
	if all_dialogue_tags.size() > 0:
		var health_percentage = (valid_tags * 100) / all_dialogue_tags.size()
		if debug: print(GameState.script_name_tag(self, _fname) + "   Tag consistency: " + str(health_percentage) + "%")
	
	if missing_tags == 0 and unused_tags == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   🎉 Perfect! All tags are properly defined and used.")
	elif missing_tags == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ✅ All dialogue tags are properly defined")
	elif unused_tags == 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ✅ All memory tags are being used")
	
	if missing_tags > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ⚠️  " + str(missing_tags) + " tags need memory definitions")
	if unused_tags > 0:
		if debug: print(GameState.script_name_tag(self, _fname) + "   ℹ️  " + str(unused_tags) + " tags could be cleaned up (unused)")
