extends Control

#Widget Page class
#responsible for instancing the widgets and keeping an up to date widget page


#this class is also responsible for implementing dragging a widget and resizing it
#editing a widget emits a signal that gets sent to WidgetBuilder
#it also stores which vector2 key is currently active/selected


var ROWS = 10
var COLUMNS = 6
var widget_page_node_references = {}
var widget_position
var _selected_widget setget set_selected_widget, get_selected_widget
var start_drag_position
var WidgetOptions
var current_widget_page setget set_widgetpage, get_widgetpage
var x_step
var y_step
var settings

export(Array,String, FILE) var scene_paths

signal edit_widget(Widget)
signal data_changed(widget_page)

func _ready():
	setup_settings(COLUMNS, ROWS)

	WidgetOptions = load("res://scenes/WidgetOptions.tscn").instance()
	WidgetOptions.connect("_on_button_pressed", self, "option_button_pressed")
	add_child(WidgetOptions)

	GlobalHelper.UI_focus = self
	setup_PopupAddWidget(scene_paths)

#GUI variables
var holding_press
var time_holding_down = 0.0
func _gui_input(event):
	GlobalHelper.UI_focus = self

func setup_PopupAddWidget(widget_paths):
	var popup_box = $PopupAddWidget/Box
	#instantiate the widget and get data
	var widget_default_data
	for widget in widget_paths:
		var placeholder = load(widget).instance()
		widget_default_data = placeholder.default_data
		var button = Button.new()
		button.text = widget_default_data.widget_type
		button.connect("pressed", self, "_on_new_widget", [widget_default_data])
		popup_box.add_child(button)


func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			holding_press = true
		else:
			holding_press = false
			time_holding_down = 0.0
	if Input.is_key_pressed(KEY_P):
		var file = "user://preview.png"
		var img = GlobalHelper.take_screenshot(2)
		img.save_png(file)

func _process(delta):
	# press and hold widget to access options
	if holding_press && GlobalHelper.UI_focus == self && GlobalHelper.dragging_widget == false:
		time_holding_down += delta
		if time_holding_down >= 0.6:
			widget_position = screen_coord_to_page_coord(get_global_mouse_position())
			$PopupAddWidget.popup()
			time_holding_down = 0.0
			holding_press = false

#return also setting when accessed outside
func get_widgetpage():
	update_current_widget_page_data()
	var page_and_settings = {"page_size":{"columns":COLUMNS,"rows":ROWS},"widget_page":current_widget_page}
	return page_and_settings

func update_current_widget_page_data():
	var widget_page_data = []
	for child in get_children():
		if child is BaseWidget:
			var data = child.get_data()
			if data != null:
				widget_page_data.append(data)
			else:
				print(child)
	current_widget_page = widget_page_data

func set_widgetpage(value):
	current_widget_page = value["widget_page"]
	setup_settings(value["page_size"]["columns"],value["page_size"]["rows"])

func set_selected_widget(Widget: BaseWidget):
	_selected_widget = Widget

func get_selected_widget() -> BaseWidget:
	return _selected_widget	

# build page with widget specs	
func clear_widget_page():
	for child in get_children():
		if child is BaseWidget:
			child.queue_free()

# build page with widget specs	
func build_widget_page(widget_page):
	for widget in widget_page:
		build_widget(widget)

func construct_widget_page(savedata : Dictionary):
	clear_widget_page()

	COLUMNS = savedata["page_size"]["columns"]
	ROWS = savedata["page_size"]["rows"]
	setup_settings(COLUMNS, ROWS)

	build_widget_page(savedata["widget_page"])

func setup_settings(columns, rows):
	settings = {}
	settings["grid"] = Vector2(COLUMNS, ROWS)
	settings["step_size"] = Vector2(self.rect_size.x/COLUMNS, self.rect_size.y/ROWS)
	COLUMNS = columns
	ROWS = rows

func get_settings() -> Dictionary:
	return settings 

#Takes page_position as key and specifications as value
#this class keeps track of page position and specifications
#Widget keeps track of specifications for user interactions and returning data later	
func build_widget(specifications : Dictionary):
	var position = specifications["position"]
	var type = specifications.widget_type
	var node_path = "res://widgets/"+type+"/"+type+".tscn"
	var Widget = load(node_path).instance()
	Widget.connect("on_release_drag_widget", self, "try_snap_widget")
	Widget.connect("on_start_drag_widget", self, "init_start_drag_widget")
	Widget.connect("on_holding_press", self, "show_widget_options")
	Widget.connect("on_user_interaction", self, "user_changed_widget")
	
	add_child(Widget)
	#Widget takes specifications and constructs itself
	Widget.construct(specifications, get_settings())
	
