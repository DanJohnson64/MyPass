## Responsible for:
##  * Displaying a list of vault items
##  * Emitting signal when an item is selected

extends Control
class_name ItemListPanel

signal item_selected(item:VaultItem)

@onready var list_container:VBoxContainer = %ItemsVBox

# Populate item list with buttons
func show_items(items:Array) -> void:
	for child in list_container.get_children():
		child.queue_free()

	for item in items:
		var btn := Button.new()
		btn.text = "%s [%s]" % [item.display_name, item.item_type]
		btn.add_theme_font_size_override("font_size", 50)
		btn.pressed.connect(func():
			item_selected.emit(item)
		)
		list_container.add_child(btn)
