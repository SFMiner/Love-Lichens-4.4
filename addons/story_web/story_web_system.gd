# story_web_system.gd
@tool
extends Node

# Story Web System for Love & Lichens
# Tracks relationships between story elements, characters, and quest arcs

signal element_added(element_id, element_data)
signal element_updated(element_id, element_data)
signal element_removed(element_id)
signal connection_added(from_id, to_id, connection_data)
signal connection_updated(from_id, to_id, connection_data)
signal connection_removed(from_id, to_id)
signal tag_added(tag_name)
signal tag_removed(tag_name)

# Categories of story elements
enum ElementType {
	CHARACTER,
	QUEST,
	LOCATION,
	ITEM,
	EVENT,
	KNOWLEDGE,
	NOTE
}

# Types of connections between elements
enum ConnectionType {
	AFFECTS,           # One element directly affects another
	DEPENDS_ON,        # Element depends on another to progress
	REVEALS,           # Element reveals information about another
	FORESHADOWS,       # Element hints at or foreshadows another
	CONTRADICTS,       # Elements contradict each other
	RELATED_TO         # General relationship
}

# The main data structure - Dictionary of all story elements
# Key: element_id, Value: element data
var story_elements = {}

# Connections between elements
# Dict structure: {from_id: {to_id: {connection_data}}}
var connections = {}

# Tags for categorizing and filtering
var tags = {}

# Counter for generating unique IDs
var next_id = 0

# File paths for saving/loading
const SAVE_FOLDER = "user://story_web/"
const ELEMENTS_FILE = "elements.json"
const CONNECTIONS_FILE = "connections.json"
const TAGS_FILE = "tags.json"

func _ready():
	print("Story Web System initialized")
	# Create save directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists_absolute(SAVE_FOLDER):
		dir.make_dir_absolute(SAVE_FOLDER)
	
	# Load data
	load_data()

# Add a new story element
func add_element(element_type, title, description="", tags_array=[], metadata={}):
	var element_id = _generate_id()
	
	var element = {
		"id": element_id,
		"type": element_type,
		"title": title,
		"description": description,
		"tags": tags_array.duplicate(),
		"metadata": metadata.duplicate(),
		"creation_date": Time.get_datetime_dict_from_system(),
		"last_modified": Time.get_datetime_dict_from_system()
	}
	
	story_elements[element_id] = element
	
	# Add any new tags to the tag system
	for tag in tags_array:
		if not tags.has(tag):
			tags[tag] = {"elements": [element_id]}
			tag_added.emit(tag)
		else:
			tags[tag]["elements"].append(element_id)
	
	# Emit signal
	element_added.emit(element_id, element)
	save_data()
	
	return element_id

# Update an existing story element
func update_element(element_id, new_data):
	if not story_elements.has(element_id):
		print("ERROR: Cannot update non-existent element: ", element_id)
		return false
	
	var element = story_elements[element_id]
	
	# Update basic properties
	if new_data.has("title"):
		element.title = new_data.title
	
	if new_data.has("description"):
		element.description = new_data.description
	
	if new_data.has("metadata"):
		element.metadata = new_data.metadata.duplicate()
	
	# Handle tag updates if present
	if new_data.has("tags"):
		# Remove this element from all its current tags
		for tag in element.tags:
			if tags.has(tag) and tag in tags[tag]["elements"]:
				tags[tag]["elements"].erase(element_id)
				
				# Remove tag if no longer used
				if tags[tag]["elements"].size() == 0:
					tags.erase(tag)
					tag_removed.emit(tag)
		
		# Set the new tags
		element.tags = new_data.tags.duplicate()
		
		# Add this element to all its new tags
		for tag in element.tags:
			if not tags.has(tag):
				tags[tag] = {"elements": [element_id]}
				tag_added.emit(tag)
			else:
				if not element_id in tags[tag]["elements"]:
					tags[tag]["elements"].append(element_id)
	
	# Update modification timestamp
	element.last_modified = Time.get_datetime_dict_from_system()
	
	# Emit signal
	element_updated.emit(element_id, element)
	save_data()
	
	return true

