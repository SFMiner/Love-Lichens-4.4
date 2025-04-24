# story_web_ui.gd
@tool
extends Control

# Story Web UI for Love & Lichens
# Provides a graphical interface for the Story Web System

# References to components
@onready var element_list = $HSplitContainer/LeftPanel/ElementList
@onready var search_input = $HSplitContainer/LeftPanel/SearchBar/SearchInput
@onready var filter_button = $HSplitContainer/LeftPanel/SearchBar/FilterButton
@onready var add_element_button = $HSplitContainer/LeftPanel/Buttons/AddElement
@onready var element_details = $HSplitContainer/RightPanel/TabContainer/Details/ScrollContainer/ElementDetails
@onready var graph_view = $HSplitContainer/RightPanel/TabContainer/GraphView

# References to popups
@onready var add_element_popup = $AddElementPopup
@onready var add_connection_popup = $AddConnectionPopup
@onready var edit_element_popup = $EditElementPopup
@onready var edit_connection_popup = $EditConnectionPopup
@onready var confirm_dialog = $ConfirmDialog
@onready var export_dialog = $ExportDialog
@onready var import_dialog = $ImportDialog

# Reference to the story web system
var story_web
var selected_element_id = null
var current_filter = null
var graph_node_scene = preload("res://addons/story_web/graph_node.tscn")
var graph_connection_scene = preload("res://addons/story_web/graph_connection.tscn")

# Node colors by type
const NODE_COLORS = {
	0: Color(0.2, 0.6, 1.0),  # CHARACTER
	1: Color(0.8, 0.2, 0.2),  # QUEST
	2: Color(0.2, 0.8, 0.2),  # LOCATION
	3: Color(0.8, 0.8, 0.2),  # ITEM
	4: Color(0.8, 0.2, 0.8),  # EVENT
	5: Color(0.2, 0.8, 0.8),  # KNOWLEDGE
	6: Color(0.6, 0.6, 0.6)   # NOTE
}

# Connection colors by type
const CONNECTION_COLORS = {
	0: Color(1.0, 0.5, 0.0),  # AFFECTS
	1: Color(0.0, 0.7, 0.0),  # DEPENDS_ON
	2: Color(0.0, 0.5, 1.0),  # REVEALS
	3: Color(1.0, 0.8, 0.0),  # FORESHADOWS
	4: Color(1.0, 0.0, 0.0),  # CONTRADICTS
	5: Color(0.7, 0.7, 0.7)   # RELATED_TO
}

# StoryWeb constants that we define here for editing operations
# These need to match the enums in story_web_system.gd
enum ElementType {
	CHARACTER,
	QUEST,
	LOCATION,
	ITEM,
	EVENT,
	KNOWLEDGE,
	NOTE
}

enum ConnectionType {
	AFFECTS,           # One element directly affects another
	DEPENDS_ON,        # Element depends on another to progress
	REVEALS,           # Element reveals information about another
	FORESHADOWS,       # Element hints at or foreshadows another
	CONTRADICTS,       # Elements contradict each other
	RELATED_TO         # General relationship
}

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		print("Story Web UI ENTERED TREE")

func _ready():
	print("Story Web UI _ready() function started")
	
	# Make sure we are inside the tree before continuing
	if not is_inside_tree():
		print("Not inside tree yet, deferring initialization")
		call_deferred("_initialize")
		return
		
	# Otherwise proceed with initialization
	_initialize()
	
func _initialize():
	print("Initializing Story Web UI...")
	
	# Check that we're inside the tree
	if not is_inside_tree():
		print("Still not inside tree! Deferring initialization again")
		call_deferred("_initialize")
		return
		
	# Create our own StoryWeb system instance for editor use
	print("Creating StoryWeb system instance...")
	
	# Create a direct instance and add as child
	var StoryWebClass = load("res://addons/story_web/story_web_system.gd")
	story_web = StoryWebClass.new()
	add_child(story_web)
	
	# Initialize it
	story_web.call("_ready")
	
	print("Successfully got StoryWeb system instance")
	
	# Connect UI signals
	_connect_ui_signals()
	
	# Connect element details buttons
	_connect_element_detail_buttons()
	
	# Setup filter button options
	_setup_filter_button()
	
	# Populate element list
	refresh_element_list()
	
	print("Story Web UI initialization complete")

