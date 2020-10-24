extends BaseWidget


var default_data = 	{"widget_type": "HealthPointsTrackerWidget","widget_size":Vector2(2,2),
					"content": 
						{"feature_name":"Health Points","current_hp": 0,
						"minimum_hp":0, "maximum_hp":50}
						}

const build_specs = {"content": {"settings":{"canDelete":false},
						"feature_name":["LineEdit"],
						"minimum_hp":["SpinBox",-100,200],
						"maximum_hp":["SpinBox",0,1000],
						"current_hp":["maximum_hp"]},
					"instructions":{"canAdd":false}}	




func construct_specific(specifications):
	current_data = specifications

	if specifications.has("content"):

		if specifications.content.has("maximum_hp"):
			current_data.content.maximum_hp = specifications.content.maximum_hp

			if specifications.content.has("current_hp"):
				current_data.content.current_hp = specifications.content.current_hp
			else:
				current_data.content.current_hp = 0

			if specifications.content.has("minimum_hp"):
				current_data.content.minimum_hp = specifications.content.minimum_hp
			else:
				current_data.content.minimum_hp = 0
		else:
			current_data.content.maximum_hp = 50
				

		if specifications.content.has("feature_name"):
			$VBox/LabelFeatureName.text = specifications.content.feature_name
	else:
		construct_specific(default_data)
	
	showCurrentHealthPoints()

func _on_BtnAdd1_pressed():
	current_data.content.current_hp = clampHealthPoints(1)
	showCurrentHealthPoints()
	emit_signal("on_user_interaction",self)

func _on_BtnSubtract1_pressed():
	current_data.content.current_hp = clampHealthPoints(-1)
	showCurrentHealthPoints()
	emit_signal("on_user_interaction",self)

func _on_BtnAdd10_pressed():
	current_data.content.current_hp = clampHealthPoints(10)
	showCurrentHealthPoints()
	emit_signal("on_user_interaction",self)

func _on_BtnSubtract10_pressed():
	current_data.content.current_hp = clampHealthPoints(-10)
	showCurrentHealthPoints()
	emit_signal("on_user_interaction",self)

func showCurrentHealthPoints():
	var formatting = "%s / %s"
	var actual_string = formatting % [current_data.content.current_hp, current_data.content.maximum_hp]
	$VBox/LabelHealthPoints.text = actual_string

func clampHealthPoints(change_amount):
	var current = current_data.content.current_hp

	if (current + change_amount >= current_data.content.maximum_hp):
		return current_data.content.maximum_hp

	elif (current + change_amount <= current_data.content.minimum_hp):
		return current_data.content.minimum_hp

	else:
		return current + change_amount
	
