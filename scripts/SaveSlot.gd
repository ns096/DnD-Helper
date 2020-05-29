extends MarginContainer

signal save_pressed(savename, saveslot)
signal change_name_pressed(savename, saveslot)
signal delete_pressed(savename, saveslot)
signal load_pressed(savename, saveslot)

var savename
var saveslot

func _ready():
	pass

func set_save(saveslot, savename, date):
	self.saveslot = saveslot
	self.savename = savename
	$"VBoxContainer/HBoxTop/Savename".text = saveslot
	$"VBoxContainer/HBoxTop2/EditSavename".text = savename
	if saveslot == "autosave" || saveslot == "default":
		$VBoxContainer/HBoxTop3/ButtonDelete.disabled = true
	show_date(date)

func get_save(saveslot, savename):
	saveslot = $"VBoxContainer/HBoxTop/Savename".text
	savename = $"VBoxContainer/HBoxTop2/EditSavename".text
	


func show_date(date):
	$"VBoxContainer/HBoxTop/Date".text ="%s.%s.%s" % [date["day"], date["month"], date["year"]]

func _on_ButtonSave_pressed() -> void:
	emit_signal("save_pressed", savename, saveslot)

func _on_ChangeNameButton_pressed() -> void:
	savename = $"VBoxContainer/HBoxTop2/EditSavename".text
	emit_signal("change_name_pressed", savename, saveslot)

func _on_ButtonDelete_pressed() -> void:
	emit_signal("delete_pressed", savename, saveslot)

func _on_ButtonLoad_pressed() -> void:
	emit_signal("load_pressed", savename, saveslot)
