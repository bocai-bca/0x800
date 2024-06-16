extends Node
class_name Main
static var SELF:Main

static var GameSave:Dictionary = {
	"HighScore": 0
}

signal add_score(score:int)

enum INPUT_DIRECTION{
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3
}
#ViewPort Size = 360.0 640.0
#Solid Colors Size = 64.0 64.0
#Background Scale = 360.0/64.0 640.0/64.0

const UI_COLOR_FADINT_RATE:float = 0.5
const MOUSE_ACTIVE_SPEED: float = 400.0 #鼠标移动被认定为输入操作的灵敏衰减delta倍率，也大概相当于鼠标移动速度。单位不好描述
const HEATING_MAX: int = 81
const COMBO_STACK_HEATING: int = 49
static var BackgroundTargetColor:Color
static var BlocksAreaTargetColor:Color
static var ScoreLabelTargetColor:Color
static var ColorOffset:float
static var TheMaxNumberInPalette:int = 0
#static var TheMinNumberShouldSpawn:int #允许生成的最小数标准，有时为了提升难度会生成比最小数标准小1的数字，无论何时，不会生成比最小数标准小1更小的数。最小数标准会在版面只存在高于最小数标准时更新为版面的最小数
static var TheMinNumberShouldSpawn: int #允许生成的最小数标准，每次温度触顶后会降低1级
static var TipBlockNumber: int #缓存显示在提示方块上的数字，用于检查更新

static var GlobalState:int
enum GLOBAL_STATE{
	TEST = 0,
	STARTING = 1, #开局动画过程
	ANIMATING = 2, #主循环
	SPAWNING = 3, #主循环
	WAITING = 4, #主循环
	GAME_OVER = 5, #游戏结束待机，不可操作
	RESTARTING = 6, #按按钮重启游戏
}
static var Score:int
static var NumberDownRoundCounter:int
static var Heating: int
static var CanComboStacking: bool #用于在方块合成时查询现在能不能连续合成
static var OneTickStackCount: int #记录一次操作内合成了多少次
static var HadSpawnLowLevelBlock: bool #在温度触顶后是否已生成过更低等级的方块

static var Node_Background:Sprite2D
static var Node_BlocksArea:BlocksArea
static var Node_ScoreLabel:Node2D
static var Node_HighScore:Sprite2D
static var Node_HeatBar:Sprite2D
static var Node_TipBlock:Node2D
static var Node_SfxManager:Node

const Prefab_FloatNumber:Resource = preload("res://2048/scenes/FloatNumber.tscn")

var MouseInput_StartPos:Vector2 = Vector2(0.0, 0.0)
var MouseInput_IsLastTickClicking:bool = false
var MouseInput_IsNeedReclick:bool = false
var MouseInput_Output:Vector2 = Vector2(0.0, 0.0)

func _ready()->void:
	SELF = self
	load_save()
	Node_SfxManager = get_node("SfxManager")
	Node_Background = get_node("Background")
	Node_BlocksArea = get_node("BlocksArea")
	Node_ScoreLabel = get_node("ScoreLabel")
	Node_HighScore = get_node("HighScore")
	Node_HeatBar = get_node("HeatBar")
	Node_TipBlock = get_node("HeatBar/TipBlock")
	Node_TipBlock.TargetPos = Node_TipBlock.get_position()
	Node_TipBlock.Node_Body = get_node("HeatBar/TipBlock/Body")
	Node_TipBlock.Node_Number = get_node("HeatBar/TipBlock/NumberDisplay")
	Node_HeatBar.heat_bar_touched_top.connect(on_heatbar_reset)
	Node_ScoreLabel.get_node("RestartButton").pressed.connect(start_new_game)
	add_score.connect(score_update)
	Node_HighScore.get_node("ScoreDisplay").set_number(GameSave.get("HighScore", 0))
	Score = 0
	start_new_game()

