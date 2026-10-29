class_name InputManager
extends RefCounted
## Port of input.InputManager: a list of game actions for one input device.
## keyActions holds the 16 button actions (indexed by the GameMode button
## constants); devices map their own codes to these actions.

const NORMAL := 0
const CHEATING := 1

var keyActions: Array = []
var mode := NORMAL
var cheat := ""
var value := 0


func reset() -> void:
	pass


func resetAllGameActions() -> void:
	for ga in keyActions:
		if ga != null:
			ga.reset()


func hasSelectDownBeenPressed() -> bool:
	return keyActions[GameMode.SELECT].isPressedDontReset() \
		and keyActions[GameMode.DOWN].isPressedDontReset()


func hasSelectBeenPressed() -> bool:
	return keyActions[GameMode.SELECT].isPressed()


func hasStartBeenPressed() -> bool:
	return keyActions[GameMode.START].isPressed()


func getGameActions() -> Array:
	return keyActions


func createGameActions() -> void:
	pass


func isActive() -> bool:
	return true


func exit() -> void:
	pass


func isCheating() -> bool:
	return mode == CHEATING


func getCheat() -> String:
	return cheat


## Called by the main loop for every input event.
func handleEvent(event: InputEvent) -> void:
	pass


## Called by the main loop once per frame.
func poll(delta_ms: float) -> void:
	pass


## Port of InputManager.InputManagers: all input devices.
class InputManagers extends RefCounted:
	var managers: Array = []
	## Dev only (the debug console's padlost): connectionLost reports a lost
	## game pad, as an unplugged pad does, until the overlay's menu is
	## answered (reset or disconnectGamePad). Nothing else sets it.
	var lost_simulated := false

	func addInputManager(man) -> void:
		managers.append(man)

	func hasStartBeenPressed() -> bool:
		var pressed := false
		for im in managers:
			pressed = pressed or im.hasStartBeenPressed()
		return pressed

	func hasSelectDownBeenPressed() -> bool:
		var pressed := false
		for im in managers:
			pressed = pressed or im.hasSelectDownBeenPressed()
		return pressed

	func hasSelectBeenPressed() -> bool:
		var pressed := false
		for im in managers:
			pressed = pressed or im.hasSelectBeenPressed()
		return pressed

	func createGameActions() -> void:
		for im in managers:
			im.createGameActions()

	func getGameActions() -> Array:
		var gas: Array = []
		gas.resize(GameMode.NUMBER_OF_BUTTONS)
		for im in managers:
			var g: Array = im.getGameActions()
			for i in GameMode.NUMBER_OF_BUTTONS:
				var ga = gas[i]
				if ga == null:
					ga = GameAction.GameActions.new()
					gas[i] = ga
				ga.addGameAction(g[i])
		return gas

	func resetAllGameActions() -> void:
		for im in managers:
			im.resetAllGameActions()

	func reset() -> void:
		lost_simulated = false
		for im in managers:
			if im is InputGamePadManager:
				im.reset()

	func connectionLost() -> bool:
		var active := true
		for im in managers:
			active = active and im.isActive()
		return not active or lost_simulated

	func disconnectGamePad() -> void:
		lost_simulated = false
		var keep: Array = []
		for im in managers:
			if not (im is InputGamePadManager):
				keep.append(im)
		managers = keep

	func exit() -> void:
		for im in managers:
			im.exit()

	func isCheating() -> bool:
		for im in managers:
			if im.isCheating():
				return true
		return false

	func getCheat() -> String:
		for im in managers:
			if im.isCheating():
				return im.getCheat()
		return ""

	func handleEvent(event: InputEvent) -> void:
		for im in managers:
			im.handleEvent(event)

	func poll(delta_ms: float) -> void:
		for im in managers:
			im.poll(delta_ms)

	func getManager(script) -> InputManager:
		for im in managers:
			if is_instance_of(im, script):
				return im
		return null
