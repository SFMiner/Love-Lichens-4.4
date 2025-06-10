extends Control

@onready var grades_table: GridContainer = %GradesTable
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var semester_label: Label = %SemesterLabel
@onready var gpa_label: Label = %GPALabel

const scr_debug := true
var debug := false

var grades_data: Array = []

func _ready() -> void:
	debug = scr_debug or GameController.sys_debug
	load_grades_from_csv("res://data/grades/current_grades.csv")

func load_grades_from_csv(file_path: String) -> void:
	if debug: print("GradesApp: Loading grades from ", file_path)
	
	# Clear existing grade rows (keep headers)
	clear_grade_rows()
	
	if not FileAccess.file_exists(file_path):
		if debug: print("GradesApp: Grades file not found: ", file_path)
		show_error_message("Grades file not found")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		if debug: print("GradesApp: Error opening file: ", FileAccess.get_open_error())
		show_error_message("Could not open grades file")
		return
	
	var csv_content = file.get_as_text()
	file.close()
	
	parse_csv_content(csv_content)

var column_headers: Array = []
var column_order: Dictionary = {}

func parse_csv_content(content: String) -> void:
	var lines = content.split("\n")
	grades_data.clear()
	column_headers.clear()
	column_order.clear()
	
	var header_processed = false
	
	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue
		
		var fields = parse_csv_line(line)
		
		# Process header line to determine column order
		if not header_processed:
			header_processed = true
			column_headers = fields.duplicate()
			
			# Map column names to their positions
			for i in range(fields.size()):
				var col_name = fields[i].to_lower()
				column_order[col_name] = i
			
			# Update semester info if "semester" column exists
			if column_order.has("semester") and fields.size() > column_order["semester"]:
				var semester_text = fields[column_order["semester"]]
				if semester_text != "":
					semester_label.text = semester_text
			
			update_table_headers()
			continue
		
		# Parse data rows using column mapping
		if fields.size() >= 3:
			var grade_entry = {
				"course": get_field_by_name(fields, "course"),
				"professor": get_field_by_name(fields, "professor"),
				"grade": get_field_by_name(fields, "grade"),
				"credits": get_field_by_name(fields, "credits")
			}
			grades_data.append(grade_entry)
	
	populate_grades_table()
	calculate_and_display_gpa()

func get_field_by_name(fields: Array, field_name: String) -> String:
	var col_index = column_order.get(field_name.to_lower(), -1)
	if col_index >= 0 and col_index < fields.size():
		return fields[col_index]
	return ""

func update_table_headers() -> void:
	# Update the static headers to match CSV order
	var header_nodes = [
		grades_table.get_node("HeaderCourse"),
		grades_table.get_node("HeaderProfessor"), 
		grades_table.get_node("HeaderGrade"),
		grades_table.get_node("HeaderCredits")
	]
	
	var standard_headers = ["course", "professor", "grade", "credits"]
	
	for i in range(min(4, column_headers.size())):
		if i < header_nodes.size() and i < column_headers.size():
			# Skip non-data columns like "semester"
			var header_text = column_headers[i]
			if header_text.to_lower() in standard_headers:
				header_nodes[i].text = header_text
				header_nodes[i].visible = true
			else:
				header_nodes[i].visible = false

func parse_csv_line(line: String) -> Array:
	var fields: Array = []
	var current_field = ""
	var in_quotes = false
	var i = 0
	
	while i < line.length():
		var char = line[i]
		
		if char == '"':
			in_quotes = !in_quotes
		elif char == ',' and not in_quotes:
			fields.append(current_field.strip_edges())
			current_field = ""
		else:
			current_field += char
		
		i += 1
	
	# Add the last field
	fields.append(current_field.strip_edges())
	
	return fields

func clear_grade_rows() -> void:
	# Keep only the header row (first 4 children: Course, Professor, Grade, Credits)
	var children_to_remove = []
	for i in range(4, grades_table.get_child_count()):
		children_to_remove.append(grades_table.get_child(i))
	
	for child in children_to_remove:
		grades_table.remove_child(child)
		child.queue_free()

func populate_grades_table() -> void:
	if debug: print("GradesApp: Populating table with ", grades_data.size(), " entries")
	
	for entry in grades_data:
		# Add fields in the order they appear in the CSV header
		for header in column_headers:
			var header_lower = header.to_lower()
			if header_lower in ["course", "professor", "grade", "credits"]:
				var field_value = entry.get(header_lower, "")
				var label = create_grade_label(field_value)
				
				# Apply special styling for grade column
				if header_lower == "grade":
					apply_grade_styling(label, field_value)
				if header_lower == "credits":
					label.horizontal_alignment = 1
				
				grades_table.add_child(label)

func create_grade_label(text: String) -> Label:
	var label = Label.new()
	label.text = text if text != "" else "N/A"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = 1
	label.clip_contents = true
	
	# Add some padding
	label.add_theme_color_override("font_color", Color.DARK_SLATE_GRAY)
	label.add_theme_constant_override("margin_left", 8)
	label.add_theme_constant_override("margin_right", 8)
	label.add_theme_constant_override("margin_top", 4)
	label.add_theme_constant_override("margin_bottom", 4)
	
	return label

