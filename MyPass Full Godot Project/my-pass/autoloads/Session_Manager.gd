## Responsible for:
##  * Logging in/out
##  * Deriving encryption key from master password
##  * Tracking session timeout (auto-lock)
##  * Exposing recovery data and helpers for account recovery

extends Node
class_name Session_Manager

signal logged_in()
signal logged_out()
signal locked_by_timeout()

var _is_logged_in := false
var _master_key:PackedByteArray
var _last_activity_time:int = 0
var _auto_lock_minutes:int = 1
var _current_email:String = ""

## ---------------- Account Registration / Login / Logout --------------------

# Register a new account (single-account demo)
# recovery_data should be:
#   Array of { "question": String, "answer": String }
func register_account(email:String, master_password:String, recovery_data) -> bool:
	# This demo only supports one account, this is expandable
	if CryptoUtil.account_exists():
		return false

	# Build and save the account record
	var record := CryptoUtil.create_account_record(email, master_password, recovery_data)
	CryptoUtil.save_account(record)

	# Derive key from the stored salt (CryptoUtil will read account.json)
	var key := CryptoUtil.derive_key_from_password(master_password)

	# Create an empty vault file for this account
	CryptoUtil.encrypt_vault(key, [])
	return true


# Log in with email + master password
func login(email:String, master_password:String) -> bool:
	# Verify credentials, load salt, derive key
	var account := CryptoUtil.verify_credentials(email, master_password)
	if account.is_empty():
		return false # account not found or bad email/password

	_is_logged_in = true
	_current_email = email

	# Derive encryption key from master password + stored salt
	_master_key = CryptoUtil.derive_key_from_password(master_password)

	_touch_activity()

	VaultStore.load_vault(_master_key)

	emit_signal("logged_in")
	return true


# Log out, clear vault and key
func logout() -> void:
	_is_logged_in = false
	_master_key = PackedByteArray()
	_current_email = ""
	VaultStore.clear()
	emit_signal("logged_out")


# Get current encryption key
func get_key() -> PackedByteArray:
	return _master_key


# Get current logged in email (or empty string)
func get_current_email() -> String:
	return _current_email

## ---------------------- Auto-lock / Session Timeout ------------------------

# Update last activity timestamp
func _touch_activity() -> void:
	_last_activity_time = Time.get_unix_time_from_system()

# Call this from UI code whenever the user interacts (click, type, etc.)
func register_activity() -> void:
	if _is_logged_in:
		_touch_activity()

# Called manually from Main._process(delta)
func process(delta:float) -> void:
	if not _is_logged_in:
		return
	if _auto_lock_minutes <= 0:
		return

	var now := Time.get_unix_time_from_system()
	if now - _last_activity_time > _auto_lock_minutes * 60:
		_lock_for_inactivity()


# Lock the session due to inactivity
func _lock_for_inactivity() -> void:
	logout()
	emit_signal("locked_by_timeout")

## ----------------------- Recovery Data / CoR Helpers -----------------------

# Return recovery data from account.json as Array:
# [ { "question": "...", "answer_hash": "..." }, ... ]
func get_recovery_data() -> Array:
	var account := CryptoUtil.load_accout()
	var rec:Variant = account.get("recovery", [])

	if typeof(rec) == TYPE_ARRAY:
		return rec
	elif typeof(rec) == TYPE_DICTIONARY:
		# Single entry fallback
		return [rec]
	else:
		return []


# Build a Chain of Responsibility from stored questions
func build_recovery_chain() -> RecoveryStep:
	var rec_array := get_recovery_data()
	if rec_array.is_empty():
		return null

	var first:RecoveryStep = null
	var prev:RecoveryStep = null

	for r in rec_array:
		if typeof(r) != TYPE_DICTIONARY:
			continue

		var q:String = r.get("question", "")
		var expected_hash:String = r.get("answer_hash", "")
		if q == "" or expected_hash == "":
			continue

		var step := QuestionStep.new(q, expected_hash)
		if first == null:
			first = step
		if prev != null:
			prev.set_next(step)
		prev = step

	return first
