extends BaseFeatureBuilder



signal BtnAdd_pressed()
signal BtnDelete_pressed()

var original

#holds JSON description because every Widget uses something else
var description
enum {LABEL,SPINBOX}

var all_input_nodes = {}
var all_feature_nodes = []

var delete_target

func setup_FeatureBuilder(content = null, hide := false):
	feature_specification = content
	original = $Original


	for feature in content:
		all_feature_nodes.append(add_feature(feature.feature_name, feature.max_marker, feature.cur_marker, false))

	all_feature_nodes.append(add_feature())
	

func add_feature(feature_name:= "write here...", max_marker:=1, current_marker:=0, hide:=true):
	var new_feature = original.duplicate()
	new_feature.visible = true
	new_feature.get_node("BtnAdd").connect("pressed",self,"_on_BtnAdd")
	new_feature.connect("delete",self,"_on_BtnDelete")
	$VBox.add_child(new_feature)

	new_feature.get_node("LineEdit").text = feature_name
	new_feature.get_node("SpinBox").value = max_marker
	new_feature.current_marker = current_marker


	if !hide:
		new_feature.get_node("BtnAdd").visible = false
		new_feature.get_node("BtnDelete").visible = true
		new_feature.get_node("SpinBox").visible = true
		new_feature.get_node("LineEdit").visible = true

	return new_feature


func collect_specs():
	var i = 0
	var new_specs = []
	for feature in all_feature_nodes:
		if !feature.get_node("BtnAdd").visible:
			new_specs.append({})
			new_specs[i].feature_name = feature.get_node("LineEdit").text
			new_specs[i].max_marker = feature.get_node("SpinBox").value
			new_specs[i].current_marker = feature.current_marker
		i += 1
	feature_specification = new_specs
	
func get_empty_feature_spec() -> Dictionary:
	var feature_spec = {"feature_name":"Write here...",
						"max_marker":0,
						"cur_marker":0}
	return feature_spec


func _on_BtnAdd():
	var last_feature = all_feature_nodes.back()
	last_feature.get_node("BtnAdd").visible = false
	last_feature.get_node("BtnDelete").visible = true
	last_feature.get_node("SpinBox").visible = true
	last_feature.get_node("LineEdit").visible = true

	all_feature_nodes.append(add_feature())

#Show PopupPanel for confirmation
func _on_BtnDelete(target):
	$PopupPanel.popup_centered()
	delete_target = target

func _on_BtnOK_pressed():
	$PopupPanel.hide()
	all_feature_nodes.erase(delete_target)

	delete_target.queue_free()

func _on_BtnCancel_pressed():
	$PopupPanel.hide()
	delete_target = null
