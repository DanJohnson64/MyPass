## Responsible for:
##  * Letting the user choose which vault item type to create
##  * Navigating to VaultItemEditor in "new item" mode
##  * Providing a way to go back to the vault list without creating anything

extends Control
class_name SelectItemType

@onready var login_button: Button = %LoginButton
@onready var credit_card_button: Button = %CreditCardButton
@onready var identity_button: Button = %IdentityButton
@onready var secure_note_button: Button = %SecureNoteButton
@onready var back_button: Button = %BackButton

# Wire up type buttons and back button
func _ready() -> void:
	# One button per vault item type
	login_button.pressed.connect(func() -> void:
		_on_type_chosen("login")
	)
	credit_card_button.pressed.connect(func() -> void:
		_on_type_chosen("credit_card")
	)
	identity_button.pressed.connect(func() -> void:
		_on_type_chosen("identity")
	)
	secure_note_button.pressed.connect(func() -> void:
		_on_type_chosen("secure_note")
	)

	back_button.pressed.connect(_on_back_pressed)


## ----------------------- Type Selection Handling ---------------------------

# Ask UIHub to open the editor for a new item of this type
func _on_type_chosen(item_type: String) -> void:
	UIHub.open_new_item(item_type)

# Return to the main vault list
func _on_back_pressed() -> void:
	UIHub.goto_vault()
