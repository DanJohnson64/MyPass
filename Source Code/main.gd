## Responsible for:
##  * Acting as main UI mediator
##  * Switching between Auth / Register / Vault / Recovery screens
##  * Forwarding toasts to ToastLayer
##  * Driving SessionManager auto-lock via process()

extends Control

@onready var auth_screen: Control = $Auth
@onready var register_screen: Control = $Register
@onready var vault_root: Control = $VaultRoot
@onready var recovery_screen: Control = $Recovery
@onready var toast_layer: Node = $ToastLayer
@onready var vault_item_editor: Control = $VaultItemEditor
@onready var select_item_type: Control = $SelectItemType

# Set up UI wiring, signals, and initial screen
func _ready() -> void:
	# Listen to UI navigation
	UIHub.show_panel.connect(_on_show_panel)
	UIHub.show_toast.connect(_on_show_toast)

	# SessionManager events redirect the UI
	SessionManager.logged_in.connect(_on_logged_in)
	SessionManager.logged_out.connect(_on_logged_out)
	SessionManager.locked_by_timeout.connect(_on_locked_by_timeout)

	# Start on Auth
	_show_only(auth_screen)

# Drive session timeout and auto-lock each frame
func _process(delta: float) -> void:
	# Drive session timeout / auto-lock
	SessionManager.process(delta)


## ------------------------- UIHub Callbacks ---------------------------------

# Handle UIHub panel navigation requests
func _on_show_panel(panel_name: String, payload: Dictionary = {}) -> void:
	match panel_name:
		UIHub.PANEL_AUTH:
			_show_only(auth_screen)
		UIHub.PANEL_REGISTER:
			_show_only(register_screen)
		UIHub.PANEL_VAULT:
			_show_only(vault_root)
		UIHub.PANEL_RECOVERY:
			_show_only(recovery_screen)
		UIHub.PANEL_SELECT_ITEM_TYPE:
			_show_only(select_item_type)
		UIHub.PANEL_VAULT_EDITOR:
			_show_only(vault_item_editor)
			_handle_vault_editor_payload(payload)
		_:
			if vault_root.has_method("handle_panel_request"):
				vault_root.handle_panel_request(panel_name, payload)

# Forward toast requests to the ToastLayer
func _on_show_toast(message: String, style: String) -> void:
	if toast_layer and toast_layer.has_method("show_toast"):
		toast_layer.show_toast(message, style)


## ------------------------ SessionManager Hooks -----------------------------

# React to SessionManager login event and go to vault
func _on_logged_in() -> void:
	UIHub.goto_vault()


# React to SessionManager logout event and go to auth
func _on_logged_out() -> void:
	UIHub.goto_auth()

# React to SessionManager auto-lock and notify user
func _on_locked_by_timeout() -> void:
	UIHub.notify_warning("Session locked due to inactivity.")
	UIHub.goto_auth()

# Track user input to reset inactivity/lock timer
func _unhandled_input(event: InputEvent) -> void:
	if SessionManager != null and event.is_pressed():
		SessionManager.register_activity()

## ----------------------------- Helpers -------------------------------------

# Show only the target screen
func _show_only(target: Control) -> void:
	if is_instance_valid(auth_screen):
		auth_screen.visible = false
	if is_instance_valid(register_screen):
		register_screen.visible = false
	if is_instance_valid(vault_root):
		vault_root.visible = false
	if is_instance_valid(recovery_screen):
		recovery_screen.visible = false
	if is_instance_valid(vault_item_editor):
		vault_item_editor.visible = false
	if is_instance_valid(select_item_type):
		select_item_type.visible = false
		
	if is_instance_valid(target):
		target.visible = true

# Handle if item is either new or is being edited
func _handle_vault_editor_payload(payload: Dictionary) -> void:
	if not vault_item_editor:
		return

	var mode := str(payload.get("mode", "edit"))

	if mode == "new":
		var item_type := str(payload.get("item_type", ""))
		if vault_item_editor.has_method("start_new_item"):
			vault_item_editor.start_new_item(item_type)
	else:
		# Edit existing item flow
		var item: Variant = payload.get("item", null)
		if vault_item_editor.has_method("edit_existing_item"):
			vault_item_editor.edit_existing_item(item)
