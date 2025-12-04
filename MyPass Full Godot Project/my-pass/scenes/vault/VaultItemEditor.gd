## Responsible for:
##  * Editing or creating a single VaultItem
##  * Showing different fields based on item_type
##  * Saving, deleting, or canceling edits
##  * Returning user to VaultRoot on completion

extends Control
class_name VaultItemEditor

# Header
@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel

# Shared fields
@onready var name_edit: LineEdit = %NameEdit

## --------------- Type field groups --------------------------------
# Login
@onready var login_fields: Control = %LoginFields
@onready var username_edit: LineEdit = %UsernameEdit
@onready var password_edit: LineEdit = %PasswordEdit
@onready var url_edit: LineEdit = %URLEdit
@onready var password_reveal_button: Button = %PasswordRevealButton
@onready var copy_username_button: Button = %CopyUsernameButton
@onready var copy_password_button: Button = %CopyPasswordButton
@onready var copy_url_button: Button = %CopyURLButton

# Credit Card
@onready var credit_card_fields: Control = %CreditCardFields
@onready var card_holder_edit: LineEdit = %CardHolderEdit
@onready var card_number_edit: LineEdit = %CardNumberEdit
@onready var expiry_edit: LineEdit = %ExpiryEdit
@onready var cvv_edit: LineEdit = %CvvEdit
@onready var card_number_reveal_button: Button = %CardNumberRevealButton
@onready var cvv_reveal_button: Button = %CvvRevealButton
@onready var copy_card_number_button: Button = %CopyCardNumberButton
@onready var copy_cvv_button: Button = %CopyCvvButton
@onready var login_suggested_password_edit: LineEdit = %LoginSuggestedPasswordEdit
@onready var login_generate_password_button: Button = %LoginGeneratePasswordButton
@onready var login_copy_password_button: Button = %LoginCopySuggestedPasswordButton

# Identity
@onready var identity_fields: Control = %IdentityFields
@onready var document_type_edit: LineEdit = %DocumentTypeEdit
@onready var id_number_edit: LineEdit = %IDNumberEdit
@onready var issuing_country_edit: LineEdit = %IssuingCountryEdit
@onready var id_expiry_edit: LineEdit = %IDExpiryEdit
@onready var ssn_edit: LineEdit = %SSNEdit
@onready var ssn_reveal_button: Button = %SsnRevealButton

# Secure Note
@onready var secure_note_fields: Control = %SecureNoteFields
@onready var note_title_edit: LineEdit = %NoteTitleEdit
@onready var note_body_edit: TextEdit = %NoteBodyEdit

# Bottom bar buttons
@onready var save_button: Button = %SaveButton
@onready var delete_button: Button = %DeleteButton
@onready var cancel_button: Button = %CancelButton

# MaskFiledProxies for secret/masked fields
var _password_proxy: MaskedFieldProxy
var _card_number_proxy: MaskedFieldProxy
var _cvv_proxy: MaskedFieldProxy
var _ssn_proxy: MaskedFieldProxy

var _item: VaultItem = null
var _is_new: bool = false
var _current_type: String = ""

var _password_revealed := false
var _card_number_revealed := false
var _cvv_revealed := false
var _ssn_revealed := false

# Wire up buttons, proxies, and initial UI state
func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	login_generate_password_button.pressed.connect(_on_login_generate_password_pressed)
	login_copy_password_button.pressed.connect(_on_login_copy_password_pressed)

	_show_type_fields("")  # hide all at start
	_set_mode_idle()
	_init_proxies()
	_connect_reveal_buttons()
	_connect_copy_buttons()

# Initialize proxies for masking sensitive fields
func _init_proxies() -> void:
	_password_proxy = MaskedFieldProxy.new()
	_password_proxy.setup(func() -> String:
		return password_edit.text
	)

	_card_number_proxy = MaskedFieldProxy.new()
	_card_number_proxy.setup(func() -> String:
		return card_number_edit.text
	)

	_cvv_proxy = MaskedFieldProxy.new()
	_cvv_proxy.setup(func() -> String:
		return cvv_edit.text
	)

	_ssn_proxy = MaskedFieldProxy.new()
	_ssn_proxy.setup(func() -> String:
		return ssn_edit.text
	)

# Connect reveal buttons for secret fields
func _connect_reveal_buttons() -> void:
	password_reveal_button.pressed.connect(_on_password_reveal_pressed)
	card_number_reveal_button.pressed.connect(_on_card_number_reveal_pressed)
	cvv_reveal_button.pressed.connect(_on_cvv_reveal_pressed)
	ssn_reveal_button.pressed.connect(_on_ssn_reveal_pressed)
	

# Connect copy-to-clipboard buttons for all fields
func _connect_copy_buttons() -> void:
	copy_username_button.pressed.connect(_on_copy_username_pressed)
	copy_password_button.pressed.connect(_on_copy_password_pressed)
	copy_url_button.pressed.connect(_on_copy_url_pressed)

	copy_card_number_button.pressed.connect(_on_copy_card_number_pressed)
	copy_cvv_button.pressed.connect(_on_copy_cvv_pressed)