func _process(delta:float)->void:
	mouse_handle_once(delta)
	var tag_0:bool = node_toward_color(Node_Background, BackgroundTargetColor, delta * UI_COLOR_FADINT_RATE)
	var tag_1:bool = node_toward_color(Node_BlocksArea, BlocksAreaTargetColor, delta * UI_COLOR_FADINT_RATE)
	var scorelabel_color:Color = make_color(TheMaxNumberInPalette, 0.35)
	var tag_2:bool
	var text_color:Color = make_text_color(scorelabel_color)
	var tag_3:bool = node_toward_color_with_children(Node_HighScore, text_color, delta * UI_COLOR_FADINT_RATE)
	if (GlobalState != GLOBAL_STATE.GAME_OVER):
		tag_2 = Node_ScoreLabel.color_update(delta * UI_COLOR_FADINT_RATE, scorelabel_color, text_color)
	match GlobalState: #匹配全局状态
		GLOBAL_STATE.STARTING: #全局状态-新游戏启动动画
			Node_TipBlock.set_scale(Node_TipBlock.get_scale().move_toward(Vector2.ZERO, delta * Block.ZOOM_SPEED))
			var tag_4: bool = (Node_TipBlock.get_scale().x <= 0.01)
			if (tag_0 and tag_1 and tag_2 and tag_4): #如果背景均变色完毕
				Node_BlocksArea.new_block(BlocksArea.get_empty_pos(Node_BlocksArea.RealPalette), 1) #生成新方块
				GlobalState = GLOBAL_STATE.SPAWNING #更改全局状态为方块移动中
				Node_TipBlock.set_process(true)
				Node_TipBlock.set_number(1)
				Node_TipBlock.IsSpawnFinished = false
		GLOBAL_STATE.ANIMATING: #全局状态-方块移动中
			if (Node_BlocksArea.query_blocks_are_all_move_finished()):
				var new_number: int = BlocksArea.get_min_number(Node_BlocksArea.RealPalette) #设定新数为版面最小数
				if (new_number != TheMinNumberShouldSpawn): #如果当前版面最小数与提示方块不符
					TheMinNumberShouldSpawn = new_number
					Node_TipBlock.add_effect(true, TheMinNumberShouldSpawn) #更新提示方块
					SfxManager.add_queue(SfxManager.SOUND_LIST.Doh)
				if (not HadSpawnLowLevelBlock): #如果在温度触顶后还没有生成N-1
					TheMinNumberShouldSpawn = clampi(TheMinNumberShouldSpawn - 1, 1, TheMaxNumberInPalette)
					new_number = TheMinNumberShouldSpawn #新数是当前版面最小数减一
					Node_TipBlock.add_effect(true, TheMinNumberShouldSpawn) #更新提示方块
					SfxManager.add_queue(SfxManager.SOUND_LIST.Doh)
					HadSpawnLowLevelBlock = true #标记为已生成，因为待会儿就会生成了
				#else: #如果已生成过
					#if (randi() % 4 == 0): #四分之一的概率会生成N+1
						#new_number += 1
					#pass
				Node_BlocksArea.new_block(BlocksArea.get_empty_pos(Node_BlocksArea.RealPalette), clampi(new_number, 1, TheMaxNumberInPalette)) #生成新方块
				GlobalState = GLOBAL_STATE.SPAWNING #更改全局状态为方块生成中
				NumberDownRoundCounter -= 1
		GLOBAL_STATE.SPAWNING: #全局状态-新方块生成动画
			if (not Node_BlocksArea.IsSpawning): #如果新方块生成动画完毕
				if (
					BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.UP) or
					BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.DOWN) or
					BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.LEFT) or
					BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.RIGHT)
				):
					GlobalState = GLOBAL_STATE.WAITING #更改全局状态为等待玩家输入
				else:
					try_save_score()
					GlobalState = GLOBAL_STATE.GAME_OVER
					SfxManager.add_queue(SfxManager.SOUND_LIST.PianoDown)
		GLOBAL_STATE.WAITING: #全局状态-等待玩家输入
			var input_direction:int = -1
			var mouse_angle:float = rad_to_deg(MouseInput_Output.angle())
			var mouse_distance_squared:float = MouseInput_Output.length_squared()
			if ((Input.is_action_just_pressed("keyboard_up") or (-135.0 <= mouse_angle and mouse_angle < -45.0 and mouse_distance_squared >= 2000.0)) and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.UP)):
				input_direction = INPUT_DIRECTION.UP
				MouseInput_IsNeedReclick = true
			elif ((Input.is_action_just_pressed("keyboard_down") or (45.0 <= mouse_angle and mouse_angle < 135.0 and mouse_distance_squared >= 2000.0)) and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.DOWN)):
				input_direction = INPUT_DIRECTION.DOWN
				MouseInput_IsNeedReclick = true
			elif ((Input.is_action_just_pressed("keyboard_left") or (-135.0 > mouse_angle or mouse_angle >= 135.0 and mouse_distance_squared >= 2000.0)) and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.LEFT)):
				input_direction = INPUT_DIRECTION.LEFT
				MouseInput_IsNeedReclick = true
			elif ((Input.is_action_just_pressed("keyboard_right") or (-45.0 <= mouse_angle and mouse_angle < 45.0 and mouse_distance_squared >= 2000.0)) and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.RIGHT)):
				input_direction = INPUT_DIRECTION.RIGHT
				MouseInput_IsNeedReclick = true
			#取得了操作方向
			if (input_direction != -1): #如果有输入
				OneTickStackCount = 0
				CanComboStacking = (Heating >= COMBO_STACK_HEATING)
				GlobalState = GLOBAL_STATE.ANIMATING
				while (true):
					if (not BlocksArea.move_simulate(Node_BlocksArea.RealPalette, input_direction)):
						break
					var source_block_list:Array[Vector2i] = BlocksArea.get_source_block_list(Node_BlocksArea.RealPalette, input_direction) #取得源方块列表
					for source_block in source_block_list:
						var move_active:Vector2i = BlocksArea.source_block_moving(source_block, Node_BlocksArea.RealPalette, input_direction)
						Node_BlocksArea.apply_moving(source_block, move_active)
				if (OneTickStackCount >= 2):
					spawn_float_number(OneTickStackCount)
				Heating = clampi(Heating - int(float(OneTickStackCount) ** 1.6 * 5.0) + 8, 0, HEATING_MAX)
				Node_HeatBar.TargetDegree = float(Heating) / float(HEATING_MAX)
				Node_BlocksArea.RealPalette.clean_stacked_tag()

