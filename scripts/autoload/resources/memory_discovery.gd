# memory_discovery.gd
class_name MemoryDiscovery
extends Resource

# Discovery entry for tracking when and how memories were found
@export var memory_tag: String = ""
@export var description: String = ""
@export var character_id: String = ""
@export var discovery_method: String = ""  # "look_at", "item_found", etc.
@export var location_id: String = ""
@export var timestamp: float = 0.0
@export var related_quest: String = ""
@export var related_dialogue: String = ""

func _init(tag: String = "", desc: String = "", char_id: String = ""):
	memory_tag = tag
	description = desc
	character_id = char_id
	timestamp = Time.get_unix_time_from_system()

func get_formatted_timestamp() -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d/%02d/%04d %02d:%02d" % [datetime.month, datetime.day, datetime.year, datetime.hour, datetime.minute]

func to_dictionary() -> Dictionary:
	return {
		"memory_tag": memory_tag,
		"description": description,
		"character_id": character_id,
		"discovery_method": discovery_method,
		"location_id": location_id,
		"timestamp": timestamp,
		"related_quest": related_quest,
		"related_dialogue": related_dialogue
	}

func from_dictionary(data: Dictionary):
	memory_tag = data.get("memory_tag", "")
	description = data.get("description", "")
	character_id = data.get("character_id", "")
	discovery_method = data.get("discovery_method", "")
	location_id = data.get("location_id", "")
	timestamp = data.get("timestamp", 0.0)
	related_quest = data.get("related_quest", "")
	related_dialogue = data.get("related_dialogue", "")
