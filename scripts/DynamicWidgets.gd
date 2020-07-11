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
	for key in widget_page:
		if key == null:
			print("widget page key is null!!")
		build_widget(key,widget_page[key])

func construct_widget_page(savedata : Dictionary):
	current_widget_page = savedata["widget_page"]
	COLUMNS = savedata["page_size"]["columns"]
	ROWS = savedata["page_size"]["rows"]
	build_widget_reference(COLUMNS,ROWS)
	x_step = self.rect_size.x/COLUMNS
	y_step = self.rect_size.y/ROWS
	update_widget_page()

#Takes page_position as key and specifications as value
#this class keeps track of page position and specifications
#Widget keeps track of specifications for user interactions and returning data later	
func build_widget(page_position, specifications):
	var node_path = "res://scenes/%s.tscn" % specifications.widget_type
	var DynamicWidget = load(node_path).instance()
	DynamicWidget.connect("on_release_drag_widget", self, "try_snap_widget")
	DynamicWidget.connect("on_start_drag_widget", self, "init_start_drag_widget")
	DynamicWidget.connect("on_holding_press", self, "show_widget_options")
	DynamicWidget.connect("on_user_interaction", self, "user_changed_widget")
	
	add_child(DynamicWidget)
	widget_page_node_references[page_position] = DynamicWidget
	#Widget takes specifications and constructs itself
	DynamicWidget.construct_widget(specifications)
	#Widget shouldnt directly care about screen size
	#That why its size and position gets changed here
	DynamicWidget.rect_size = Vector2(x_step*(specifications.widget_size.x), y_step*(specifications.widget_size.y))
	DynamicWidget.rect_position = page_coord_to_screen_coord(page_position)
	
#TODO make drag and snap widget search from center
func get_widget_center(Widget : BaseWidget):
	var widget_center_position = Widget.rect_position
	widget_center_position.x += Widget.rect_size.x/2
	widget_center_position.y += Widget.rect_size.y/2
	return widget_center_position

#widget signal on_start_drag_widget
#keep initial start_drag_position for access later
#set quick access widget_page_node_references to null and start moving
func init_start_drag_widget(Widget : BaseWidget):
	GlobalHelper.dragging_widget = true
	start_drag_position = screen_coord_to_page_coord(Widget.rect_position)
	#widget_page_node_references[start_drag_position] = null
	WidgetOptions.visible = false

#widget signal on_release_drag_widget
func try_snap_widget(Widget : BaseWidget):
	#check if the tile beneath widget is free
	#if free then move widget there and change all belonging data
	if widget_page_node_references[screen_coord_to_page_coord(Widget.rect_position)] == null:
		#take current position, check which tile it is and then return the position of the tile
		Widget.rect_position = page_coord_to_screen_coord(screen_coord_to_page_coord(Widget.rect_position))
		#if the location is different than the starting position, change widget_page_node_references and current_widget_page
		if not screen_coord_to_page_coord(Widget.rect_position) == start_drag_position:
			widget_page_node_references[screen_coord_to_page_coord(Widget.rect_position)] = Widget
			current_widget_page[screen_coord_to_page_coord(Widget.rect_position)] = current_widget_page[start_drag_position]
			current_widget_page.erase(start_drag_position)
			widget_page_node_references[start_drag_position] = null
		start_drag_position = null
	else:
		if find_any_empty() != null:
			Widget.rect_position = page_coord_to_screen_coord(start_drag_position)
			widget_page_node_references[screen_coord_to_page_coord(Widget.rect_position)] = Widget
		else:
			print("try_snap_widget: no space left?")
			widget_page_node_references["shit"]
	GlobalHelper.dragging_widget = false


#update current widget_page as soon as user toggles a checkbox
func user_changed_widget(Widget:BaseWidget):
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

#finds the first empty slot in widget_page_node_references
#only if snapping the widget doesn't find a free slot
func find_any_empty():
	for key in widget_page_node_references:
		if widget_page_node_references[key] == null:
			return key
	return null

func build_widget_reference(columns, rows):
	for x in columns:
		for y in rows:
			widget_page_node_references[Vector2(x,y)] = null
					
func screen_coord_to_page_coord(pos):
	if pos.x < 0 || pos.x > self.rect_size.x || pos.y < 0 || pos.y > self.rect_size.y:
		return(find_any_empty())
	#this has a nasty rounding error with 3 columns so I increase pos.x by a bit
	var u = 0.002
	return Vector2(int((pos.x+u)/x_step), int((pos.y+u)/y_step))

func page_coord_to_screen_coord(pos):
	return Vector2((x_step*pos.x),(y_step*pos.y))

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

#PopupAddWidget calls the following functions
func _on_BtnBasicWidget_pressed() -> void:
	var basic_widget_data = {"widget_type": "BasicWidget","widget_size": Vector2(2,2), "content": [{"feature_name":"Basic Widget","cur_marker":0, "max_marker": 0},{"feature_name":"","cur_marker":0,"max_marker":4},{"feature_name":"Extra", "cur_marker":0, "max_marker": 2}]}
	current_widget_page[selected_widget_key] = basic_widget_data
	update_widget_page()
	$PopupAddWidget.visible = false
	selected_widget_key = null
						
func _on_BtnSpellSlotWidget_pressed() -> void:
	var spellslot_widget_data = {"widget_type": "SpellSlotWidget","widget_size":Vector2(2,3),"content": [{"feature_name":"Spell Slots","class_level": 6,"used_slots":[0,0,0,0,0,0,0,0,0]}]}
	current_widget_page[selected_widget_key] = spellslot_widget_data
	update_widget_page()
	$PopupAddWidget.visible = false
	selected_widget_key = null

func _on_BtnDiceTrackerWidget_pressed() -> void:
	var dicetracker_widget_data = {"widget_type": "DiceTrackerWidget","widget_size":Vector2(2,3),"content": [{"feature_name":"Ammo","current_die": 3,"maximum_die":5}]}
	current_widget_page[selected_widget_key] = dicetracker_widget_data
	update_widget_page()
	$PopupAddWidget.visible = false
	selected_widget_key = null
	print("DICETRACKAA")


#TODO new widget popup easier to add new data 
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
	


