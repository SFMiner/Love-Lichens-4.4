extends Control

const scr_debug := false
var debug := false
var current_reply_to := ""
var all_emails : Dictionary
@onready var inbox = %EmailList_Inbox
@onready var sent = %EmailList_Sent
@onready var archived = %EmailList_Archive
@onready var all_boxes = [inbox, sent, archived]
func _ready() -> void:
	var _fname = "_ready"
	debug = scr_debug or GameController.sys_debug
	load_email_lists()
	connect_all_signals()
	show_container("list_email")
	show_tab("inbox")

func show_container(container : String):
	match container:
		"list_email":
			%TabContainer.visible = true
			%EmailViewerPanel.visible = false
			%ComposePanel.visible = false
		"read_email":
			%TabContainer.visible = false
			%EmailViewerPanel.visible = true
			%ComposePanel.visible  = false
		"compose_email":
			%TabContainer.visible = false
			%EmailViewerPanel.visible = false
			%ComposePanel.visible = true

func connect_all_signals() -> void:
	%EmailList_Inbox.connect("item_selected", Callable(self, "_on_inbox_email_selected"))
	%EmailList_Sent.connect("item_selected", Callable(self, "_on_sent_email_selected"))
	%EmailList_Archive.connect("item_selected", Callable(self, "_on_archive_email_selected"))
	%ReplyButton.connect("pressed", Callable(self, "_on_reply_pressed"))
	%SendButton.connect("pressed", Callable(self, "send_email"))
	%SendCancelButton.connect("pressed", Callable(self, "show_container").bind("read_email"))
	%ReadCancelButton.connect("pressed", Callable(self, "show_container").bind("list_email"))
	%ArchiveButton.connect("pressed", Callable(self, "_on_archive_pressed"))



func load_email_lists() -> void:
	all_emails = GameState.phone_apps["email_app_entries"]

	for v in all_boxes:
		for c in v.get_children():
			c.queue_free()

	for email_id in all_emails.keys():
		var email = all_emails[email_id]
		match email["box"]:
			"inbox":
				add_email_button_to_list(inbox, email_id, email)
			"sent":
				add_email_button_to_list(sent, email_id, email)
			"archive":
				add_email_button_to_list(archived, email_id, email)


func add_email_button_to_list(container: VBoxContainer, email_id: String, email: Dictionary) -> void:
	var label := "%s — %s" % [email["timestamp"], email["subject"]]
	var b = Button.new()
	b.text = label
	b.size_flags_horizontal = Control.SIZE_FILL
	b.clip_text = true
	b.gui_input.connect(Callable(self, "_on_email_gui_input").bind(email_id))
	container.add_child(b)

func get_preview_line(body: String) -> String:
	var lines := body.split("\n")
	return lines[0] if lines.size() > 0 else ""


func _on_email_gui_input(event: InputEvent, email_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.double_click:
		show_email(email_id)

func show_email(email_id: String) -> void:
	var email = GameState.phone_apps["email_app_entries"].get(email_id, null)
	if email == null:
		push_warning("Invalid email ID")
		return

	show_container("read_email")
	
	%SubjectLabel.text = email["subject"]
	%SenderLabel.text = "From: " + email["sender"]
	%RecipientLabel.text = "To: " + email["recipient"]
	%TimestampLabel.text = email["timestamp"]
	%BodyText.clear()
	%BodyText.append_text(email["body"])
	%EmailViewerPanel.visible = true
	%ComposePanel.visible = false
	current_reply_to = email_id

func _on_reply_pressed() -> void:
	var email = GameState.phone_apps["email_app_entries"].get(current_reply_to, null)
	if email == null:
		push_warning("Cannot reply, email not found.")
		return
	var prefill := {
		"recipient": email["sender"],
		"subject": "Re: " + email["subject"]
	}
	compose_email(current_reply_to, prefill)

func compose_email(reply_to_id := "", prefill := {}) -> void:
	show_container("compose_email")
	%ToField.text = prefill.get("recipient", "")
	%SubjectField.text = prefill.get("subject", "")
	%BodyEdit.text = prefill.get("body", "")
#	%ComposePanel.visible = true
#	%EmailViewerPanel.visible = false
	current_reply_to = reply_to_id

func send_email() -> void:
	var to = %ToField.text.strip_edges()
	var subject = %SubjectField.text.strip_edges()
	var body = %BodyEdit.text.strip_edges()

	if to == "" or subject == "" or body == "":
		push_warning("Cannot send incomplete email")
		return

	var email_id = generate_email_id()
	var email := {
		"email_id": email_id,
		"reply_to_id": current_reply_to,
		"subject": subject,
		"body": body,
		"timestamp": TimeSystem.format_game_time("Mmmm, dd, yyyy h:nn"),
		"sender": "adam",
		"recipient": to,
		"box": "sent"
	}

	GameState.phone_apps["email_app_entries"][email_id] = email
	load_email_lists()
	show_container("list_email")	

func generate_email_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _on_archive_pressed() -> void:
	archive_email(current_reply_to)

func archive_email(email_id: String) -> void:
	if GameState.phone_apps["email_app_entries"].has(email_id):
		GameState.phone_apps["email_app_entries"][email_id]["box"] = "archive"
		load_email_lists()
		%EmailViewerPanel.visible = false

func show_tab(tab: String) -> void:
	match tab:
		"inbox":
			%TabContainer.current_tab = 0
		"sent":
			%TabContainer.current_tab = 1
		"archive":
			%TabContainer.current_tab = 2

func _on_bold_button_pressed() -> void:
	%BodyEdit.insert_text_at_cursor("[b][/b]")

func _on_italic_button_pressed() -> void:
	%BodyEdit.insert_text_at_cursor("[i][/i]")

func _on_img_button_pressed() -> void:
	%BodyEdit.insert_text_at_cursor("[img]res://assets/images/your_image.png[/img]")

# Fucntionality to be added: connect to dialogue system for reply options.
