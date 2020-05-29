extends MarginContainer

#this is the main class of the app
#it instances the widget_page, the widget_builder and saveload functionality
#responsible for switching between those scenes and transmitting relevant data between those


var DynamicWidgetPage
var WidgetBuilder
var SaveAndLoad
var current_session
var current_widget_page


signal on_build_current_widget_page()
signal on_construct_widget_page()
signal on_save_current_widget_page()
signal on_submit_feature()

signal yield_this()

#this class manages the different menus and also the up-to-date DynamicWidgetPage
#it loads and connects the important parts and has them as reference for all other classes
func _ready():
	VisualServer.set_default_clear_color(Color('acacac'))
	#load all neccessary scenes and keep them as hidden children
	SaveAndLoad = load("res://scenes/SaveAndLoad.tscn").instance()
	WidgetBuilder = load("res://scenes/WidgetBuilder.tscn").instance()
	$VBox.add_child(SaveAndLoad)
	$VBox.add_child(WidgetBuilder)
	#move NavigationBar to the bottom of node tree
	$VBox/NavigationBar.raise()
	DynamicWidgetPage = $VBox/DynamicWidgets

	#connect signals
	SaveAndLoad.connect("savedata_loaded", self, "_on_save_data_loaded")
	SaveAndLoad.connect("save_current_session", self, "_on_save_session")
	DynamicWidgetPage.connect("edit_widget",self,"swipe_to_WidgetBuilder")
	DynamicWidgetPage.connect("data_changed",self,"_on_widget_page_changed")
	#hide unused menu
	SaveAndLoad.hide()
	WidgetBuilder.hide()
	setup_widget_page()
	$VBox/NavigationBar/BtnWidgetPage.disabled = true
	#DEV_setup_widget_page()
	GlobalHelper.startup_done = true

#calling $DynamicWidgetPage functions in conjunction with $SaveAndLoad
#DynamicWidgetPageSpecs are loaded into $DynamicWidgetPage
# I didnt want to use many signals because either way those functions would be called from here (this $MainFrame Node) 
func setup_widget_page():
	SaveAndLoad.get_save_by_saveslot("default")
	var savedata = SaveAndLoad.current_session["savedata"]
	DynamicWidgetPage.construct_widget_page(savedata)


#update SaveAndLoad data which triggers the set signal on current_session
func _on_save_session():
	print("save session pressed")
	SaveAndLoad.current_session = DynamicWidgetPage.current_widget_page	

# $DynamicWidgetPage sends data_changed signal everytime a checkbox gets pressed and triggers the autosave	
func _on_widget_page_changed(_widget_page):
	if GlobalHelper.startup_done == true:
		SaveAndLoad.autosave()

func construct_WidgetPage(widget_page):
	DynamicWidgetPage.construct_widget_page(widget_page)

func _on_save_data_loaded(save_data):
	construct_WidgetPage(save_data)
	_on_Widget_Page_pressed()



func _notification(event):
	if event == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:	
		SaveAndLoad.autosave(current_session)
	
func swipe_to_WidgetBuilder(Widget):
	#switch UI to Widget Builder
	DynamicWidgetPage.hide()
	WidgetBuilder.show()
	SaveAndLoad.hide()

	$VBox/NavigationBar/BtnCancel.visible = true
	$VBox/NavigationBar/BtnSubmit.visible = true
	$VBox/NavigationBar/BtnWidgetPage.visible = false
	$VBox/NavigationBar/BtnSaveAndLoad.visible = false

	GlobalHelper.tween_swipe_show(WidgetBuilder)
	WidgetBuilder.setup_WidgetBuilder(Widget)
	
	
func _on_Widget_Page_pressed() -> void:
	$VBox/NavigationBar/BtnWidgetPage.disabled = true
	$VBox/NavigationBar/BtnSaveAndLoad.disabled = false
	DynamicWidgetPage.show()
	WidgetBuilder.hide()
	SaveAndLoad.hide()
	GlobalHelper.tween_swipe_show(DynamicWidgetPage)
	
func _on_Save_And_Load_pressed() -> void:
	$VBox/NavigationBar/BtnWidgetPage.disabled = false
	$VBox/NavigationBar/BtnSaveAndLoad.disabled = true
	SaveAndLoad.show()
	#SaveAndLoad.update_widget_page(DynamicWidgetPage.current_widget_page)	
	DynamicWidgetPage.hide()
	WidgetBuilder.hide()
	GlobalHelper.tween_swipe_show(SaveAndLoad)


func _on_Cancel_pressed():
	WidgetBuilder.reset_WidgetBuilder()
	#switch UI back to Widget Page
	$VBox/NavigationBar/BtnCancel.visible = false
	$VBox/NavigationBar/BtnSubmit.visible = false
	$VBox/NavigationBar/BtnWidgetPage.visible = true
	$VBox/NavigationBar/BtnSaveAndLoad.visible = true
	DynamicWidgetPage.show()
	WidgetBuilder.hide()
	GlobalHelper.tween_swipe_show(DynamicWidgetPage)

func _on_Submit_pressed():
	var new_widget_specs = WidgetBuilder.get_widget_specs()
	var widget_key = DynamicWidgetPage.selected_widget_key
	#make copy of current_widget_page
	var copy_widget_page = GlobalHelper.deep_copy(DynamicWidgetPage.current_widget_page)
	#completely delete old widget we have key and data locally
	#DynamicWidgetPage.clear_widget_from_page(widget_key)
	#add new widget data directly
	DynamicWidgetPage.current_widget_page["widget_page"][widget_key] = new_widget_specs
	DynamicWidgetPage.selected_widget_key = null
	DynamicWidgetPage.update_widget_page()

	WidgetBuilder.reset_WidgetBuilder()
	
	$VBox/NavigationBar/BtnCancel.visible = false
	$VBox/NavigationBar/BtnSubmit.visible = false
	$VBox/NavigationBar/BtnWidgetPage.visible = true
	$VBox/NavigationBar/BtnSaveAndLoad.visible = true
	DynamicWidgetPage.show()
	WidgetBuilder.hide()
	GlobalHelper.tween_swipe_show(DynamicWidgetPage)

func DEV_test_json_parsing():
	var json = SaveAndLoad.parse_widget_page_to_json(DynamicWidgetPage.current_widget_page)
	var parsed_json = SaveAndLoad.parse_json_to_widget_page(json)
	DynamicWidgetPage.current_widget_page = parsed_json
	DynamicWidgetPage.update_widget_page()


#important DEV function for filling up the page so it can then be saved onto a json file
#I'm not manually writing json
func DEV_setup_widget_page():
	DynamicWidgetPage.DEV_fill_page()
