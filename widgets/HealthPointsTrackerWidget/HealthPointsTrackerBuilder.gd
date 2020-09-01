extends BaseFeatureBuilder

func setup_FeatureBuilder(feature_data = null):
	feature_specification = feature_data
	setup_LineEdit($VBox/HBox1/LineEdit, feature_data.feature_name)
	setup_SpinBox($VBox/HBox2/Minimum, feature_data.minimum_hp)
	setup_SpinBox($VBox/HBox3/Maximum, feature_data.maximum_hp)

func collect_specs():
	feature_specification.feature_name = $VBox/HBox1/LineEdit.text
	feature_specification.minimum_hp = $VBox/HBox2/Minimum.value
	feature_specification.maximum_hp = $VBox/HBox3/Maximum.value
