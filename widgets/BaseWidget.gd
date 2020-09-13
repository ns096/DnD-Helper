class_name BaseWidget
extends Control

#base class for Widgets
#implements drag and UI functionality
#and has empty functions so inherited class know what to implement

#signals include self reference so that parent objects can differentiate the signal
#I've tried adding this as a custom argument while instancing and connecting 
#but sometimes the reference would get lost
#not sure if that't an instancing bug or my widget_page got updated incorrectly
#maybe a custom argument would work now, but this works so I'm not changing it

#to add a new widget:
#make a widget scene implementing the right functionality
#implement empty functions
#write a specific FeatureBuilder and link it
#DynamicWidgetPage needs to be able to add and instance it 

export(String) var builderPath

signal on_user_interaction(self_reference)
signal on_release_drag_widget(self_reference)
signal on_start_drag_widget(self_reference)
signal on_holding_press(self_reference)

onready var bounding_box = Rect2(rect_position,rect_size)

var current_data = null
var step_size : Vector2
var widget_size : Vector2
var page_position : Vector2

#var default_data = null
#every widget should have the red_dot for dragging
func _ready():
	red_dot = load("res://scenes/red_dot.tscn").instance()
	add_child(red_dot)
	red_dot.visible = false
	self.connect("resized",self,"_on_resized")
	mouse_filter = MOUSE_FILTER_STOP

func get_data():
	return current_data

func get_builder():
	var builder : BaseFeatureBuilder = load(builderPath).instance()
	builder.setup_FeatureBuilder(current_data)
	return builder

#Widget needs to construct itself with Dictionary Data
#Same Data has to be stored then in save file
func construct_widget(specifications : Dictionary):
	pass

func update_current_data():
	pass

#resizing image textures doesn't properly work in godot
#it's easier to manually resize and save textures seperately
func get_resized_texture(t: Texture, width: int = 0, height: int = 0):
	var image = t.get_data()
	if width > 0 && height > 0:
		image.resize(width, height)
	var itex = ImageTexture.new()
	itex.create_from_image(image)
	return itex

var red_dot
var holding_press = false

#update the size of bounding box
func _on_resized():
	bounding_box.size = rect_size

func set_steps(x_step, y_step):
	step_size = Vector2(x_step, y_step)


#input checks for if the event was inside the bounding box and if it's currently the UI_focus. 
#because widgets can overlap this is necessary
#first set Singleton GlobalHelper_UI_focus to self when getting input
#then start setting flags for time,drag and hold  	
func _input(event):

	#this needs to be decoupled from the bounding box check because get_global_mouse_position() updates too slowly
	if GlobalHelper.dragging_widget&&GlobalHelper.UI_focus == self && event is InputEventScreenDrag:
		drag_widget(event)

	if bounding_box.has_point(get_global_mouse_position())&&GlobalHelper.UI_focus == self:
		if event is InputEventScreenTouch:
			if event.is_pressed():
				holding_press = true
			else:
				holding_press = false
				time_gone = 0.0
				red_dot.visible = false
				rect_scale = Vector2(1,1)
				GlobalHelper.UI_focus = null
				if GlobalHelper.dragging_widget:
					emit_signal("on_release_drag_widget",self)
					
		if event is InputEventScreenDrag:
			if !GlobalHelper.dragging_widget:
				emit_signal("on_start_drag_widget",self)
				red_dot.visible = true
				rect_scale *= 1.1
			holding_press = false
			#drag_widget(event)

var time_gone = 0.0				
func _process(delta):
	bounding_box.position = rect_position
	if holding_press && bounding_box.has_point(get_global_mouse_position()):
		time_gone += delta
		if time_gone >= 0.4:
			emit_signal("on_holding_press",self)
			time_gone = 0.0
			holding_press = false


func _gui_input(event):
	GlobalHelper.UI_focus = self

func drag_widget(event):
	rect_position += event.relative

