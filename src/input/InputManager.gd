class_name InputManager
extends RefCounted
## Port of input.InputManager: a list of game actions for one input device.
## keyActions holds the 16 button actions (indexed by the GameMode button
## constants); devices map their own codes to these actions.
##
## Phase 4.3 (docs/ARCHITECTURE.md section 16): every device reads its
## buttons through Godot's InputMap (project.godot's [input]: one action per
## button, BUTTON_ACTIONS). Each device keeps its own GameActions, as the
## original's managers did: the call sites read them through
## InputManagers.getGameActions, whose OR over the devices they depend on.
## (The original's typed cheats, Shift+0, went with COTZ-006's console.)

## The InputMap action of each button, indexed by the GameMode button
## constants (L1R1 and L2R2 have no button).
const BUTTON_ACTIONS: Array[StringName] = [&"triangle", &"circle", &"cross", &"square",
	&"l2", &"r2", &"l1", &"r1", &"select", &"", &"", &"start", &"up", &"right", &"down",
	&"left"]

var keyActions: Array = []


func reset() -> void:
	pass


func resetAllGameActions() -> void:
	for ga in keyActions:
		if ga != null:
			ga.reset()


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


## Called by the main loop for every input event.
func handleEvent(event: InputEvent) -> void:
	pass


## Presses (a press event) or releases (a release event) the buttons whose
## InputMap action the event is; false if it is none of them.
func press_actions(event: InputEvent) -> bool:
	var found := false
	for i in BUTTON_ACTIONS.size():
		if BUTTON_ACTIONS[i] != &"" and event.is_action(BUTTON_ACTIONS[i]):
			found = true
			if event.is_pressed():
				keyActions[i].press()
			else:
				keyActions[i].release()
	return found


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

	func handleEvent(event: InputEvent) -> void:
		for im in managers:
			im.handleEvent(event)

	func poll(delta_ms: float) -> void:
		for im in managers:
			im.poll(delta_ms)