func _notification(what:int)-> void:
	if (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH):
		try_save_score()

func spawn_float_number(stack_count: int) -> void:
	var float_number_ins:Node2D = Prefab_FloatNumber.instantiate()
	float_number_ins.Number = stack_count
	add_child(float_number_ins)

func score_update(score:int) -> void:
	Score += score
	Node_ScoreLabel.emit_signal("update_score", Score)

func start_new_game() -> void:
	ColorOffset =fmod(randf(), 1.0)
	GlobalState = GLOBAL_STATE.STARTING
	Node_BlocksArea.emit_signal("blocks_clear")
	Node_BlocksArea.RealPalette = BlocksArea.PaletteData.new()
	TheMaxNumberInPalette = 1
	TheMinNumberShouldSpawn = 1
	NumberDownRoundCounter = 20
	BackgroundTargetColor = make_color(0, 0.25)
	BlocksAreaTargetColor = make_text_color(BackgroundTargetColor)
	try_save_score()
	Node_HighScore.get_node("ScoreDisplay").set_number(GameSave.get("HighScore", 0))
	Score = 0
	Node_ScoreLabel.emit_signal("update_score", Score)
	Heating = 0
	Node_HeatBar.TargetDegree = 0.0
	OneTickStackCount = 0
	TipBlockNumber = 1
	Node_TipBlock.reinit()
	HadSpawnLowLevelBlock = true
	SfxManager.add_queue(SfxManager.SOUND_LIST.PianoUp)

#尝试保存分数，可以自由调用。如果当前游戏分数大于内存中的存档最高分，则会保存分数并写入硬盘
func try_save_score() -> void:
	if (Score > GameSave.get("HighScore", 2147483647)):
		print("save score!")
		GameSave["HighScore"] = Score
		load_save(true)

