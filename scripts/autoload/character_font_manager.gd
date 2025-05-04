# character_font_manager.gd
extends Node

# Dictionary to store character fonts and colors
# Format: { "character_id": { "font": FontResource, "color": Color } }
var character_styles: Dictionary = {}

# Default font and color for fallback
var default_font: Font
var default_color: Color = Color(1, 1, 1, 1)  # White

const scr_debug: bool = false
var debug

func _ready():
	debug = scr_debug or GameController.sys_debug if Engine.has_singleton("GameController") else scr_debug
	if debug: print("Character Font Manager initialized")
	
	# Load default font
	if ResourceLoader.exists("res://assets/fonts/default_font.ttf"):
		default_font = load("res://assets/fonts/default_font.ttf")
		if debug: print("Loaded default font")
	else:
		# Try to use the default theme font
		var theme = ThemeDB.get_default_theme()
		if theme:
			default_font = theme.get_font("normal_font", "RichTextLabel")
			if debug: print("Using theme default font")

# Register a character's font and color
func register_character_style(character_id: String, font_path: String, text_color: Color) -> void:
	var style = {}
	
	# Load font if path is valid
	if font_path and ResourceLoader.exists(font_path):
		style["font"] = load(font_path)
		if debug: print("Loaded font for " + character_id + ": " + font_path)
	else:
		style["font"] = default_font
		if debug: print("Using default font for " + character_id)
	
	style["color"] = text_color
	character_styles[character_id] = style

# Get font for a character
func get_font(character_id: String) -> Font:
	if character_styles.has(character_id) and character_styles[character_id].has("font"):
		return character_styles[character_id]["font"]
	return default_font

# Get text color for a character
func get_color(character_id: String) -> Color:
	if character_styles.has(character_id) and character_styles[character_id].has("color"):
		return character_styles[character_id]["color"]
	return default_color
