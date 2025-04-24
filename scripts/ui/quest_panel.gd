# quest_panel.gd
extends Control

const scr_debug :bool = true
var debug


var quest_system

@onready var quest_list = $MarginContainer/VBoxContainer/HBoxContainer2/QuestList
@onready var available_list = $MarginContainer/VBoxContainer/HBoxContainer2/AvailableList
@onready var details_panel = $MarginContainer/VBoxContainer/HBoxContainer2/DetailsPanel
@onready var quest_title = $MarginContainer/VBoxContainer/HBoxContainer2/DetailsPanel/MarginContainer/VBoxContainer/QuestTitle
@onready var quest_description = $MarginContainer/VBoxContainer/HBoxContainer2/DetailsPanel/MarginContainer/VBoxContainer/QuestDescription
@onready var objectives_container = $MarginContainer/VBoxContainer/HBoxContainer2/DetailsPanel/MarginContainer/VBoxContainer/ObjectivesContainer



var selected_quest_id = ""

func _ready():
	debug = scr_debug or GameController.sys_debug 
	if debug: print("Quest panel initializing...")
	
	# Get quest system reference
	quest_system = get_node_or_null("/root/QuestSystem")
	if not quest_system:
		if debug: print("ERROR: QuestSystem not found")
		# We'll still try to reference the UI elements
	
	# Make sure we can find the UI elements
	if not quest_list:
		if debug: print("ERROR: QuestList node not found!")
		# Try to find it manually by path
		quest_list = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer2/QuestList")
	
	if not available_list:
		if debug: print("ERROR: AvailableList node not found!")
		available_list = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer2/AvailableList")
	
	if not details_panel:
		if debug: print("ERROR: DetailsPanel node not found!")
		details_panel = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer2/DetailsPanel")
	
	if not quest_title:
		if debug: print("ERROR: QuestTitle node not found!")
		if details_panel:
			quest_title = details_panel.get_node_or_null("MarginContainer/VBoxContainer/QuestTitle")
	
	if not quest_description:
		if debug: print("ERROR: QuestDescription node not found!")
		if details_panel:
			quest_description = details_panel.get_node_or_null("MarginContainer/VBoxContainer/QuestDescription")
	
	if not objectives_container:
		if debug: print("ERROR: ObjectivesContainer node not found!")
		if details_panel:
			objectives_container = details_panel.get_node_or_null("MarginContainer/VBoxContainer/ObjectivesContainer")
	
	# Connect to quest system signals if available
	if quest_system:
		quest_system.quest_started.connect(_on_quest_started)
		quest_system.quest_updated.connect(_on_quest_updated)
		quest_system.quest_completed.connect(_on_quest_completed)
		quest_system.objective_updated.connect(_on_objective_updated)
		if debug: print("Connected to QuestSystem signals")
	
	# Hide details panel until a quest is selected
	if details_panel:
		details_panel.visible = false
	
	# Connect close button
	var close_button = $MarginContainer/VBoxContainer/HBoxContainer/CloseButton
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	else:
		if debug: print("WARNING: Close button not found")
		close_button = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/CloseButton")
		if close_button:
			close_button.pressed.connect(_on_close_button_pressed)
	
	if debug: print("Quest panel initialized")
	
	# Load the initial quest list
	call_deferred("refresh_all_lists")

func _process(delta):
	# Emergency visibility check
	if visible:
		# Force self to top layer
		z_index = 100
		
		# Make all children visible too
		for child in get_children():
			if child is Control:
				child.visible = true
				child.modulate.a = 1.0 # Force full opacity

func refresh_all_lists():
	refresh_active_quests()
	refresh_available_quests()

func refresh_active_quests():
	if debug: print("Refreshing active quests...")
	
	# Safety check
	if not quest_list:
		if debug: print("ERROR: Cannot refresh quest list - quest_list is null")
		return
	
	# Clear existing items
	for child in quest_list.get_children():
		child.queue_free()
	
	# Get active quests if quest system is available
	var active_quests = {}
	if quest_system:
		active_quests = quest_system.get_active_quests()
	
	# Add a header
	var header = Label.new()
	header.text = "Active Quests"
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	quest_list.add_child(header)
	
	# Add buttons for each quest
	if active_quests.size() > 0:
		for quest_id in active_quests:
			var quest = active_quests[quest_id]
			
			var button = Button.new()
			button.text = quest.title if quest.has("title") else quest_id
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			# IMPORTANT: Make sure we create a new function reference for each button
			var callable = Callable(self, "_on_quest_selected").bind(quest_id)
			button.pressed.connect(callable)
			
			# Highlight the selected quest
			if quest_id == selected_quest_id:
				button.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
			
			quest_list.add_child(button)
			if debug: print("Added quest button: ", quest.title if quest.has("title") else quest_id)
		
		if debug: print("Added " + str(active_quests.size()) + " quests to the list")
	else:
		# Show a message if no quests
		var label = Label.new()
		label.text = "No active quests"
		quest_list.add_child(label)
		
