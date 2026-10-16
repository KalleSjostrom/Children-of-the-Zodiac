class_name FakeInputManager
extends InputManager
## Port of input.FakeInputManager: an input device driven from code.
## Used by the original's replay/testing support (factories.Load) and by the
## port's automated tests (Main --autoplay).


func _init() -> void:
	createGameActions()


func createGameActions() -> void:
	keyActions = []
	for i in GameMode.NUMBER_OF_BUTTONS + 1:
		keyActions.append(GameAction.new(GameAction.DETECT_INITAL_PRESS_ONLY))


## Presses the button with the given GameMode index.
func pressButton(button: int) -> void:
	keyActions[button].press()


## Releases the button with the given GameMode index.
func releaseButton(button: int) -> void:
	keyActions[button].release()


func isActive() -> bool:
	return true


func reset() -> void:
	pass
