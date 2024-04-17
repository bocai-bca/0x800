extends Node2D
class_name Block

signal spawn_finished()
signal move_finished()

var SpawnFinished:bool = false
const MOVE_SPEED:float = 12288.0
const ZOOM_SPEED:float = 9.0
const COLOR_FADING_SPEED:float = 2.0
const ADD_EFFECT_SPEED:float = 25.0
var TargetPos:Vector2 = Vector2.ZERO
var TargetColor:Color
var NumberTargetColor:Color
var PalettePos:Vector2i
var Number:int
var AddEffectTimer:float = 0.0 #增数动效倒计时器，范围是2PI至0
var DieAfterMove:bool = false #一个布尔标记，在需要合并方块时使用。被标记为true的方块在完成移动动作后会自行free

#由BlocksArea赋值
var Node_Body:Sprite2D
var Node_Number:Node2D

func _process(delta:float)-> void:
	if (not SpawnFinished):
		set_scale(get_scale().move_toward(Vector2.ONE, delta * ZOOM_SPEED))
		if (get_scale() == Vector2.ONE):
			SpawnFinished = true
			emit_signal(&"spawn_finished")
	elif (AddEffectTimer != 0.0):
		AddEffectTimer = clampf(AddEffectTimer - delta * ADD_EFFECT_SPEED, 0.0, 2 * PI)
		set_scale(Vector2.ONE + Vector2.ONE * -0.25 * (cos(AddEffectTimer) - 1.0))
	set_position(get_position().move_toward(TargetPos, delta * MOVE_SPEED))
	if (DieAfterMove and get_position() == TargetPos): #如果被标记了移动后自杀，并且当前坐标符合目标坐标
		emit_signal("move_finished")
		death()
	#过渡颜色更新
	var body_color:Color = Node_Body.get_self_modulate()
	Node_Body.set_self_modulate(body_color.lerp(TargetColor, delta * COLOR_FADING_SPEED))
	#Node_Body.set_self_modulate(TargetColor)
	#print("body: ", body_color, " ", Node_Body.get_self_modulate())
	var text_color:Color = Node_Number.get_modulate()
	Node_Number.set_modulate(text_color.lerp(NumberTargetColor, delta * COLOR_FADING_SPEED))
	#Node_Number.set_modulate(NumberTargetColor)
	#print("text: ", text_color, " ", Node_Number.get_self_modulate())
	pass

#设置方块数字，并自动瞬间更新颜色
func set_number(number:int)-> void:
	Number = number
	Node_Number.set_number(number)
	var block_color:Color = Main.make_color(number)
	TargetColor = block_color
	Node_Body.set_self_modulate(block_color)
	var number_color:Color = Main.make_text_color(block_color)
	NumberTargetColor = number_color
	Node_Number.set_modulate(number_color)

#更改方块数字，并设置颜色过渡目标然后由process变换颜色
func change_number(number:int)-> void:
	Number = number
	Node_Number.set_number(number)
	TargetColor = Main.make_color(number)
	NumberTargetColor = Main.make_text_color(TargetColor)

#执行一次增加动效，并且可选屏蔽增加值(以便非信号呼叫时只播放动效而不增加数字)
func add_effect(add_number:bool = true)-> void:
	AddEffectTimer = 2 * PI
	if (add_number):
		var now_number:int = Number + 1
		change_number(now_number)
		if (now_number > Main.TheMaxNumberInPalette):
			Main.TheMaxNumberInPalette = now_number
			Main.Node_Background.set_self_modulate(Color(1.0, 1.0, 1.0, 1.0))
			Main.BackgroundTargetColor = Main.make_color(Main.TheMaxNumberInPalette, 0.25)
			Main.BlocksAreaTargetColor = Main.make_text_color(Main.BackgroundTargetColor)
		Main.SELF.emit_signal("add_score", Number)

#清除
func death()->void:
	queue_free()
