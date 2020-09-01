extends BaseFeatureBuilder

func setup_FeatureBuilder(feature_data = null):
	feature_specification = feature_data
	setup_LineEdit($VBox/HBox1/LineEdit, feature_data.feature_name)


func collect_specs():
	feature_specification.feature_name = $VBox/HBox1/LineEdit.text

