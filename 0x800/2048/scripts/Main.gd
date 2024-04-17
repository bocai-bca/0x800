extends Node
class_name Main
static var SELF:Main

static var GameSave:Dictionary = {
	"HighScore": 0
}

signal get_input(direction:int)
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
static var BackgroundTargetColor:Color
static var BlocksAreaTargetColor:Color
static var ScoreLabelTargetColor:Color
static var ColorOffset:float
static var TheMaxNumberInPalette:int = 0
static var TheMinNumberShouldSpawn:int #允许生成的最小数标准，有时为了提升难度会生成比最小数标准小1的数字，无论何时，不会生成比最小数标准小1更小的数。最小数标准会在版面只存在高于最小数标准时更新为版面的最小数

static var GlobalState:int
enum GLOBAL_STATE{
	TEST = 0,
	STARTING = 1, #开局动画过程
	ANIMATING = 2, #主循环
	SPAWNING = 3, #主循环
	WAITING = 4, #主循环
	GAME_OVER = 5, #游戏结束待机，不可操作
}
static var Score:int
static var NumberDownRoundCounter:int

static var Node_Background:Node2D
static var Node_BlocksArea:Node2D
static var Node_ScoreLabel:Node2D
static var Node_HighScore:Node2D

func _ready()->void:
	SELF = self
	load_save()
	Node_Background = get_node("Background")
	Node_BlocksArea = get_node("BlocksArea")
	Node_ScoreLabel = get_node("ScoreLabel")
	Node_HighScore = get_node("HighScore")
	Node_ScoreLabel.get_node("RestartButton").pressed.connect(start_new_game)
	add_score.connect(score_update)
	Node_HighScore.get_node("ScoreDisplay").set_number(GameSave.get("HighScore", 0))
	Score = 0
	start_new_game()

func _process(delta:float)->void:
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
			if (tag_0 and tag_1 and tag_2): #如果背景均变色完毕
				Node_BlocksArea.new_block(BlocksArea.get_empty_pos(Node_BlocksArea.RealPalette), 1) #生成新方块
				GlobalState = GLOBAL_STATE.SPAWNING #更改全局状态为方块移动中
		GLOBAL_STATE.ANIMATING: #全局状态-方块移动中
			if (Node_BlocksArea.query_blocks_are_all_move_finished()):
				var min_number:int = BlocksArea.get_min_number(Node_BlocksArea.RealPalette) #取得版面中的最小数
				if (min_number > TheMinNumberShouldSpawn): #如果版面最小数比最小数标准大
					TheMinNumberShouldSpawn = min_number #设定最小数标准为版面最小数
				var new_number:int = min_number
				if (randi() % 2 == 0): # 1/2的概率
					if (NumberDownRoundCounter > 0):
						new_number = clampi(new_number + randi_range(0, 1), 1, TheMaxNumberInPalette) #生成一个比最小数标准大1的数
					else:
						new_number = clampi(new_number + randi_range(-1, 1), TheMinNumberShouldSpawn - 1, TheMaxNumberInPalette) #生成一个比最小数标准大1或小1的数
						NumberDownRoundCounter = 5
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
		GLOBAL_STATE.WAITING: #全局状态-等待玩家输入
			var input_direction:int = -1
			if (Input.is_action_just_pressed("keyboard_up") and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.UP)):
				input_direction = INPUT_DIRECTION.UP
			elif (Input.is_action_just_pressed("keyboard_down") and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.DOWN)):
				input_direction = INPUT_DIRECTION.DOWN
			elif (Input.is_action_just_pressed("keyboard_left") and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.LEFT)):
				input_direction = INPUT_DIRECTION.LEFT
			elif (Input.is_action_just_pressed("keyboard_right") and BlocksArea.move_simulate(Node_BlocksArea.RealPalette, INPUT_DIRECTION.RIGHT)):
				input_direction = INPUT_DIRECTION.RIGHT
			#取得了操作方向
			if (input_direction != -1): #如果有输入
				GlobalState = GLOBAL_STATE.ANIMATING
				var source_block_list:Array[Vector2i] = BlocksArea.get_source_block_list(Node_BlocksArea.RealPalette, input_direction) #取得源方块列表
				for source_block in source_block_list:
					var move_active:Vector2i = BlocksArea.source_block_moving(source_block, Node_BlocksArea.RealPalette, input_direction)
					Node_BlocksArea.apply_moving(source_block, move_active)

func _notification(what:int)-> void:
	if (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH):
		try_save_score()

func score_update(score:int)-> void:
	Score += score
	Node_ScoreLabel.emit_signal("update_score", Score)

func start_new_game()-> void:
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

#尝试保存分数，可以自由调用。如果当前游戏分数大于内存中的存档最高分，则会保存分数并写入硬盘
func try_save_score()-> void:
	if (Score > GameSave.get("HighScore", 2147483647)):
		print("save score!")
		GameSave["HighScore"] = Score
		load_save(true)

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


#static func make_text_color(background_color:Color)-> Color:
	#var value:float
	#value = 1.0 - background_color.v
	#if (absf(background_color.v - 0.5) < 0.2): #相当于 a - 0.5 < 0.2 或 a - 0.5 > -0.2
		#if (background_color.v < 0.5):
			#value = 1.0
		#else:
			#value = 0.0
	#background_color.v = value
	#print(background_color)
	#return background_color

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
