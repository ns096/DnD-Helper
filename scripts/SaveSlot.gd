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
	$"H/V/HBox1/Savename".text = saveslot
	$"H/V/HBox2/EditSavename".text = savename
	if saveslot == "autosave" || saveslot == "default":
		$"H/V/HBox3/ButtonDelete".disabled = true
	show_date(date)

func get_save(saveslot, savename):
	saveslot = $"H/V/HBox1/Savename".text
	savename = $"H/V/HBox2/EditSavename".text
	


func show_date(date):
	$"H/V/HBox1/Date".text = "%s.%s.%s | %s:%s" % [date["day"], date["month"], date["year"], date["hour"], date["minute"]]

func _on_ButtonSave_pressed() -> void:
	emit_signal("save_pressed", savename, saveslot)

func _on_ChangeNameButton_pressed() -> void:
	savename = $"H/V/HBox2/EditSavename".text
	emit_signal("change_name_pressed", savename, saveslot)

func _on_ButtonDelete_pressed() -> void:
	emit_signal("delete_pressed", savename, saveslot)

func _on_ButtonLoad_pressed() -> void:
	emit_signal("load_pressed", savename, saveslot)
