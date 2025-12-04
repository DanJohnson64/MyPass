## Responsible for:
##  * Account persistence (account.json)
##  * Vault persistence (vault.enc)
##  * Hashing and key derivation
##  * Security question hashing for recovery

extends RefCounted
class_name CryptoUtil

const VAULT_PATH := "user://vault.enc"
const ACCOUNT_PATH := "user://account.json"

## -------------------Account File Helpers ----------------------------------

# Check if account exists
static func account_exists() -> bool:
	return FileAccess.file_exists(ACCOUNT_PATH)


# Load account.json -> Dictionary
static func load_accout() -> Dictionary:
	if not FileAccess.file_exists(ACCOUNT_PATH):
		return {}

	var file := FileAccess.open(ACCOUNT_PATH, FileAccess.READ)
	if not file:
		return {}

	var text := file.get_as_text()
	file.close()

	var data: Variant = JsonUtil.decode(text)
	if typeof(data) == TYPE_DICTIONARY:
		return data

	return {}


# Save account.json
static func save_account(data:Dictionary) -> void:
	var json := JsonUtil.encode(data)
	var f := FileAccess.open(ACCOUNT_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.close()

## ----------- Hashing and key derivation ------------------------------------

# sha256(bytes) helper using HashingContext
static func sha256_bytes(data:PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	var err := ctx.start(HashingContext.HASH_SHA256)
	if err != OK:
		push_error("CryptoUtil: failed to start HashingContext")
		return PackedByteArray()
	ctx.update(data)
	return ctx.finish()


# Hash a password with salt (user credential, not vault password)
static func hash_password(password:String, salt:PackedByteArray) -> PackedByteArray:
	# sha256(salt + password_utf8)
	var buf := PackedByteArray()
	buf.append_array(salt)
	buf.append_array(password.to_utf8_buffer())
	return sha256_bytes(buf)


# Convert the text to UTF-8 bytes, hash them using sha2, return hex
static func hash_answer(text:String) -> String:
	var buf := text.to_utf8_buffer()
	var hash_bytes := sha256_bytes(buf)
	return hash_bytes.hex_encode()

## --------------- Account Creation And Verification -------------------------

# Create account record from email/password/recovery
# recovery_data can be:
#  * Array of { "question": String, "answer": String }      (preferred)
#  * Dictionary with single { "question", "answer_plain" }  (backwards compat)
static func create_account_record(
	email:String,
	master_password:String,
	recovery_data
	) -> Dictionary:

	var salt := generate_salt()
	var pwd_hash := hash_password(master_password, salt)

	var rec_array:Array = []

	if typeof(recovery_data) == TYPE_ARRAY:
		for entry in recovery_data:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var q:String = entry.get("question", "")
			var ans:String = entry.get("answer", entry.get("answer_plain", ""))
			if q == "" or ans == "":
				continue
			rec_array.append({
				"question": q,
				"answer_hash": hash_answer(ans)
			})
	elif typeof(recovery_data) == TYPE_DICTIONARY:
		# Single-question fallback
		var q_single:Variant = recovery_data.get("question", "")
		var ans_single:Variant = recovery_data.get("answer_plain", recovery_data.get("answer", ""))
		if q_single != "" and ans_single != "":
			rec_array.append({
				"question": String(q_single),
				"answer_hash": hash_answer(String(ans_single))
			})

## WARNING:
##  * master_password_plain is stored here ONLY for requirement purposes
##  * This is NOT safe for a full scale password manager
##  * I would recommend using reset-style recovery instead of recovery
	return {
		"email": email,
		"salt": salt.hex_encode(),
		"password_hash": pwd_hash.hex_encode(),
		"recovery": rec_array,
		"master_password_plain": master_password
	}


# Verify email + password against stored account
static func verify_credentials(email:String, password:String) -> Dictionary:
	var account := load_accout()
	if account.is_empty():
		return {} # no account

	var stored_email:Variant = account.get("email", "")
	if stored_email != "" and stored_email != email:
		return {} # wrong email

	var salt_hex:Variant = account.get("salt", "")
	var stored_hash_hex:Variant = account.get("password_hash", "")
	if salt_hex == "" or stored_hash_hex == "":
		return {}

	var salt := PackedByteArray()
	salt = String(salt_hex).hex_decode()

	var expected_hash := PackedByteArray()
	expected_hash = String(stored_hash_hex).hex_decode()

	var actual_hash := hash_password(password, salt)
	if actual_hash != expected_hash:
		return {}

	return account # valid login

## ---------------- Vault Encryption / Decryption (simple XOR) --------------

# Save vault via XOR encrypt -> vault.enc
static func save_vault(key:PackedByteArray, items_array:Array) -> void:
	encrypt_vault(key, items_array)


# Load vault via XOR decrypt <- vault.enc
static func load_vault(key:PackedByteArray) -> Array:
	return decrypt_vault(key)


# Core XOR helper
static func _xor_with_key(data:PackedByteArray, key:PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	var key_len := key.size()
	if key_len == 0:
		# No key, just return a copy
		return data.duplicate()

	for i in data.size():
		out.append(data[i] ^ key[i % key_len])
	return out


# Encrypt vault Array using XOR and write to VAULT_PATH
static func encrypt_vault(key:PackedByteArray, data:Array) -> void:
	var json := JsonUtil.encode(data)
	var bytes := json.to_utf8_buffer()
	var enc := _xor_with_key(bytes, key)

	var file := FileAccess.open(VAULT_PATH, FileAccess.WRITE)
	if file:
		file.store_buffer(enc)
		file.close()


# Decrypt vault from VAULT_PATH using XOR and parse JSON
static func decrypt_vault(key:PackedByteArray) -> Array:
	if not FileAccess.file_exists(VAULT_PATH):
		return []

	var file := FileAccess.open(VAULT_PATH, FileAccess.READ)
	if not file:
		return []

	var enc := file.get_buffer(file.get_length())
	file.close()

	var dec := _xor_with_key(enc, key)
	var text := dec.get_string_from_utf8()
	var data:Variant = JsonUtil.decode(text)
	if typeof(data) == TYPE_ARRAY:
		return data

	return []

## --------------- Salt + Key Derivation Helpers -----------------------------

# Generate random salt for user credentials
static func generate_salt(length:int = 16) -> PackedByteArray:
	var salt := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in length:
		salt.append(rng.randi() % 256)
	return salt


# Derive a master key from password + salt
static func derive_master_key(master_password:String, salt:PackedByteArray) -> PackedByteArray:
	var buf := PackedByteArray()
	buf.append_array(salt)
	buf.append_array(master_password.to_utf8_buffer())
	return sha256_bytes(buf)


# Derive encryption key from password.
static func derive_key_from_password(password:String) -> PackedByteArray:
	var account := load_accout()
	if account.is_empty():
		# Fallback: no account yet, just hash the password bytes
		return sha256_bytes(password.to_utf8_buffer())

	var salt_hex:Variant = account.get("salt", "")
	if salt_hex == "":
		return sha256_bytes(password.to_utf8_buffer())

	var salt := PackedByteArray()
	salt = String(salt_hex).hex_decode()

	return derive_master_key(password, salt)
