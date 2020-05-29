extends VBoxContainer

var custom_margin = 10;

enum FEATURE_TYPE {BASIC_FEATURE, SPELL_SLOTS}

signal update_feature_list()

func _ready() -> void:
	pass

func build_dimensional_array(width, height):
	var matrix = []
	for x in range(height):
		matrix.append([])
		for y in range(width):
			matrix[x].append(0)
	return matrix 

#TODO
#build exact feature list but with movable objects ontop to rearrange node tree
func construct_feature_list(feature_list_specification)-> void:
	reset_feature_list()
	
	for row in feature_list_specification:
		var MarginRow = MarginContainer.new()
		var HBoxRow = HBoxContainer.new()
		MarginRow.add_child(HBoxRow)
		add_child(MarginRow)
		
		for specification in row:
			#Basic 
			if specification["feature_type"] == FEATURE_TYPE.BASIC_FEATURE:
				var BasicFeatureInstance : Control = load("res://scenes/BasicFeature.tscn").instance()
				BasicFeatureInstance.construct_basic_feature(specification)
				BasicFeatureInstance.size_flags_horizontal = SIZE_EXPAND
				
				HBoxRow.add_child(BasicFeatureInstance)
			#Spell Slots
			elif specification["feature_type"] == FEATURE_TYPE.SPELL_SLOTS:
				var SpellSlotFeatureInstance = load("res://scenes/SpellSlotFeature.tscn").instance()
				SpellSlotFeatureInstance.construct_spell_slot_feature(specification)
				SpellSlotFeatureInstance.size_flags_horizontal = SIZE_EXPAND
				
				HBoxRow.add_child(SpellSlotFeatureInstance)
		
func build_rect():
	pass

func collect_feature_list():
	var feature_list = []
	var y = 0
	
	for MarginRow in get_children():
		feature_list.append([])        
		#Features are nested inside MarginContainer/HBoxContainer
		for feature in MarginRow.get_child(0).get_children():
			var data = feature.get_data()
			data["feature_location"] = y
			
			feature_list[y].append(data)
		y+=1
	return feature_list

func reset_feature_list():
	for child in get_children():
		child.queue_free()

func _on_checkbox_pressed():
	emit_signal("update_feature_list")