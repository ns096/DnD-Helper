extends BaseFeatureBuilder

func setup_FeatureBuilder(feature_data = null):
	feature_specification = feature_data
	setup_LineEdit($VBox/HBox1/Label, feature_data[0].feature_name)
	setup_SpinBox($VBox/HBox2/Minimum, feature_data[1].minimum_hp)
	setup_SpinBox($VBox/HBox3/Maximum, feature_data[1].maximum_hp)

func collect_specs():
	feature_specification[0].feature_name = $VBox/HBox1/name.text
	feature_specification[1].minimum_hp = $VBox/HBox2/Minimum.value
	feature_specification[1].maximum_hp = $VBox/HBox3/Maximum.value
