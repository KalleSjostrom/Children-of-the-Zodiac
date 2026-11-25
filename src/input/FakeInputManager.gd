class_name FakeInputManager
extends InputManager
## Port of input.FakeInputManager: an input device driven from code.
## Used by the original's replay/testing support (factories.Load) and by the
## port's automated tests (Main --autoplay).
##
## Phase 4.3 (docs/ARCHITECTURE.md section 16): AutoPlay presses its
## buttons as InputMap action events through Godot's Input
## (Input.parse_input_event); this device takes those events (handleEvent),
## so AutoPlay's buttons stay a device of their own beside the keyboard's.
## A held button is pressed once, as AutoPlay's presses always were: nothing
## presses it again while it is held (no repeat).


func _init() -> void:
	createGameActions()


func createGameActions() -> void:
	keyActions = []
	for i in GameMode.NUMBER_OF_BUTTONS + 1:
		keyActions.append(GameAction.new(GameAction.DETECT_INITAL_PRESS_ONLY))


## The action events AutoPlay sends (InputEventAction).
func handleEvent(event: InputEvent) -> void:
	if event is InputEventAction:
		press_actions(event)


func isActive() -> bool:
	return true


func reset() -> void:
	pass