func _connect_ui_signals():
	# Connect popup buttons
	add_element_popup.get_node("VBoxContainer/ButtonsPanel/AddButton").pressed.connect(_on_add_element_confirmed)
	add_element_popup.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): add_element_popup.hide())
	
	edit_element_popup.get_node("VBoxContainer/ButtonsPanel/SaveButton").pressed.connect(_on_edit_element_confirmed)
	edit_element_popup.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): edit_element_popup.hide())
	
	add_connection_popup.get_node("VBoxContainer/ButtonsPanel/AddButton").pressed.connect(_on_add_connection_confirmed)
	add_connection_popup.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): add_connection_popup.hide())
	
	edit_connection_popup.get_node("VBoxContainer/ButtonsPanel/SaveButton").pressed.connect(_on_edit_connection_confirmed)
	edit_connection_popup.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): edit_connection_popup.hide())
	
	confirm_dialog.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): confirm_dialog.hide())
	
	export_dialog.get_node("VBoxContainer/ButtonsPanel/ExportButton").pressed.connect(_on_export_confirmed)
	export_dialog.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): export_dialog.hide())
	
	import_dialog.get_node("VBoxContainer/ButtonsPanel/ImportButton").pressed.connect(_on_import_confirmed)
	import_dialog.get_node("VBoxContainer/ButtonsPanel/CancelButton").pressed.connect(func(): import_dialog.hide())

func _connect_element_detail_buttons():
	# Connect element details buttons
	element_details.get_node("ButtonsPanel/EditElement").pressed.connect(_on_edit_element_button_pressed)
	element_details.get_node("ButtonsPanel/DeleteElement").pressed.connect(_on_delete_element_button_pressed)
	element_details.get_node("ButtonsPanel/AddConnection").pressed.connect(_on_add_connection_button_pressed)

func _setup_filter_button():
	filter_button.clear()
	filter_button.add_item("All Types", -1)
	
	# Add element types
	for type_id in ElementType.keys():
		filter_button.add_item(type_id, ElementType[type_id])

func refresh_element_list():
	element_list.clear()
	
	var elements = []
	var search_text = search_input.text.strip_edges()
	
	if search_text.length() > 0:
		# Search for elements
		elements = story_web.search_elements(search_text)
	else:
		# Get all elements
		for element_id in story_web.story_elements:
			elements.append(story_web.story_elements[element_id])
	
	# Apply type filter if set
	if current_filter != null and current_filter >= 0:
		var filtered_elements = []
		for element in elements:
			if element.type == current_filter:
				filtered_elements.append(element)
		elements = filtered_elements
	
	# Sort by title
	elements.sort_custom(func(a, b): return a.title < b.title)
	
	# Add to list
	for element in elements:
		var icon = _get_icon_for_type(element.type)
		if icon:
			element_list.add_item(element.title, icon)
		else:
			element_list.add_item(element.title) # Fallback if icon is missing
		
		# Store element ID in metadata
		var item_index = element_list.get_item_count() - 1
		element_list.set_item_metadata(item_index, element.id)
		
		# Set item color based on type
		if NODE_COLORS.has(element.type):
			element_list.set_item_custom_fg_color(item_index, NODE_COLORS[element.type])
	
	# If previously selected element is still in the list, re-select it
	if selected_element_id != null:
		for i in range(element_list.get_item_count()):
			if element_list.get_item_metadata(i) == selected_element_id:
				element_list.select(i)
				break

func _get_icon_for_type(type):
	# Define paths for icon resources
	var icon_paths = {
		ElementType.CHARACTER: "res://addons/story_web/icons/character_icon.png",
		ElementType.QUEST: "res://addons/story_web/icons/quest_icon.png",
		ElementType.LOCATION: "res://addons/story_web/icons/location_icon.png",
		ElementType.ITEM: "res://addons/story_web/icons/item_icon.png",
		ElementType.EVENT: "res://addons/story_web/icons/event_icon.png",
		ElementType.KNOWLEDGE: "res://addons/story_web/icons/knowledge_icon.png",
		ElementType.NOTE: "res://addons/story_web/icons/note_icon.png"
	}
	
	# Try to load the icon
	if icon_paths.has(type) and ResourceLoader.exists(icon_paths[type]):
		return load(icon_paths[type])
	
	# Return null if icon doesn't exist (we'll handle this gracefully)
	return null

