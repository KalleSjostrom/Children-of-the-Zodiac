class_name MapPage
extends AbstractPage
## Port of menu.MapPage: shows the maps of the visited labyrinths.
##
## Port note: the Java private update() (refresh the shown map) and the
## inherited update(float elapsedTime) share update(elapsedTime = null):
## update() with no argument is the Java private method; with an argument it
## is the per-frame AbstractPage.update, which does nothing.

## Bridge (phase 4.2 step B): the node of _show_all and _show_single.
const AUTOMAP_VIEW := "res://scenes/ui/Automap.tscn"

var map = null
var lab = null
var currentFloors = null
var currentNode = null
static var mappiece = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "mappiece.png")
static var mappiece2 = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "mappiece2.png")
static var mappiece3 = _createMappiece3()
var floor = null
## Port addition (COTZ-012): opened with Square from the game: Square goes
## straight back to it, Circle from the whole labyrinth.
var shortcut := false
## Port addition: the labyrinth the page opens on (the player's, or the last
## one visited). Cross shows it on floor, any other on its first floor.
var homeLab = null


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
		homeLab = name
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
		zoomIn(false)
		if floor != null:
			activeNode.setCurrentChild(floor)
			update()
	else:
		var labInfo = Database.getLastVisitedLabyrinth()
		name = labInfo[0]
		homeLab = name
		floor = labInfo[1]
		activeNode.setCurrentChild(name)
		zoomIn(false)
		if floor != null:
			activeNode.setCurrentChild(floor)
			update()
	# Port change: the page opens on the whole labyrinth (every floor), with
	# the hand on it in the list of visited labyrinths, not on one floor
	# (Cross zooms in on that).
	if not isZoomedOut():
		zoomOut()
	setPage(BESTIARY_PAGE)


func getRootNode():
	var n = MenuNode.new(null, "Map")
	if not n.hasChildren():
		var list = Database.getVisitedLabyrinthsList()
		for i in range(list.size()):
			n.insertChild(list[i])
		n.setStandardWithBB()
	return n


## Zooms in from the whole labyrinth to one floor. On a floor it does
## nothing, as in Java (a floor is no labyrinth for zoomIn).
func crossPressed(playSound = null):
	if isZoomedOut():
		zoomIn()


## Down a level: from a labyrinth to its floors, one floor shown. Java's
## crossPressed (Java overloads crossPressed(), which plays the sound, and
## crossPressed(playSound)). upPressed, downPressed and _init also use it to
## load a labyrinth's floors.
func zoomIn(playSound = true):
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
		# Port change: only homeLab starts on floor. Java tried floor in every
		# labyrinth, but floor names repeat (Second Floor is in three).
		var f = floor if str(name).to_lower() == str(homeLab).to_lower() else null
		currentFloors = li.getFloors()
		for i in range(currentFloors.size()):
			n.insertChild(currentFloors[i].getName())
		n.setDistance(MenuValues.DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
		n.setCurrentChild(f)
		var found: bool = false
		var i: int = 0
		while i < currentFloors.size() and not found:
			# Java: floor.equals(...) (a null floor would throw there).
			found = f != null and f == currentFloors[i].getName()
			if found:
				map = currentFloors[i]
			i += 1
	activeNode = n


func upPressed():
	activeNode.previousChild()
	if isZoomedOut():
		update()
		zoomIn(false)
		zoomOut()
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
		zoomIn(false)
		zoomOut()
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


## Zooms out: from a floor to the whole labyrinth, then to the start page, or
## out of the menu when opened with Square.
func circlePressed(pressAnyWay = null):
	if shortcut and isZoomedOut():
		MainMenu.getMainMenu().exit()
	else:
		zoomOut()


## Up a level: to the labyrinths, then the start page. Java's circlePressed;
## upPressed, downPressed and _init use it too (also while _init looks for the
## labyrinth the player is in, COTZ-022), so it never leaves the menu.
func zoomOut():
	var n = activeNode.getParent()
	if n != null:
		activeNode = MenuNode.switchNode(activeNode, n)
		activeNode.updateHandPos()
	else:
		MainMenu.getMainMenu().initStartPage(5)


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): each part is
## shown by its node where it was drawn, or drawn with its --legacy flag
## (AbstractPage.draw_title, draw_list, _show_all and _show_single (the
## Automap node), AbstractPage.draw_help, _show_explored,
## StartPage.draw_screen_shot, draw_info).
func draw3D(g):
	super.drawStandard(g)
	AbstractPage.draw_title(g, activeNode.getName())
	AbstractPage.draw_list(g, activeNode, false, true, false, false, false)
	var percent: int = 0
	var automap: bool = not Main.is_legacy("automap")
	if isZoomedOut():
		percent = _show_all(g) if automap else drawAll(g)
		AbstractPage.draw_help(g, drawHelp.bind(true))
	else:
		percent = _show_single(g) if automap else drawSingle(g)
		AbstractPage.draw_help(g, drawHelp.bind(false))
	if Main.is_legacy("menu_text"):
		g.drawString("Explored: " + str(percent) + " %", 40, 50)
	else:
		_show_explored(g, percent)
	StartPage.draw_screen_shot(g)
	StartPage.draw_info(g)


## Bridge (phase 4.2 step B): "Explored: n %" without the drawing
## (drawString's setColor(color)); a MenuText node shows it.
func _show_explored(g, percent: int) -> void:
	var line := ["Explored: " + str(percent) + " %", Vector2i(40, 50), g.getFontSize(),
			Graphics.text_color(1.0), Graphics.font_bold(), HORIZONTAL_ALIGNMENT_LEFT]
	g.setColor(g.color)
	AbstractPage.show_lines(g, [line])


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


## Bridge (phase 4.2 step B): drawSingle without the drawing
## (LabyrinthMap.place_map), and the frame's next Automap node on the UI
## layer shows the floor (Graphics.show_ui).
func _show_single(g) -> int:
	var currentDir: int = -1
	if lab != null:
		currentDir = lab.getPlayerDirection()
	var mat = g.canvas_material()
	var floor: Dictionary = map.place_map(g, currentNode, currentDir, null, false, true)
	_show_automap(g, [floor], mat)
	return floor.percent


## Bridge (phase 4.2 step B): drawAll without the drawing: the same matrix
## calls (each floor's pieces placed through the modelview:
## LabyrinthMap.place_map), and the frame's next Automap node on the UI
## layer shows every floor (Graphics.show_ui).
func _show_all(g) -> int:
	var mat = g.canvas_material()
	var floors := []
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
		var floor: Dictionary = m.place_map(g, currentNode, currentDir, pos, true, false)
		percent += floor.percent
		floors.append(floor)
		g.pop()
	g.scale(3)
	g.pop()
	percent = J.round((percent / float(size)) * 100)
	_show_automap(g, floors, mat)
	return percent


static func _show_automap(g, floors: Array, mat) -> void:
	var view = g.show_ui(AUTOMAP_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_map(floors, mat)


func drawHelp(g, drawAll = null):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 720
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawString("Exit", helpx, helpy)
	# Port change: Cross (Zoom in, Java's Select) only on the whole labyrinth,
	# see crossPressed; on a floor Circle takes its place.
	if drawAll:
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons)
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons)
		g.drawString("Zoom in", helpx + step, helpy)
		g.drawString("Back" if shortcut else "To main menu", helpx + 2 * step, helpy)
	else:
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + step, helpyicons)
		g.drawString("Zoom out", helpx + step, helpy)
