extends Node2D

signal update_score(score:int)

var GameOverHighLightTimer:float = 0

var Node_Button:Node
var Node_Score:Node

func _ready()-> void:
	Node_Button = get_node("RestartButton")
	Node_Score = get_node("ScoreDisplay")
	update_score.connect(Node_Score.set_number)
	Node_Button.button_down.connect(button_down)
	Node_Button.button_up.connect(button_up)

func _process(delta:float)-> void:
	if (Main.GlobalState == Main.GLOBAL_STATE.GAME_OVER):
		GameOverHighLightTimer = fmod(GameOverHighLightTimer + delta * 8.0, 2 * PI)
		var button_color:Color = Main.make_color(Main.TheMaxNumberInPalette, 0.35)
		button_color = Color.from_hsv(
			button_color.h,
			button_color.s + sin(GameOverHighLightTimer - 0.5 * PI) / 2.0,
			button_color.v,
			1.0
		)
		Main.node_toward_color(Node_Button, button_color, delta)
		Main.node_toward_color_with_children(Node_Score, Main.make_text_color(button_color), delta)
	else:
		GameOverHighLightTimer = 0

func color_update(delta:float, In_Button:Color, In_Score:Color)-> bool:
	return (Main.node_toward_color(Node_Button, In_Button, delta) and Main.node_toward_color_with_children(Node_Score, In_Score, delta))

func button_down()-> void:
	Node_Score.set_position(Vector2(0.0, 42.0))

func button_up()-> void:
	Node_Score.set_position(Vector2.ZERO)
