extends BaseFeatureBuilder

func setup_FeatureBuilder(feature_data = null):
	feature_specification = feature_data
	setup_LineEdit($VBox/HBox1/LineEdit, feature_data.feature_name)
	setup_SpinBox($VBox/HBox2/SpinBox, feature_data.class_level)

func collect_specs():
	feature_specification.feature_name = $VBox/HBox1/LineEdit.text
	feature_specification.maximum_die = $VBox/HBox2/SpinBox.value
