class_name StartPage
extends AbstractPage
## Port of menu.StartPage: the first page that will show when the player
## enters the menu. In this menu, the player can choose to check the decks and
## equipment of the characters, check the items, read the tutorials, check the
## labyrinth map and save the game. A screenshot of the screen before the menu
## was entered is shown in thumbnail size.

static var frame = ""
static var miniScreenShot = null
const EQUIP_PAGE_ = 0
const DECK_PAGE_ = 1

var parentNode = null
var displayParent: bool = false
var saving: bool = false
var selectedMode: int = -1
var savingString = ""


## Creates the start page. im is the thumbnail sized screenshot (an Image or
## null) and menuIndex the index where the menu hand should start.
func _init(im = null, menuIndex = null) -> void:
	miniScreenShot = im
	activeNode = MenuNode.new(null, "Main")
	activeNode.setDistance(MenuValues.DISTANCE)
	activeNode.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	activeNode.setMenuCursor(menuIndex)
	loadImages()
	fillRoot()
	setPage(START_PAGE)


## Loads the images used on this page.
func loadImages():
	frame = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "frame.png")


## Moves the menu hand one step upwards in the active menu.
func upPressed():
	if not saving:
		activeNode.previousChild()


## Moves the menu hand one step downwards in the active menu.
func downPressed(playSound = null):
	if not saving:
		activeNode.nextChild()


## Activates the current node in the menu tree and executes it.
func crossPressed(playSound = null):
	if not saving and activeNode.hasChildren():
		var n = activeNode.getCurrentChild()
		if n.isEnabled():
			activeNode = n
			activeNode.setActive(true)
			parentNode = activeNode.getParent()
			parentNode.setActive(false)
			displayParent = false
			var name: String = activeNode.getName()
			if not name.contains("Slot"):
				SoundPlayer.playSound(SoundMap.ACCEPT)
			executeNode(name)
		else:
			SoundPlayer.playSound(SoundMap.ERROR)


## Backs one step in the menu tree. If the active node is the root, the menu
## is exited and the previous mode is resumed.
func circlePressed(pressAnyWay = null):
	if pressAnyWay == null:
		pressAnyWay = false
	if pressAnyWay or not saving:
		var n = activeNode.getParent()
		if n != null:
			activeNode = MenuNode.switchNode(activeNode, n)
			parentNode = activeNode
		else:
			MainMenu.getMainMenu().exit()


## Executes different methods depending on which node that should be
## executed. Called right after the player has chosen a node.
func executeNode(name):
	if name == "Deck":
		fillCharacter()
		displayParent = true
		selectedMode = DECK_PAGE_
	elif name == "Equip":
		fillCharacter()
		displayParent = true
		selectedMode = EQUIP_PAGE_
	elif name == "Key Items":
		fillItems()
	elif name == "Tutorial":
		MainMenu.getMainMenu().initTutorialPage()
	elif name == "Options":
		MainMenu.getMainMenu().initHelpPage()
	elif name == "Load":
		fillLoad()
	elif name.contains("Save"):
		fillLoad()
	elif name.contains("Slot"):
		var save: bool = activeNode.getParent().getName() == "Save"
		if save:
			var prev = Organizer.getOrganizer().getPreviousMode()
			var mainName: String = prev.getName()
			if prev is Labyrinth:
				mainName += "-save"
			elif prev is Landscape:
				mainName = "land" + mainName
			elif prev is AirLandscape:
				mainName = "air" + mainName
			var finalMainName: String = mainName
			var finalName: String = name
			savingString = "Saving.  "
			saving = true
			var t = MainMenu.getMainMenu()
			SoundPlayer.playSound(SoundMap.MENU_SAVE)
			# Java: a thread that sleeps 3 x 500 ms and then saves.
			circlePressed(true)
			Scheduler.after(500, func():
				savingString = "Saving.. "
				Scheduler.after(500, func():
					savingString = "Saving..."
					Scheduler.after(500, func():
						Save.getSave().saveGame(finalName, finalMainName)
						saving = false
						t.unLockInput())))
		else:
			Load.loadGame(name)
			MainMenu.getMainMenu().exitTo(Load.getStartLocation())
	elif name == "":
		if selectedMode == DECK_PAGE_:
			MainMenu.getMainMenu().initDeckPage(
					activeNode.getParent().getMenuCursor(), -1, null)
		elif selectedMode == EQUIP_PAGE_:
			MainMenu.getMainMenu().initEquipPage(
					activeNode.getParent().getMenuCursor(), 0, false)
	elif name.contains("Map"):
		MainMenu.getMainMenu().initMapPage()


