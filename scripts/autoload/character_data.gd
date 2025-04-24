# character_data.gd
extends Resource
class_name CharacterData

# Core character information
var id: String = ""
var name: String = ""
var description: String = ""
var portrait_path: String = ""
var dialogue_file: String = ""  # Path to the character's dialogue file
var initial_dialogue_title: String = "start"

# Character personality and traits
var personality_traits: Array = []  # Changed from Array[String]
var interests: Array = []  # Changed from Array[String]
var background: String = ""

# Observable features
var observable_features: Dictionary = {}

# Special items and relationships
var special_items: Array = []  # Changed from Array[Dictionary]
var relationships: Dictionary = {}

# Function to load from dictionary
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	portrait_path = data.get("portrait_path", "")
	dialogue_file = data.get("dialogue_file", "res://data/dialogues/" + id.to_lower() + ".dialogue")
	initial_dialogue_title = data.get("initial_dialogue_title", "start")
	personality_traits = data.get("personality_traits", [])
	interests = data.get("interests", [])
	background = data.get("background", "")
	observable_features = data.get("observable_features", {})
	special_items = data.get("special_items", [])
	relationships = data.get("relationships", {})
