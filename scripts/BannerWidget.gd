extends "BaseWidget.gd"

const default_data = {"widget_type": "BannerWidget","widget_size": Vector2(3,1), 
					"content": [{"feature_name":"Fancy Banner"}]}

const build_specs = {"content": {"settings":{"canDelete":false},"feature_name":["LineEdit"]},
					"instructions":{"canAdd":false}}

func construct_widget(specifications : Dictionary):
	current_data = specifications
	if specifications.has("content"):
		for feature in specifications.content:
			$MarginContainer/Label.text = feature.feature_name
	else:
		construct_widget(default_data)



