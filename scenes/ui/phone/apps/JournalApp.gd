extends Control

@onready var new_entry_button = $UI/Toolbar/NewEntryButton
@onready var back_button      = $UI/Toolbar/BackButton
@onready var entries_list     = $UI/Scroll/EntriesList
@onready var entry_panel   = $EntryPanel
@onready var body_edit     = $EntryPanel/DialogVBox/BodyEdit
@onready var save_button   = $EntryPanel/DialogVBox/Buttons/SaveButton
@onready var cancel_button = $EntryPanel/DialogVBox/Buttons/CancelButton
@onready var toolbar = $UI/Toolbar

var all_entries: Array = []

func _ready() -> void:
	new_entry_button.pressed.connect(Callable(self, "_on_new_entry_pressed"))
	back_button.pressed.connect(Callable(self, "_on_back_pressed"))
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	cancel_button.pressed.connect(Callable(self, "_on_cancel_pressed"))
	_refresh_list()

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
	
func _on_back_pressed() -> void:
	hide()  # Or however you return to the phone’s main UI

func _on_save_pressed() -> void:
	var text = body_edit.text.strip_edges()
	if text == "":
		return  # nothing to save

	# 1) Title = first line
	var lines = text.split("\n", false)
	var title = lines[0]

	# 2) Body = all remaining lines
	var body = lines.slice(1).join("\n") if lines.size() > 1 else ""

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
	var game_date = get_node("/root/GameState").get_current_date_string()

	# 5) Add it
	add_entry(title, game_date, tags, body)
	entry_panel.visible = false
	toolbar.visible = true

func add_entry(title: String, date: String, tags: Array, body: String) -> void:
	all_entries.append({
		"title": title,
		"date": date,
		"tags": tags,
		"body": body
	})
	_refresh_list()

func _refresh_list() -> void:
	for c in entries_list.get_children():
		c.queue_free()

	for idx in all_entries.size():
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
	# fill the panel
	body_edit.text = "%s\n\n%s" % [e["title"], e["body"]]
	# show panel in read‐only mode
	entry_panel.visible = true
	save_button.visible = false
	cancel_button.text = "Back"
