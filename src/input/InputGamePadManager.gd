class_name InputGamePadManager
extends InputManager
## Port of input.InputGamePadManager: polls the first game pad every 40 ms
## (like the original's javax.swing.Timer; every third frame at 60 FPS: the
## time left over is dropped) and presses/releases the actions.
## Buttons use the PlayStation layout the game was designed for:
## cross = bottom face button, circle = right, square = left, triangle = top.
## Phase 4.3: GamePadController reads them through the InputMap (the left
## stick is the directions' axis events there); the lost pad and its overlay
## (GameCore.testDraw) are as before.

const DELAY := 40.0

var gpController := GamePadController.new()
var active := true
var _accum := 0.0


func _init() -> void:
	keyActions = []


func reset() -> void:
	gpController = GamePadController.new()
	active = true


func _keyPressed(keyCode: int) -> void:
	var gameAction = keyActions[keyCode]
	if gameAction != null:
		gameAction.press()


func _keyReleased(keyCode: int) -> void:
	var gameAction = keyActions[keyCode]
	if gameAction != null:
		gameAction.release()


func poll(delta_ms: float) -> void:
	_accum += delta_ms
	if _accum < DELAY:
		return
	_accum = 0.0
	active = gpController.poll()
	if not active:
		return
	var buttons: Array = gpController.getButtons()
	for i in buttons.size():
		if buttons[i]:
			_keyPressed(i)
		else:
			_keyReleased(i)


func isActive() -> bool:
	return active


func createGameActions() -> void:
	keyActions = []
	for i in GameMode.NUMBER_OF_BUTTONS:
		keyActions.append(GameAction.new(GameAction.DETECT_INITAL_PRESS_ONLY))
