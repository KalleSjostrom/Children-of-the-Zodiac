class_name MapPage
extends AbstractPage
## Port of menu.MapPage: shows the maps of the visited labyrinths.
##
## Port note: the Java private update() (refresh the shown map) and the
## inherited update(float elapsedTime) share update(elapsedTime = null):
## update() with no argument is the Java private method; with an argument it
## is the per-frame AbstractPage.update, which does nothing.

var map = null
var lab = null
var currentFloors = null
var currentNode = null
static var mappiece = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "mappiece.png")
static var mappiece2 = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "mappiece2.png")
static var mappiece3 = _createMappiece3()
var floor = null
## Port addition (COTZ-012): opened with Square from the game: Circle and
## Square go straight back to it.
var shortcut := false


static func _createMappiece3() -> Array:
	var m: Array = J.array(4, null)
	for i in range(4):
		m[i] = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "mappiece3" + str(i) + ".png")
	return m


func _init(p_shortcut = false) -> void:
	shortcut = p_shortcut
	var name = null
	var gameMode = Organizer.getOrganizer().getPreviousMode()
	activeNode = getRootNode()
	if gameMode is Labyrinth:
		lab = gameMode
		name = lab.getSimpleName()
		floor = lab.getFloorName()
		currentNode = lab.getCurrentNode()
		var found: bool = false
		var i: int = 0
		while i < activeNode.getSize() and not found:
			var n: String = activeNode.getChild(i).getName()
			found = n.to_lower() == str(name).to_lower()
			if not found:
				downPressed(false)
			i += 1
		crossPressed(false)
		if floor != null:
			activeNode.setCurrentChild(floor)
			update()
	else:
		var labInfo = Database.getLastVisitedLabyrinth()
		name = labInfo[0]
		floor = labInfo[1]
		activeNode.setCurrentChild(name)
		crossPressed(false)
		if floor != null:
			activeNode.setCurrentChild(floor)
			update()
	setPage(BESTIARY_PAGE)


func getRootNode():
	var n = MenuNode.new(null, "Map")
	if not n.hasChildren():
		var list = Database.getVisitedLabyrinthsList()
		for i in range(list.size()):
			n.insertChild(list[i])
		n.setStandardWithBB()
	return n


## Java overloads crossPressed() (plays the sound) and crossPressed(playSound).
func crossPressed(playSound = null):
	if playSound == null:
		playSound = true
	var name = activeNode.getCurrentChild().getName()
	var li = Database.getMap(name)
	if li != null:
		map = li.getFirstFloor()
		if playSound:
			SoundPlayer.playSound(SoundMap.ACCEPT)
		setCurrent(li, name)


func setCurrent(li, name):
	var n = MenuNode.new(activeNode, name)
	if not n.hasChildren():
		currentFloors = li.getFloors()
		for i in range(currentFloors.size()):
			n.insertChild(currentFloors[i].getName())
		n.setDistance(MenuValues.DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
		n.setCurrentChild(floor)
		var found: bool = false
		var i: int = 0
		while i < currentFloors.size() and not found:
			# Java: floor.equals(...) (a null floor would throw there).
			found = floor != null and floor == currentFloors[i].getName()
			if found:
				map = currentFloors[i]
			i += 1
	activeNode = n


func upPressed():
	activeNode.previousChild()
	if isZoomedOut():
		update()
		crossPressed(false)
		circlePressed()
	else:
		update()


func update(elapsedTime = null):
	if elapsedTime != null:
		return
	var name = activeNode.getCurrentChild().getName()
	var li = Database.getMap(name)
	if li != null:
		map = li.getFirstFloor()
	else:
		map = currentFloors[activeNode.getMenuCursor()]


## Java overloads downPressed() (plays the sound) and downPressed(playSound).
func downPressed(playSound = null):
	if playSound == null:
		playSound = true
	activeNode.nextChild(playSound)
	if isZoomedOut():
		update()
		crossPressed(false)
		circlePressed()
	else:
		update()


func squarePressed():
	if shortcut:
		SoundPlayer.playSound(SoundMap.MENU_EXIT)
		MainMenu.getMainMenu().exit()


func R1Pressed():
	# Change floor in the map
	pass


func L1Pressed():
	# Change floor in the map
	pass


## Up a level (to the labyrinths, then the start page), or out of the menu
## when opened with Square. upPressed and downPressed use the first, but
## only on the list of labyrinths, which Square does not open on.
func circlePressed(pressAnyWay = null):
	var n = activeNode.getParent()
	if shortcut:
		MainMenu.getMainMenu().exit()
	elif n != null:
		activeNode = MenuNode.switchNode(activeNode, n)
		activeNode.updateHandPos()
	else:
		MainMenu.getMainMenu().initStartPage(5)


func draw3D(g):
	super.drawStandard(g)
	g.drawString(activeNode.getName(), MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)
	activeNode.drawAllChildren(g)
	var percent: int = 0
	if isZoomedOut():
		percent = drawAll(g)
		drawHelp(g, true)
	else:
		percent = drawSingle(g)
		drawHelp(g, false)
	g.drawString("Explored: " + str(percent) + " %", 40, 50)
	StartPage.drawScreenShot(g)
	StartPage.drawInfo(g)


func isZoomedOut():
	return activeNode.getName() == "Map" # Fulhack...


func drawSingle(g):
	var currentDir: int = -1
	if lab != null:
		currentDir = lab.getPlayerDirection()
	return map.draw(g, currentNode, currentDir, null, false, true)


func drawAll(g):
	g.push()
	g.translate(25, 80, 0)
	g.scale(1.0 / 3)
	var percent: int = 0
	var size: int = 0
	for i in range(currentFloors.size()):
		var m = currentFloors[i]
		size = m.getSize()
		var pos = m.getMapPos()
		var currentDir: int = -1
		if lab != null:
			currentDir = lab.getPlayerDirection()
		g.push()
		g.translate(pos[0] * 700, pos[1] * 1000, 0)
		percent += m.draw(g, currentNode, currentDir, pos, true, false)
		g.pop()
	g.scale(3)
	g.pop()
	percent = J.round((percent / float(size)) * 100)
	return percent


func drawHelp(g, drawAll = null):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 720
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons)

	g.drawString("Exit", helpx, helpy)
	g.drawString("Select", helpx + step, helpy)
	if shortcut:
		g.drawString("Back", helpx + 2 * step, helpy)
	else:
		g.drawString("To main menu" if drawAll else "Zoom out", helpx + 2 * step, helpy)
