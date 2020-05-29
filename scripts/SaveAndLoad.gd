extends VBoxContainer

#class for save and load functionality
#it copies, saves and reads the .json files
#it also parses the widget_page data in and out of json
# JSON does not have godot variant data like Vector2
#the nesting of the json data is really important, look at save.json and default.json for examples
#an example from the top of my head
#{"savename","savedata":{"page_size","widget_page":[{Widget1},{Widget2}]}}

var selected_save
var default_save_path = "user://default_save.json"
onready var current_session : Dictionary = {"savename":"default"} setget savedata_set

signal savedata_loaded(widget_page)
signal save_current_session()
signal savedata_updated()

var VERSION = "1.0"

func _ready() -> void:
	prepare_empty_folder()
	assign_saveslots()
	load_defaultsave()
	

var timer = 0
func _physics_process(delta) -> void:
	pass
#	timer += delta
#
#	if(timer >= 8):
#		timer = 0
#		print("autosave")
#		autosave()


#there is a central save.json that contains data for the savedata filenames
#It also saves some additional info for that file (date,savename)
#depending on the user several other save files are then created and registered in save.json
#these save files contain the savename and the full featurelist
#
#I split the central file and the user files so if the user wants he can see directly which file to access

#using setget this emits a signal everytime savedata gets updated
#this signal then starts waiting coroutines that wait for the uptodate data
#yield(self, "savedata_updated")
func savedata_set(value):
	current_session["savedata"] = value
	emit_signal("savedata_updated")
	#print("signal:savedata_updated")

#load save.json and instance SaveSlots to add functionality to the data	
func assign_saveslots():
	var saves = load_json_file("user://save.json")
	#print(saves)
	for saveslot in saves:
		
		var SaveSlot = load("res://scenes/SaveSlot.tscn").instance()
		SaveSlot.set_save(saveslot,saves[saveslot]["savename"],saves[saveslot]["date"])
		
		#connect signals
		SaveSlot.connect("save_pressed", self, "_on_save_pressed")
		SaveSlot.connect("change_name_pressed", self, "_on_change_name_pressed")
		SaveSlot.connect("load_pressed", self, "_on_load_pressed")
		SaveSlot.connect("delete_pressed", self, "_on_delete_pressed")
		
		add_child(SaveSlot)

#when first starting the app, relevant user data gets copied to user://
#res:// can't be overwritten 
#savedata has to be stored in user://		
func prepare_empty_folder():
	var file = File.new()
	#check for save,json and default.json
	# from saves folder to user folder
	if not file.file_exists("user://save.json"):
		var dir = Directory.new()
		if dir.copy("res://saves/save.json", "user://save.json") != 0:
			$NewSave.text = "Cant_: %s" % dir.copy("res://saves/save.json", "user://save.json")
	if not file.file_exists("user://default.json"):
		var dir = Directory.new()
		if dir.copy("res://saves/default.json", "user://default.json") != 0:
			$NewSave.text = "Cant_: %s" % dir.copy("res://saves/default_autosave.json", "user://default_autosave.json")

	if not file.file_exists("user://autosave.json"):
		var dir = Directory.new()
		if dir.copy("res://saves/default.json", "user://autosave.json") != 0:
			$NewSave.text = "Cant_: %s" % dir.copy("res://saves/default.json", "user://autosave.json")

#take default_save
func load_defaultsave():
	get_save_by_saveslot("default")

#save current data to autosave
func autosave():
	save_session("autosave","autosave",current_session)

#takes the default or user given savename
func get_save_by_savename(savename):
	var filepath = "user://%s.json" % savename
	current_session = load_json_file(filepath)
	prepare_data(current_session)
	return current_session

#user can't change saveslot name
#this takes saveslot and checks for the savename
func get_save_by_saveslot(saveslot):
	var savename = load_json_file("user://save.json")[saveslot]["savename"]
	var filepath = "user://%s.json" % savename
	current_session = load_json_file(filepath)
	prepare_data(current_session)
	return current_session

#takes savename and data and saves it
func store_save(savename, savedata):
	var filepath = "user://%s.json" % savename
	save_json_file(filepath, savedata)

#make a new file and write Dict as json data
func save_json_file(filepath, savedata):
	var file = File.new()
	if file.open(filepath, File.WRITE) != 0:
		print(file.open(filepath, File.WRITE))
		print("Error opening file")
		return
	if(typeof(savedata)==TYPE_NIL):
		print("WTF")
	file.open(filepath,File.WRITE)
	file.store_line(to_json(savedata))
	file.close()

#open json file and load data as Dict
func load_json_file(filepath:String):
	var file = File.new()
	file.open(filepath,File.READ)
	var text = file.get_as_text()
	var result = JSON.parse(text);
	file.close()
	if result.error != 0:
		print("ErrorString:", result.error_string)
		return ("Error")
	else:
		#print(result.result)
		return result.result
		

