extends Sprite2D
class_name HeatBar

signal heat_bar_touched_top()

const COLOR_MIN: Color = Color(0.8, 0.48, 0.48, 1.0)
const COLOR_BOUND: Color = Color(0.8, 0.0, 0.0, 1.0)
const COLOR_LIGHT: Color = Color(1.0, 0.0, 0.0, 1.0)
const COLOR_GRAY_MIN: Color = Color(0.7, 0.7, 0.7, 1.0)
const COLOR_GRAY_BOUND: Color = Color(0.5, 0.5, 0.5, 1.0)
const COLOR_GRAY_LIGHT: Color = Color(0.35, 0.35, 0.35, 1.0)
var CurrentColorMin: Color = Color(1.0, 1.0, 1.0, 1.0)
var CurrentColorBound: Color = Color(1.0, 1.0, 1.0, 1.0)
var CurrentColorLight: Color = Color(1.0, 1.0, 1.0, 1.0)
const LINE_WIDTH: float = 1536.0
const SMOOTH_STEP_SPEED: float = 0.1618
var NowDegree: float #0-1
var TargetDegree: float #0-1
var NowAlpha: float #0-1。仅使用于FADE_TO_EMPTY
var PlayingState: int
enum PLAYING_STATE{
	INSTANT = 0,
	SMOOTH_STEP = 1, #平滑移动
	FADE_TO_EMPTY = 2, #触顶时清空
}
var FlashingTimer: float

@onready var Line:Sprite2D = get_node("Line")

func _ready() -> void:
	PlayingState = PLAYING_STATE.SMOOTH_STEP
	FlashingTimer = 0.0

func _process(delta: float) -> void:
	if (Main.IsSoundEnable):
		CurrentColorMin = Color(
			move_toward(CurrentColorMin.r, COLOR_MIN.r, delta),
			move_toward(CurrentColorMin.g, COLOR_MIN.g, delta),
			move_toward(CurrentColorMin.b, COLOR_MIN.b, delta)
		)
		CurrentColorBound = Color(
			move_toward(CurrentColorBound.r, COLOR_BOUND.r, delta),
			move_toward(CurrentColorBound.g, COLOR_BOUND.g, delta),
			move_toward(CurrentColorBound.b, COLOR_BOUND.b, delta)
		)
	else:
		CurrentColorMin = Color(
			move_toward(CurrentColorMin.r, COLOR_GRAY_MIN.r, delta),
			move_toward(CurrentColorMin.g, COLOR_GRAY_MIN.g, delta),
			move_toward(CurrentColorMin.b, COLOR_GRAY_MIN.b, delta)
		)
		CurrentColorBound = Color(
			move_toward(CurrentColorBound.r, COLOR_GRAY_BOUND.r, delta),
			move_toward(CurrentColorBound.g, COLOR_GRAY_BOUND.g, delta),
			move_toward(CurrentColorBound.b, COLOR_GRAY_BOUND.b, delta)
		)
	var is_line_lighting:bool = false
	if (Line.modulate == CurrentColorLight):
		is_line_lighting = true
	if (Main.IsSoundEnable):
		CurrentColorLight = Color(
			move_toward(CurrentColorLight.r, COLOR_LIGHT.r, delta),
			move_toward(CurrentColorLight.g, COLOR_LIGHT.g, delta),
			move_toward(CurrentColorLight.b, COLOR_LIGHT.b, delta)
		)
	else:
		CurrentColorLight = Color(
			move_toward(CurrentColorLight.r, COLOR_GRAY_LIGHT.r, delta),
			move_toward(CurrentColorLight.g, COLOR_GRAY_LIGHT.g, delta),
			move_toward(CurrentColorLight.b, COLOR_GRAY_LIGHT.b, delta)
		)
	Line.set_modulate(CurrentColorMin.lerp(CurrentColorBound, float(clampi(Main.Heating, 0, Main.COMBO_STACK_HEATING)) / float(Main.COMBO_STACK_HEATING)))
	if (Main.Heating >= Main.COMBO_STACK_HEATING):
		var a: int = clampi(Main.HEATING_MAX - Main.Heating, 2, Main.HEATING_MAX)
		if (fmod(FlashingTimer, a) <= float(a / 2.0)):
			if (!is_line_lighting and PlayingState == PLAYING_STATE.SMOOTH_STEP and Main.GlobalState != Main.GLOBAL_STATE.GAME_OVER):
				SfxManager.add_queue(SfxManager.SOUND_LIST.Alarm)
			else:
				SfxManager.clear_queue(SfxManager.SOUND_LIST.Alarm)
			Line.set_modulate(CurrentColorLight)
		FlashingTimer = fmod(FlashingTimer + delta * 10.0, 4 * a)
	match PlayingState:
		PLAYING_STATE.SMOOTH_STEP:
			Line.set_region_rect(
				Rect2(0.0, 0.0, NowDegree * LINE_WIDTH, 384.0)
			)
			Line.set_position(Vector2(
				LINE_WIDTH * -0.5 + NowDegree * 0.5 * LINE_WIDTH, 0.0
			))
			NowDegree = move_toward(NowDegree, TargetDegree, delta * SMOOTH_STEP_SPEED)
			if (NowDegree == 1.0):
				emit_signal("heat_bar_touched_top")
				PlayingState = PLAYING_STATE.FADE_TO_EMPTY
				NowAlpha = 1.0
				SfxManager.clear_queue(SfxManager.SOUND_LIST.Alarm)
		PLAYING_STATE.FADE_TO_EMPTY:
			NowAlpha = clampf(NowAlpha - delta, 0.0, 1.0)
			if (NowAlpha == 0.0):
				Line.set_modulate(Color(Line.get_modulate(), 1.0))
				PlayingState = PLAYING_STATE.SMOOTH_STEP
				NowDegree = 0.0
				Line.set_region_rect(
					Rect2(0.0, 0.0, NowDegree * LINE_WIDTH, 384.0)
				)
				Line.set_position(Vector2(
					LINE_WIDTH * -0.5 + NowDegree * 0.5 * LINE_WIDTH, 0.0
				))
			else:
				Line.set_modulate(Color(COLOR_LIGHT, NowAlpha))
