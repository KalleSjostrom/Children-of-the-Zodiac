class_name TitleScreen
extends GameMode
## Port of title.TitleScreen: the title screen. The player can load games
## from here, but not create new save slots.
##
## Port addition (COTZ-004): "Start" opens the difficulty choice (Easy,
## Medium, Original; see Difficulty), with the highlighted level's
## description under it. The level is stored once the new game is loaded.
##
## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): UI nodes show
## the title where the drawing drew it: Title (the background and the logo),
## MenuList (activeNode, MenuNode.show_all_children), ShadowText (the
## difficulty's description), SlotDates (the slots' dates);
## --legacy=title and --legacy=menu_list keep the drawing.

const TITLE_VIEW := "res://scenes/ui/Title.tscn"
const SHADOW_TEXT_VIEW := "res://scenes/ui/ShadowText.tscn"

var background = ""
var titleBackground = ""
var activeNode = null
var index: float = 0.0
var x: int = 78
var y: int = 59
## The Difficulty.Level chosen for a new game, -1 when continuing a save.
var newGameLevel: int = -1
## Bridge: the frame's Title node (_show_background), for drawTitle's logo.
var _title_view = null

## Java: init(HashMap info).
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_INIT)
	pausable = false
	loadImages()
	activeNode = MenuNode.new(null, "")
	activeNode.setEnableColor(JColor.WHITE)
	fillRoot()
	fadeInSpeed = 1
	logicLoading = false


func fillRoot():
	var n = activeNode
	n.insertChild("Start")
	n.insertChild("Continue")
	n.setDistance(50)
	n.setPositions(Values.createNormalPoint(450, 600))


## Fills the difficulty choice of a new game (the cursor on Medium).
func fillStart():
	var n = activeNode
	activeNode.setEnableColor(JColor.WHITE)
	if not n.hasChildren():
		for level in Difficulty.Level.values():
			n.insertChild(Difficulty.name_of(level))
		n.setDistance(50)
		n.setPositions(Values.createNormalPoint(450, 570))
		n.setMenuCursor(Difficulty.Level.MEDIUM)


## Fills the slots to continue from: the autosave (when there is one) and
## the three slots, each with the date it was saved (COTZ-005).
func fillContinue():
	var n = activeNode
	activeNode.setEnableColor(JColor.WHITE)
	if not n.hasChildren():
		var slots: PackedStringArray = SaveSlots.loadable()
		for slot in slots:
			n.insertChild(slot)
		n.setDistance(50)
		n.setPositions(Values.createNormalPoint(450, 750 - 50 * slots.size()))


func loadImages(name = null, nightLayer = null, extra = null):
	background = Values.TitleImages + "loggasten.png"
	titleBackground = Values.TitleImages + "loggatext.png"
	ImageHandler.addToCurrentLoadNow(background)
	ImageHandler.addToCurrentLoadNow(titleBackground)


func update(elapsedTime: float):
	if mode != Values.NO_MODE_IS_SELECTED:
		fadeout = true
	elif doneFading():
		checkGameInput()
	elif gameActions[CROSS].isPressed():
		fadein = false
		fadeout = false
		fadeValue = 1
		index = 1

	if not fadein:
		if index < .9:
			index += .005
	super.update(elapsedTime)


func checkGameInput():
	if gameActions[UP].isPressed():
		activeNode.previousChild(true)
	elif gameActions[DOWN].isPressed():
		activeNode.nextChild(true)
	elif gameActions[CIRCLE].isPressed():
		SoundPlayer.playSound(SoundMap.MENU_BACK)
		var n = activeNode.getParent()
		if n != null:
			activeNode = n
	elif gameActions[CROSS].isPressed():
		SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
		var n = activeNode.getCurrentChild()
		if n.getName() == "Continue":
			activeNode = n
			fillContinue()
		elif n.getName() == "Start" and activeNode.getParent() == null:
			activeNode = n
			fillStart()
		elif activeNode.getName() == "Start":
			newGameLevel = activeNode.getMenuCursor()
			Load.setSlot("Start")
			mode = Values.EXIT
		else:
			Load.setSlot(n.getName())
			mode = Values.EXIT


func finishOff():
	Load.loadGame()
	if newGameLevel >= 0:
		Difficulty.start_with(newGameLevel)
	nextPlace = Load.getStartLocation()


func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(24)
	if Main.is_legacy("title"):
		g.drawImage(background, x, y)
	else:
		_show_background(g)
	if not fadein:
		drawTitle(g)
		if doneFading():
			if Main.is_legacy("menu_list"):
				activeNode.drawAllChildren(g)
			else:
				activeNode.show_all_children(g, Graphics.UI_LAYER)
			if activeNode.getName() == "Start":
				drawDifficultyInfo(g)
			elif activeNode.getName() == "Continue":
				if Main.is_legacy("title"):
					SaveSlots.draw_dates_beside(g, activeNode, 620, 24)
				else:
					SaveSlots.show_dates_beside(g, activeNode, 620, 24)
	super.draw(g)


## The description of the highlighted difficulty, under the choice.
func drawDifficultyInfo(g):
	var level = Difficulty.LEVELS[activeNode.getMenuCursor()]
	g.setFontSize(20)
	if Main.is_legacy("title"):
		g.drawWithShadow(level.description, 450, 728)
	else:
		_show_difficulty_info(g, level.description)
	g.setFontSize(24)


func doneFading():
	return index > .9


func drawTitle(g):
	if index < .9:
		g.setColor(1, 1, 1, index)
	if Main.is_legacy("title"):
		g.drawImage(titleBackground, x, y, 1)
	else:
		_show_logo(g)


# Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the drawing
# without the drawing. Each makes the drawing's state changes in the same
# order (drawImage's bind: Graphics.skip_image; drawWithShadow's text colours
# and setColor(color): Graphics.place_with_shadow) and hands its UI node what
# would have been drawn, in the colour and with the material of the GL state.

## The background (drawImage(background, x, y)): the frame's Title node.
func _show_background(g) -> void:
	var t = g.skip_image(background)
	_title_view = g.show_ui(TITLE_VIEW, Graphics.UI_LAYER)
	if _title_view != null:
		_title_view.show_background(t != null, g.getCurrentColor(), g.canvas_material())


## The logo (drawImage(titleBackground, x, y, 1)), in its colour (the alpha
## index while it fades in), on the frame's Title node.
func _show_logo(g) -> void:
	var t = g.skip_image(titleBackground)
	if _title_view != null:
		_title_view.show_logo(t != null, g.getCurrentColor(), g.canvas_material())


## The description (drawWithShadow at 450, 728): a ShadowText node.
func _show_difficulty_info(g, description: String) -> void:
	var colors: Array[Color] = g.place_with_shadow()
	var view = g.show_ui(SHADOW_TEXT_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_text(description, Vector2i(450, 728), &"DifficultyInfo", colors[0], colors[1],
				Graphics.font_bold(), g.canvas_material())