func show_element_details(element_id):
	if not story_web.story_elements.has(element_id):
		element_details.visible = false
		return
	
	selected_element_id = element_id
	var element = story_web.story_elements[element_id]
	
	# Set element details
	element_details.get_node("Title").text = element.title
	element_details.get_node("Type").text = ElementType.keys()[element.type]
	element_details.get_node("Description").text = element.description
	
	# Set tags
	var tags_text = ""
	for tag in element.tags:
		if tags_text != "":
			tags_text += ", "
		tags_text += tag
	element_details.get_node("Tags").text = tags_text
	
	# Get connections
	var outgoing = story_web.get_outgoing_connections(element_id)
	var incoming = story_web.get_incoming_connections_for_element(element_id)
	
	# Clear existing connections
	var outgoing_list = element_details.get_node("Connections/OutgoingList")
	var incoming_list = element_details.get_node("Connections/IncomingList")
	outgoing_list.clear()
	incoming_list.clear()
	
	# Add outgoing connections
	for to_id in outgoing:
		var to_element = story_web.get_element(to_id)
		var connection = outgoing[to_id]
		var connection_type = ConnectionType.keys()[connection.type]
		
		var item_text = to_element.title + " (" + connection_type + ")"
		outgoing_list.add_item(item_text)
		outgoing_list.set_item_metadata(outgoing_list.get_item_count() - 1, {
			"from_id": element_id,
			"to_id": to_id,
			"connection": connection
		})
		
		# Set item color based on connection type
		var item_index = outgoing_list.get_item_count() - 1
		if CONNECTION_COLORS.has(connection.type):
			outgoing_list.set_item_custom_fg_color(item_index, CONNECTION_COLORS[connection.type])
	
	# Add incoming connections
	for from_id in incoming:
		var from_element = story_web.get_element(from_id)
		var connection = incoming[from_id]
		var connection_type = ConnectionType.keys()[connection.type]
		
		var item_text = from_element.title + " (" + connection_type + ")"
		incoming_list.add_item(item_text)
		incoming_list.set_item_metadata(incoming_list.get_item_count() - 1, {
			"from_id": from_id,
			"to_id": element_id,
			"connection": connection
		})
		
		# Set item color based on connection type
		var item_index = incoming_list.get_item_count() - 1
		if CONNECTION_COLORS.has(connection.type):
			incoming_list.set_item_custom_fg_color(item_index, CONNECTION_COLORS[connection.type])
	
	# Show element details
	element_details.visible = true
	
	# Update graph view
	update_graph_view(element_id)

func update_graph_view(center_element_id):
	# Clear existing graph
	for child in graph_view.get_children():
		if child.name != "InstructionsLabel": # Keep instructions label
			graph_view.remove_child(child)
			child.queue_free()
	
	if not center_element_id or not story_web.story_elements.has(center_element_id):
		return
	
	# Get the center element
	var center_element = story_web.story_elements[center_element_id]
	
	# Get all connected elements (1 step away)
	var connected = story_web.get_connected_elements(center_element_id)
	
	# Create nodes
	var nodes = {}
	var node_positions = {}
	
	# Create center node
	var center_node = graph_node_scene.instantiate()
	center_node.name = center_element_id
	center_node.element = center_element
	center_node.position = Vector2(500, 300)  # Center of view
	graph_view.add_child(center_node)
	nodes[center_element_id] = center_node
	node_positions[center_element_id] = center_node.position
	
	# Distribute connected nodes in a circle around the center
	var angle_step = 2 * PI / max(connected.size(), 1)
	var current_angle = 0
	var radius = 250
	
	for connected_id in connected:
		var element = story_web.story_elements[connected_id]
		var node = graph_node_scene.instantiate()
		node.name = connected_id
		node.element = element
		
		# Position in circle
		var pos = Vector2(
			center_node.position.x + radius * cos(current_angle),
			center_node.position.y + radius * sin(current_angle)
		)
		node.position = pos
		node_positions[connected_id] = pos
		
		graph_view.add_child(node)
		nodes[connected_id] = node
		
		current_angle += angle_step
	
	# Create connections
	for from_id in nodes:
		if story_web.connections.has(from_id):
			for to_id in story_web.connections[from_id]:
				if nodes.has(to_id):
					var connection_data = story_web.connections[from_id][to_id]
					var connection = graph_connection_scene.instantiate()
					connection.from_node = nodes[from_id]
					connection.to_node = nodes[to_id]
					connection.connection_data = connection_data
					graph_view.add_child(connection)

