class_name TitleScreen
extends GameMode
## Port of title.TitleScreen: the title screen. The player can load games
## from here, but not create new save slots.
##
## Port addition (COTZ-004): "Start" opens the difficulty choice (Easy,
## Medium, Original; see Difficulty), with the highlighted level's
## description under it. The level is stored once the new game is loaded.

var background = ""
var titleBackground = ""
var activeNode = null
var index: float = 0.0
var x: int = 78
var y: int = 59
## The Difficulty.Level chosen for a new game, -1 when continuing a save.
var newGameLevel: int = -1

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


func fillContinue():
	var n = activeNode
	activeNode.setEnableColor(JColor.WHITE)
	if not n.hasChildren():
		n.insertChild("Slot 1")
		n.insertChild("Slot 2")
		n.insertChild("Slot 3")
		n.setDistance(50)
		n.setPositions(Values.createNormalPoint(450, 600))


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
	g.drawImage(background, x, y)
	if not fadein:
		drawTitle(g)
		if doneFading():
			activeNode.drawAllChildren(g)
			if activeNode.getName() == "Start":
				drawDifficultyInfo(g)
	super.draw(g)


## The description of the highlighted difficulty, under the choice.
func drawDifficultyInfo(g):
	var level = Difficulty.LEVELS[activeNode.getMenuCursor()]
	g.setFontSize(20)
	g.drawWithShadow(level.description, 450, 728)
	g.setFontSize(24)


func doneFading():
	return index > .9


func drawTitle(g):
	if index < .9:
		g.setColor(1, 1, 1, index)
	g.drawImage(titleBackground, x, y, 1)
