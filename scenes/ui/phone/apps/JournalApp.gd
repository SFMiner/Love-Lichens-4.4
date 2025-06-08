extends Control

@onready var new_entry_button = $UI/Toolbar/NewEntryButton
@onready var entries_list     = $UI/Scroll/EntriesList
@onready var entry_panel   = $EntryPanel
@onready var body_edit     = $EntryPanel/DialogVBox/BodyEdit
@onready var save_button   = $EntryPanel/DialogVBox/Buttons/SaveButton
@onready var cancel_button = $EntryPanel/DialogVBox/Buttons/CancelButton
@onready var toolbar = $UI/Toolbar
var editing_key: String = ""

var all_entries: Array = []

func _ready() -> void:
	new_entry_button.pressed.connect(Callable(self, "_on_new_entry_pressed"))
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	cancel_button.pressed.connect(Callable(self, "_on_cancel_pressed"))
	_refresh_list()
	print()

func _on_new_entry_pressed() -> void:
	entry_panel.visible = true
	body_edit.text = ""
	toolbar.visible = false

func _on_entry_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.double_click:
		_open_entry(idx)

func _on_cancel_pressed() -> void:
	entry_panel.visible = false
	toolbar.visible = true
	
func _on_save_pressed() -> void:
	var text = body_edit.text.strip_edges()
	if text == "":
		return  # nothing to save
	var game_date = ""
	# 1) Title = first line
	var lines = text.split("\n", false)
	var title = lines[0]

	# 2) Body = all remaining lines
#	print("lines class name: ", lines.get_class())  # should be PackedStringArray
#	var body = lines.slice(1).join("\n") if lines.size() > 1 else ""
	var body = "\n".join(lines.slice(1)) if lines.size() > 1 else ""
	# 3) Parse #tags via regex
	var tag_regex = RegEx.new()
	tag_regex.compile("#([A-Za-z0-9_-]+)")
	var tags = []
	for m in tag_regex.search_all(text):
		var tag = m.get_string(1)
		if not tags.has(tag):
			tags.append(tag)

	# 4) Auto–date from your game’s date manager
	#    Replace this with however you fetch the in-game date:
	if editing_key != "" : 
		game_date = editing_key 
	else:
		game_date = TimeSystem.format_game_time("mm-dd-yy - h:nn")
	
	# 5) Add it
	add_entry(title, game_date, tags, body)
	entry_panel.visible = false
	toolbar.visible = true

func add_entry(title: String, date: String, tags: Array, body: String) -> void:
	var new_entry : Dictionary = {
		"title": title,
		"date": date,
		"tags": tags,
		"body": body
	} 
	print("new_entry = " + str(new_entry))
	var found : bool = false
	for entry_position in all_entries.size():
		if all_entries[entry_position]["date"] == date:
			found = true	
			all_entries.remove_at(entry_position)
			all_entries.insert(entry_position, new_entry)
			print("Found! " + str(all_entries[entry_position]))
		else:
			print("Not found. " + str(all_entries[entry_position]))

	if ! found:
		all_entries.append(new_entry)

	GameState.phone_apps["journal_app_entries"] = all_entries
#	print (GameState.phone_apps["journal_app_entries"])
	_refresh_list()



func _refresh_list() -> void:
	for c in entries_list.get_children():
		c.queue_free()
	var saved_entries = GameState.phone_apps["journal_app_entries"]
	all_entries = saved_entries
	for idx in saved_entries.size():
		print("all_entries[idx] = " + str(saved_entries[idx]))
		var e = saved_entries[idx]
		var b = Button.new()
		b.text = "%s — %s" % [e["date"], e["title"]]
		b.size_flags_horizontal = Control.SIZE_FILL

		# connect gui_input for double-click, binding idx into the handler
		b.gui_input.connect(
			Callable(self, "_on_entry_gui_input").bind(idx)
		)
		entries_list.add_child(b)

	$UI/Scroll.scroll_vertical = 0

func _refresh_list_original() -> void:
	for c in entries_list.get_children():
		c.queue_free()

	for idx in all_entries.size():
		print("all_entries[idx] = " + str(all_entries[idx]))
		var e = all_entries[idx]
		var b = Button.new()
		b.text = "%s — %s" % [e["date"], e["title"]]
		b.size_flags_horizontal = Control.SIZE_FILL

		# connect gui_input for double-click, binding idx into the handler
		b.gui_input.connect(
			Callable(self, "_on_entry_gui_input").bind(idx)
		)

		entries_list.add_child(b)

	$UI/Scroll.scroll_vertical = 0


func _open_entry(idx: int) -> void:
	var e = all_entries[idx]
	editing_key = e["date"]  # <-- Capture the original timestamp key
	# fill the panel
	body_edit.text = "%s\n\n%s" % [e["title"], e["body"]]
	# show panel in read‐only mode
	entry_panel.visible = true
	save_button.visible = true
	cancel_button.text = "Cancel"

	
func clear_data():
	all_entries = []
