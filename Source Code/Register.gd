## Responsible for:
##  * Collecting email + master password
##  * Collecting answers to 3 preset security questions
##  * Creating a new account via Session_Manager
##  * Navigating back to Auth on success/cancel

extends Control

@onready var email_edit:LineEdit = %EmailEdit
@onready var password_edit:LineEdit = %PasswordEdit
@onready var register_suggested_password_edit: LineEdit = %RegisterSuggestedPasswordEdit
@onready var register_generate_password_button: Button = %RegisterGeneratePasswordButton
@onready var register_copy_password_button: Button = %RegisterCopyPasswordButton
@onready var password_reveal_button: Button = %PasswordRevealButton

@onready var q1_label:Label = %Question1Label
@onready var a1_edit:LineEdit = %Answer1Edit
@onready var q2_label:Label = %Question2Label
@onready var a2_edit:LineEdit = %Answer2Edit
@onready var q3_label:Label = %Question3Label
@onready var a3_edit:LineEdit = %Answer3Edit

@onready var create_button:Button = %CreateButton
@onready var back_button:Button = %BackButton

var _password_revealed: bool = false
var _password_proxy: MaskedFieldProxy

# Wire up registration UI and initialize password masking
func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	back_button.pressed.connect(_on_back_pressed)
	register_generate_password_button.pressed.connect(_on_register_generate_password_pressed)
	register_copy_password_button.pressed.connect(_on_register_copy_password_pressed)
	password_reveal_button.pressed.connect(_on_password_reveal_pressed)
	_init_proxies()


# Initialize password proxy for masking/unmasking
func _init_proxies() -> void:
	_password_proxy = MaskedFieldProxy.new()
	_password_proxy.setup(func() -> String:
		return password_edit.text
	)

# Generate a suggested strong password for registration
func _on_register_generate_password_pressed() -> void:
	var builder := PasswordBuilder.new()
	var pwd := builder.build()

	register_suggested_password_edit.text = pwd
	register_suggested_password_edit.caret_column = pwd.length()
	register_suggested_password_edit.select_all()

# Copy suggested password to clipboard using Clipboard_Guard
func _on_register_copy_password_pressed() -> void:
	var pwd := register_suggested_password_edit.text
	if pwd.is_empty():
		UIHub.notify_warning("Nothing to copy.")
		return

	ClipboardGuard.copy_secret(pwd)

# Handle account creation, validation, and recovery data setup
func _on_create_pressed() -> void:
	var email := email_edit.text.strip_edges()
	var pwd := password_edit.text

	if email == "" or pwd == "":
		UIHub.notify_warning("Email and master password are required.")
		return

	# Delegate the rule to the observer class
	if SecurityWatcher.is_weak(pwd):
		UIHub.notify_warning(
			"Master password is weak. Use at least 10 characters, with at least 1 uppercase letter and 2 symbols.")
		return

	# Build recovery data from preset questions + answers
	var rec: Array = [
		{
			"question": q1_label.text,
			"answer": a1_edit.text
		},
		{
			"question": q2_label.text,
			"answer": a2_edit.text
		},
		{
			"question": q3_label.text,
			"answer": a3_edit.text
		}
	]

	var ok := SessionManager.register_account(email, pwd, rec)
	if not ok:
		UIHub.notify_warning("Account already exists or could not be created.")
		return

	UIHub.notify_info("Account created. You can now log in.")
	UIHub.goto_auth()

# Return to the Auth/login screen without creating an account
func _on_back_pressed() -> void:
	UIHub.goto_auth()

# Update the password reveal button icon based on state
func _update_password_button_label() -> void:
	password_reveal_button.text = "🔒" if _password_revealed else "👁"

# Toggle password visibility and sync with proxy/button label
func _on_password_reveal_pressed() -> void:
	_password_revealed = not _password_revealed
	password_edit.secret = not _password_revealed
	_password_proxy.reveal(_password_revealed)
	_update_password_button_label()
