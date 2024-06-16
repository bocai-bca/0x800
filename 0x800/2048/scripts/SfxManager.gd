extends Node
class_name SfxManager

enum SOUND_LIST {
	Bubble = 0,
	PianoUp = 1,
	PianoDown = 2,
	Alarm = 3,
	Doh = 4
}

@onready var Bubble:AudioStreamPlayer = $Bubble
static var BubbleQueue:int = 0
static var BubblePlayAgo:float = 0.0
const BubblePlayInterval:float = 0.075

@onready var PianoUp:AudioStreamPlayer = $PianoUp
static var PianoUpQueue:int = 0
static var PianoUpPlayAgo:float = 0.0
const PianoUpPlayInterval:float = 0.3

@onready var PianoDown:AudioStreamPlayer = $PianoDown
static var PianoDownQueue:int = 0
static var PianoDownPlayAgo:float = 0.0
const PianoDownPlayInterval:float = 0.3

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
	PianoUpPlayAgo = move_toward(PianoUpPlayAgo, PianoUpPlayInterval, delta)
	PianoDownPlayAgo = move_toward(PianoDownPlayAgo, PianoDownPlayInterval, delta)
	AlarmPlayAgo = move_toward(AlarmPlayAgo, AlarmPlayInterval, delta)
	DohPlayAgo = move_toward(DohPlayAgo, DohPlayInterval, delta)
	if (BubbleQueue >= 1 and BubblePlayAgo >= BubblePlayInterval):
		BubblePlayAgo = 0.0
		BubbleQueue -= 1
		if (_0):
			Bubble.set_pitch_scale(randf_range(0.7, 1.3))
			Bubble.play()
	if (PianoUpQueue >= 1 and PianoUpPlayAgo >= PianoUpPlayInterval):
		PianoUpPlayAgo = 0.0
		PianoUpQueue -= 1
		if (_0):
			PianoUp.play()
	if (PianoDownQueue >= 1 and PianoDownPlayAgo >= PianoDownPlayInterval):
		PianoDownPlayAgo = 0.0
		PianoDownQueue -= 1
		if (_0):
			PianoDown.play()
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
		SOUND_LIST.PianoUp:
			PianoUpQueue += 1
		SOUND_LIST.PianoDown:
			PianoDownQueue += 1
		SOUND_LIST.Alarm:
			AlarmQueue += 1
		SOUND_LIST.Doh:
			DohQueue += 1

static func clear_queue(sound_id:int)-> void:
	match sound_id:
		SOUND_LIST.Bubble:
			BubbleQueue = 0
		SOUND_LIST.PianoUp:
			PianoUpQueue = 0
		SOUND_LIST.PianoDown:
			PianoDownQueue = 0
		SOUND_LIST.Alarm:
			AlarmQueue = 0
		SOUND_LIST.Doh:
			DohQueue = 0
