extends Control

@onready var entry_container: VBoxContainer = $ScrollContainer/EntryContainer

func _ready():
    add_entry("My First Entry", "Today I started working on this cool journal app. It's going to be great for keeping track of thoughts and discoveries!")
    add_entry("Observations", "The old willow tree near the library seems to hum at dusk. I should investigate further. #mystery #spooky")

func add_entry(title: String, entry_text: String):
    var entry_item = VBoxContainer.new()
    entry_item.layout_mode = 2
    entry_item.size_flags_horizontal = 3

    if not title.is_empty():
        var title_label = Label.new()
        title_label.text = title
        # Optional: Make title stand out, e.g., by theme override or a specific stylebox.
        # title_label.add_theme_font_override("font", preload("res://path/to/bold_font.tres")) # Example
        title_label.add_theme_font_size_override("font_size", 18) # Example: Larger font size
        title_label.size_flags_horizontal = 3
        entry_item.add_child(title_label)
        
        # Add a small spacer after the title
        var title_spacer = Control.new()
        title_spacer.custom_minimum_size = Vector2(0, 5) # 5 pixels of vertical space
        entry_item.add_child(title_spacer)


    var text_label = RichTextLabel.new()
    text_label.bbcode_enabled = true # Good practice for RichTextLabel
    text_label.text = entry_text
    text_label.fit_content = true
    text_label.size_flags_horizontal = 3
    entry_item.add_child(text_label)

    # Optional: Add some spacing between entries
    if entry_container.get_child_count() > 0:
        var spacer = Control.new()
        spacer.custom_minimum_size = Vector2(0, 10) # 10 pixels of vertical space
        entry_container.add_child(spacer)
        
    entry_container.add_child(entry_item)
