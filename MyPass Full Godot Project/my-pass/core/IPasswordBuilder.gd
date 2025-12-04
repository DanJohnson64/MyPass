## Responsible for:
##  * Interface for password builder implementations
##  * Defining the fluent builder operations

extends RefCounted
class_name IPasswordBuilder

# Configure desired password length
func length(n: int):
	pass

# Enable or disable uppercase characters
func allow_upper(b):
	pass

# Enable or disable lowercase characters
func allow_lower(b):
	pass

# Enable or disable digits
func allow_digits(b):
	pass

# Enable or disable symbols
func allow_symbols(b):
	pass

# Build and return the final password string
func build() -> String:
	return ""
