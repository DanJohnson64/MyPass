## Responsible for:
##  * Encoding Dictionaries/Arrays to JSON strings
##  * Decoding JSON strings back into Variant data

extends RefCounted
class_name JsonUtil

# Convert Variant to JSON string
static func encode(data: Variant) -> String:
	return JSON.stringify(data)

# Parse JSON string into Variant
static func decode(text:String) -> Variant:
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("JSON parse error: %s" % json.get_error_message())
		return null
	return json.data
