extends Node
class_name BlocksArea
static var SELF:BlocksArea

signal blocks_clear()
signal call_query_move_finished()

#4*4的版面存储类型，以一维形态存储十六个版面槽位元素
class PaletteData:
	var Value:Array[PaletteSlotData] = []
	func _init(In_Palette:Array[PaletteSlotData] = [])-> void:
		Value.resize(16)
		for i in 16:
			Value[i - 1] = PaletteSlotData.new(0)
	static func vec2i_to_index(In_Vec2i:Vector2i)-> int: #二维版面坐标转一维版面存储索引
		return 4 * In_Vec2i.x + In_Vec2i.y
	static func index_to_vec2i(In_Index:int)-> Vector2i: #一维版面存储索引转二维版面坐标
		return Vector2i(In_Index / 4, In_Index % 4)
	func clean_stacked_tag()-> void: #清除自身中被标记为刚合成标签的槽位
		for slot in Value:
			slot.StackedOnThisTime = false

#版面槽位元素，包含了槽位数字缓存和槽位节点引用
class PaletteSlotData:
	var Number:int
	var BlockNode:Block
	var StackedOnThisTime:bool #用于阻止在不该连续合成的时候连续合成
	func _init(In_Number:int, In_Block:Block = null)-> void:
		StackedOnThisTime = false
		Number = In_Number
		if (In_Block != null):
			BlockNode = In_Block

const Prefab_Block:Resource = preload("res://2048/scenes/Blocks.tscn")

const PosList:Array = [ #缩放倍率0.15。方块长宽512*512，间隙32。索引时把X和Y反过来
	[Vector2(-816.0, -816.0), Vector2(-272.0, -816.0), Vector2(272.0, -816.0), Vector2(816.0, -816.0)],
	[Vector2(-816.0, -272.0), Vector2(-272.0, -272.0), Vector2(272.0, -272.0), Vector2(816.0, -272.0)],
	[Vector2(-816.0, 272.0), Vector2(-272.0, 272.0), Vector2(272.0, 272.0), Vector2(816.0, 272.0)],
	[Vector2(-816.0, 816.0), Vector2(-272.0, 816.0), Vector2(272.0, 816.0), Vector2(816.0, 816.0)]
]
#存储真实版面的变量
var RealPalette:PaletteData
var IsSpawning:bool = false

func _ready()-> void:
	SELF = self

#获取源方块处理队列
static func get_source_block_list(In_Palette:PaletteData, In_Direction:int)-> Array[Vector2i]:
	var result:Array[Vector2i] = []
	match In_Direction:
		Main.INPUT_DIRECTION.UP:
			for x in 4:
				for y in 4:
					var palette_pos:Vector2i = Vector2i(x, y)
					if (In_Palette.Value[PaletteData.vec2i_to_index(palette_pos)].Number != 0):
						result.append(palette_pos)
		Main.INPUT_DIRECTION.DOWN:
			for x in 4:
				for y in 4:
					var palette_pos:Vector2i = Vector2i(x, 3 - y)
					if (In_Palette.Value[PaletteData.vec2i_to_index(palette_pos)].Number != 0):
						result.append(palette_pos)
		Main.INPUT_DIRECTION.LEFT:
			for y in 4:
				for x in 4:
					var palette_pos:Vector2i = Vector2i(x, y)
					if (In_Palette.Value[PaletteData.vec2i_to_index(palette_pos)].Number != 0):
						result.append(palette_pos)
		Main.INPUT_DIRECTION.RIGHT:
			for y in 4:
				for x in 4:
					var palette_pos:Vector2i = Vector2i(3 - x, y)
					if (In_Palette.Value[PaletteData.vec2i_to_index(palette_pos)].Number != 0):
						result.append(palette_pos)
	return result

#源方块移动递归，其中源方块的数字将通过输入的源方块坐标从输入的版面中查询。
#返回源方块在输入版面执行输入方向的移动后进行的移动操作，输出一个版面坐标，移动后位置可能存在相同数字，需要靠上级的版面操作来进行判断并进行对应操作
static func source_block_moving(In_SourceBlockPos:Vector2i, In_Palette:PaletteData, In_Direction:int)-> Vector2i:
	var direction_vec:Vector2i
	match In_Direction:
		Main.INPUT_DIRECTION.UP:
			direction_vec = Vector2i.UP
		Main.INPUT_DIRECTION.DOWN:
			direction_vec = Vector2i.DOWN
		Main.INPUT_DIRECTION.LEFT:
			direction_vec = Vector2i.LEFT
		Main.INPUT_DIRECTION.RIGHT:
			direction_vec = Vector2i.RIGHT
	var point_pos:Vector2i = In_SourceBlockPos
	var source_slot:PaletteSlotData = In_Palette.Value[PaletteData.vec2i_to_index(In_SourceBlockPos)]
	while (true):
		point_pos += direction_vec
		if (point_pos.clamp(Vector2i(0, 0), Vector2i(3, 3)) != point_pos):
			point_pos -= direction_vec
			break
		var point_slot:PaletteSlotData = In_Palette.Value[PaletteData.vec2i_to_index(point_pos)]
		if (point_slot.Number == 0): #为空格
			continue
		elif (point_slot.Number == source_slot.Number): #为源数字
			if ((point_slot.StackedOnThisTime or source_slot.StackedOnThisTime) and not Main.CanComboStacking): #如果这个格子刚被合成过，并且当前热度不能连续合成
				point_pos -= direction_vec
			break
		else: #为其他数字
			point_pos -= direction_vec
			break
	return point_pos

