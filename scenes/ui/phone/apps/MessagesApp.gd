extends Control

@onready var header_label: Label = $AppMarginContainer/MainVBox/HeaderHBox/HeaderLabel
@onready var back_to_list_button: Button = $AppMarginContainer/MainVBox/HeaderHBox/BackToListButton
@onready var conversation_list_view: ScrollContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ConversationListView
@onready var conversation_list_vbox: VBoxContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ConversationListView/ConversationListVBox
@onready var chat_view: ScrollContainer = $AppMarginContainer/MainVBox/ContentSwitchControl/ChatView
@onready var message_rich_text_label: RichTextLabel = $AppMarginContainer/MainVBox/ContentSwitchControl/ChatView/ChatViewMargins/MessageRichTextLabel

# Mock data for conversations
var conversations_data = {
    "contact1_id": {
        "name": "Alice Wonderland",
        "messages": [
            {"sender": "Alice Wonderland", "text": "Hey! Down the rabbit hole yet?", "style_tag": null},
            {"sender": "Player", "text": "Not yet, still debugging this phone.", "style_tag": null},
            {"sender": "Alice Wonderland", "text": "Tell me when you see a cat that grins.", "style_tag": "spore_data"}
        ]
    },
    "contact2_id": {
        "name": "Mad Hatter",
        "messages": [
            {"sender": "Mad Hatter", "text": "Tea party at my place! You're invited!", "style_tag": null},
            {"sender": "Player", "text": "Is it a coding tea party?", "style_tag": null},
            {"sender": "Mad Hatter", "text": "Of course! Bring your own bugs!", "style_tag": "important_quest"}
        ]
    }
}

const STYLE_TAG_COLORS = {
    "spore_data": Color.PALE_VIOLET_RED, # Example color
    "important_quest": Color.GOLD,      # Example color
    "default_npc": Color.WHITE_SMOKE,       # Example: Light gray for NPC
    "default_player": Color.LIGHT_CYAN      # Example: Light blue for Player
}

var current_conversation_id = null

func _ready():
    back_to_list_button.connect("pressed", Callable(self, "_on_back_to_list_button_pressed"))
    populate_conversation_list()
    show_conversation_list()

func populate_conversation_list():
    # Clear any existing buttons
    for child in conversation_list_vbox.get_children():
        child.queue_free()

    for convo_id in conversations_data:
        var convo_button = Button.new()
        convo_button.text = conversations_data[convo_id]["name"]
        convo_button.connect("pressed", Callable(self, "_on_conversation_selected").bind(convo_id))
        conversation_list_vbox.add_child(convo_button)

func _on_conversation_selected(convo_id: String):
    current_conversation_id = convo_id
    load_chat_view(convo_id)
    show_chat_view()

func load_chat_view(convo_id: String):
    message_rich_text_label.clear()
    var conversation = conversations_data[convo_id]
    header_label.text = conversation["name"]

    for message_data in conversation["messages"]:
        var sender = message_data["sender"]
        var text = message_data["text"]
        var style_tag = message_data["style_tag"]

        var alignment_tag_open = ""
        var alignment_tag_close = ""
        var final_text_color = STYLE_TAG_COLORS.get("default_npc", Color.WHITE)


        if sender == "Player":
            alignment_tag_open = "[align=right]"
            alignment_tag_close = "[/align]"
            final_text_color = STYLE_TAG_COLORS.get("default_player", Color.LIGHT_SKY_BLUE)
        
        # If a specific style tag is present, it overrides default sender color
        if style_tag and STYLE_TAG_COLORS.has(style_tag):
            final_text_color = STYLE_TAG_COLORS[style_tag]
        
        var color_hex = final_text_color.to_html(false) # no alpha

        message_rich_text_label.append_text(alignment_tag_open)
        message_rich_text_label.push_font_size(16) # Example font size
        message_rich_text_label.push_bold()
        message_rich_text_label.push_color(final_text_color) # Push color for sender name
        message_rich_text_label.append_text(sender + ": ")
        message_rich_text_label.pop() # Pop color
        message_rich_text_label.pop() # Pop bold

        message_rich_text_label.push_color(final_text_color) # Push color for message text
        message_rich_text_label.append_text(text)
        message_rich_text_label.pop() # Pop color
        
        message_rich_text_label.append_text(alignment_tag_close)
        message_rich_text_label.newline()
        message_rich_text_label.newline() # Extra newline for spacing

    # Scroll to bottom
    chat_view.call_deferred("set_v_scroll", message_rich_text_label.get_v_scroll_bar().max_value)


func show_conversation_list():
    conversation_list_view.visible = true
    chat_view.visible = false
    back_to_list_button.visible = false
    header_label.text = "Messages"

func show_chat_view():
    conversation_list_view.visible = false
    chat_view.visible = true
    back_to_list_button.visible = true
    # HeaderLabel is updated in load_chat_view

func _on_back_to_list_button_pressed():
    show_conversation_list()
