class_name GamePadController
extends RefCounted
## Port of input.GamePadController using Godot's joypad API.
##
## Phase 4.3 (docs/ARCHITECTURE.md section 16): the buttons are the
## InputMap's: a button is held while one of its action's game pad events is
## on this pad (a pad button; an axis past the action's dead zone in the
## event's direction: the triggers and the left stick, both axes at once for
## a diagonal).

var device := -1


func _init() -> void:
	var pads := Input.get_connected_joypads()
	device = pads[0] if pads.size() > 0 else -1


static func areThereAnyGamePadControllers() -> bool:
	return Input.get_connected_joypads().size() > 0


## Returns true while the game pad is connected.
func poll() -> bool:
	if device < 0:
		return false
	return Input.get_connected_joypads().has(device)


## The 16 buttons indexed by the GameMode button constants.
func getButtons() -> Array:
	var b: Array = []
	b.resize(GameMode.NUMBER_OF_BUTTONS)
	for i in InputManager.BUTTON_ACTIONS.size():
		b[i] = _is_action_held(InputManager.BUTTON_ACTIONS[i])
	return b


## True while one of the action's game pad events is held on this pad: a
## button pressed, or an axis further than the action's dead zone in the
## event's direction (strictly, as the original's 0.5).
func _is_action_held(action: StringName) -> bool:
	if action == &"":
		return false
	var deadzone := InputMap.action_get_deadzone(action)
	for e: InputEvent in InputMap.action_get_events(action):
		var button := e as InputEventJoypadButton
		if button != null and Input.is_joy_button_pressed(device, button.button_index):
			return true
		var motion := e as InputEventJoypadMotion
		if motion != null and Input.get_joy_axis(device, motion.axis) * signf(motion.axis_value) > deadzone:
			return true
	return false
