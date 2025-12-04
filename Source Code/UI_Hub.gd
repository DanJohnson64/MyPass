## Responsible for:
##  * Central UI navigation
##  * Emitting panel change requests to Main
##  * Emitting toast notifications for ToastLayer

extends Node
class_name UI_Hub

signal show_panel(panel_name: String, payload: Dictionary)
signal show_toast(message: String, style: String)

const PANEL_AUTH := "auth"
const PANEL_REGISTER := "register"
const PANEL_VAULT := "vault"
const PANEL_RECOVERY := "recovery"
const PANEL_VAULT_EDITOR := "vault_editor"
const PANEL_SELECT_ITEM_TYPE := "select_item_type" 


## -------------------------- Panel Navigation -------------------------------

# Show login screen
func goto_auth() -> void:
	show_panel.emit(PANEL_AUTH, {})


# Show register screen
func goto_register() -> void:
	show_panel.emit(PANEL_REGISTER, {})


# Show main vault screen
func goto_vault() -> void:
	show_panel.emit(PANEL_VAULT, {})


# Show recovery screen
func open_recovery() -> void:
	show_panel.emit(PANEL_RECOVERY, {})


# Open vault item editor (handled by VaultRoot / Main)
func open_editor_for(item: VaultItem) -> void:
	show_panel.emit(PANEL_VAULT_EDITOR, {"item": item})

# Show the SelectItemType screen
func goto_select_item_type() -> void:
	show_panel.emit(PANEL_SELECT_ITEM_TYPE, {})


# Called by SelectItemType when user chooses a type
func open_new_item(item_type: String) -> void:
	show_panel.emit(PANEL_VAULT_EDITOR, {
		"mode": "new",
		"item_type": item_type
	})
	
## ----------------------------- Toast Helpers -------------------------------

# Emit informational toast
func notify_info(text: String) -> void:
	show_toast.emit(text, "info")

# Emit warning toast
func notify_warning(text: String) -> void:
	show_toast.emit(text, "warning")

# Emit error toast
func notify_error(text: String) -> void:
	show_toast.emit(text, "error")
