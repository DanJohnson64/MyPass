## Responsible for:
##  * Rendering toast notifications from anywhere in the app
##  * Styling toast based on its type (info / warning / error)
##  * Auto-hiding the toast after a delay
##  * Handling fade-in / fade-out animation

extends Control
class_name ToastLayer

@onready var toast: Control = %Toast
@onready var toast_label: Label = %Label
@onready var background: Panel = %Background

var _timer := 1.5              ## How long toast stays visible
var _fade_time := 0.25         ## Fade animation length
var _tween: Tween = null       ## Holds the active animation

# Initialize toast layer hidden and transparent
func _ready() -> void:
	# Start hidden
	toast.visible = false
	modulate.a = 0.0


# Show a toast on screen.
# Called by Main when UIHub emits show_toast().
func show_toast(message: String, style: String = "info") -> void:
	_apply_style(style)
	toast_label.text = message
	toast.visible = true

	# Kill previous tween if any
	if _tween and _tween.is_running():
		_tween.stop()

	# Fade in
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, _fade_time)
	_tween.tween_callback(Callable(self, "_start_auto_hide"))


# Begin timed hiding of toast
func _start_auto_hide() -> void:
	await get_tree().create_timer(_timer).timeout
	_fade_out()


# Fade-out animation
func _fade_out() -> void:
	if _tween and _tween.is_running():
		_tween.stop()

	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, _fade_time)
	_tween.tween_callback(Callable(self, "_hide"))


# Fully hide once faded out
func _hide() -> void:
	toast.visible = false


# Apply background color based on style
func _apply_style(style: String) -> void:
	var sb: StyleBox = background.get_theme_stylebox("panel")
	
	# If the stylebox isn't overridden yet, clone it so we don't modify the theme asset.
	if sb == null:
		return
	
	# Make a mutable copy (theme resources may be shared)
	sb = sb.duplicate()
	background.add_theme_stylebox_override("panel", sb)
	
	var flat := sb as StyleBoxFlat
	if flat == null:
		return
	
	match style:
		"warning":
			flat.bg_color = Color(0.385, 0.292, 0.043, 0.839)
			flat.border_color = Color(0.699, 0.759, 0.628, 0.839)
		"error":
			flat.bg_color = Color(0.498, 0.116, 0.126, 0.839)
			flat.border_color = Color(0.712, 0.19, 0.201, 0.839)
		_:
			flat.bg_color = Color(0.052, 0.287, 0.573, 0.839)
			flat.border_color = Color(0.25, 0.55, 0.95, 0.839)