#update current widget_page as soon as user toggles a checkbox
func user_changed_widget(Widget : BaseWidget):
	emit_signal("data_changed",current_widget_page)

func show_widget_options(Widget : BaseWidget):
	_selected_widget = Widget
	WidgetOptions.rect_position = Vector2(get_global_mouse_position().x-WidgetOptions.rect_size.x/2,get_global_mouse_position().y-WidgetOptions.rect_size.y)
	WidgetOptions.popup()
	GlobalHelper.tween_pop(WidgetOptions)

#long press on widget opens up this WidgetOptions menu			
func option_button_pressed(type):
	match type:
		"resize":
			$PopupResize.popup()
			$PopupResize/VBox/HBox1/Width.value = _selected_widget.widget_size.x
			$PopupResize/VBox/HBox2/Height.value = _selected_widget.widget_size.y
		"delete":
			_selected_widget.queue_free()
			_selected_widget = null
		"edit":
			GlobalHelper.tween_swipe_hide(self)
			emit_signal("edit_widget",_selected_widget)
		_:
			print(type)
	WidgetOptions.visible = false

func find_widget_on_page(Widget : BaseWidget):
	if Widget is BaseWidget:
		for key in widget_page_node_references:
			if widget_page_node_references[key] == Widget:
				return key
		print("couldn't find: ", Widget )
		print(widget_page_node_references)
		
	return "Not A Widget"

#widget signal on_start_drag_widget
#keep initial start_drag_position for access later
#set quick access widget_page_node_references to null and start moving
func init_start_drag_widget(Widget : BaseWidget):
	GlobalHelper.dragging_widget = true
	start_drag_position = screen_coord_to_page_coord(Widget.rect_position)
	#widget_page_node_references[start_drag_position] = null
	WidgetOptions.visible = false

func resize_widget(Widget, new_size):
	Widget.rect_size = Vector2(x_step*new_size.x, y_step*new_size.y)
	Widget.current_data.widget_size = new_size

func _on_PopupResize_Submit_pressed() -> void:
	$PopupResize.visible = false
	var new_size = Vector2($PopupResize/VBox/HBox1/Width.value,$PopupResize/VBox/HBox2/Height.value)
	_selected_widget.resize(new_size)

	widget_position = null
	emit_signal("data_changed",current_widget_page)

func screen_coord_to_page_coord(pos: Vector2):
	#this has a nasty rounding error with 3 columns so I increase pos.x by a bit
	var u = 0.002
	var step_size = get_settings()["step_size"]
	return Vector2(int((pos.x+u)/step_size.x), int((pos.y+u)/step_size.y))

func page_coord_to_screen_coord(pos: Vector2):
	var step_size = get_settings()["step_size"]
	return step_size * pos


#widget popup easier to add new data 
func _on_new_widget(widget_data):
	widget_data["position"] = widget_position
	build_widget(widget_data)
	$PopupAddWidget.visible = false
	_selected_widget = null
	widget_position = null

#DEV functions
#fill all page slots with a basic test widget
func DEV_fill_page():
	var ALL_MY_WIDGETS = {Vector2(0,0):{"widget_type": "BasicWidget","widget_size": Vector2(2,2), "content": [{"feature_name":"widget test","cur_marker":0, "max_marker": 0},{"feature_name":"","cur_marker":1,"max_marker":4},{"feature_name":"extra", "cur_marker":1, "max_marker": 2}]},
						Vector2(0,4):{"widget_type": "SpellSlotWidget","widget_size":Vector2(2,4),"content": [{"feature_name":"Spell Slots","class_level": 5,"used_slots":[2,2,0,0,0,0,0,0,0]}]},
						Vector2(2,5):{"widget_type": "DiceTrackerWidget","widget_size":Vector2(4,4),
						"content": [{"feature_name":"Example","current_die": 0,"maximum_die":5}]}
	}

	current_widget_page = ALL_MY_WIDGETS
	build_widget_page(current_widget_page)

