class_name BaseFeatureBuilder
extends Node

#Baseclass for widget_feature_builder
#Every feature builder needs to be instantiated with the Widget Builder 
#and communicate its specs with the corresponding widget

var feature_specification
var current_data

func _ready():
	pass

func setup_FeatureBuilder(feature_data = null):
	pass

func collect_specs():
	pass	

func get_specification():
	collect_specs()
	return feature_specification


func setup_LineEdit(targetNode : LineEdit, value:="write here"):
	targetNode.text = value


func setup_SpinBox(targetSpinBox : SpinBox, value := 0):
	targetSpinBox.value = value
