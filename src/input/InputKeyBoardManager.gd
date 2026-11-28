class_name InputKeyBoardManager
extends InputManager
## Port of input.InputKeyBoardManager: keyboard input.
##
## Keys: arrows = directions, W = triangle (menu), D = circle (back),
## S = cross (confirm), A = square, Enter = start (pause), Space = select,
## Q/E = L1/R1, 1/3 = L2/R2. Escape quits, F toggles full screen (so does
## Alt+Enter, which Main._input takes before it gets here), 6/7/8 make an
## emergency save. (Java: Space + Down opened the cheat menu and
## Shift+0 started typing a cheat; the debug console replaces both, COTZ-006.)
##
## Phase 4.3 (docs/ARCHITECTURE.md section 16): the keys are the InputMap's
## (the buttons' actions, "quit", "fullscreen" and "emergency_save_1" to 3).
## A key's press and release press and release its button; its echo events
## do nothing: poll presses a held key's button again every frame instead
## (GameAction's repeat, 480 ms then 90 ms on the game clock).

## The keys held whose press reached the game: keycode -> the press event.
var _held_keys := {}


func _init(comp = null) -> void:
	keyActions = []


func createGameActions() -> void:
	keyActions = []
	for i in GameMode.NUMBER_OF_BUTTONS + 1:
		keyActions.append(GameAction.new(GameAction.DETECT_INITAL_PRESS_ONLY))


func _saveEmergency(nr: int) -> void:
	var gm = Game.current_mode
	if gm != null:
		# Port fix (COTZ-005): the place and labyrinth position a menu save
		# would write; Java wrote the mode's name, which is not a place in
		# labyrinths and on the world map.
		Save.save_game_in("E" + str(nr), gm)


## A key through the InputMap: Escape, F and 6/7/8 when pressed, then its
## button pressed or released; echo events are left to poll.
func handleEvent(event: InputEvent) -> void:
	var e := event as InputEventKey
	if e == null or e.echo:
		return
	if e.pressed:
		if e.is_action(&"quit"):
			GameCore.exitGame()
		elif e.is_action(&"fullscreen"):
			GameCore.setFullScreen()
		for nr in range(1, 4):
			if e.is_action(StringName("emergency_save_%d" % nr)):
				_saveEmergency(nr)
	if press_actions(e):
		if e.pressed:
			_held_keys[e.keycode] = e
		else:
			_held_keys.erase(e.keycode)


## Every frame: each held key presses its button again, as its echo events
## did (the repeat of a DETECT_AS_KEY_LISTENER button; a button reset or let
## go by the game while its key is held is seen again). Not while the keys
## are the developer console's or a text box's (Main.keys_reach_game, as
## Main._input); a key let go meanwhile is dropped.
func poll(delta_ms: float) -> void:
	if _held_keys.is_empty() or (Main.instance != null and not Main.instance.keys_reach_game()):
		return
	for keycode: int in _held_keys.keys():
		if Input.is_key_pressed(keycode as Key):
			press_actions(_held_keys[keycode])
		else:
			_held_keys.erase(keycode)


func isActive() -> bool:
	return true


func reset() -> void:
	pass
