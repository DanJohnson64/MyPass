## Responsible for:
##  * Handling login UI flow
##  * Validating user input for login
##  * Navigating to Register and Recovery screens
##  * Managing password masking and visibility toggle

extends Control

@onready var email_edit:LineEdit = %EmailEdit
@onready var password_edit:LineEdit = %PasswordEdit
@onready var login_button:Button = %LoginButton
@onready var register_button:Button = %RegisterButton
@onready var recovery_button:Button = %RecoveryButton
@onready var password_toggle_button: Button = %PasswordToggleButton
var password_proxy: MaskedFieldProxy

# Connects all button signals, sets up the masking proxy, and initializes password toggle state.
func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	recovery_button.pressed.connect(_on_recovery_pressed)
	visibility_changed.connect(_on_visibility_changed)
	# Create proxy for masking/unmasking
	password_proxy = MaskedFieldProxy.new()
	password_toggle_button.pressed.connect(_on_toggle_password_visibility)
	password_toggle_button.text = "👁"

# Validates inputs, attempts login, and routes to the vault on success.
func _on_login_pressed() -> void:
	var email := email_edit.text.strip_edges()
	var pwd := password_edit.text

	if email == "" or pwd == "":
		UIHub.notify_warning("Email and master password are required.")
		return

	var ok := SessionManager.login(email, pwd)
	if not ok:
		UIHub.notify_warning("Login failed. Check email and master password.")
		return

	UIHub.goto_vault()

# Navigates to account registration screen
func _on_register_pressed() -> void:
	UIHub.goto_register()

# Opens the account recovery screen
func _on_recovery_pressed() -> void:
	UIHub.open_recovery()

# Clears all input fields when the login UI becomes visible
func clear_fields() -> void:
	email_edit.text = ""
	password_edit.text = ""
	email_edit.grab_focus()

# Resets fields and button text when returning to this screen
func _on_visibility_changed() -> void:
	if visible:
		clear_fields()
		password_toggle_button.text = "👁"

# Masks/unmasks password on toggle button pressed
func _on_toggle_password_visibility() -> void:
	var now_revealed := password_proxy.toggle()
	if now_revealed:
		password_proxy.unmask(password_edit)
		password_toggle_button.text = "👁"  
	else:
		password_proxy.mask(password_edit)
		password_toggle_button.text = "🔒"   