# Remove a story element
func remove_element(element_id):
	if not story_elements.has(element_id):
		print("ERROR: Cannot remove non-existent element: ", element_id)
		return false
	
	var element = story_elements[element_id]
	
	# Remove from tags
	for tag in element.tags:
		if tags.has(tag) and element_id in tags[tag]["elements"]:
			tags[tag]["elements"].erase(element_id)
			
			# Remove tag if no longer used
			if tags[tag]["elements"].size() == 0:
				tags.erase(tag)
				tag_removed.emit(tag)
	
	# Remove all connections involving this element
	if connections.has(element_id):
		var to_connections = connections[element_id].duplicate()
		for to_id in to_connections:
			remove_connection(element_id, to_id)
		connections.erase(element_id)
	
	# Remove incoming connections from other elements
	for from_id in connections:
		if connections[from_id].has(element_id):
			remove_connection(from_id, element_id)
	
	# Remove the element itself
	story_elements.erase(element_id)
	
	# Emit signal
	element_removed.emit(element_id)
	save_data()
	
	return true

# Add a connection between elements
func add_connection(from_id, to_id, connection_type, description="", metadata={}):
	if not story_elements.has(from_id) or not story_elements.has(to_id):
		print("ERROR: Cannot connect non-existent elements")
		return false
	
	# Initialize connection dictionaries if needed
	if not connections.has(from_id):
		connections[from_id] = {}
	
	# Create the connection data
	var connection_data = {
		"type": connection_type,
		"description": description,
		"metadata": metadata.duplicate(),
		"creation_date": Time.get_datetime_dict_from_system(),
		"last_modified": Time.get_datetime_dict_from_system()
	}
	
	# Store the connection
	connections[from_id][to_id] = connection_data
	
	# Emit signal
	connection_added.emit(from_id, to_id, connection_data)
	save_data()
	
	return true

# Update an existing connection
func update_connection(from_id, to_id, new_data):
	if not connections.has(from_id) or not connections[from_id].has(to_id):
		print("ERROR: Connection does not exist")
		return false
	
	var connection = connections[from_id][to_id]
	
	# Update properties
	if new_data.has("type"):
		connection.type = new_data.type
	
	if new_data.has("description"):
		connection.description = new_data.description
	
	if new_data.has("metadata"):
		connection.metadata = new_data.metadata.duplicate()
	
	# Update modification timestamp
	connection.last_modified = Time.get_datetime_dict_from_system()
	
	# Emit signal
	connection_updated.emit(from_id, to_id, connection)
	save_data()
	
	return true

# Remove a connection
func remove_connection(from_id, to_id):
	if not connections.has(from_id) or not connections[from_id].has(to_id):
		print("ERROR: Connection does not exist")
		return false
	
	# Remove the connection
	connections[from_id].erase(to_id)
	
	# Remove the from_id entry if it has no more connections
	if connections[from_id].size() == 0:
		connections.erase(from_id)
	
	# Emit signal
	connection_removed.emit(from_id, to_id)
	save_data()
	
	return true

# Get a story element by ID
func get_element(element_id):
	if story_elements.has(element_id):
		return story_elements[element_id]
	return null

# Get all connections from an element
func get_outgoing_connections(element_id):
	if connections.has(element_id):
		return connections[element_id]
	return {}

# Get all connections (to match parent signature)
func get_incoming_connections() -> Array[Dictionary]:
	var incoming_array = []
	
	for from_id in connections:
		for to_id in connections[from_id]:
			incoming_array.append({
				"from_id": from_id,
				"to_id": to_id,
				"connection": connections[from_id][to_id]
			})
	
	return incoming_array

# Get all connections to an element (custom method)
func get_incoming_connections_for_element(element_id):
	var incoming = {}
	
	for from_id in connections:
		if connections[from_id].has(element_id):
			incoming[from_id] = connections[from_id][element_id]
	
	return incoming

# Get elements by tag
func get_elements_by_tag(tag_name):
	if not tags.has(tag_name):
		return []
	
	var elements = []
	for element_id in tags[tag_name]["elements"]:
		if story_elements.has(element_id):
			elements.append(story_elements[element_id])
	
	return elements

