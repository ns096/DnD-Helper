extends HBoxContainer


signal delete(target)

var current_marker

export(Resource) var DeleteConfirmation 

func _on_BtnDelete_pressed():
	emit_signal("delete",self)