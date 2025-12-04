## Responsible for:
##  * Representing a credit card vault item
##  * Initializing default credit card fields

extends VaultItem
class_name CreditCardItem

# Call base init and set values
func init() -> void:
	item_type = "credit_card"
	display_name = "New Card"
	fields = {
		"card_holder": "",
		"card_number": "",
		"expires_on": "",
		"cvv": "",
	}
