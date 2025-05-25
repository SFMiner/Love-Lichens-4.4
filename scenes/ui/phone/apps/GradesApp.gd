extends Control

@onready var grades_table: GridContainer = $GradesTable

func _ready():
    load_grades_from_file("res://data/grades/year1_sem1_grades.json")

func load_grades_from_file(file_path: String):
    # Clear existing data rows (keep headers - first 3 children)
    # Iterate from the last child to just after the headers (index 2).
    # The header children are at indices 0, 1, 2.
    for i in range(grades_table.get_child_count() - 1, 2, -1):
        var child = grades_table.get_child(i)
        grades_table.remove_child(child)
        child.queue_free() # Important to free the node from memory

    if not FileAccess.file_exists(file_path):
        print("Error: Grades file not found: ", file_path)
        # Optionally, display an error message in the UI
        var error_label = Label.new()
        error_label.text = "Error: Could not load grades data."
        error_label.size_flags_horizontal = 3
        # Make it span all columns if the table has columns set
        if grades_table.columns > 0:
             error_label.set("theme_override_constants/max_columns", grades_table.columns)
        grades_table.add_child(error_label)
        return

    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null: # Check if FileAccess.open returned null (error)
        print("Error opening file: " + str(FileAccess.get_open_error()) + " at path: " + file_path)
        return
        
    var content = file.get_as_text()
    file.close() # Ensure file is closed after reading

    var parse_result = JSON.parse_string(content)

    if parse_result == null: # JSON.parse_string returns null on error
        print("Error parsing JSON from grades file: ", file_path)
        # Optionally, display an error message in the UI
        var error_label = Label.new()
        error_label.text = "Error: Could not parse grades data."
        error_label.size_flags_horizontal = 3
        if grades_table.columns > 0:
             error_label.set("theme_override_constants/max_columns", grades_table.columns)
        grades_table.add_child(error_label)
        return

    if typeof(parse_result) == TYPE_ARRAY:
        for entry in parse_result:
            if typeof(entry) == TYPE_DICTIONARY:
                var course_label = Label.new()
                course_label.text = entry.get("course", "N/A") # Use .get with default for safety
                course_label.size_flags_horizontal = 3
                grades_table.add_child(course_label)

                var prof_label = Label.new()
                prof_label.text = entry.get("professor", "N/A")
                prof_label.size_flags_horizontal = 3
                grades_table.add_child(prof_label)

                var grade_label = Label.new()
                grade_label.text = entry.get("grade", "N/A")
                grade_label.size_flags_horizontal = 3
                grades_table.add_child(grade_label)
            else:
                print("Warning: Invalid entry type in grades JSON array. Entry: ", entry)
    else:
        print("Error: Grades JSON content is not an array. Content type: ", typeof(parse_result))
        # Optionally, display an error message in the UI
        var error_label = Label.new()
        error_label.text = "Error: Grades data is malformed."
        error_label.size_flags_horizontal = 3
        if grades_table.columns > 0:
             error_label.set("theme_override_constants/max_columns", grades_table.columns)
        grades_table.add_child(error_label)
