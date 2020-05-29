extends Control

var OriginalFeatureBuilder
var PreviewWidget
onready var current_widget_data = null
var old_widget_data
var build_specs
const content_description = {"BasicWidget":["feature_name","max_marker"],
							"SpellSlotWidget":["feature_name","class_level"],
							"DiceTrackerWidget":["feature_name","maximum_die"]}

func _ready():
	OriginalFeatureBuilder = load("res://scenes/FeatureBuilder.tscn")

var update_preview_timer = 0.0
func _process(delta):
	update_preview_timer += delta
	#every .5seconds delete the current preview and build a new
	#TODO just make the Widget able to reset
	if update_preview_timer >= 0.5 && current_widget_data != null:
		build_WidgetPreview()

#old		
func add_FeatureBuilder(widget_type,description,feature_specs = null):
	var new_FeatureBuilder = OriginalFeatureBuilder.instance()
	$WidgetMaker.add_child(new_FeatureBuilder)
	new_FeatureBuilder.connect("BtnAdd_pressed",self,"_on_BtnAdd_pressed")
	new_FeatureBuilder.connect("BtnDelete_pressed",self,"_on_BtnDelete_pressed",[new_FeatureBuilder])
	new_FeatureBuilder.construct_FeatureBuilder(widget_type,description,feature_specs)

func _add_FeatureBuilder(build_specs, current_data, hide := 0):
	var new_FeatureBuilder = OriginalFeatureBuilder.instance()
	$WidgetMaker.add_child(new_FeatureBuilder)
	new_FeatureBuilder.connect("BtnAdd_pressed",self,"_on_BtnAdd_pressed")
	new_FeatureBuilder.connect("BtnDelete_pressed",self,"_on_BtnDelete_pressed",[new_FeatureBuilder])
	new_FeatureBuilder.setup_FeatureBuilder(build_specs, current_data, hide)
	return new_FeatureBuilder


func setup_WidgetBuilder(Widget : BaseWidget):
	for child in $WidgetMaker.get_children():
		child.queue_free()
	current_widget_data = Widget.current_data
	old_widget_data = GlobalHelper.deep_copy(Widget.current_data)
	build_specs = Widget.build_specs

	for feature in current_widget_data.content:
		_add_FeatureBuilder(build_specs.content,feature)

	if build_specs.instructions.canAdd:
		_add_FeatureBuilder(build_specs.content,current_widget_data.content[0],1)
	
	# #using the Dictionary pattern with match to change the FeatureBuilder configuration
	# match current_widget_data:
	# 	{"widget_type":"BasicWidget", ..}:
	# 		for feature in current_widget_data.content:
	# 			add_FeatureBuilder(current_widget_data.widget_type,content_description["BasicWidget"], feature)
	# 		add_FeatureBuilder(current_widget_data.widget_type,content_description["BasicWidget"])
	# 	{"widget_type":"SpellSlotWidget", ..}:
	# 			add_FeatureBuilder(current_widget_data.widget_type,content_description["SpellSlotWidget"],current_widget_data.content[0]) 
	# 	{"widget_type":"DiceTrackerWidget", ..}:
	# 			add_FeatureBuilder(current_widget_data.widget_type,content_description["DiceTrackerWidget"],current_widget_data.content[0]) 
				
func reset_WidgetBuilder():
	$WidgetPreview.get_child(0).queue_free()
	for child in $WidgetMaker.get_children():
		child.queue_free()
	current_widget_data = null

func collect_specification() -> Dictionary:
	var specs = []
	for Feature in $WidgetMaker.get_children():
		if !Feature.get_node("BtnAdd").visible:
			specs.append(Feature.get_data())
	return specs

#TODO make widget reset instead of new instance
func build_WidgetPreview():
	if $WidgetPreview.get_child_count() > 0:
		$WidgetPreview.get_child(0).queue_free()
	var new_preview = load("res://scenes/%s.tscn" % current_widget_data.widget_type).instance()
	current_widget_data.content = collect_specification()
	new_preview.construct_widget(current_widget_data)
	$WidgetPreview.add_child(new_preview)

func _on_BtnAdd_pressed():
	_add_FeatureBuilder(build_specs.content,current_widget_data.content[0],1)

func _on_BtnDelete_pressed(FeatureBuilder):
	if $WidgetMaker.get_child_count() <= 1:
		_add_FeatureBuilder(build_specs.content,current_widget_data.content[0],1)
	FeatureBuilder.queue_free()


func get_widget_specs() -> Dictionary:
	return current_widget_data
