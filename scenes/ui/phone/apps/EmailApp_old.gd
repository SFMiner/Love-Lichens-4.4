extends Control

@onready var email_list    = $EmailListView
@onready var detail_view   = $EmailDetailView
@onready var back_button   = $EmailDetailView/VBoxDetail/BackButton
@onready var from_label    = $EmailDetailView/VBoxDetail/FromLabel
@onready var to_label      = $EmailDetailView/VBoxDetail/ToLabel
@onready var subject_label = $EmailDetailView/VBoxDetail/SubjectLabel
@onready var date_label    = $EmailDetailView/VBoxDetail/DateLabel
@onready var body_text     = $EmailDetailView/VBoxDetail/BodyScroll/BodyText

# Dummy data store: replace with your real loader
var email_threads := [
	{
		"sender":  "Service Bot",
		"to":      ["You"],
		"subject": "Welcome to Our Service",
		"date":    "2025-05-20",
		"body":    "Hello, and thanks for joining us!"
	},
	{
		"sender":  "Alice",
		"to":      ["You","Bob"],
		"subject": "Meeting Agenda",
		"date":    "2025-05-22",
		"body":    "Here's the agenda for tomorrow's meeting:\n- Item A\n- Item B"
	}
]

func _ready() -> void:
	# wire both select and activate (tap/click/enter)
	email_list.item_selected.connect(Callable(self, "_on_email_selected"))
	email_list.item_activated.connect(Callable(self, "_on_email_selected"))
	back_button.pressed.connect(Callable(self, "_show_email_list_view"))
	_load_inbox()

# 5. Data Loading: populate the inbox list
func _load_inbox() -> void:
	email_list.clear()
	for i in range(email_threads.size()):
		var mail = email_threads[i]
		# 1. Sender — Subject — Date snippet
		var label_text = "%s — %s <%s>" % [mail["sender"], mail["subject"], mail["date"]]
		var idx = email_list.add_item(label_text)
		# bind our array index as metadata
		email_list.set_item_metadata(idx, i)

# 3. Respond to selection
func _on_email_selected(index: int) -> void:
	var idx = email_list.get_item_metadata(index)
	var mail = email_threads[idx]
	email_list.visible  = false
	detail_view.visible = true
	_load_email_detail(mail)

# 4. Show the detail view
func _load_email_detail(mail: Dictionary) -> void:
	from_label.text    = "From: %s"   % mail["sender"]
	to_label.text      = "To: %s"     % mail["to"].join(", ")
	subject_label.text = "Subject: %s" % mail["subject"]
	date_label.text    = "Date: %s"    % mail["date"]
	body_text.clear()
	body_text.append_text(mail["body"])
	# scroll to top
	body_text.scroll_vertical = 0

# 4. Back to list
func _show_email_list_view() -> void:
	detail_view.visible = false
	email_list.visible  = true
	email_list.unselect_all()
