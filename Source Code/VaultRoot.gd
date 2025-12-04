## Responsible for:
##  * High-level vault UI
##  * Filtering items by type and showing them in ItemListPanel
##  * Reacting to Vault_Store signals

extends Control

@onready var header_email_label:Label = %EmailLabel
@onready var type_filter:OptionButton = %TypeFilter
@onready var item_list_panel:ItemListPanel = %ItemListPanel
@onready var status_label:Label = %StatusLabel
@onready var add_item_button: Button = %AddItemButton
@onready var return_to_login_button: Button = %ReturnToLoginButton

# Initialize vault UI, wire signals, and populate list
func _ready() -> void:
	type_filter.clear()
	type_filter.add_item("All", 0)
	type_filter.add_item("Logins", 1)
	type_filter.add_item("Credit Cards", 2)
	type_filter.add_item("Identities", 3)
	type_filter.add_item("Secure Notes", 4)
	
	# Make the popup menu items use the same font size
	var popup := type_filter.get_popup()
	if popup:
		popup.add_theme_font_size_override("font_size", 40)
		
	type_filter.item_selected.connect(_on_type_filter_changed)
	
	VaultStore.vault_loaded.connect(_on_vault_loaded)
	VaultStore.item_added.connect(_on_item_changed)
	VaultStore.item_updated.connect(_on_item_changed)
	VaultStore.item_deleted.connect(_on_item_deleted)
	add_item_button.pressed.connect(_on_add_item_button_pressed)
	item_list_panel.item_selected.connect(_on_item_selected)
	return_to_login_button.pressed.connect(_on_return_to_login_pressed)
	_refresh_header()
	_refresh_list()


# Navigate to SelectItemType screen to add a new item
func _on_add_item_button_pressed() -> void:
	UIHub.goto_select_item_type()

## ---------------- Vault / Filter Updates -----------------------------------


# Refresh header and list after vault is loaded
func _on_vault_loaded() -> void:
	_refresh_header()
	_refresh_list()


# Refresh list when an item is added or updated
func _on_item_changed(item:VaultItem) -> void:
	_refresh_list()


# Refresh list when an item is deleted
func _on_item_deleted(id:String) -> void:
	_refresh_list()


# Refresh list when the type filter selection changes
func _on_type_filter_changed(index:int) -> void:
	_refresh_list()


# Update header label with current user email
func _refresh_header() -> void:
	header_email_label.text = SessionManager.get_current_email()

# Apply type filter and push items to ItemListPanel
func _refresh_list() -> void:
	var all_items := VaultStore.items
	var filtered:Array = []

	var sel_id := type_filter.get_selected_id()
	match sel_id:
		0: # All
			filtered = all_items.duplicate()
		1:
			filtered = _filter_by_type(all_items, "login")
		2:
			filtered = _filter_by_type(all_items, "credit_card")
		3:
			filtered = _filter_by_type(all_items, "identity")
		4:
			filtered = _filter_by_type(all_items, "secure_note")
		_:
			filtered = all_items.duplicate()

	if item_list_panel:
		item_list_panel.show_items(filtered)

	status_label.text = "%d items (filtered)" % filtered.size()


# Return items of a specific type from the source array
func _filter_by_type(source:Array, item_type:String) -> Array:
	var out:Array = []
	for item in source:
		if item.item_type == item_type:
			out.append(item)
	return out

# Open selected item in VaultItemEditor via UI_Hub
func _on_item_selected(item: VaultItem) -> void:
	# Ask UI_Hub to open the VaultItemEditor in "edit" mode for this item
	UIHub.open_editor_for(item)

# Log out and return to Auth/login screen
func _on_return_to_login_pressed() -> void:
	# Clear the active session
	SessionManager.logout()

	# Show the Auth screen
	UIHub.goto_auth()
