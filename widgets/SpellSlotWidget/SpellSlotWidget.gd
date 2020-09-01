extends BaseWidget


func _ready():
	pass

func get_data():
	pass

var spell_slot_progression_dnd_5e = [
[2],
[3],
[4,2],
[4,3],
[4,3,2],
[4,3,3],
[4,3,3,1],
[4,3,3,2],
[4,3,3,3,1],
[4,3,3,3,2],
[4,3,3,3,2,1],
[4,3,3,3,2,1],
[4,3,3,3,2,1,1],
[4,3,3,3,2,1,1],
[4,3,3,3,2,1,1,1],
[4,3,3,3,2,1,1,1],
[4,3,3,3,2,1,1,1,1],
[4,3,3,3,3,1,1,1,1],
[4,3,3,3,3,2,1,1,1],
[4,3,3,3,3,2,2,1,1]
]
var empty_slots = [0,0,0,0,0,0,0,0,0]
var roman_numerals = ["I","II","III","IV","V","VI","VII","VIII","IX"]


var default_data = {"widget_type": "SpellSlotWidget","widget_size":Vector2(2,3),
				"content": {"feature_name":"Spell Slots","class_level": 6,"used_slots":[0,0,0,0,0,0,0,0,0]}}

const build_specs = {"content": {"settings":{"canDelete":false},"feature_name":["LineEdit"],"class_level":["SpinBox",1,20],"used_slots":["max_marker"] },
					"instructions":{"canAdd":false}}				


func construct_widget(specifications : Dictionary):
	current_data = specifications
	if specifications.has("content"):
		if specifications.content.has("class_level"):
			var used_slots
			if specifications.content.has("used_slots"):
				used_slots = specifications.content.used_slots
			else:
				used_slots = empty_slots
			current_data.content.used_slots = used_slots
			var VerticalContainer = VBoxContainer.new()
			var SpellSlotLabel = Label.new()
			SpellSlotLabel.theme = theme
			if specifications.content.has("feature_name"):
				SpellSlotLabel.text = specifications.content.feature_name
			else:
				SpellSlotLabel.text = "Spell Slots"
			VerticalContainer.add_child(SpellSlotLabel)
			SpellSlotLabel.mouse_filter = MOUSE_FILTER_IGNORE
			var available_slots = spell_slot_progression_dnd_5e[specifications.content.class_level-1]
			for slot_level in range(0,available_slots.size()):
				VerticalContainer.add_child(make_spell_slots(slot_level,available_slots[slot_level],used_slots[slot_level]))
			$CenterContainer.add_child(VerticalContainer)
	else:
		construct_widget(default_data)


#returns an HBoxContainer with CheckBoxes
func make_spell_slots(slot_level, max_slots, used_slots):
	var ContainerForMarker = HBoxContainer.new()
	var SlotLevelLabel = Label.new()
	SlotLevelLabel.text = roman_numerals[slot_level]
	SlotLevelLabel.mouse_filter = MOUSE_FILTER_IGNORE
	#align label, looks like a proper column
	SlotLevelLabel.align = 2
	SlotLevelLabel.rect_min_size = Vector2(75,50)

	ContainerForMarker.add_child(SlotLevelLabel)
	for i in range(1,max_slots+1):
		var CheckBoxMarker = CheckBox.new()
		#Connect new checkbox to this/self with toggled event for access to state and add custom argument to differentiate
		CheckBoxMarker.connect("toggled", self, "_on_checkbox_pressed",[slot_level])
		if i <= used_slots:
			CheckBoxMarker.pressed = true
		ContainerForMarker.add_child(CheckBoxMarker)

	#Toggling checkbox calls toggled event
	#thats why current_data needs to get reset manually
	current_data.content.used_slots[slot_level] = used_slots
	return ContainerForMarker

func _on_checkbox_pressed(checkbox_state,slot_level):
	#print("toggled ", checkbox_state," row: ", row)
	if checkbox_state:
		current_data.content.used_slots[slot_level] += 1
	else:
		current_data.content.used_slots[slot_level] -= 1
	#print(current_data)
	emit_signal("on_user_interaction",self)

