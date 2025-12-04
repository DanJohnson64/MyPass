## Responsible for:
##  * Managing in-memory vault items
##  * Saving/loading vault to disk via CryptoUtil
##  * Emitting signals when items change

extends Node
class_name Vault_Store

signal item_added(item:VaultItem)
signal item_updated(item:VaultItem)
signal item_deleted(id:String)
signal vault_loaded()
signal vault_saved()

var items:Array[VaultItem] = []

## ------------------------ Item Management ----------------------------------

# Create a new item instance of the given type
func create_item_of_type(item_type:String) -> VaultItem:
	match item_type:
		"login":
			return LoginItem.new()
		"credit_card":
			return CreditCardItem.new()
		"identity":
			return IdentityItem.new()
		"secure_note":
			return SecureNoteItem.new()
		_:
			return VaultItem.new()


# Add new item to store and save
func add_item(item:VaultItem) -> void:
	if item.id == "":
		item.id = _generate_id(item.item_type)

	items.append(item)
	emit_signal("item_added", item)
	_save_vault()


# Update existing item in place
func update_item(item:VaultItem) -> void:
	for i in items.size():
		if items[i].id == item.id:
			items[i] = item
			emit_signal("item_updated", item)
			_save_vault()
			return


# Delete item by id
func delete_item(item_id:String) -> void:
	for i in items.size():
		if items[i].id == item_id:
			items.remove_at(i)
			emit_signal("item_deleted", item_id)
			_save_vault()
			return


# Clear all items (used on logout)
func clear() -> void:
	items.clear()

## ----------------------- Serialization Helpers -----------------------------

# Generate unique id for new items
func _generate_id(item_type:String) -> String:
	var t := Time.get_unix_time_from_system()
	return "%s_%s" % [item_type, str(t)]


# Convert all items to an Array of dictionaries for storage
func to_serializable_array() -> Array:
	var arr:Array = []
	for item in items:
		arr.append(item.to_dict())
	return arr


# Load items from an Array of dictionaries (after decrypt)
func load_from_array(arr:Array) -> void:
	items.clear()
	for entry in arr:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var d:Dictionary = entry
		var item_type:String = d.get("item_type", "")
		var item := create_item_of_type(item_type)
		item.from_dict(d)
		items.append(item)
		
	emit_signal("vault_loaded")

## ---------------------- Vault Persistence ----------------------------------

# Save vault to disk immediately
func _save_vault() -> void:
	var key := SessionManager.get_key()
	if key.is_empty():
		return

	var arr := to_serializable_array()
	CryptoUtil.encrypt_vault(key, arr)
	emit_signal("vault_saved")


# Load vault from disk using current session key
func load_vault(key:PackedByteArray) -> void:
	var arr := CryptoUtil.decrypt_vault(key)
	load_from_array(arr)


# Hook called after vault changes to trigger security checks
func _after_vault_changed() -> void:
	# Called whenever the vault items are modified or loaded.
	if SecurityWatcher != null:
		SecurityWatcher.check_vault(items)
