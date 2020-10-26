extends Control

#Widget Page class
#responsible for instancing the widgets and keeping an up to date widget page
#current_widget_page is a dictionary with Vector2 as a key and widget_data as their value
#widget_page_node_references is a dictionary with Vector2 as a key and stores the widget children node references
#this class is also responsible for implementing dragging a widget and resizing it
#editing a widget emits a signal that gets sent to WidgetBuilder
#it also stores which vector2 key is currently active/selected


var ROWS = 10
var COLUMNS = 6
var widget_page_node_references = {}
var selected_widget_key
var start_drag_position
var WidgetOptions
var current_widget_page setget widgetpage_set,widgetpage_get
var x_step
var y_step

export(Array,String, FILE) var scene_paths

signal edit_widget(Widget)
signal data_changed(widget_page)

func _ready():
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
		var img =GlobalHelper.take_screenshot(2)
		img.save_png(file)

func _process(delta):
	if holding_press && GlobalHelper.UI_focus == self && GlobalHelper.dragging_widget == false:
		time_holding_down += delta
		if time_holding_down >= 0.6:
			var pos = get_global_mouse_position()
			if widget_page_node_references[screen_coord_to_page_coord(pos)] == null:
				selected_widget_key = screen_coord_to_page_coord(pos)
				$PopupAddWidget.popup()
			time_holding_down = 0.0
			holding_press = false

#return also setting when accessed outside
func widgetpage_get():
	print("widget_page getter accessed from outside")
	var page_and_settings = {"page_size":{"columns":COLUMNS,"rows":ROWS},"widget_page":current_widget_page}
	return page_and_settings

func widgetpage_set(value):
	match value:
		{"page_size","widget_page"}:
			#complete data overwrites current data
			current_widget_page = value["widget_page"]
			COLUMNS = value["page_size"]["columns"]
			ROWS = value["page_size"]["rows"]
			build_widget_reference(COLUMNS,ROWS)
			x_step = self.rect_size.x/COLUMNS
			y_step = self.rect_size.y/ROWS
			update_widget_page()
		{"widget_page",..}:
			current_widget_page = value["widget_page"]
		var wildcard:
			print("pattern does not match")
			print(wildcard)

func update_widget_page():
	build_widget_reference(COLUMNS,ROWS)
	for child in get_children():
		if child is BaseWidget:
			child.free()
	build_widget_page(current_widget_page)

func build_widget_page(widget_page):
	page_meta_data = get_meta_data()
	for position in widget_page:
		if position == null:
			print("widget page position is null!!")
		build_widget(widget_page[position], position)

func construct_widget_page(savedata : Dictionary):
	current_widget_page = savedata["widget_page"]
	COLUMNS = savedata["page_size"]["columns"]
	ROWS = savedata["page_size"]["rows"]
	build_widget_reference(COLUMNS,ROWS)
	step_size = Vector2(self.rect_size.x/COLUMNS, self.rect_size.y/ROWS)
	update_widget_page()

func get_meta_data() -> Dictionary:
	meta_data = {}
	meta_data["grid"] = Vector2(COLUMNS, ROWS)
	meta_data["step_size"] = step_size
	return meta_data	

#Takes page_position as key and specifications as value
#this class keeps track of page position and specifications
#Widget keeps track of specifications for user interactions and returning data later	
func build_widget(specifications : Dictionary, position : Vector2):
	var type = specifications.widget_type
	var node_path = "res://widgets/"+type+"/"+type+".tscn"
	var Widget = load(node_path).instance()
	Widget.connect("on_release_drag_widget", self, "try_snap_widget")
	Widget.connect("on_start_drag_widget", self, "init_start_drag_widget")
	Widget.connect("on_holding_press", self, "show_widget_options")
	Widget.connect("on_user_interaction", self, "user_changed_widget")
	
	add_child(Widget)
	#Widget takes specifications and constructs itself
	Widget.construct(specifications, get_meta_data(), position)
	Widget.set_steps(x_step, y_step)
	
	Widget.rect_size = Vector2(x_step*(specifications.widget_size.x), y_step*(specifications.widget_size.y))
	Widget.rect_position = page_coord_to_screen_coord(page_position)
	
#update current widget_page as soon as user toggles a checkbox
func user_changed_widget(Widget : BaseWidget):
	var key = find_widget_on_page(Widget)
	current_widget_page[key] = Widget.current_data
	emit_signal("data_changed",current_widget_page)

func show_widget_options(Widget : BaseWidget):
	selected_widget_key = screen_coord_to_page_coord(Widget.rect_position)
	WidgetOptions.rect_position = Vector2(get_global_mouse_position().x-WidgetOptions.rect_size.x/2,get_global_mouse_position().y-WidgetOptions.rect_size.y)
	WidgetOptions.popup()
	GlobalHelper.tween_pop(WidgetOptions)

#long press on widget opens up this WidgetOptions menu			
func option_button_pressed(type):
	match type:
		"resize":
			$PopupResize.popup()
			$PopupResize/VBox/HBox1/Width.value = current_widget_page[selected_widget_key].widget_size.x
			$PopupResize/VBox/HBox2/Height.value = current_widget_page[selected_widget_key].widget_size.y
		"delete":
			clear_widget_from_page(selected_widget_key)
			selected_widget_key = null
		"edit":
			GlobalHelper.tween_swipe_hide(self)
			emit_signal("edit_widget",widget_page_node_references[selected_widget_key])
		_:
			print(type)
	WidgetOptions.visible = false

#takes widget and removes it from the page array and then frees it
func clear_widget_from_page(key : Vector2):
	if widget_page_node_references[key] != null:
		widget_page_node_references[key].free()
		widget_page_node_references[key] = null
		if current_widget_page.has(key):
			current_widget_page.erase(key)
		else:
			print("widget_page_node_references has widget but widget_page doesnt")
	else:
		print("could not find widget in widget_page_node_references")

func find_widget_on_page(Widget : BaseWidget):
	if Widget is BaseWidget:
		for key in widget_page_node_references:
			if widget_page_node_references[key] == Widget:
				return key
		print("couldn't find: ", Widget )
		print(widget_page_node_references)
		
	return "Not A Widget"

				

func resize_widget(Widget, new_size):
	Widget.rect_size = Vector2(x_step*new_size.x, y_step*new_size.y)
	Widget.current_data.widget_size = new_size

func _on_PopupResize_Submit_pressed() -> void:
	$PopupResize.visible = false
	var new_size = Vector2($PopupResize/VBox/HBox1/Width.value,$PopupResize/VBox/HBox2/Height.value)
	resize_widget(widget_page_node_references[selected_widget_key], new_size)
	current_widget_page[selected_widget_key].widget_size = new_size
	selected_widget_key = null
	emit_signal("data_changed",current_widget_page)



#widget popup easier to add new data 
func _on_new_widget(widget_data):
	print(widget_data)
	current_widget_page[selected_widget_key] = widget_data
	update_widget_page()
	$PopupAddWidget.visible = false
	selected_widget_key = null

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

