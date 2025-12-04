## Responsible for:
##  * Representing a secure note vault item
##  * Initializing default note fields

extends VaultItem
class_name SecureNoteItem

# Call base init and set values
func init() -> void:
	item_type = "secure_note"
	display_name = "New Secure Note"
	fields = {
		"title": "",
		"body": "",
	}