# Get elements by type
func get_elements_by_type(element_type):
	var elements = []
	
	for element_id in story_elements:
		if story_elements[element_id].type == element_type:
			elements.append(story_elements[element_id])
	
	return elements

# Search for elements
func search_elements(query, fields=["title", "description"], types=null, include_tags=true):
	var results = []
	var query_lower = query.to_lower()
	
	for element_id in story_elements:
		var element = story_elements[element_id]
		
		# Filter by type if specified
		if types != null and not element.type in types:
			continue
		
		var matches = false
		
		# Search in specified fields
		for field in fields:
			if element.has(field) and typeof(element[field]) == TYPE_STRING:
				if element[field].to_lower().find(query_lower) != -1:
					matches = true
					break
		
		# Search in tags if requested
		if not matches and include_tags:
			for tag in element.tags:
				if tag.to_lower().find(query_lower) != -1:
					matches = true
					break
		
		if matches:
			results.append(element)
	
	return results

# Find all elements connected to a given element
func get_connected_elements(element_id, include_incoming=true, include_outgoing=true):
	var connected = {}
	
	# Get outgoing connections
	if include_outgoing and connections.has(element_id):
		for to_id in connections[element_id]:
			if story_elements.has(to_id):
				connected[to_id] = {
					"element": story_elements[to_id],
					"connection": connections[element_id][to_id],
					"direction": "outgoing"
				}
	
	# Get incoming connections
	if include_incoming:
		for from_id in connections:
			if connections[from_id].has(element_id):
				connected[from_id] = {
					"element": story_elements[from_id],
					"connection": connections[from_id][element_id],
					"direction": "incoming"
				}
	
	return connected

# Get the path between two elements
func find_path(from_id, to_id, max_depth=5):
	if not story_elements.has(from_id) or not story_elements.has(to_id):
		return null
	
	# Use breadth-first search to find a path
	var queue = []
	var visited = {}
	var paths = {}
	
	# Initialize
	queue.append(from_id)
	visited[from_id] = true
	paths[from_id] = []
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_path = paths[current]
		
		# Check if we reached the target
		if current == to_id:
			return current_path
		
		# Stop if we've reached the maximum depth
		if current_path.size() >= max_depth:
			continue
		
		# Check outgoing connections
		if connections.has(current):
			for next_id in connections[current]:
				if not visited.has(next_id):
					visited[next_id] = true
					var new_path = current_path.duplicate()
					new_path.append({
						"from": current,
						"to": next_id,
						"connection": connections[current][next_id]
					})
					paths[next_id] = new_path
					queue.append(next_id)
	
	# No path found
	return null

# Helper to generate unique IDs
func _generate_id():
	next_id += 1
	return "element_" + str(next_id)

# Save data to files
func save_data():
	# Save elements
	var elements_file = FileAccess.open(SAVE_FOLDER + ELEMENTS_FILE, FileAccess.WRITE)
	elements_file.store_string(JSON.stringify(story_elements))
	elements_file.close()
	
	# Save connections
	var connections_file = FileAccess.open(SAVE_FOLDER + CONNECTIONS_FILE, FileAccess.WRITE)
	connections_file.store_string(JSON.stringify(connections))
	connections_file.close()
	
	# Save tags
	var tags_file = FileAccess.open(SAVE_FOLDER + TAGS_FILE, FileAccess.WRITE)
	tags_file.store_string(JSON.stringify(tags))
	tags_file.close()
	
	print("Story Web data saved")

