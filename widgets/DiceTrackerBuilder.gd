extends BaseFeatureBuilder


func setup_FeatureBuilder(feature_data = null):
	feature_specification = feature_data
	setup_LineEdit($VBox/HBox1/name, feature_data.feature_name)
	setup_SpinBox($VBox/HBox2/Maximum, feature_data.maximum_die)

func collect_specs():
	feature_specification.feature_name = $VBox/HBox1/name.text
	feature_specification.maximum_die = $VBox/HBox2/Maximum.value
