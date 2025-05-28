extends Control

@onready var channel_list : ItemList = $ChannelListView
@onready var chat_view : Control = $ChannelChatView
@onready var back_button : Button = $ChannelChatView/VBoxChat/BackButton
@onready var chat_text : RichTextLabel   = $ChannelChatView/VBoxChat/ChatScroll/ChatText
@onready var text_field : TextEdit  = $ChannelChatView/VBoxChat/HBoxContainer/TextField

# Dummy data: channel → array of { "user": String, "text": String }
var channels: Dictionary = {
	"#general": [
		{"user":"Alice",   "text":"Welcome to #general!"},
		{"user":"Bob",     "text":"Anyone here up for a lichens hike?"}
	],
	"#lichen_enthusiasts": [
		{"user":"Charlie", "text":"I found a new Prototaxites specimen today!"},
		{"user":"Dana",    "text":"Share pics? #science"}
	]
}

func _ready() -> void:
	# wire signals
	channel_list.item_selected.connect(Callable(self, "_on_channel_selected"))
#	back_button.pressed.connect(Callable(self, "_show_channel_list_view"))
	# populate the channel list
	load_channels_by_tags([])

# Populate the ItemList of channels (tags filtering stubbed out)
func load_channels_by_tags(tags: Array) -> void:
	channel_list.clear()
	for chan_id in channels.keys():
		channel_list.add_item(chan_id)

# When a channel is tapped…
func _on_channel_selected(index: int) -> void:
	var chan_id = channel_list.get_item_text(index)
	channel_list.visible = false
	chat_view.visible    = true
	load_channel_messages(chan_id)

# Fill the RichTextLabel with BBCode-styled messages
func load_channel_messages(channel_id: String) -> void:
	chat_text.clear()
	if not channels.has(channel_id):
		chat_text.bbcode_text = "[i]No messages in this channel.[/i]"
		return
	for msg in channels[channel_id]:
		chat_text.append_text("[b]%s:[/b] %s\n" % [msg["user"], msg["text"]])

# Back button: hide chat, show channel list
func _show_channel_list_view() -> void:
	chat_view.visible    = false
	channel_list.visible = true
	chat_text.clear()
	channel_list.deselect_all()



func _on_channel_list_view_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var chan_id = channel_list.get_item_text(index)
	print("Opening chat for channel:", chan_id)
	channel_list.visible = false
	chat_view.visible    = true
	load_channel_messages(chan_id) # Replace with function body.


func _on_submit_button_button_up() -> void:
	chat_text.append_text("\n[p align=\"right\"][b]Adam:[/b] " + text_field.text + "[/p]") # Replace with function body.