#从输入版面获取一个随机的空的槽位，如果没有空位返回Vec2i(-1,-1)
static func get_empty_pos(In_Palette:PaletteData)-> Vector2i:
	var empty_index:Array[int] = []
	for i in 16:
		if (In_Palette.Value[i].BlockNode == null):
			empty_index.append(int(i))
	if (empty_index.size() >= 1):
		var result:Vector2i = PaletteData.index_to_vec2i(empty_index[randi_range(0, empty_index.size() - 1)])
		return result
	else:
		return Vector2i(-1, -1)

#从输入版面中获取所有非空槽位的节点(不查重复引用)
func get_blocks_node(In_Palette:PaletteData)-> Array[Block]:
	var result:Array[Block] = []
	for slot:PaletteSlotData in In_Palette.Value:
		if (slot.BlockNode != null):
			result.append(slot.BlockNode)
	return result

#从缓存查找最小数字
static func get_min_number(In_Palette:PaletteData)-> int:
	var result:int = Main.TheMaxNumberInPalette
	for slot:PaletteSlotData in In_Palette.Value:
		if (slot.Number > 0 and slot.Number < result):
			result = slot.Number
	return result

#向真实版面的指定坐标生成一个新方块
func new_block(at_pos:Vector2i, number:int)-> bool:
	for slot:PaletteSlotData in RealPalette.Value:
		if (slot.BlockNode != null and slot.BlockNode.PalettePos == at_pos):
			return false
	var block_ins:Block = Prefab_Block.instantiate()
	block_ins.PalettePos = at_pos
	block_ins.spawn_finished.connect(on_new_block_animating_finish, CONNECT_ONE_SHOT)
	var block_position:Vector2 = PosList[at_pos.y][at_pos.x]
	block_ins.set_position(block_position)
	block_ins.TargetPos = block_position
	blocks_clear.connect(block_ins.death)
	IsSpawning = true
	add_child(block_ins)
	block_ins.Node_Body = block_ins.get_node("Body")
	block_ins.Node_Number = block_ins.get_node("NumberDisplay")
	block_ins.set_number(number)
	var palette_index:int = PaletteData.vec2i_to_index(at_pos)
	RealPalette.Value[palette_index].Number = number
	RealPalette.Value[palette_index].BlockNode = block_ins
	return true

#向真实版面应用方块的移动或合并，不能接受在对应位置没有节点引用的坐标
func apply_moving(source_pos:Vector2i, target_pos:Vector2i)-> void:
	if (source_pos == target_pos): #如果起点与终点相同，就不管
		return
	var source_index:int = PaletteData.vec2i_to_index(source_pos) #获得起点索引
	var target_index:int = PaletteData.vec2i_to_index(target_pos) #获得终点索引
	var source_block_node:Block = RealPalette.Value[source_index].BlockNode #获得起点节点引用
	var target_block_node:Block = RealPalette.Value[target_index].BlockNode #获得终点节点引用
	source_block_node.TargetPos = PosList[target_pos.y][target_pos.x] #设定起点节点的移动目的地为对应坐标
	RealPalette.Value[target_index].Number = RealPalette.Value[source_index].Number #将终点的数字设为起点的
	if (target_block_node != null): #如果目的地有节点
		RealPalette.Value[target_index].StackedOnThisTime = true
		Main.OneTickStackCount += 1 #记录一次合成
		source_block_node.z_index = 1 #让起点节点的图层往里一级
		source_block_node.DieAfterMove = true #让起点节点移动完就死掉
		source_block_node.move_finished.connect(target_block_node.add_effect)
		RealPalette.Value[target_index].Number += 1
	else: #如果目的地没有节点
		RealPalette.Value[target_index].BlockNode = RealPalette.Value[source_index].BlockNode #将终点的节点引用设为起点的
	RealPalette.Value[source_index].Number = 0
	RealPalette.Value[source_index].BlockNode = null
	RealPalette.Value[target_index].BlockNode.PalettePos = target_pos

#模拟移动，用来判断输入版面在指定方向上能不能动(版面是否发生变化)，输出为true表示能动
static func move_simulate(In_Palette:PaletteData, In_Direction:int)-> bool:
	var source_block_list:Array[Vector2i] = get_source_block_list(In_Palette, In_Direction)
	for source_block in source_block_list:
		var move_active:Vector2i = BlocksArea.source_block_moving(source_block, In_Palette, In_Direction)
		if (move_active != source_block):
			return true
	return false

#信号连接。由新生成的方块完成动画后呼叫执行
func on_new_block_animating_finish()-> void:
	IsSpawning = false

#查找方块是否都已移动完毕
func query_blocks_are_all_move_finished()-> bool:
	var result:bool = true
	for block in get_blocks_node(RealPalette):
		if (block.get_position() != block.TargetPos):
			result = false
	return result