# Toggle login password visibility and update proxy/button
func _on_password_reveal_pressed() -> void:
	_password_revealed = not _password_revealed
	password_edit.secret = not _password_revealed
	_password_proxy.reveal(_password_revealed)
	_update_password_button_label()

# Toggle credit card number visibility and update proxy/button
func _on_card_number_reveal_pressed() -> void:
	_card_number_revealed = not _card_number_revealed
	card_number_edit.secret = not _card_number_revealed
	_card_number_proxy.reveal(_card_number_revealed)
	_update_card_number_button_label()

# Toggle CVV visibility and update proxy/button
func _on_cvv_reveal_pressed() -> void:
	_cvv_revealed = not _cvv_revealed
	cvv_edit.secret = not _cvv_revealed
	_cvv_proxy.reveal(_cvv_revealed)
	_update_cvv_button_label()


# Toggle SSN visibility and update proxy/button
func _on_ssn_reveal_pressed() -> void:
	_ssn_revealed = not _ssn_revealed
	ssn_edit.secret = not _ssn_revealed
	_ssn_proxy.reveal(_ssn_revealed)
	_update_ssn_button_label()

# Copy username to clipboard via Clipboard_Guard
func _on_copy_username_pressed() -> void:
	var text := username_edit.text.strip_edges()
	if text.is_empty():
		UIHub.notify_warning("No username to copy.")
		return
	ClipboardGuard.copy_secret(text)

# Copy login password to clipboard via Clipboard_Guard
func _on_copy_password_pressed() -> void:
	var text := password_edit.text
	if text.is_empty():
		UIHub.notify_warning("No password to copy.")
		return
	ClipboardGuard.copy_secret(text)

# Copy login URL to clipboard via Clipboard_Guard
func _on_copy_url_pressed() -> void:
	var text := url_edit.text.strip_edges()
	if text.is_empty():
		UIHub.notify_warning("No URL to copy.")
		return
	ClipboardGuard.copy_secret(text)

# Copy card number to clipboard via Clipboard_Guard
func _on_copy_card_number_pressed() -> void:
	var text := card_number_edit.text.strip_edges()
	if text.is_empty():
		UIHub.notify_warning("No card number to copy.")
		return
	ClipboardGuard.copy_secret(text)

# Copy CVV to clipboard via Clipboard_Guard
func _on_copy_cvv_pressed() -> void:
	var text := cvv_edit.text.strip_edges()
	if text.is_empty():
		UIHub.notify_warning("No CVV to copy.")
		return
	ClipboardGuard.copy_secret(text)

# Generate a suggested password for login items
func _on_login_generate_password_pressed() -> void:
	var builder := PasswordBuilder.new()
	var pwd := builder.build() 

	login_suggested_password_edit.text = pwd
	login_suggested_password_edit.caret_column = pwd.length()
	login_suggested_password_edit.select_all()

# Copy suggested login password to clipboard
func _on_login_copy_password_pressed() -> void:
	var pwd := login_suggested_password_edit.text
	if pwd.is_empty():
		UIHub.notify_warning("Nothing to copy.")
		return

	ClipboardGuard.copy_secret(pwd)

# Update login password reveal button icon
func _update_password_button_label() -> void:
	password_reveal_button.text = "🔒" if _password_revealed else "👁"

# Update card number reveal button icon
func _update_card_number_button_label() -> void:
	card_number_reveal_button.text = "🔒" if _card_number_revealed else "👁"

# Update CVV reveal button icon
func _update_cvv_button_label() -> void:
	cvv_reveal_button.text = "🔒" if _cvv_revealed else "👁"

# Update SSN reveal button icon
func _update_ssn_button_label() -> void:
	ssn_reveal_button.text = "🔒" if _ssn_revealed else "👁"

# Toggle which field group is visible based on item type
func _show_type_fields(item_type: String) -> void:
	_current_type = item_type

	login_fields.visible = (item_type == "login")
	credit_card_fields.visible = (item_type == "credit_card")
	identity_fields.visible = (item_type == "identity")
	secure_note_fields.visible = (item_type == "secure_note")

# Called when user clicks item in VaultRoot / ItemListPanel
# Configure editor for editing an existing VaultItem
func edit_existing_item(item: VaultItem) -> void:
	_item = item
	_is_new = false

	if _item == null:
		_set_mode_idle()
		return

	title_label.text = "Edit Item"
	type_label.text = "Type: %s" % _item.item_type

	_show_type_fields(_item.item_type)
	_populate_shared_from_item()
	_populate_type_fields_from_item()
	SecurityWatcher.check_item_for_expiration(item)
	delete_button.disabled = false

# Called when user chooses a type in the SelectType scene
# Configure editor for creating a new VaultItem of given type
func start_new_item(item_type: String) -> void:
	_is_new = true
	_item = null
	_current_type = item_type

	title_label.text = "New Item"
	type_label.text = "Type: %s" % item_type

	_show_type_fields(item_type)
	_clear_all_fields()

	# New items cannot be deleted yet
	delete_button.disabled = true

