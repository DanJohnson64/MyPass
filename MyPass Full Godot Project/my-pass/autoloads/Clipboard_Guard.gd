## Responsible for:
##  * Safely copying sensitive text to the system clipboard
##  * Automatically clearing clipboard contents after a timeout
##  * Notifying the user when copying or clearing occurs
extends Node
class_name Clipboard_Guard

var _clear_timer: Timer

#Sets internal timer
func _ready() -> void:
	_clear_timer = Timer.new()
	_clear_timer.one_shot = true
	_clear_timer.wait_time = 60
	_clear_timer.timeout.connect(_on_clear_timeout)
	add_child(_clear_timer)

# Add text to clipboard
func copy_secret(text:String) -> void:
	DisplayServer.clipboard_set(text)
	_clear_timer.start()
	UIHub.notify_info("copied (will clear in 60 seconds).")
	
# Calls for toast on clipboard clear
func _on_clear_timeout() -> void:
	DisplayServer.clipboard_set("")
	UIHub.notify_info("Clipboard cleared.")
