class_name GameCore
extends RefCounted
## Port of organizer.GameCore: initializes the input managers and runs one
## step of the game loop per frame (called from Main.gd).

## Bridge (phase 3 step B): the UI nodes of testDraw's overlays.
const PAUSED_VIEW := "res://scenes/ui/Paused.tscn"
const PAD_LOST_VIEW := "res://scenes/ui/PadLost.tscn"

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
		# Bridge (phase 3 step B): the Transition layer's PadLost node shows
		# the overlay (_show_pad_lost); --legacy=pause keeps the drawing.
		var view = null
		if Main.is_legacy("pause"):
			g.fadeOldSchool(0.5)
			var cx: int = Values.ORIGINAL_RESOLUTION[Values.X] / 2
			g.drawSingleCenteredText("Connection to game pad lost", 250, 1, 1, 50, cx)
			g.drawSingleCenteredText("Please reconnect the game pad in a USB port", 320, 1, 1, 30, cx)
			g.drawSingleCenteredText("(You can connect to the gamepad from the menu (Settings) later)", 350, 1, 1, 20, cx)
		else:
			view = _show_pad_lost(g)
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
		if Main.is_legacy("pause"):
			activeNode.drawAllChildren(g)
		else:
			_show_pad_lost_menu(g, view)
	elif paused:
		# Bridge (phase 3 step B): the Transition layer's Paused node
		# (_show_paused); --legacy=pause keeps the drawing.
		if Main.is_legacy("pause"):
			g.fadeOldSchool(0.5)
			var fs := g.getFontSize()
			g.drawSingleCenteredText("Paused", 250, 1, 1, 50, Values.ORIGINAL_RESOLUTION[Values.X] / 2)
			g.setFontSize(fs)
		else:
			_show_paused(g)


# Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): testDraw's
# overlays without the drawing. Each makes the drawing's state changes in the
# same order (fadeOldSchool's colour and bind: Graphics.show_fade, whose Fade
# node draws the dim; drawSingleCenteredText's font size, startText and
# finishText) and hands its node on the Transition layer the text colours,
# the font and the material of the 2D state.

## "Paused": the dim and the title.
func _show_paused(g: Graphics) -> void:
	g.show_fade(0.5)
	var fs := g.getFontSize()
	g.setFontSize(50)
	g.startText(1, 1)
	var color: Color = Graphics.text_color(g.text_alpha())
	g.finishText()
	var view = g.show_ui(PAUSED_VIEW, Graphics.TRANSITION_LAYER)
	if view != null:
		view.show_paused(color, g.canvas_material(), Graphics.font_bold())
	g.setFontSize(fs)


## "Connection to game pad lost": the dim, the title and the two lines; the
## menu follows after the input (_show_pad_lost_menu). Returns the node.
func _show_pad_lost(g: Graphics):
	g.show_fade(0.5)
	var colors: Array[Color] = []
	for size in [50, 30, 20]:
		g.setFontSize(size)
		g.startText(1, 1)
		colors.append(Graphics.text_color(g.text_alpha()))
		g.finishText()
	var view = g.show_ui(PAD_LOST_VIEW, Graphics.TRANSITION_LAYER)
	if view != null:
		view.show_texts(colors, g.canvas_material(), Graphics.font_bold())
	return view


## The game pad lost menu (activeNode.drawAllChildren): its choices and hand.
func _show_pad_lost_menu(g: Graphics, view) -> void:
	var menu: Dictionary = activeNode.place_all_children(g)
	if view == null:
		return
	var hand: Texture2D = null
	var at := Vector2i.ZERO
	var tint := Color.WHITE
	if not menu.hand.is_empty():
		var t = ImageHandler.getTexture(menu.hand[0])
		hand = t.getGodotTexture() if t != null else null
		at = Vector2i(menu.hand[1], menu.hand[2])
		tint = menu.hand[3]
	var choices := []
	for item: Array in menu.items:
		choices.append([item[0], Vector2i(item[1], item[2]), item[3]])
	view.show_menu(choices, g.getFontSize(), Graphics.font_bold(), hand, at, tint)


func _preDraw(g: Graphics) -> void:
	if isPausable() and inputManager.hasStartBeenPressed():
		paused = not paused


static func isPaused() -> bool:
	return paused


## Quits the game; only for the player's own quit (Escape). The game's code
## never quits: a broken invariant or bad data asserts instead (Java's
## System.exit calls, the debugger stops there).
static func exitGame() -> void:
	inputManager.exit()
	OggStreamer.stopAll()
	if screen != null and screen.is_inside_tree():
		screen.get_tree().quit()


## Toggles between a window and borderless full screen (F, Alt+Enter).
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
