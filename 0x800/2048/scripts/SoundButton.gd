extends Node2D

var Node_Button:Node
var Node_Icon:Node

func _ready()-> void:
	Node_Button = get_node("Button")
	Node_Icon = get_node("Icon")
	Node_Button.button_down.connect(button_down)
	Node_Button.button_up.connect(button_up)

func button_down()-> void:
	Node_Icon.set_position(Vector2(0.0, 42.0))

func button_up()-> void:
	Node_Icon.set_position(Vector2.ZERO)
