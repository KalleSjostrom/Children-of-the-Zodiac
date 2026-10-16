class_name GameAction
extends RefCounted
## Port of input.GameAction: an abstraction of a user-initiated action
## (a button). Supports three behaviors:
##  - NORMAL: isPressed() is true for as long as the button is held,
##  - DETECT_INITAL_PRESS_ONLY: true once per press,
##  - DETECT_AS_KEY_LISTENER: true once, then repeating after 480 ms every 90 ms.
## The Java version used threads for the repeat timing; here it uses timestamps.

const NORMAL := 0
const DETECT_INITAL_PRESS_ONLY := 1
const DETECT_AS_KEY_LISTENER := 2

const STATE_RELEASED := 0
const STATE_PRESSED := 1
const STATE_WAITING_FOR_RELEASE := 2

var behavior := 0
var amount := 0
var state := 0
var prevBehavior := 0
var _add_at_msec := -1 # when the repeat flag ("add") becomes true; -1 = never


func _init(p_behavior: int = NORMAL) -> void:
	changeBehavior(p_behavior)


func changeBehavior(p_behavior: int) -> void:
	prevBehavior = behavior
	behavior = p_behavior
	reset()


func changeBehaviorBack() -> void:
	var temp := behavior
	behavior = prevBehavior
	prevBehavior = temp
	reset()


func reset() -> void:
	amount = 0


func _add() -> bool:
	return _add_at_msec >= 0 and Time.get_ticks_msec() >= _add_at_msec


func _startThread(time: int) -> void:
	_add_at_msec = Time.get_ticks_msec() + time


## Signals that the key was pressed.
func press() -> void:
	if state == STATE_RELEASED:
		amount += 1
		if behavior == DETECT_AS_KEY_LISTENER:
			_startThread(480)
	if state != STATE_WAITING_FOR_RELEASE:
		if behavior != DETECT_INITAL_PRESS_ONLY:
			if behavior == DETECT_AS_KEY_LISTENER and _add():
				amount += 1
				_add_at_msec = -1
				_startThread(90)
			elif behavior == NORMAL:
				amount += 1
		state = STATE_PRESSED


## Signals that the key was released.
func release() -> void:
	state = STATE_RELEASED
	_add_at_msec = -1
	amount = 0


func isPressed() -> bool:
	return getAmount() != 0


func isPressedDontReset() -> bool:
	return state != STATE_RELEASED


func isReleased() -> bool:
	return not isPressed()


func getAmount() -> int:
	var retVal := amount
	if retVal != 0:
		if state == STATE_RELEASED:
			amount = 0
		elif behavior == DETECT_INITAL_PRESS_ONLY:
			state = STATE_WAITING_FOR_RELEASE
			amount = 0
		elif behavior == DETECT_AS_KEY_LISTENER:
			amount -= 1
	return retVal


## Port of GameAction.GameActions: the same button on all input devices.
class GameActions extends RefCounted:
	var gameActions: Array = []

	func addGameAction(ga) -> void:
		gameActions.append(ga)

	func changeBehavior(detectionMode: int) -> void:
		for ga in gameActions:
			ga.changeBehavior(detectionMode)

	func changeBehaviorBack() -> void:
		for ga in gameActions:
			ga.changeBehaviorBack()

	func release() -> void:
		for ga in gameActions:
			ga.release()

	func reset() -> void:
		for ga in gameActions:
			ga.reset()

	func isPressed() -> bool:
		var pressed := false
		for ga in gameActions:
			pressed = pressed or ga.isPressed()
		return pressed

	func isPressedDontReset() -> bool:
		var pressed := false
		for ga in gameActions:
			pressed = pressed or ga.isPressedDontReset()
		return pressed

	func isReleased() -> bool:
		var released := false
		for ga in gameActions:
			released = released or ga.isReleased()
		return released