func refresh_available_quests():
	if debug: print("Refreshing available quests...")
	
	# Safety check
	if not available_list:
		if debug: print("ERROR: Cannot refresh available quests - available_list is null")
		return
	
	# Clear existing items
	for child in available_list.get_children():
		child.queue_free()
	
	# Get available quests
	var available_quests = {}
	if quest_system:
		available_quests = quest_system.get_available_quests()
	
	# Add a header
	var header = Label.new()
	header.text = "Available Quests"
	header.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	available_list.add_child(header)
	
	# Add buttons for each available quest
	if available_quests.size() > 0:
		for quest_id in available_quests:
			var quest = available_quests[quest_id]
			
			var button = Button.new()
			button.text = quest.title if quest.has("title") else quest_id
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			# IMPORTANT: Create a new function reference
			var callable = Callable(self, "_on_available_quest_selected").bind(quest_id)
			button.pressed.connect(callable)
			
			available_list.add_child(button)
			if debug: print("Added available quest button: ", quest.title if quest.has("title") else quest_id)
	
		if debug: print("Added " + str(available_quests.size()) + " available quests")
	else:
		# Show a message if no available quests
		var label = Label.new()
		label.text = "No available quests"
		available_list.add_child(label)
		
		# Add intro quest button for testing
		if quest_system and not quest_system.get_quest("intro_quest"):
			var starter_button = Button.new()
			starter_button.text = "Start Intro Quest"
			starter_button.tooltip_text = "Click to begin a simple introductory quest"
			starter_button.pressed.connect(_on_start_intro_quest)
			available_list.add_child(starter_button)

func _on_start_intro_quest():
	if quest_system:
		var result = quest_system.load_new_quest("intro_quest", true)
		if result:
			if debug: print("Started intro quest")
			refresh_all_lists()
		else:
			if debug: print("Failed to start intro quest")
	else:
		if debug: print("ERROR: Cannot start quest - QuestSystem not found")

func _on_available_quest_selected(quest_id):
	if quest_system:
		# Display details first
		display_quest_details(quest_id)
		
		# Add a start button
		var start_button = Button.new()
		start_button.text = "Start Quest"
		start_button.pressed.connect(_on_start_quest_pressed.bind(quest_id))
		
		if objectives_container:
			# Add some space
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 20)
			objectives_container.add_child(spacer)
			
			# Add the button
			objectives_container.add_child(start_button)

func _on_start_quest_pressed(quest_id):
	if quest_system:
		var result = quest_system.start_quest(quest_id)
		if result:
			if debug: print("Started quest: ", quest_id)
			selected_quest_id = quest_id
			refresh_all_lists()
			display_quest_details(quest_id)
			
			# Close the panel after accepting the quest
			if debug: print("Closing quest panel after accepting quest")
			call_deferred("_on_close_button_pressed")
		else:
			if debug: print("Failed to start quest: ", quest_id)

func display_quest_details(quest_id):
	if debug: print("Displaying details for quest: ", quest_id)
	
	if not details_panel or not quest_title or not quest_description or not objectives_container:
		if debug: print("ERROR: Cannot display quest details - UI components are missing")
		return
		
	var quest = quest_system.get_quest(quest_id)
	
	if not quest:
		if debug: print("ERROR: Quest not found: ", quest_id)
		details_panel.visible = false
		return
	
	if debug: print("Found quest: ", quest.title if quest.has("title") else quest_id)
	
	# Set title and description
	quest_title.text = quest.title if quest.has("title") else quest_id
	quest_description.text = quest.description if quest.has("description") else ""

	
	# Clear objectives container
	for child in objectives_container.get_children():
		child.queue_free()
	
	# Add objectives
	if quest.has("objectives"):
		for objective in quest.objectives:
			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var checkbox = CheckBox.new()
			checkbox.button_pressed = objective.completed if objective.has("completed") else false
			checkbox.disabled = true
			hbox.add_child(checkbox)
			
			var label = Label.new()
			label.text = objective.description if objective.has("description") else objective.type + ": " + objective.target
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)
			
			# Show progress for gather objectives
			if objective.type == "gather" and objective.has("progress") and objective.has("required"):
				var progress = Label.new()
				progress.text = str(objective.progress) + "/" + str(objective.required)
				progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				hbox.add_child(progress)
			
			objectives_container.add_child(hbox)
	
	# Show rewards if available
	if quest.has("rewards") and quest.rewards.size() > 0:
		var rewards_label = Label.new()
		rewards_label.text = "Rewards:"
		rewards_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		
		# Add some space
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		objectives_container.add_child(spacer)
		objectives_container.add_child(rewards_label)
		
		# List rewards
		for reward in quest.rewards:
			var label = Label.new()
			
			match reward.type:
				"item":
					label.text = "• " + reward.id + " (x" + str(reward.amount) + ")"
				"knowledge":
					label.text = "• Knowledge: " + reward.id
				"relationship":
					label.text = "• Improved relationship with " + reward.character
				"unlock_area":
					label.text = "• Unlock area: " + reward.id
				_:
					label.text = "• " + reward.type + " reward"
					
			objectives_container.add_child(label)
	
	# Show the panel
	details_panel.visible = true

func _on_quest_selected(quest_id):
	selected_quest_id = quest_id
	display_quest_details(quest_id)
	refresh_active_quests()  # Refresh to update selection highlighting

func _on_quest_started(quest_id):
	refresh_all_lists()
	
	# Auto-select the new quest
	selected_quest_id = quest_id
	display_quest_details(quest_id)

func _on_quest_updated(quest_id):
	if quest_id == selected_quest_id:
		display_quest_details(quest_id)

func _on_quest_completed(quest_id):
	if quest_id == selected_quest_id:
		selected_quest_id = ""
		details_panel.visible = false
	
	refresh_all_lists()

func _on_objective_updated(quest_id, objective_index, progress, required):
	if quest_id == selected_quest_id:
		display_quest_details(quest_id)

func _on_close_button_pressed():
	visible = false
	get_tree().paused = false

func toggle_visibility():
	visible = !visible
	
	# Pause/unpause the game
	get_tree().paused = visible
	
	if visible:
		refresh_all_lists()
		
		# If we have a selected quest, display its details
		if selected_quest_id and quest_system and quest_system.get_quest(selected_quest_id):
			display_quest_details(selected_quest_id)
		else:
			# Hide details if no quest selected
			if details_panel:
				details_panel.visible = false
			selected_quest_id = ""