func apply_grade_styling(label: Label, grade: String) -> void:
	# Make grade text bold
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = 1
	
	# Apply color coding based on grade
	match grade.to_upper():
		"A+", "A":
			label.add_theme_color_override("font_color", Color.GREEN)
		"A-", "B+", "B":
			label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		"B-", "C+", "C":
			label.add_theme_color_override("font_color", Color.YELLOW)
		"C-", "D+", "D":
			label.add_theme_color_override("font_color", Color.ORANGE)
		"D-", "F":
			label.add_theme_color_override("font_color", Color.RED)
		"NOT GRADED", "N/A", "":
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 14)
	


func show_error_message(message: String) -> void:
	# Clear any existing data
	clear_grade_rows()
	
	# Create error message spanning all columns
	var error_label = Label.new()
	error_label.text = "Error: " + message
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	grades_table.add_child(error_label)

# Function to calculate GPA and display it
func calculate_and_display_gpa() -> void:
	var gpa = calculate_gpa()
	var total_credits = calculate_total_credits()
	
	if gpa > 0:
		gpa_label.text = "GPA: %.2f (%.0f credits)" % [gpa, total_credits]
		
		# Color code the GPA
		if gpa >= 3.7:
			gpa_label.add_theme_color_override("font_color", Color.GREEN)
		elif gpa >= 3.0:
			gpa_label.add_theme_color_override("font_color", Color.YELLOW_GREEN)
		elif gpa >= 2.0:
			gpa_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			gpa_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		gpa_label.text = "GPA: No graded courses"
		gpa_label.add_theme_color_override("font_color", Color.GRAY)
	
	if debug: print("GradesApp: Calculated GPA: ", gpa, " with ", total_credits, " credits")

# Function to calculate total credits
func calculate_total_credits() -> float:
	var total_credits: float = 0.0
	
	for entry in grades_data:
		var credits = entry.credits.to_float()
		var grade_points = get_grade_points(entry.grade)
		
		# Only count credits for graded courses
		if grade_points >= 0 and credits > 0:
			total_credits += credits
	
	return total_credits

# Function to calculate GPA (updated with better logic)
func calculate_gpa() -> float:
	var total_points: float = 0.0
	var total_credits: float = 0.0
	
	for entry in grades_data:
		var grade_points = get_grade_points(entry.grade)
		var credits = entry.credits.to_float()
		
		if debug: print("GradesApp: Processing - Course: ", entry.course, ", Grade: ", entry.grade, ", Points: ", grade_points, ", Credits: ", credits)
		
		# Only include graded courses in GPA calculation
		if grade_points >= 0 and credits > 0:
			total_points += grade_points * credits
			total_credits += credits
			if debug: print("GradesApp: Added to GPA - Points: ", grade_points * credits, ", Credits: ", credits)
	
	if debug: print("GradesApp: Total points: ", total_points, ", Total credits: ", total_credits)
	return total_points / total_credits if total_credits > 0 else 0.0

func get_grade_points(grade: String) -> float:
	match grade.to_upper().strip_edges():
		"A+": return 4.0
		"A": return 4.0
		"A-": return 3.7
		"B+": return 3.3
		"B": return 3.0
		"B-": return 2.7
		"C+": return 2.3
		"C": return 2.0
		"C-": return 1.7
		"D+": return 1.3
		"D": return 1.0
		"D-": return 0.7
		"F": return 0.0
		"NOT GRADED", "N/A", "": return -1.0  # Not graded or invalid
		_: 
			if debug: print("GradesApp: Unknown grade format: '", grade, "'")
			return -1.0

# Function to refresh grades (can be called from external systems)
func refresh_grades() -> void:
	load_grades_from_csv("res://data/grades/current_grades.csv")

# Function to load different semester grades
func load_semester_grades(semester: String) -> void:
	var file_path = "res://data/grades/" + semester + "_grades.csv"
	load_grades_from_csv(file_path)

# Get detailed GPA breakdown for debugging or display
func get_gpa_breakdown() -> Dictionary:
	var breakdown = {
		"total_gpa_points": 0.0,
		"total_credits": 0.0,
		"gpa": 0.0,
		"graded_courses": 0,
		"ungraded_courses": 0,
		"course_details": []
	}
	
	for entry in grades_data:
		var grade_points = get_grade_points(entry.grade)
		var credits = entry.credits.to_float()
		
		var course_detail = {
			"course": entry.course,
			"grade": entry.grade,
			"credits": credits,
			"grade_points": grade_points,
			"quality_points": 0.0,
			"counted_in_gpa": false
		}
		
		if grade_points >= 0 and credits > 0:
			course_detail.quality_points = grade_points * credits
			course_detail.counted_in_gpa = true
			breakdown.total_gpa_points += course_detail.quality_points
			breakdown.total_credits += credits
			breakdown.graded_courses += 1
		else:
			breakdown.ungraded_courses += 1
		
		breakdown.course_details.append(course_detail)
	
	breakdown.gpa = breakdown.total_gpa_points / breakdown.total_credits if breakdown.total_credits > 0 else 0.0
	
	return breakdown

# Get save data for phone app persistence
func get_save_data() -> Dictionary:
	return {
		"last_loaded_semester": semester_label.text,
		"grades_data": grades_data
	}

# Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("last_loaded_semester"):
		semester_label.text = data["last_loaded_semester"]
	
	if data.has("grades_data"):
		grades_data = data["grades_data"]
		populate_grades_table()
