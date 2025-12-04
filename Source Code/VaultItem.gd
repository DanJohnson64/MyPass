## Responsible for:
##  * Base data model for all vault items
##  * Serializing/deserializing fields to/from dictionaries

extends Resource
class_name VaultItem

var id: String = ""
var item_type: String = ""
var display_name: String = ""
var fields: Dictionary = {}

# Convert this item into a serializable Dictionary
func to_dict() -> Dictionary:
	return{
		"id": id,
		"item_type": item_type,
		"display_name": display_name,
		"fields": fields,
	}

# Populate this item from a Dictionary
func from_dict(data: Dictionary) -> void:
	id = data.get("id", id)
	item_type = data.get("item_type", item_type)
	display_name = data.get("display_name", display_name)
	fields = data.get("fields", fields)
