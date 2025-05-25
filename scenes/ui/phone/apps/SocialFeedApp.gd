extends Control

@onready var post_feed_container: VBoxContainer = $ScrollContainer/PostFeedContainer

func _ready():
    add_post("Just saw the weirdest cloud formation! #skywatching #anomaly", "5 minutes ago")
    add_post("Anyone else hear that strange humming sound last night near the old lighthouse? It's probably nothing... #mystery", "2 hours ago")

func add_post(post_text: String, timestamp_text: String):
    var post_item = VBoxContainer.new()
    post_item.layout_mode = 2 # Make VBoxContainer itself expand if needed within its parent (PostFeedContainer)
    post_item.size_flags_horizontal = 3 # Fill width

    var text_label = Label.new()
    text_label.text = post_text
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    text_label.size_flags_horizontal = 3 # Fill width

    var timestamp_label = Label.new()
    timestamp_label.text = timestamp_text
    timestamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    timestamp_label.size_flags_horizontal = 3 # Fill width
    
    # Optional: Add some spacing between post text and timestamp
    timestamp_label.set("theme_override_constants/margin_top", 5)


    post_item.add_child(text_label)
    post_item.add_child(timestamp_label)
    
    # Optional: Add some spacing between posts
    if post_feed_container.get_child_count() > 0:
        var spacer = Control.new()
        spacer.custom_minimum_size = Vector2(0, 10) # 10 pixels of vertical space
        post_feed_container.add_child(spacer)

    post_feed_container.add_child(post_item)