# Load data from files
func load_data():
	# Load elements
	if FileAccess.file_exists(SAVE_FOLDER + ELEMENTS_FILE):
		var elements_file = FileAccess.open(SAVE_FOLDER + ELEMENTS_FILE, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(elements_file.get_as_text())
		if error == OK:
			story_elements = json.data
			
			# Update next_id based on existing elements
			for element_id in story_elements:
				if element_id.begins_with("element_"):
					var id_num = element_id.substr(8).to_int()
					if id_num > next_id:
						next_id = id_num
		elements_file.close()
	
	# Load connections
	if FileAccess.file_exists(SAVE_FOLDER + CONNECTIONS_FILE):
		var connections_file = FileAccess.open(SAVE_FOLDER + CONNECTIONS_FILE, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(connections_file.get_as_text())
		if error == OK:
			connections = json.data
		connections_file.close()
	
	# Load tags
	if FileAccess.file_exists(SAVE_FOLDER + TAGS_FILE):
		var tags_file = FileAccess.open(SAVE_FOLDER + TAGS_FILE, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(tags_file.get_as_text())
		if error == OK:
			tags = json.data
		tags_file.close()
	
	print("Story Web data loaded: ", story_elements.size(), " elements, ", connections.size(), " connections, ", tags.size(), " tags")

# Export data to a single JSON file
func export_data(file_path):
	var export_data = {
		"story_elements": story_elements,
		"connections": connections,
		"tags": tags,
		"export_date": Time.get_datetime_dict_from_system()
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data))
		file.close()
		print("Exported Story Web data to: ", file_path)
		return true
	else:
		print("ERROR: Could not export Story Web data")
		return false

# Import data from a JSON file
func import_data(file_path):
	if not FileAccess.file_exists(file_path):
		print("ERROR: Import file does not exist: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open import file")
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("ERROR: Failed to parse import file: ", json.get_error_message())
		file.close()
		return false
	
	var import_data = json.data
	file.close()
	
	# Validate imported data
	if not import_data.has("story_elements") or not import_data.has("connections") or not import_data.has("tags"):
		print("ERROR: Import file is missing required data")
		return false
	
	# Apply imported data
	story_elements = import_data.story_elements
	connections = import_data.connections
	tags = import_data.tags
	
	# Update next_id
	for element_id in story_elements:
		if element_id.begins_with("element_"):
			var id_num = element_id.substr(8).to_int()
			if id_num > next_id:
				next_id = id_num
	
	# Save the imported data
	save_data()
	
	print("Imported Story Web data: ", story_elements.size(), " elements, ", connections.size(), " connections, ", tags.size(), " tags")
	return true

# Generate Markdown export of the story web
func export_to_markdown(file_path):
	var content = "# Love & Lichens Story Web\n\n"
	content += "Generated: " + _format_datetime(Time.get_datetime_dict_from_system()) + "\n\n"
	
	# Elements by type
	for type in ElementType:
		var elements = get_elements_by_type(ElementType[type])
		if elements.size() > 0:
			content += "## " + type + "s\n\n"
			
			for element in elements:
				content += "### " + element.title + " {#" + element.id + "}\n\n"
				
				# Add tags
				if element.tags.size() > 0:
					content += "Tags: " + ", ".join(element.tags) + "\n\n"
				
				# Description
				if element.description != "":
					content += element.description + "\n\n"
				
				# Connections
				var outgoing = get_outgoing_connections(element.id)
				var incoming = get_incoming_connections_for_element(element.id)  # Use the new function name here

				if outgoing.size() > 0 or incoming.size() > 0:
					content += "#### Connections\n\n"
					
					# Outgoing connections
					if outgoing.size() > 0:
						content += "Affects:\n\n"
						for to_id in outgoing:
							var to_element = get_element(to_id)
							var connection = outgoing[to_id]
							
							content += "- [" + to_element.title + "](#" + to_id + ") (" + ConnectionType.keys()[connection.type] + ")"
							if connection.description != "":
								content += ": " + connection.description
							content += "\n"
						content += "\n"
					
					# Incoming connections
					if incoming.size() > 0:
						content += "Affected by:\n\n"
						for from_id in incoming:
							var from_element = get_element(from_id)
							var connection = incoming[from_id]
							
							content += "- [" + from_element.title + "](#" + from_id + ") (" + ConnectionType.keys()[connection.type] + ")"
							if connection.description != "":
								content += ": " + connection.description
							content += "\n"
						content += "\n"
				
				content += "---\n\n"
	
	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("Exported Story Web to Markdown: ", file_path)
		return true
	else:
		print("ERROR: Could not export to Markdown")
		return false

# Helper to format datetime for display
func _format_datetime(datetime):
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
