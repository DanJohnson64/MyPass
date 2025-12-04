## Responsible for:
##  * Base class for recovery chain steps
##  * Linking steps together as a Chain of Responsibility

extends RefCounted
class_name RecoveryStep

var _next: RecoveryStep = null


# Set the next step in the chain
func set_next(next_step: RecoveryStep) -> RecoveryStep:
	_next = next_step
	return next_step


# Get the next step in the chain
func get_next() -> RecoveryStep:
	return _next
