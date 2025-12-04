## Responsible for:
##  * Building secure random passwords with configurable rules
##  * Enforcing minimum length and required character sets

extends IPasswordBuilder
class_name PasswordBuilder

const UPPER_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const LOWER_CHARS := "abcdefghijklmnopqrstuvwxyz"
const DIGIT_CHARS := "0123456789"
const SYMBOL_CHARS := "!@#$%^&*()_+"

var _len := 10
var _upper := true
var _lower := true
var _digits := true
var _symbols := true

# Set desired password length
func length(n: int):
	_len = clamp(n, 8, 64)
	return self

# Enable/disable uppercase characters
func allow_upper(b):
	_upper = b
	return self

# Enable/disable lowercase characters
func allow_lower(b):
	_lower = b
	return self

# Enable/disable digits
func allow_digits(b):
	_digits = b
	return self

# Enable/disable symbols
func allow_symbols(b):
	_symbols = b
	return self

# Generate and return the final password
func build() -> String:
	var pool := ""
	if _upper: pool += UPPER_CHARS
	if _lower: pool += LOWER_CHARS
	if _digits: pool += DIGIT_CHARS
	if _symbols: pool += SYMBOL_CHARS

	if pool.is_empty():
		return ""

	# We guarantee at least 10 chars, so the requirement is meaningful.
	var length: Variant = max(_len, 10)

	var chars: Array[String] = []
	var remaining: Variant = length

	# At least one uppercase if that set is enabled.
	if _upper:
		chars.append(UPPER_CHARS[randi() % UPPER_CHARS.length()])
		remaining -= 1

	# At least two symbols if that set is enabled.
	if _symbols:
		var sym_count: Variant = min(2, remaining)
		for i in range(sym_count):
			chars.append(SYMBOL_CHARS[randi() % SYMBOL_CHARS.length()])
			remaining -= 1

	# Fill the rest from the combined pool.
	while remaining > 0:
		var idx := randi() % pool.length()
		chars.append(pool[idx])
		remaining -= 1

	# Shuffle so required chars aren’t always up front.
	for i in range(chars.size()):
		var j := randi() % chars.size()
		var tmp = chars[i]
		chars[i] = chars[j]
		chars[j] = tmp

	var out := ""
	for c in chars:
		out += c
	return out
