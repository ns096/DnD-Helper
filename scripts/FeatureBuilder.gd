extends HBoxContainer

#WidgetBuilder instances one or more FeatureBuilder children depending on the widget_type
#FeatureBuilder then displays the correct options and sends the current specs to WidgetBuilder

signal BtnAdd_pressed()
signal BtnDelete_pressed()

#holds JSON description because every Widget uses something else
var description
enum {LABEL,SPINBOX}
var current_data
var all_input_nodes = {}

func _ready():
	$BtnAdd.connect("pressed",self,"_on_BtnAdd")
	$BtnDelete.connect("pressed",self,"_on_BtnDelete")


func setup_FeatureBuilder(build_specs,feature_data = null, hide := 0):
	$BtnAdd.visible = false

	if feature_data != null:
		current_data = GlobalHelper.deep_copy(feature_data)
		print("current_data is null")

	var default_data = {"widget_type": "BasicWidget","widget_size": Vector2(2,2), 
							"content": [
								{"feature_name":"Basic Widget","cur_marker":0, "max_marker":0},
								{"feature_name":"","cur_marker":0,"max_marker":4}
								]
							}

	var placeholder = 	{"content": {
									"settings":{"canDelete":true},
									"feature_name":["LineEdit"],
									"max_marker":["SpinBox",0,10],
									"cur_marker":["max_marker"]},
						"instructions":{"canAdd":true}}


	for key in feature_data:
		match build_specs[key][0]:
			"LineEdit":
				current_data[key] = setup_LineEdit(feature_data[key])
			"SpinBox":
				current_data[key] = setup_SpinBox(feature_data[key],build_specs[key][1],build_specs[key][2])
			_:
				pass
	
	$BtnDelete.visible = build_specs.settings.canDelete
	$BtnDelete.raise()

	if hide == 1:
		$BtnDelete.visible = false
		$BtnAdd.visible = true
		$SpinBox.visible = false
		$TxtLabel.visible = false
	

	
func setup_LineEdit(value:="write here", feature:="test"):
	var feature_LineEdit = $TxtLabel.duplicate()
	feature_LineEdit.text = value
	feature_LineEdit.visible = true
	all_input_nodes[feature] = feature_LineEdit
	add_child(feature_LineEdit)
	return feature_LineEdit

func setup_SpinBox(value,min_size:=0,max_size:=10,step := 1, feature:="test"):
	var feature_SpinBox = $SpinBox.duplicate()
	feature_SpinBox.value = value
	feature_SpinBox.min_value = min_size
	feature_SpinBox.max_value = max_size
	feature_SpinBox.step = step
	feature_SpinBox.visible = true
	all_input_nodes[feature] = feature_SpinBox
	add_child(feature_SpinBox)
	return feature_SpinBox


#deprecated function
func construct_FeatureBuilder(widget_type,content_description,feature_specs):
	match widget_type:
		"BasicWidget":
			$SpinBox.prefix = "Marker"
			$BtnDelete.visible = true

		"SpellSlotWidget":
			$SpinBox.prefix = "Class Level"
			$SpinBox.min_value = 1
			$SpinBox.max_value = 20
			$BtnDelete.visible = false
		"DiceTrackerWidget":
			$SpinBox.prefix = "Maximum Die Size"
			$SpinBox.min_value = 1
			$SpinBox.max_value = 6
			$BtnDelete.visible = false
		_:
			print("construct_FeatureBuilder: Wrong type: ", widget_type)
			
	$BtnAdd.visible = false
	$TxtLabel.visible = true
	$SpinBox.visible = true

	description = content_description
	if feature_specs != null:
		if feature_specs.has(description[LABEL]):
			$TxtLabel.text = feature_specs[description[LABEL]]
		if feature_specs.has(description[SPINBOX]):
			$SpinBox.value = feature_specs[description[SPINBOX]]

	#show only BtnAdd if there are no specs
	else :
		$BtnAdd.visible = true
		$TxtLabel.visible = false
		$SpinBox.visible = false
		$BtnDelete.visible = false


func _on_BtnAdd():
	$BtnAdd.visible= false
	$TxtLabel.visible = true
	$SpinBox.visible = true
	$BtnDelete.visible = true
	emit_signal("BtnAdd_pressed")

func get_specs() -> Dictionary:
	var spinbox_value = $SpinBox.value
	var label_text = $TxtLabel.text 
	var feature_specs = {}

	
	if label_text != "" or label_text != "write here...":
		feature_specs[description[LABEL]] = label_text
	if spinbox_value != 0:
		feature_specs[description[SPINBOX]] = spinbox_value
	
	return feature_specs

func get_data() -> Dictionary:
	var data = GlobalHelper.deep_copy(current_data)
	for key in current_data:
		if current_data[key] is Node:
			match current_data[key].get_class():
				"LineEdit":
					data[key] = current_data[key].text
				"SpinBox":
					data[key] = current_data[key].value
	return data

#Show PopupPanel for confirmation
func _on_BtnDelete():
	$PopupPanel.popup_centered()

func _on_BtnOK_pressed():
	$PopupPanel.hide()
	emit_signal("BtnDelete_pressed")

func _on_BtnCancel_pressed():
	$PopupPanel.hide()
