extends Control

func _ready():
	pass

var dragging_panel = null
var selected_widget = null

var holding_press = false
var time_gone = 0

func _input(event):
	if event is InputEventScreenDrag:
		rect_position += event.relative
		# holding_press = false
		# if dragging_panel == null:
			
		# 	if page_dict[screen_coord_to_page_coord(event.position)] != null:
		# 		dragging_widget = page_dict[screen_coord_to_page_coord(event.position)]
		# 		page_dict[screen_coord_to_page_coord(event.position)] = null
		# 		remove_child(WidgetOptions)
		# elif can_drag:
		# 	drag_widget(dragging_widget,event)