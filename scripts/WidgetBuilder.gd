extends Control

var PreviewWidget
var FeatureBuilder

onready var current_widget_data = null
var old_widget_data
var build_specs
var builder : BaseFeatureBuilder
const content_description = {"BasicWidget":["feature_name","max_marker"],
							"SpellSlotWidget":["feature_name","class_level"],
							"DiceTrackerWidget":["feature_name","maximum_die"],
							"HealthPointsTrackerWidget":["feature_name","max_hp"]
							}


var update_preview_timer = 0.0
func _process(delta):
	update_preview_timer += delta
	#every .5seconds delete the current preview and build a new
	#TODO just make the Widget able to reset
	if update_preview_timer >= 0.5 && current_widget_data != null:
		build_WidgetPreview()


func add_FeatureBuilder(specification, builderPath):
	builder = load(builderPath).instance()
	builder.setup_FeatureBuilder(specification)
	$FeatureBuilder.add_child(builder)

func load_feature_builder(builder_path : String):
	FeatureBuilder = load(builder_path).instance()
	add_child(FeatureBuilder)


func get_new_widget_specs() -> Dictionary:
	if FeatureBuilder.has_method('get_specs'):
		return FeatureBuilder.get_specs()
	else:
		return {'Error':'Method get specs not found'}

func setup_WidgetBuilder(Widget : BaseWidget):
	for child in $FeatureBuilder.get_children():
		child.queue_free()
	current_widget_data = Widget.current_data
	old_widget_data = GlobalHelper.deep_copy(Widget.current_data)
	build_specs = Widget.build_specs

	
	add_FeatureBuilder(current_widget_data.content, Widget.builderPath)
		
func reset_WidgetBuilder():
	$WidgetPreview.get_child(0).queue_free()
	for child in $FeatureBuilder.get_children():
		child.queue_free()
	current_widget_data = null

func collect_specification() -> Dictionary:
	return builder.get_specification()


#TODO make widget reset instead of new instance
func build_WidgetPreview():
	if $WidgetPreview.get_child_count() > 0:
		$WidgetPreview.get_child(0).queue_free()

	var type = current_widget_data.widget_type
	var node_path = "res://widgets/"+type+"/"+type+".tscn"
	var new_preview = load(node_path).instance()
	current_widget_data.content = collect_specification()
	new_preview.construct_widget(current_widget_data)
	$WidgetPreview.add_child(new_preview)

func get_widget_specs() -> Dictionary:
	return current_widget_data