func _on_element_list_item_selected(index):
	var element_id = element_list.get_item_metadata(index)
	show_element_details(element_id)

func _on_search_text_changed(new_text):
	refresh_element_list()

func _on_filter_selected(index):
	var selected_id = filter_button.get_item_id(index)
	current_filter = selected_id
	refresh_element_list()

func _on_add_element_button_pressed():
	# Show add element popup
	print("Add Element button pressed.")
	add_element_popup.popup_centered()

func _on_add_element_confirmed():
	var title = add_element_popup.get_node("VBoxContainer/TitleInput").text
	var type = add_element_popup.get_node("VBoxContainer/TypeOption").selected
	var description = add_element_popup.get_node("VBoxContainer/DescriptionInput").text
	var tags_text = add_element_popup.get_node("VBoxContainer/TagsInput").text
	
	# Parse tags
	var tags = []
	if tags_text.strip_edges() != "":
		tags = tags_text.split(",")
		for i in range(tags.size()):
			tags[i] = tags[i].strip_edges()
	
	# Add the element
	var element_id = story_web.add_element(type, title, description, tags)
	
	# Clear the popup fields
	add_element_popup.get_node("VBoxContainer/TitleInput").text = ""
	add_element_popup.get_node("VBoxContainer/DescriptionInput").text = ""
	add_element_popup.get_node("VBoxContainer/TagsInput").text = ""
	
	# Hide popup
	add_element_popup.hide()
	
	# Select the new element
	refresh_element_list()
	for i in range(element_list.get_item_count()):
		if element_list.get_item_metadata(i) == element_id:
			element_list.select(i)
			break

func _on_edit_element_button_pressed():
	if not selected_element_id:
		return
	
	var element = story_web.get_element(selected_element_id)
	if not element:
		return
	
	# Fill the popup with current values
	edit_element_popup.get_node("VBoxContainer/TitleInput").text = element.title
	edit_element_popup.get_node("VBoxContainer/TypeOption").selected = element.type
	edit_element_popup.get_node("VBoxContainer/DescriptionInput").text = element.description
	
	var tags_text = ""
	for tag in element.tags:
		if tags_text != "":
			tags_text += ", "
		tags_text += tag
	edit_element_popup.get_node("VBoxContainer/TagsInput").text = tags_text
	
	# Show edit popup
	edit_element_popup.popup_centered()

func _on_edit_element_confirmed():
	if not selected_element_id:
		return
	
	var title = edit_element_popup.get_node("VBoxContainer/TitleInput").text
	var type = edit_element_popup.get_node("VBoxContainer/TypeOption").selected
	var description = edit_element_popup.get_node("VBoxContainer/DescriptionInput").text
	var tags_text = edit_element_popup.get_node("VBoxContainer/TagsInput").text
	
	# Parse tags
	var tags = []
	if tags_text.strip_edges() != "":
		tags = tags_text.split(",")
		for i in range(tags.size()):
			tags[i] = tags[i].strip_edges()
	
	# Update the element
	story_web.update_element(selected_element_id, {
		"title": title,
		"type": type,
		"description": description,
		"tags": tags
	})
	
	# Hide popup
	edit_element_popup.hide()

