## Responsible for:
##  * Representing an identity document vault item
##  * Initializing default identity-related fields

extends VaultItem
class_name IdentityItem

# Call base init and set values
func init() -> void:
	item_type = "identity"
	display_name = "New Identity"
	fields = {
		"document_type": "",
		"id_number": "",
		"issuing_country": "",
		"expires_on": "",
		"social_security_number": "",
	}
