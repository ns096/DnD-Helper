extends BaseFeatureBuilder



signal BtnAdd_pressed()
signal BtnDelete_pressed()

var original

#holds JSON description because every Widget uses something else
var description
enum {LABEL,SPINBOX}

var all_input_nodes = {}
var all_feature_nodes = []

func setup_FeatureBuilder(content = null, hide := false):
	feature_specification = content
	original = $Original


	for feature in content:
		all_feature_nodes.append(add_feature(feature.feature_name, feature.max_marker,false))

	all_feature_nodes.append(add_feature())
	

func add_feature(feature_name:= "write here...", value:=1, hide:=true):
	var new_feature = original.duplicate()
	new_feature.visible = true
	new_feature.get_node("BtnAdd").connect("pressed",self,"_on_BtnAdd")
	new_feature.get_node("BtnDelete").connect("pressed",self,"_on_BtnDelete")
	$VBox.add_child(new_feature)

	new_feature.get_node("LineEdit").text = feature_name
	new_feature.get_node("SpinBox").value = value


	if !hide:
		new_feature.get_node("BtnAdd").visible = false
		new_feature.get_node("BtnDelete").visible = true
		new_feature.get_node("SpinBox").visible = true
		new_feature.get_node("LineEdit").visible = true

	return new_feature

func _on_BtnAdd():
	var last_feature = all_feature_nodes.back()
	last_feature.get_node("BtnAdd").visible = false
	last_feature.get_node("BtnDelete").visible = true
	last_feature.get_node("SpinBox").visible = true
	last_feature.get_node("LineEdit").visible = true

	all_feature_nodes.append(add_feature())

func collect_specs():
	var i = 0
	for feature in all_feature_nodes:
		if !feature.get_node("BtnAdd").visible:
			if i >= feature_specification.size():
				feature_specification.append(get_empty_feature_spec())
			feature_specification[i].feature_name = feature.get_node("LineEdit").text
			feature_specification[i].max_marker = feature.get_node("SpinBox").value
		i += 1
	
func get_empty_feature_spec() -> Dictionary:
	var feature_spec = {"feature_name":"",
						"max_marker":0,
						"cur_marker":0}
	return feature_spec

#Show PopupPanel for confirmation
func _on_BtnDelete():
	$PopupPanel.popup_centered()

func _on_BtnOK_pressed():
	$PopupPanel.hide()
	emit_signal("BtnDelete_pressed")

func _on_BtnCancel_pressed():
	$PopupPanel.hide()