func _on_delete_element_button_pressed():
	if not selected_element_id:
		return
	
	# Get element data for confirmation message
	var element = story_web.get_element(selected_element_id)
	if not element:
		return
	
	# Set confirmation message
	confirm_dialog.get_node("VBoxContainer/Label").text = "Are you sure you want to delete element \"" + element.title + "\"?"
	
	# Check if already connected and disconnect
	var delete_button = confirm_dialog.get_node("VBoxContainer/ButtonsPanel/DeleteButton")
	var connections = delete_button.get_signal_connection_list("pressed")
	for connection in connections:
		if connection.callable.get_method() == "_on_delete_element_confirmed":
			delete_button.disconnect("pressed", connection.callable)
	
	# Connect delete button
	delete_button.pressed.connect(_on_delete_element_confirmed.bind(selected_element_id))
	
	# Show confirmation dialog
	confirm_dialog.popup_centered()

func _on_delete_element_confirmed(element_id):
	# Delete the element
	story_web.remove_element(element_id)
	
	# Reset selection
	selected_element_id = null
	element_details.visible = false
	
	# Disconnect the signal
	var delete_button = confirm_dialog.get_node("VBoxContainer/ButtonsPanel/DeleteButton")
	var connections = delete_button.get_signal_connection_list("pressed")
	for connection in connections:
		if connection.callable.get_method() == "_on_delete_element_confirmed":
			delete_button.disconnect("pressed", connection.callable)
	
	# Hide dialog
	confirm_dialog.hide()

func _on_add_connection_button_pressed():
	if not selected_element_id:
		return
	
	# Get the source element
	var source_element = story_web.get_element(selected_element_id)
	if not source_element:
		return
	
	# Set source element in the popup
	add_connection_popup.get_node("VBoxContainer/FromLabel").text = "From: " + source_element.title
	
	# Populate target element dropdown
	var target_dropdown = add_connection_popup.get_node("VBoxContainer/ToDropdown")
	target_dropdown.clear()
	
	var sorted_elements = []
	for id in story_web.story_elements:
		if id != selected_element_id:  # Don't include the source
			sorted_elements.append(story_web.story_elements[id])
	
	# Sort by title
	sorted_elements.sort_custom(func(a, b): return a.title < b.title)
	
	for element in sorted_elements:
		target_dropdown.add_item(element.title)
		target_dropdown.set_item_metadata(target_dropdown.get_item_count() - 1, element.id)
	
	# Show the popup
	add_connection_popup.popup_centered()

func _on_add_connection_confirmed():
	if not selected_element_id:
		return
	
	# Get connection data from popup
	var target_dropdown = add_connection_popup.get_node("VBoxContainer/ToDropdown")
	var selected_index = target_dropdown.selected
	if selected_index < 0:
		return
	
	var target_id = target_dropdown.get_item_metadata(selected_index)
	var connection_type = add_connection_popup.get_node("VBoxContainer/TypeOption").selected
	var description = add_connection_popup.get_node("VBoxContainer/DescriptionInput").text
	
	# Add the connection
	story_web.add_connection(selected_element_id, target_id, connection_type, description)
	
	# Clear the popup fields
	add_connection_popup.get_node("VBoxContainer/DescriptionInput").text = ""
	
	# Hide popup
	add_connection_popup.hide()

func _on_edit_connection_button_pressed(from_id, to_id):
	if not from_id or not to_id:
		return
	
	# Get the connection
	if not story_web.connections.has(from_id) or not story_web.connections[from_id].has(to_id):
		return
	
	var connection = story_web.connections[from_id][to_id]
	var from_element = story_web.get_element(from_id)
	var to_element = story_web.get_element(to_id)
	
	# Fill the popup with current values
	edit_connection_popup.get_node("VBoxContainer/FromLabel").text = "From: " + from_element.title
	edit_connection_popup.get_node("VBoxContainer/ToLabel").text = "To: " + to_element.title
	edit_connection_popup.get_node("VBoxContainer/TypeOption").selected = connection.type
	edit_connection_popup.get_node("VBoxContainer/DescriptionInput").text = connection.description
	
	# Store connection IDs in the popup metadata
	edit_connection_popup.set_meta("from_id", from_id)
	edit_connection_popup.set_meta("to_id", to_id)
	
	# Show edit popup
	edit_connection_popup.popup_centered()

