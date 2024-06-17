extends Node
class_name SfxManager

enum SOUND_LIST {
	Bubble = 0,
	WaterDrop = 1,
	BaDumTss = 2,
	Alarm = 3,
	Doh = 4
}

@onready var Bubble:AudioStreamPlayer = $Bubble
static var BubbleQueue:int = 0
static var BubblePlayAgo:float = 0.0
const BubblePlayInterval:float = 0.075

@onready var WaterDrop:AudioStreamPlayer = $WaterDrop
static var WaterDropQueue:int = 0
static var WaterDropPlayAgo:float = 0.0
const WaterDropPlayInterval:float = 0.3

@onready var BaDumTss:AudioStreamPlayer = $BaDumTss
static var BaDumTssQueue:int = 0
static var BaDumTssPlayAgo:float = 0.0
const BaDumTssPlayInterval:float = 0.3

@onready var Alarm:AudioStreamPlayer = $Alarm
static var AlarmQueue:int = 0
static var AlarmPlayAgo:float = 0.0
const AlarmPlayInterval:float = 0.25

@onready var Doh:AudioStreamPlayer = $Doh
static var DohQueue:int = 0
static var DohPlayAgo:float = 0.0
const DohPlayInterval:float = 0.01

func _process(delta:float)-> void:
	var _0:bool = Main.IsSoundEnable
	BubblePlayAgo = move_toward(BubblePlayAgo, BubblePlayInterval, delta)
	WaterDropPlayAgo = move_toward(WaterDropPlayAgo, WaterDropPlayInterval, delta)
	BaDumTssPlayAgo = move_toward(BaDumTssPlayAgo, BaDumTssPlayInterval, delta)
	AlarmPlayAgo = move_toward(AlarmPlayAgo, AlarmPlayInterval, delta)
	DohPlayAgo = move_toward(DohPlayAgo, DohPlayInterval, delta)
	if (BubbleQueue >= 1 and BubblePlayAgo >= BubblePlayInterval):
		BubblePlayAgo = 0.0
		BubbleQueue -= 1
		if (_0):
			Bubble.set_pitch_scale(randf_range(0.7, 1.3))
			Bubble.play()
	if (WaterDropQueue >= 1 and WaterDropPlayAgo >= WaterDropPlayInterval):
		WaterDropPlayAgo = 0.0
		WaterDropQueue -= 1
		if (_0):
			WaterDrop.set_pitch_scale(randf_range(0.8, 1.2))
			WaterDrop.play()
	if (BaDumTssQueue >= 1 and BaDumTssPlayAgo >= BaDumTssPlayInterval):
		BaDumTssPlayAgo = 0.0
		BaDumTssQueue -= 1
		if (_0):
			BaDumTss.play()
	if (AlarmQueue >= 1 and AlarmPlayAgo >= AlarmPlayInterval):
		AlarmPlayAgo = 0.0
		AlarmQueue -= 1
		if (_0):
			Alarm.set_pitch_scale((float(Main.Heating) / float(Main.HEATING_MAX)) / 2.0 + 1.0)
			Alarm.play()
	if (DohQueue >= 1 and DohPlayAgo >= DohPlayInterval):
		DohPlayAgo = 0.0
		DohQueue -= 1
		if (_0):
			Doh.set_pitch_scale(randf_range(0.7, 1.3))
			Doh.play()

static func add_queue(sound_id:int)-> void:
	match sound_id:
		SOUND_LIST.Bubble:
			BubbleQueue += 1
		SOUND_LIST.WaterDrop:
			WaterDropQueue = 1
		SOUND_LIST.BaDumTss:
			BaDumTssQueue = 1
		SOUND_LIST.Alarm:
			AlarmQueue += 1
		SOUND_LIST.Doh:
			DohQueue += 1

static func clear_queue(sound_id:int)-> void:
	match sound_id:
		SOUND_LIST.Bubble:
			BubbleQueue = 0
		SOUND_LIST.WaterDrop:
			WaterDropQueue = 0
		SOUND_LIST.BaDumTss:
			BaDumTssQueue = 0
		SOUND_LIST.Alarm:
			AlarmQueue = 0
		SOUND_LIST.Doh:
			DohQueue = 0
