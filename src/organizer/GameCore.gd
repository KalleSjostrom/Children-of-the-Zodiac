class_name GameCore
extends RefCounted
## Port of organizer.GameCore: initializes the input managers and runs one
## step of the game loop per frame (called from Main.gd).

static var screen # The Main node (the original's AWT Frame).
static var inputManager := InputManager.InputManagers.new()
static var gameActions: Array = []

static var paused := false
static var strings: Array = []
static var values: Array = []
static var zeroTime := 0

var activeNode
var firstTimeIn := true
var counter := 0
var counter2 := 0
var counter3 := 0


func init() -> void:
	activeNode = MenuNode.new(null, "")
	activeNode.setEnableColor(JColor.WHITE)
	_fillRoot()


func _fillRoot() -> void:
	var n = activeNode
	n.insertChild("Try to reconnect")
	n.insertChild("Use keyboard instead")
	n.setDistance(50)
	n.setPositions(Values.createNormalPoint(400, 600))


func init2(obs: Array = []) -> void:
	# Determinism hook: a deterministic run (Main --seed, driven by AutoPlay)
	# reads no game pad. A connected pad, even untouched, releases every
	# button it does not hold each poll, so AutoPlay's presses would end
	# after one frame (and connecting it pauses the game).
	if GamePadController.areThereAnyGamePadControllers() and not J.deterministic:
		inputManager.addInputManager(InputGamePadManager.new())
	for o in obs:
		if o is InputManager:
			inputManager.addInputManager(o)
	inputManager.addInputManager(InputKeyBoardManager.new(screen))
	inputManager.createGameActions()
	setGameAction()


static func setGameAction() -> void:
	gameActions = inputManager.getGameActions()


static func enterCheat() -> void:
	strings = Database.getStoredKeys()
	values = []
	for s in strings:
		values.append(str(Database.getStatusFor(str(s))))
	zeroTime = J.currentTimeMillis()


func testDraw(g: Graphics) -> void:
	_preDraw(g)
	draw(g)
	g.checkError()
	if inputManager.connectionLost():
		if firstTimeIn:
			for i in range(GameMode.UP, GameMode.LEFT + 1):
				gameActions[i].changeBehavior(GameAction.DETECT_INITAL_PRESS_ONLY)
		firstTimeIn = false
		g.fadeOldSchool(0.5)
		var cx: int = Values.ORIGINAL_RESOLUTION[Values.X] / 2
		g.drawSingleCenteredText("Connection to game pad lost", 250, 1, 1, 50, cx)
		g.drawSingleCenteredText("Please reconnect the game pad in a USB port", 320, 1, 1, 30, cx)
		g.drawSingleCenteredText("(You can connect to the gamepad from the menu (Settings) later)", 350, 1, 1, 20, cx)
		if gameActions[GameMode.UP].isPressed():
			activeNode.previousChild()
		elif gameActions[GameMode.DOWN].isPressed():
			activeNode.nextChild()
		elif gameActions[GameMode.CROSS].isPressed():
			var n = activeNode.getCurrentChild()
			if n.getName().contains("keyboard"):
				inputManager.disconnectGamePad()
			else:
				inputManager.reset()
			for i in range(GameMode.UP, GameMode.LEFT + 1):
				gameActions[i].changeBehaviorBack()
			firstTimeIn = true
		activeNode.drawAllChildren(g)
	elif paused:
		g.fadeOldSchool(0.5)
		var fs := g.getFontSize()
		g.drawSingleCenteredText("Paused", 250, 1, 1, 50, Values.ORIGINAL_RESOLUTION[Values.X] / 2)
		g.setFontSize(fs)


func _preDraw(g: Graphics) -> void:
	if isPausable() and inputManager.hasStartBeenPressed():
		paused = not paused


static func isPaused() -> bool:
	return paused


static func exitGame() -> void:
	inputManager.exit()
	OggStreamer.stopAll()
	if screen != null and screen.is_inside_tree():
		screen.get_tree().quit()


static func setFullScreen() -> void:
	var w := DisplayServer.window_get_mode()
	if w == DisplayServer.WINDOW_MODE_FULLSCREEN or w == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Updates the game. elapsedTime is in milliseconds.
func update(elapsedTime: float) -> void:
	pass


func draw(g: Graphics) -> void:
	pass


func isPausable() -> bool:
	return false
