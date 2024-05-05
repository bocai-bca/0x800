extends ScoreDisplay
class_name FloatNumber

const CharX:CompressedTexture2D = preload("res://2048/textures/numbers/x.png")

var Number:int
var Motion:Vector2
var LifeTimer:float = 0.0

func _ready() -> void:
	set_position(Vector2.from_angle(randf()) * randf_range(-128.0, 128.0))
	Motion = -1.0 * get_position() + Vector2(0.0, -384.0)
	set_position(get_position() + Vector2(0.0, 64.0))
	set_number(Number)

func _process(delta: float) -> void:
	LifeTimer += delta
	set_scale(smoothstep(0.0, 1.0, LifeTimer) * Vector2(0.5, 0.5))
	set_position(get_position() + Motion * delta)
	Motion = Motion.move_toward(Vector2(0.0, 1024.0), delta * 256.0)
	if (get_position().y >= 384.0):
		queue_free()
	if (fmod(LifeTimer, 0.6) > 0.3):
		set_modulate(Color(0.75, 0.75, 0.75, 0.5))
	else:
		set_modulate(Color(0.25, 0.25, 0.25, 0.5))

func set_number(number_dec: int) -> void:
	var number_hex:String = String.num_int64(number_dec, 16, true) #转换到十六进制
	number_hex = "x" + number_hex #在十六进制数开头加一个x
	var number_count:int = number_hex.length() #十六进制数字的位数
	var children_count:int = get_child_count() #获取子节点数量，并用于计数
	#数位节点居中与分配帧号
	while (children_count < number_count): #检查如果已有的数位节点小于需要的位数，就添加
		var number_ins:AnimatedSprite2D = AnimatedSprite2D.new() #实例化新子节点
		number_ins.set_sprite_frames(NumbersFrames) #给新子节点设定纹理
		number_ins.set_offset(Vector2(32.0, 32.0)) #给新子节点设定纹理偏移以居中数字纹理
		add_child(number_ins, false, Node.INTERNAL_MODE_DISABLED) #列入子节点
		children_count += 1 #while计数
	var number_nodes:Array[Node] = get_children(false) #取得包含每个数位节点的列表
	var original_total_width:float = number_count * NUMBER_WIDTH + (number_count + 1) * NODE_SPACING #计算默认缩放状态下的总宽度
	var zoom_rate:float = TOTAL_MAX_WIDTH / original_total_width #计算数字缩放倍率
	zoom_rate = clampf(zoom_rate, zoom_rate, 0.5) #钳制缩放倍率
	for index in number_nodes.size(): #开始遍历
		var current_node:Node = number_nodes[index - 1] #提取一个节点
		if (index >= number_hex.length()):
			current_node.set_visible(false) #如果该节点的位数超出了需要的位数，就隐藏
			continue
		else:
			current_node.set_visible(true) #否则显示
		current_node.set_frame(char_to_frame(number_hex[index])) #设定帧号
		current_node.set_scale(Vector2(1.0, 1.0) * zoom_rate) #设定缩放
		var pos_x:float = (index * NUMBER_WIDTH + index * NODE_SPACING) - original_total_width / 2.0 + NODE_SPACING + NUMBER_WIDTH / 2.0 #计算X轴偏移量
		current_node.set_position(Vector2(pos_x * zoom_rate, 0.0)) #设定坐标
