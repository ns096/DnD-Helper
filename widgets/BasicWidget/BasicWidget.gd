extends BaseWidget

const default_data = {"widget_type": "BasicWidget","widget_size": Vector2(2,2), 
					"content": [
						{"feature_name":"Basic Widget","cur_marker":0, "max_marker":0},
						{"feature_name":"","cur_marker":0,"max_marker":4}
						]
					}

const build_specs = {"content": {"settings":{"canDelete":true},
						"feature_name":["LineEdit"],
						"max_marker":["SpinBox",0,10],
						"cur_marker":["max_marker"]},
					"instructions":{"canAdd":true}}

func construct_widget(specifications : Dictionary):
	current_data = specifications
	if specifications.has("content"):
		var VerticalContainer = VBoxContainer.new()
		var row = 0
		for feature in specifications.content:
			
			var ContainerForFeature = HBoxContainer.new()
			VerticalContainer.add_child(ContainerForFeature)
			if feature.has("feature_name"):
				var WidgetLabel = Label.new()
				WidgetLabel.text = feature.feature_name
				WidgetLabel.theme = theme
				WidgetLabel.mouse_filter = MOUSE_FILTER_IGNORE
				ContainerForFeature.add_child(WidgetLabel)
			if feature.has("max_marker"):
				if feature.has("cur_marker"):
					#if cur_marker is too big for max_marker just clip it
					#example: 5/6 gets changed to 5/3 clip it to 3/3
					if feature.cur_marker >  feature.max_marker:
						make_marker(row,feature.max_marker, feature.max_marker,ContainerForFeature)
					else:
						make_marker(row,feature.max_marker, feature.cur_marker,ContainerForFeature)
				else:
					make_marker(row,feature.max_marker, 0,ContainerForFeature)
			row+=1
		$CenterContainer.add_child(VerticalContainer)
	else:
		construct_widget(default_data)

#returns an HBoxContainer with CheckBoxes
func make_marker(row, max_marker, cur_marker,container):
	var ContainerForMarker = container
	
	for i in range(1,max_marker+1):
		var CheckBoxMarker = CheckBox.new()
		#Connect new checkbox to this/self with toggled event for access to state and add custom argument to differentiate
		CheckBoxMarker.connect("toggled", self, "_on_checkbox_pressed",[row])
		if i <= cur_marker:
			CheckBoxMarker.pressed = true
		ContainerForMarker.add_child(CheckBoxMarker)
		
	#Toggling checkbox calls toggled event
	#thats why current_data needs to get reset manually
	current_data.content[row].cur_marker = cur_marker
	return ContainerForMarker


func _on_checkbox_pressed(checkbox_state,row):
	#print("toggled ", checkbox_state," row: ", row)
	if checkbox_state:
		current_data.content[row].cur_marker += 1
	else:
		current_data.content[row].cur_marker -= 1
	emit_signal("on_user_interaction",self)


