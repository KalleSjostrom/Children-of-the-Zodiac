class_name GamePadController
extends RefCounted
## Port of input.GamePadController using Godot's joypad API.

const DEADZONE := 0.5

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


## The 16 buttons indexed by the GameMode button constants (directions are
## filled in from the d-pad here and from the stick by getXYStickDir()).
func getButtons() -> Array:
	var b: Array = []
	b.resize(GameMode.NUMBER_OF_BUTTONS)
	b.fill(false)
	b[GameMode.TRIANGLE] = Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
	b[GameMode.CIRCLE] = Input.is_joy_button_pressed(device, JOY_BUTTON_B)
	b[GameMode.CROSS] = Input.is_joy_button_pressed(device, JOY_BUTTON_A)
	b[GameMode.SQUARE] = Input.is_joy_button_pressed(device, JOY_BUTTON_X)
	b[GameMode.L1] = Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER)
	b[GameMode.R1] = Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER)
	b[GameMode.L2] = Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > DEADZONE
	b[GameMode.R2] = Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > DEADZONE
	b[GameMode.SELECT] = Input.is_joy_button_pressed(device, JOY_BUTTON_BACK)
	b[GameMode.START] = Input.is_joy_button_pressed(device, JOY_BUTTON_START)
	b[GameMode.UP] = Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)
	b[GameMode.RIGHT] = Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
	b[GameMode.DOWN] = Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
	b[GameMode.LEFT] = Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
	return b


## Directions of the left stick as Values.UP/RIGHT/DOWN/LEFT, -1 for none.
func getXYStickDir() -> Array:
	var x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	var h := -1
	var v := -1
	if x > DEADZONE:
		h = Values.RIGHT
	elif x < -DEADZONE:
		h = Values.LEFT
	if y > DEADZONE:
		v = Values.DOWN
	elif y < -DEADZONE:
		v = Values.UP
	return [h, v]
