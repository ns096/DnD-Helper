extends BaseWidget

export(Array, Texture) var dice_textures

var dice_names = ["d4","d6","d8","d10","d12","d20"]

var default_data = 	{"widget_type": "DiceTrackerWidget","widget_size":Vector2(3,3),
					"content": {"feature_name":"Example","current_die": 0,"maximum_die":5}}

const build_specs = {"content": {"settings":{"canDelete":false},
						"feature_name":["LineEdit"],
						"maximum_die":["SpinBox",0,5],
						"current_die":["maximum_die"] },
					"instructions":{"canAdd":false}}


func init():
	pass
	

func load_die_image(value : int):
	if value > 0:
		value -= 1
	$VBox/TextureRect.texture = dice_textures[value]
	$VBox/HBox/Label.text = dice_names[value]


func construct_widget(specifications):
	current_data = specifications
	if specifications.has("content"):

		if specifications.content.has("maximum_die"):
			if specifications.content.has("current_die"):
				load_die_image(specifications.content.current_die)
			else:
				current_data.content.current_die = 0
				load_die_image(specifications.content.current_die)

		if specifications.content.has("feature_name"):
			$VBox/LabelFeatureName.text = specifications.content.feature_name
	else:
		construct_widget(default_data)

func _on_BtnAdd_pressed():
	if not current_data.content.current_die == current_data.content.maximum_die:
		current_data.content.current_die += 1
	load_die_image(current_data.content.current_die)
	emit_signal("on_user_interaction",self)

func _on_BtnSubtract_pressed():
	if not current_data.content.current_die == 0:
		current_data.content.current_die -= 1
	load_die_image(current_data.content.current_die)
	emit_signal("on_user_interaction",self)