# Reset editor to idle state with no selected item
func _set_mode_idle() -> void:
	title_label.text = "No item selected"
	type_label.text = ""
	_clear_all_fields()
	delete_button.disabled = true

# Clear all UI fields for every item type
func _clear_all_fields() -> void:
	name_edit.text = ""

	username_edit.text = ""
	password_edit.text = ""
	url_edit.text = ""

	card_holder_edit.text = ""
	card_number_edit.text = ""
	expiry_edit.text = ""
	cvv_edit.text = ""

	document_type_edit.text = ""
	id_number_edit.text = ""
	issuing_country_edit.text = ""
	id_expiry_edit.text = ""
	ssn_edit.text = ""

	note_title_edit.text = ""
	note_body_edit.text = ""

# Populate shared fields (name) from current item
func _populate_shared_from_item() -> void:
	if _item == null:
		return

	name_edit.text = _item.display_name

# Populate type-specific fields from current item
func _populate_type_fields_from_item() -> void:
	if _item == null:
		return

	match _item.item_type:
		"login":
			username_edit.text = str(_item.fields.get("username", ""))
			password_edit.text = str(_item.fields.get("password", ""))
			url_edit.text = str(_item.fields.get("url", ""))
		"credit_card":
			card_holder_edit.text = str(_item.fields.get("card_holder", ""))
			card_number_edit.text = str(_item.fields.get("card_number", ""))
			expiry_edit.text = str(_item.fields.get("expires_on", ""))
			cvv_edit.text = str(_item.fields.get("cvv", ""))
		"identity":
			document_type_edit.text = str(_item.fields.get("document_type", ""))
			id_number_edit.text = str(_item.fields.get("id_number", ""))
			issuing_country_edit.text = str(_item.fields.get("issuing_country", ""))
			id_expiry_edit.text = str(_item.fields.get("expires_on", ""))
			ssn_edit.text = str(_item.fields.get("social_security_number", ""))
		"secure_note":
			note_title_edit.text = str(_item.fields.get("title", ""))
			note_body_edit.text = str(_item.fields.get("body", ""))

# Apply current UI field values back onto the given item
func _apply_to_item(item: VaultItem) -> void:
	item.display_name = name_edit.text.strip_edges()

	match _current_type:
		"login":
			item.fields["username"] = username_edit.text
			item.fields["password"] = password_edit.text
			item.fields["url"] = url_edit.text
		"credit_card":
			item.fields["card_holder"] = card_holder_edit.text
			item.fields["card_number"] = card_number_edit.text
			item.fields["expires_on"] = expiry_edit.text
			item.fields["cvv"] = cvv_edit.text
		"identity":
			item.fields["document_type"] = document_type_edit.text
			item.fields["id_number"] = id_number_edit.text
			item.fields["issuing_country"] = issuing_country_edit.text
			item.fields["expires_on"] = id_expiry_edit.text
			item.fields["social_security_number"] = ssn_edit.text
		"secure_note":
			item.fields["title"] = note_title_edit.text
			item.fields["body"] = note_body_edit.text


# Validate and save current item (create or update) then return to vault
func _on_save_pressed() -> void:
	if _current_type == "":
		UIHub.notify_warning("No item type selected.")
		return

	if name_edit.text.strip_edges().is_empty():
		UIHub.notify_warning("Name is required.")
		return

	if _is_new:
		var item: VaultItem = _create_new_item_for_type(_current_type)
		if item == null:
			UIHub.notify_error("Could not create item for type: %s" % _current_type)
			return
		_apply_to_item(item)
		VaultStore.add_item(item)
		UIHub.notify_info("Item created.")
	else:
		if _item == null:
			UIHub.notify_error("No item loaded to save.")
			return
		_apply_to_item(_item)
		VaultStore.update_item(_item)
		UIHub.notify_info("Item updated.")

	UIHub.goto_vault()

# Create a new VaultItem resource instance for the given type
func _create_new_item_for_type(item_type: String) -> VaultItem:
	match item_type:
		"login":
			var li := LoginItem.new()
			li.item_type = "login"
			return li
		"credit_card":
			var cc := CreditCardItem.new()
			cc.item_type = "credit_card"
			return cc
		"identity":
			var id := IdentityItem.new()
			id.item_type = "identity"
			return id
		"secure_note":
			var sn := SecureNoteItem.new()
			sn.item_type = "secure_note"
			return sn
		_:
			return null


# Delete current item from VaultStore and return to vault
func _on_delete_pressed() -> void:
	if _is_new or _item == null:
		return

	var id := _item.id
	if id.is_empty():
		UIHub.notify_error("Item has no id to delete.")
		return

	VaultStore.delete_item(id)
	UIHub.notify_info("Item deleted.")
	UIHub.goto_vault()


# Cancel editing and return to vault without saving changes
func _on_cancel_pressed() -> void:
	UIHub.goto_vault()
