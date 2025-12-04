## Responsible for:
## - Observing Vault_Store for changes
## - Emitting warnings for:
##   - Weak passwords
##   - Soon-to-expire / expired credit card and identity items

extends Node
class_name Security_Watcher

const UPPER_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const SYMBOL_CHARS := "!@#$%^&*()_+"
const DAYS_BEFORE_WARNING: int = 30  # warn if expiration is within this many days

# Connect to VaultStore signals and start observing items
func _ready():
	VaultStore.item_added.connect(_on_item_changed)
	VaultStore.item_updated.connect(_on_item_changed)

# React to added/updated items and trigger checks
func _on_item_changed(item: VaultItem) -> void:
	if item is LoginItem:
		_check_password(item, item.fields.get("password", ""))
	elif item is IdentityItem:
		_check_password(item, item.fields.get("id_number", ""))


# Check a given password for weakness and notify if needed
func _check_password(item: VaultItem, pwd: String) -> void:
	if is_weak(pwd):
		UIHub.notify_warning("Weak password in: " + item.display_name)


## ----------------- Helpers ------------------------------------

# Public helper to check if a password is weak
func is_weak(pwd: String) -> bool:
	return _is_weak(pwd)


# Internal implementation of weak-password rules
func _is_weak(pwd: String) -> bool:
	# Length rule
	if pwd.length() < 10:
		return true

	var has_upper := false
	var symbol_count := 0

	for ch in pwd:
		if UPPER_CHARS.find(ch) != -1:
			has_upper = true
		if SYMBOL_CHARS.find(ch) != -1:
			symbol_count += 1

	# At least one uppercase
	if not has_upper:
		return true

	# At least two symbols
	if symbol_count < 2:
		return true

	return false

# Compare an MM/YY expiration string to current time and warn
func _check_mm_yy_expiration(mm_yy: String, now_unix: int) -> void:
	var expiry_unix := _parse_mm_yy_to_unix(mm_yy)
	if expiry_unix <= 0:
		return  # invalid date format

	var delta_days: int = int((expiry_unix - now_unix) / 86400.0)

	if delta_days < 0:
		_notify_expiration("This item is EXPIRED (%s)." % mm_yy)
	elif delta_days <= DAYS_BEFORE_WARNING:
		_notify_expiration("This item will expire soon (%s)." %  mm_yy)

# Entry point to check a VaultItem for expiration
func check_item_for_expiration(item: VaultItem) -> void:
	# Only check items that actually have an 'expires_on' field.
	if item == null:
		return
	
	if not item.fields.has("expires_on"):
		return

	var exp_str: String = item.fields["expires_on"]
	if exp_str == "":
		return  # no expiration date set, nothing to do

	var now_dict := Time.get_datetime_dict_from_system()
	var now_unix: int = Time.get_unix_time_from_datetime_dict(now_dict)

	_check_mm_yy_expiration(exp_str, now_unix)

# Safely get an expires_on property if present
func _get_expires_on(item: Object) -> String:
	# Safely check if the object actually has a property named 'expires_on'
	var properties := item.get_property_list()
	for p in properties:
		if p.has("name") and p["name"] == "expires_on":
			# Property exists; get its value as a string.
			var value: Variant = item.get("expires_on")
			if typeof(value) == TYPE_NIL:
				return ""
			return str(value)
	return ""


# Show an expiration-related warning toast
func _notify_expiration(message: String) -> void:
	# Adjust this call to whatever your toast API actually is.
	UIHub.notify_warning(message)

## ---------------------- Date Parser ---------------------------------

# Parse an MM/YY string into a Unix timestamp for the end of that month
func _parse_mm_yy_to_unix(mm_yy: String) -> int:
	# Expect format "MM/YY"
	var parts := mm_yy.split("/")
	if parts.size() != 2:
		return -1

	var month := int(parts[0])
	var year_two := int(parts[1])

	if month < 1 or month > 12:
		return -1

	# Convert YY to YYYY (assume 2000–2099 range)
	var year := 2000 + year_two

	# Compute expiration as the last second of that month
	# We'll take the first day of the next month minus 1 second
	var next_month := month + 1
	var next_year := year

	if next_month > 12:
		next_month = 1
		next_year += 1

	var dt := {
		"year": next_year,
		"month": next_month,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}

	# One second before next month
	return Time.get_unix_time_from_datetime_dict(dt) - 1
