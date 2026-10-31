class_name TutorialPage
extends AbstractPage
## Port of menu.TutorialPage: the page in the menu where the player can read
## the tutorials that have been shown so far.

static var list = createList()
static var map = createMap()
const NORMAL = 0
const TUTORIAL = 1
var mode: int = NORMAL
var tutorial = null

func _init() -> void:
	activeNode = MenuNode.new(null, "Tutorial")
	fillRoot(true)
	activeNode.setMenuCursor(0)
	setPage(START_PAGE)


static func createList():
	var l: Array = []
	l.append("Battle - Basic")
	l.append("Battle - Cards & Slots")
	l.append("Battle - Battle Modes")
	l.append("Battle - Elements")
	l.append("Levels")
	l.append("Bless")
	l.append("Equipment & Slots")
	l.append("Cards")
	l.append("Decks")
	return l


static func createMap():
	var m: Dictionary = {}
	m["Battle - Basic"] = "forest of reil--forest path"
	m["Battle - Cards & Slots"] = "forest of reil--deep forest"
	m["Battle - Battle Modes"] = "grivera--first floor"
	m["Battle - Elements"] = "elements"
	m["Levels"] = "churchlevels"
	m["Bless"] = "churchbless"
	m["Equipment & Slots"] = "weaponstore"
	m["Cards"] = "cardstore"
	m["Decks"] = "deck"
	return m


func fillRoot(resetCursor = null):
	var n = activeNode
	n.removeChildren(resetCursor)

	for s in list:
		if Database.getStatusFor(str(map.get(s)) + ".tut") == 2:
			n.insertChild(s)

	n.insertChild("Back")
	n.setStandardWithBB()
	n.updateHandPos()


func upPressed():
	if mode == NORMAL:
		activeNode.previousChild()


func downPressed(playSound = null):
	if mode == NORMAL:
		activeNode.nextChild()


func circlePressed(pressAnyWay = null):
	if mode == NORMAL:
		MainMenu.getMainMenu().initStartPage(3)


func crossPressed(playSound = null):
	match mode:
		NORMAL:
			var command = activeNode.getCurrentChild().getName()
			if command == "Back":
				circlePressed()
			else:
				var s = map.get(command)
				tutorial = Tutorial.new(s, true)
				if tutorial.increment():
					mode = TUTORIAL
					tutorial.setActive(true)
		TUTORIAL:
			if tutorial.crossedPressed():
				mode = NORMAL


func selectPressed():
	# HELP
	pass


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): each part is
## shown by its node where it was drawn, or drawn with its --legacy flag
## (AbstractPage.draw_title, draw_list, StatusPage.draw_top,
## StartPage.draw_screen_shot, draw_info); the tutorial is phase 3's node.
func draw3D(g):
	drawStandard(g)
	AbstractPage.draw_title(g, activeNode.getName())
	AbstractPage.draw_list(g, activeNode, false, false, false, false, false)

	for i in range(Load.getCharacters().size()):
		var d: int = MenuValues.CHARACTER_DISTANCE * i
		var c = Load.getCharacters()[i]
		StatusPage.draw_top(g, c, d)
	StartPage.draw_screen_shot(g)
	StartPage.draw_info(g)

	if mode == TUTORIAL:
		tutorial.drawTopLayer(g)


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
	g.drawString("Choose", helpx + step, helpy)
	g.drawString("Back", helpx + 2 * step, helpy)