#build and store an empty default save
#TODO
func build_save(savename):
	var dir = Directory.new()
	if dir.copy("res://saves/empty_page.json", "user://%s.json" % savename) != 0:
		$NewSave.text = "Cant_: %s" % dir.copy("res://saves/default.json", "user://%s.json" % savename)


#helper function to create empty array
#so I don't have to fill my save data by hand
func build_dimensional_array(width, height):
	var matrix = []
	for x in range(height):
		matrix.append([])
	return matrix

#reset SaveSlot Nodes and build them anew
#gets called everytime relevant data changes
func reset_SaveSlots():
	for child in get_children():
		if not child is Button:
			child.queue_free()
	assign_saveslots()

#uses dictionary pattern matching to check JSON validity
#data is either directly accessible or nested	
func prepare_data(data):
	match data:
		{"savedata":{"widget_page",..},..}:
			var widget_page = data["savedata"]["widget_page"]
			if typeof(widget_page) == TYPE_ARRAY:
				print("is type array")
			current_session["savedata"]["widget_page"] = parse_json_to_widget_page(widget_page)
		{"widget_page",..}:
			var widget_page = data["widget_page"]
			current_session["savedata"]["widget_page"] = parse_json_to_widget_page(widget_page)
		_:
			print("data pattern does not match")
			print(data)

#take current_session data and save it, also update the save.json file with the current metadata
func save_session(savename,saveslot,sessiondata):
	emit_signal("save_current_session")
	#savedata_updated gets send out before yield even get executed
	#yield(self, "savedata_updated")
	var data = load_json_file("user://save.json")
	data[saveslot]["date"] = OS.get_datetime()
	save_json_file("user://save.json", data)

	var user_data = GlobalHelper.deep_copy(sessiondata)
	user_data["savedata"]["widget_page"] = parse_widget_page_to_json(sessiondata["savedata"]["widget_page"])

	store_save(savename, user_data)

#this section is for handling button presses and signals
############
func _on_save_pressed(savename, saveslot):
	save_session(savename, saveslot,current_session)

func _on_load_pressed(savename, saveslot):
	selected_save = saveslot
	current_session = get_save_by_savename(savename)
	emit_signal("savedata_loaded", current_session["savedata"])

func _on_delete_pressed(savename, saveslot):
	var data = load_json_file("user://save.json")
	data.erase(saveslot)
	save_json_file("user://save.json", data)
	
	var dir = Directory.new()
	dir.remove("user://%s.json" % savename)
	
	reset_SaveSlots()

func _on_change_name_pressed(savename, saveslot):
	var data = load_json_file("user://save.json")
	var old_savename = data[saveslot]["savename"]
	data[saveslot] = {"savename":savename,"date":OS.get_datetime()}
	save_json_file("user://save.json", data)
	var dir = Directory.new()
	if dir.rename("user://%s.json" % old_savename, "user://%s.json" % savename) != 0:
		print("ERROR RENAMING FILE")
	
	reset_SaveSlots()

#make a new save
#add relevant data to save.json and make an empty savename.json file 	
func _on_NewSave_pressed() -> void:
	var data = load_json_file("user://save.json")
	var saveslot = ""
	for i in range(1,10):
		if not data.has("Saveslot %s" % i):
			saveslot = "Saveslot %s" % i
			break
	if saveslot == "":
		saveslot = "Saveslot %s" % (data.size()+1)
	
	data[saveslot] = {}
	data[saveslot]["savename"] = saveslot
	data[saveslot]["version"] = VERSION
	data[saveslot]["date"] = OS.get_datetime()
	data[saveslot]["date_created"] = OS.get_datetime()
	
	build_save(saveslot)
	save_json_file("user://save.json", data)
	
	reset_SaveSlots()

#takes widget_page with all the variant datatype like Vector2 and saves it all as a Dictionary
#this could get event bigger if more diverse widgets are added
#the nesting of the savedata has to be valid	
func parse_widget_page_to_json(widget_page : Dictionary) -> Dictionary:
	var valid_json = []
	
	for key in widget_page:
		var widget = {}
		widget.pos_x = key.x
		widget.pos_y = key.y
		widget.size_x = widget_page[key].widget_size.x
		widget.size_y = widget_page[key].widget_size.y
		widget.widget_type = widget_page[key].widget_type
		widget.content = widget_page[key].content

		valid_json.append(widget)
	return valid_json


#takes the json with all its primitves and turn them into variant data to be read and accessed properly
#nesting of the data is really important
#look at save.json and default.json for examples	
func parse_json_to_widget_page(json : Array) -> Dictionary:
	var widget_page = {}
	for data in json:
		var widget = {"widget_type":data.widget_type,
						"widget_size":Vector2(data.size_x,data.size_y),
						"content": data.content}
		widget_page[Vector2(data.pos_x,data.pos_y)] = widget
	return widget_page
