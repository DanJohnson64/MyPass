## Responsible for:
##  * Masking/unmasking sensitive LineEdit fields
##  * Providing controlled access to revealed/hidden text

extends ISecretField
class_name MaskedFieldProxy


var _getter: Callable
var _revealed := false

# Assign getter used to pull raw text
func setup(getter: Callable) -> MaskedFieldProxy:
	_getter = getter; return self
	
# Set reveal state directly
func reveal(on: bool): _revealed = on

# Return either raw or masked text
func text() -> String:
	var raw: String = _getter.call()
	return raw if _revealed else "•".repeat(max(4, raw.length()))

# Check if field is currently revealed
func is_revealed() -> bool:
	return _revealed

# Toggle revealed state and return new value
func toggle() -> bool:
	_revealed = not _revealed
	return _revealed

# Apply masking to a LineEdit
func mask(field: LineEdit) -> void:
	field.secret = true

# Remove masking from a LineEdit
func unmask(field: LineEdit) -> void:
	field.secret = false
