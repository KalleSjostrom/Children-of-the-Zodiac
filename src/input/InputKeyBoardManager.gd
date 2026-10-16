class_name InputKeyBoardManager
extends InputManager
## Port of input.InputKeyBoardManager: keyboard input.
##
## Keys: arrows = directions, W = triangle (menu), D = circle (back),
## S = cross (confirm), A = square, Enter = start (pause), Space = select,
## Q/E = L1/R1, 1/3 = L2/R2. Space + Down opens the cheat/debug menu.
## Escape quits, F toggles full screen, 6/7/8 make an emergency save,
## Shift+0 starts typing a cheat (Enter applies it).

var keyMap := {} # Godot keycode -> GameAction


func _init(comp = null) -> void:
	keyActions = []


func createGameActions() -> void:
	keyActions = []
	for i in GameMode.NUMBER_OF_BUTTONS + 1:
		keyActions.append(GameAction.new(GameAction.DETECT_INITAL_PRESS_ONLY))
	keyMap.clear()
	mapToKey(keyActions[GameMode.UP], KEY_UP)
	mapToKey(keyActions[GameMode.RIGHT], KEY_RIGHT)
	mapToKey(keyActions[GameMode.DOWN], KEY_DOWN)
	mapToKey(keyActions[GameMode.LEFT], KEY_LEFT)
	mapToKey(keyActions[GameMode.TRIANGLE], KEY_W)
	mapToKey(keyActions[GameMode.CIRCLE], KEY_D)
	mapToKey(keyActions[GameMode.CROSS], KEY_S)
	mapToKey(keyActions[GameMode.SQUARE], KEY_A)
	mapToKey(keyActions[GameMode.START], KEY_ENTER)
	mapToKey(keyActions[GameMode.START], KEY_KP_ENTER)
	mapToKey(keyActions[GameMode.SELECT], KEY_SPACE)
	mapToKey(keyActions[GameMode.R2], KEY_3)
	mapToKey(keyActions[GameMode.R1], KEY_E)
	mapToKey(keyActions[GameMode.L1], KEY_Q)
	mapToKey(keyActions[GameMode.L2], KEY_1)


func mapToKey(gameAction: GameAction, keyCode: int) -> void:
	keyMap[keyCode] = gameAction


func _getKeyAction(e: InputEventKey) -> GameAction:
	var keyCode := e.keycode
	if e.pressed and not e.echo:
		if keyCode == KEY_6:
			_saveEmergency(1)
		elif keyCode == KEY_7:
			_saveEmergency(2)
		elif keyCode == KEY_8:
			_saveEmergency(3)
	return keyMap.get(keyCode)


func _saveEmergency(nr: int) -> void:
	var o := Organizer.getOrganizer()
	if o == null:
		return
	var gm = o.getCurrentMode()
	if gm != null:
		var save = ClassRegistry.forName("factories.Save")
		if save != null:
			save.getSave().saveGame("E" + str(nr), gm.getName())


func handleEvent(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var e := event as InputEventKey
	if e.pressed:
		_keyPressed(e)
	else:
		_keyReleased(e)


func _keyPressed(e: InputEventKey) -> void:
	if mode == CHEATING:
		if e.keycode == KEY_BACKSPACE:
			if cheat.length() > 0:
				cheat = cheat.substr(0, cheat.length() - 1)
		elif e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
			pass
		elif e.unicode >= 32:
			cheat += char(e.unicode)
		if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
			var cheater = ClassRegistry.forName("organizer.Cheater")
			if cheater != null:
				cheater.doCheat(cheat)
			mode = NORMAL
		elif e.keycode == KEY_ESCAPE:
			mode = NORMAL
	else:
		if e.shift_pressed and e.keycode == KEY_0 and not e.echo:
			mode = CHEATING
			cheat = ""
			GameCore.enterCheat()
		if e.keycode == KEY_ESCAPE and not e.echo:
			GameCore.exitGame()
		elif e.keycode == KEY_F and not e.echo:
			GameCore.setFullScreen()
		var gameAction := _getKeyAction(e)
		if gameAction != null:
			gameAction.press()


func _keyReleased(e: InputEventKey) -> void:
	var gameAction := _getKeyAction(e)
	if gameAction != null:
		gameAction.release()


func isActive() -> bool:
	return true


func reset() -> void:
	pass
