## Responsible for:
##  * Interface for secret/field proxies
##  * Defining the minimal API used by UI clients

extends RefCounted
class_name ISecretField

# Return the text currently exposed to the UI
func text() -> String:
	return ""

# Return whether the field is currently revealed
func is_revealed() -> bool:
	return false

# Toggle reveal state and return the new state
func toggle() -> bool:
	return false

# Apply masking behavior to a LineEdit
func mask(field: LineEdit) -> void:
	pass

# Apply unmasking behavior to a LineEdit
func unmask(field: LineEdit) -> void:
	pass