## Fills the root menu.
func fillRoot(resetCursor = null):
	activeNode.insertChild("Deck")
	activeNode.insertChild("Equip")
	activeNode.insertChild("Key Items")
	activeNode.insertChild("Tutorial")
	activeNode.insertChild("Options")
	activeNode.insertChild("Map").setEnabled(
			Database.getVisitedLabyrinths().size() > 0)
	var gm = Organizer.getOrganizer().getPreviousMode()
	var isOnSave := false
	if gm is Labyrinth:
		var lab = gm
		var inv = lab.getCurrentNode().getInventory()
		if inv != null:
			isOnSave = inv is InventorySave
	else:
		isOnSave = true
	if true: # isOnSave) {
		activeNode.insertChild("Save")
	else:
		activeNode.insertChild("Load")


## Fills the character menu.
func fillCharacter():
	var list: Array = []
	for i in range(Load.getCharacters().size()):
		list.append("")
	fillMenu(list, MenuValues.CHARACTER_DISTANCE, 50, 105)


func fillItems():
	var n = activeNode
	n.removeChildren(true)
	for i in range(Load.getPartyItems().itemSize()):
		var item = Load.getPartyItems().getItem(i)
		var child = n.insertChild(item.getName())
		child.addNumber(item.getNr())
		child.setEnabled(false)
	n.setDisableColor(JColor.black)
	n.setStandardWithBB()


## Fills the load menu.
func fillLoad():
	var list: Array = []
	list.append("Slot 1")
	list.append("Slot 2")
	list.append("Slot 3")
	fillMenu(list)


## Inserts the elements in the list as children to the activeNode, using the
## given distance between the children and x, y as position of the menu
## (default: the standard menu position).
func fillMenu(list, dist = null, x = null, y = null):
	if dist == null:
		fillMenu(list, MenuValues.DISTANCE, MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
		return
	var n = activeNode
	n.removeChildren(true)
	for i in range(list.size()):
		n.insertChild(list[i])
	n.setDistance(dist)
	n.setPositions(x, y)


## Draws the start page on the given graphics.
func draw3D(g):
	drawStandard(g)
	if displayParent:
		parentNode.drawAllChildren(g)
	else:
		activeNode.drawChildrenFreely(g, false, true, true, false, false)
	var title = activeNode.getName()
	var x: int = MenuValues.MENU_TEXT_X
	g.drawString(title, x, MenuValues.MENU_TITLE_Y)

	for i in range(Load.getCharacters().size()):
		var d: int = MenuValues.CHARACTER_DISTANCE * i
		var c = Load.getCharacters()[i]
		StatusPage.drawTop(g, c, d)
	drawScreenShot(g)
	drawInfo(g)
	if saving:
		drawConfirmBuyDialog(g)


func drawConfirmBuyDialog(g):
	g.drawCenteredImage(Values.MenuImages + "Pieces/1.png", 300)
	g.drawString(savingString, 470, 347)


## Draws the screen shot miniature on the given graphics.
static func drawScreenShot(g):
	g.drawImage(miniScreenShot, MenuValues.MENU_TEXT_X, 428)
	g.drawImage(frame, MenuValues.MENU_TEXT_X, 428)


## Draws the amount of gold, the number of steps taken and the time that the
## player has played the game.
static func drawInfo(g):
	var x: int = MenuValues.MENU_TEXT_X
	g.drawString("Gold: " + str(Load.getPartyItems().getGold()) + " gp", x, 648)
	g.drawString("Steps: " + str(Load.getPartyItems().getSteps()), x, 689)
	g.drawString("Time: " + str(Load.getTime().getHours()) + ":" + str(Load.getTime().getMin()), x, 730)
