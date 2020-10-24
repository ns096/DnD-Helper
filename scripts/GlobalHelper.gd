extends Node

var loaded_images
var tween_helper
var UI_focus
onready var dragging_widget = false
onready var startup_done = false

func _ready():
	tween_helper = Tween.new()
	add_child(tween_helper)


	preload_images()


func preload_images():
	loaded_images = {}
	var temp_img = ImageTexture.new()
	temp_img = load("res://assets/UI/checkbox_circle_crossed_50px.png")
	loaded_images.checkbox_checked = temp_img
	temp_img = ImageTexture.new()
	temp_img = load("res://assets/UI/checkbox_circle_50px.png")
	loaded_images.checkbox_unchecked = temp_img

func tween_pop(target):
	tween_helper.interpolate_property(target,'rect_scale',Vector2(0,0),Vector2(1,1),0.3,Tween.TRANS_BACK,Tween.EASE_OUT)
	tween_helper.start()

func tween_shrink(target):
	tween_helper.interpolate_property(target,'rect_scale',null,Vector2(0.4,0.4),0.3,Tween.TRANS_BACK,Tween.EASE_OUT)
	tween_helper.start()

func tween_swipe_show(target):
	tween_helper.interpolate_property(target,'rect_position',Vector2(get_viewport().size.x*-1.5,0),Vector2(0,0) ,0.3,Tween.TRANS_BACK,Tween.EASE_OUT)
	tween_helper.start()

func tween_swipe_hide(target):
	tween_helper.interpolate_property(target,'rect_position',null,Vector2(get_viewport().size.x*1.5,0) ,0.3,Tween.TRANS_BACK,Tween.EASE_OUT)
	tween_helper.start()

#.duplicate() only returns a shallow copy
#makes a real copy of Arrays and Dictionaries
func deep_copy(v):
	var t = typeof(v)
	if t == TYPE_DICTIONARY:
		var d = {}
		for k in v:
			d[k] = deep_copy(v[k])
		return d
	elif t == TYPE_ARRAY:
		var d = []
		d.resize(len(v))
		for i in range(len(v)):
			d[i] = deep_copy(v[i])
		return d

	else:
		return v

func getDateString() -> String:
	var date = OS.get_datetime()
	var date_string = ""
	date_string += str(date["year"])
	date_string += str(date["month"])
	date_string += str(date["day"]) + "_"
	date_string += str(date["hour"]) + "_"
	date_string += str(date["minute"])
	return date_string
		
func take_screenshot(shrink_factor := 0) -> Image:
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	for _x in range(shrink_factor):
		image.shrink_x2()
	
	return image


func set_ui_focus(UI : Control, is_dragging : bool):
	UI_focus = UI
	