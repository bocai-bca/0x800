extends Node
class_name SfxManager

enum SOUND_LIST {
	Bubble = 0,
	PianoUp = 1,
	PianoDown = 2
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

func _process(delta:float)-> void:
	BubblePlayAgo = move_toward(BubblePlayAgo, BubblePlayInterval, delta)
	PianoUpPlayAgo = move_toward(PianoUpPlayAgo, PianoUpPlayInterval, delta)
	PianoDownPlayAgo = move_toward(PianoDownPlayAgo, PianoDownPlayInterval, delta)
	if (BubbleQueue >= 1 and BubblePlayAgo >= BubblePlayInterval):
		BubblePlayAgo = 0.0
		BubbleQueue -= 1
		Bubble.set_pitch_scale(randf_range(0.7, 1.3))
		Bubble.play()
	if (PianoUpQueue >= 1 and PianoUpPlayAgo >= PianoUpPlayInterval):
		PianoUpPlayAgo = 0.0
		PianoUpQueue -= 1
		PianoUp.set_pitch_scale(randf_range(1.2, 1.2))
		PianoUp.play()
	if (PianoDownQueue >= 1 and PianoDownPlayAgo >= PianoDownPlayInterval):
		PianoDownPlayAgo = 0.0
		PianoDownQueue -= 1
		PianoDown.set_pitch_scale(randf_range(1.2, 1.2))
		PianoDown.play()

static func add_queue(sound_id:int)-> void:
	match sound_id:
		SOUND_LIST.Bubble:
			BubbleQueue += 1
		SOUND_LIST.PianoUp:
			PianoUpQueue += 1
		SOUND_LIST.PianoDown:
			PianoDownQueue += 1