func _on_edit_connection_confirmed():
	var from_id = edit_connection_popup.get_meta("from_id")
	var to_id = edit_connection_popup.get_meta("to_id")
	
	if not from_id or not to_id:
		return
	
	var connection_type = edit_connection_popup.get_node("VBoxContainer/TypeOption").selected
	var description = edit_connection_popup.get_node("VBoxContainer/DescriptionInput").text
	
	# Update the connection
	story_web.update_connection(from_id, to_id, {
		"type": connection_type,
		"description": description
	})
	
	# Hide popup
	edit_connection_popup.hide()

func _on_delete_connection_button_pressed(from_id, to_id):
	if not from_id or not to_id:
		return
	
	# Get element data for confirmation message
	var from_element = story_web.get_element(from_id)
	var to_element = story_web.get_element(to_id)
	if not from_element or not to_element:
		return
	
	# Set confirmation message
	confirm_dialog.get_node("VBoxContainer/Label").text = "Are you sure you want to delete connection from \"" + from_element.title + "\" to \"" + to_element.title + "\"?"
	
	# Check if already connected and disconnect
	var delete_button = confirm_dialog.get_node("VBoxContainer/ButtonsPanel/DeleteButton")
	var connections = delete_button.get_signal_connection_list("pressed")
	for connection in connections:
		if connection.callable.get_method() == "_on_delete_connection_confirmed":
			delete_button.disconnect("pressed", connection.callable)
	
	# Connect deletion function
	delete_button.pressed.connect(_on_delete_connection_confirmed.bind(from_id, to_id))
	
	# Show confirmation dialog
	confirm_dialog.popup_centered()

func _on_delete_connection_confirmed(from_id, to_id):
	# Delete the connection
	story_web.remove_connection(from_id, to_id)
	
	# Disconnect the signal
	var delete_button = confirm_dialog.get_node("VBoxContainer/ButtonsPanel/DeleteButton")
	var connections = delete_button.get_signal_connection_list("pressed")
	for connection in connections:
		if connection.callable.get_method() == "_on_delete_connection_confirmed":
			delete_button.disconnect("pressed", connection.callable)
	
	# Hide dialog
	confirm_dialog.hide()

func _on_export_button_pressed():
	export_dialog.popup_centered()

func _on_export_confirmed():
	var file_path = export_dialog.get_node("VBoxContainer/FilePathInput").text
	
	if export_dialog.get_node("VBoxContainer/FormatOption").selected == 0:
		# Export as JSON
		story_web.export_data(file_path)
	else:
		# Export as Markdown
		story_web.export_to_markdown(file_path)
	
	# Hide dialog
	export_dialog.hide()

func _on_import_button_pressed():
	import_dialog.popup_centered()

func _on_import_confirmed():
	var file_path = import_dialog.get_node("VBoxContainer/FilePathInput").text
	story_web.import_data(file_path)
	refresh_element_list()
	
	# Hide dialog
	import_dialog.hide()

# Signal handlers from the StoryWeb system to refresh UI
func _on_element_added(element_id, element_data):
	refresh_element_list()

func _on_element_updated(element_id, element_data):
	refresh_element_list()
	
	# If this is the currently selected element, refresh details
	if element_id == selected_element_id:
		show_element_details(element_id)

func _on_element_removed(element_id):
	refresh_element_list()
	
	# If this was the selected element, clear details
	if element_id == selected_element_id:
		selected_element_id = null
		element_details.visible = false

func _on_connection_added(from_id, to_id, connection_data):
	# If either end is the currently selected element, refresh details
	if from_id == selected_element_id or to_id == selected_element_id:
		show_element_details(selected_element_id)

func _on_connection_updated(from_id, to_id, connection_data):
	# If either end is the currently selected element, refresh details
	if from_id == selected_element_id or to_id == selected_element_id:
		show_element_details(selected_element_id)

func _on_connection_removed(from_id, to_id):
	# If either end is the currently selected element, refresh details
	if from_id == selected_element_id or to_id == selected_element_id:
		show_element_details(selected_element_id)
