extends Control


signal _on_button_pressed(type)



func _on_WidgetOptions_id_pressed(type):
	match type:
		0:
			emit_signal("_on_button_pressed", "resize")
		1:
			emit_signal("_on_button_pressed", "edit")
		2:
			emit_signal("_on_button_pressed", "delete")

func _on_ButtonDelete_pressed() -> void:
	print("DELTE")
	emit_signal("_on_button_pressed", "delete")


func _on_ButtonEdit_pressed() -> void:
	emit_signal("_on_button_pressed", "edit")


func _on_ButtonResize_pressed() -> void:
	emit_signal("_on_button_pressed", "resize")