#单次鼠标处理，直接引用动态变量
func mouse_handle_once(delta: float) -> void:
	if (Input.is_action_pressed("mouse_lmb")): #如果按下了左键
		var PosNow: Vector2 = get_viewport().get_mouse_position()
		if (MouseInput_IsLastTickClicking): #并且上一刻也按了左键
			if (not MouseInput_IsNeedReclick): #如果没被标记需要重按
				MouseInput_Output = PosNow - MouseInput_StartPos #输出=当前鼠标-开始坐标
			else:
				MouseInput_Output = Vector2(0.0, 0.0)
		else: #上一刻没按左键，意味着是从这一刻开始按的
			MouseInput_StartPos = get_viewport().get_mouse_position() #开始坐标=当前坐标
			MouseInput_Output = Vector2(0.0, 0.0) #输出=0,0
		MouseInput_IsLastTickClicking = true #记录本刻按了左键，以供后续使用
		MouseInput_StartPos = MouseInput_StartPos.move_toward(PosNow, delta * MOUSE_ACTIVE_SPEED)
	else: #如果没按左键
		MouseInput_IsNeedReclick = false #解除需要重按标记
		MouseInput_Output = Vector2(0.0, 0.0) #输出=0,0
		MouseInput_IsLastTickClicking = false #记录本刻没按左键，以供后续使用

#信号连接。当热度条触顶动画播放完毕时呼叫
func on_heatbar_reset() -> void:
	Heating = 0
	Node_HeatBar.TargetDegree = 0.0
	if (TheMinNumberShouldSpawn > 1):
		HadSpawnLowLevelBlock = false
		Node_TipBlock.add_effect(true, clampi(TheMinNumberShouldSpawn - 1, 1, TheMaxNumberInPalette)) #更新提示方块

static func node_toward_color(target_node:Node, target_color:Color, delta:float)-> bool:
	var from_color:Color = target_node.get_self_modulate()
	var to_color:Color = Color(
		move_toward(from_color.r, target_color.r, delta),
		move_toward(from_color.g, target_color.g, delta),
		move_toward(from_color.b, target_color.b, delta)
	)
	target_node.set_self_modulate(to_color)
	if (to_color == from_color):
		return true
	else:
		return false

static func node_toward_color_with_children(target_node:Node, target_color:Color, delta:float)-> bool:
	var from_color:Color = target_node.get_modulate()
	var to_color:Color = Color(
		move_toward(from_color.r, target_color.r, delta),
		move_toward(from_color.g, target_color.g, delta),
		move_toward(from_color.b, target_color.b, delta)
	)
	target_node.set_modulate(to_color)
	if (to_color == from_color):
		return true
	else:
		return false

static func make_color(number:int, saturation:float = 0.5)-> Color:
	number = clampi(number, 0, number)
	return Color.from_hsv(fmod(float(number) / 17.0 + ColorOffset, 1.0), saturation, 1.0)

static func make_text_color(background_color:Color)-> Color:
	if (background_color.v > 0.5):
		return background_color.darkened(0.5)
	else:
		return background_color.lightened(0.5)

#读取存档，引入true时表示从Main中的游戏数据变量写入至存档
static func load_save(save_instead_load:bool = false)-> void:
	if (not FileAccess.file_exists("./game_save_loader.dll")): #如果根目录不存在读写卡就不进行读写
		return
	match save_instead_load:
		false: #硬盘读取至内存
			if (not FileAccess.file_exists("./high_score.dat")):
				return
			var file_access:FileAccess = FileAccess.open_compressed("./high_score.dat", FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
			var json_instance = JSON.new()
			var is_ok:Error = json_instance.parse(file_access.get_as_text(true))
			if (is_ok == OK):
				GameSave = json_instance.get_data()
			else:
				push_error(is_ok)
		true: #内存保存至硬盘
			var file_access:FileAccess = FileAccess.open_compressed("./high_score.dat", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
			file_access.store_line(JSON.stringify(GameSave, "", true, false))

#手动按按键print，用于防止每刻都输出的print刷屏
static func debug_print(content)-> void:
	if (Input.is_action_just_pressed("debug_print")):
		print(content)
