## Responsible for:
##  * Representing a login vault item
##  * Initializing default login fields

extends VaultItem
class_name LoginItem

# Call base init and set values
func init() -> void:
	item_type = "login"
	display_name = "New Login"
	fields = {
		"username": "",
		"password": "",
		"url": "",
	}
