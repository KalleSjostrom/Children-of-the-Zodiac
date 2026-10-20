class_name Church
extends Building
## Port of store.Church: the church. In this building, the player can save
## the game, take the levels tutorial or be blessed (change class and get a
## random experience percentage). The priest is animated when blessing.

static var GREEN = Vector3f.new(0, 0.7, 0)
static var BLUE = Vector3f.new(0, 0, 0.7)
const BLESS_NAME_DISTANCE = 50
const BLESS_NAME_X = 50
const BLESS_NAME_Y = 400
const BLESS_NOT_ACTIVE = -1
const BLESS_LOW_HAND = 0
const BLESS_HIGH_HAND = 1
const BLESS_MODE_ANIMATE = 2
const BLESS_DONE = 3
const LOWEST_UPPER_BOUND = 250
const BLESS_SCALE = 1000.0
const BLESS_MOVE_SPEED = 10
const BLESS_COST_SPEED_LOW = 60 # 60 - Dellna
const BLESS_COST_SPEED_HIGH = 30 # 30
const NORMAL = -1
const LEVEL_TUTORIAL = 0
const BLESS_TUTORIAL = 1
var place = ""
var keeperName = ""
var images = [null, null, null]
var saving: bool = false
var blessMode: int = BLESS_NOT_ACTIVE
## Java: Church.mode (hides GameMode.mode).
var mode_: int = NORMAL
static var map = createMap()
static var testInfo = null
var handLow = MenuHand.new(Values.DOWN)
var handHigh = MenuHand.new(Values.DOWN)
var percents = null
var currentPair = null
var levelTutorial = null
var blessTutorial = null
var text = null
var handAnim = null
const MAX_SPEED = 0.1
var speed: float = MAX_SPEED
var interval: float = 0.0
var counter: int = 0
var totalCost: int = 0


## Initiates the church with the given information map.
func init(info, lab = null, hinders = null):
	super.init(info)
	if info == null:
		info = testInfo
	place = info.get("villageName")

	keeperName = str(info.get("keeper")).replace(".png", "")
	loadFromInfo(info, keeperName + "0.png")
	activeNode = MenuNode.new(null, "Church")
	fillRoot()
	setStoreImages(CHURCH)
	setMenuImagesUsed(0x000000ff)
	loadAnimImages()

	logicLoading = false


static func createMap():
	var m: Dictionary = {}
	m["Alares"] = 2
	m["Zazo"] = 3
	m["Pensara - The School District"] = 4
	m["Berca"] = 5
	m["Dellna"] = 6
	return m


func getClass(place):
	return map.get(place)


## Loads all the images of the priest. Used when animating.
func loadAnimImages():
	images[0] = keeper
	images[1] = ImageHandler.addToCurrentLoadOnUse(
			Values.StoreImages + keeperName + "1.png")
	images[2] = ImageHandler.addToCurrentLoadOnUse(
			Values.StoreImages + keeperName + "2.png")


## Java has update(long) (never called by the Organizer, which calls
## update(float)) and update(float); only the latter is ported.
func update(elapsedTime: float):
	if blessMode == BLESS_MODE_ANIMATE:
		handAnim.setXpos(180 - 28 + currentPair.getHand(interval))
		interval += speed
		speed *= 0.95
		if absf(speed) < 0.001:
			counter += 1
			speed = 0.0
			if counter > 15:
				currentPair.setHigh(interval)
				currentPair.setLow(interval)
				setCurrentPair(activeNode.getMenuCursor() + 1)
				super.update(elapsedTime)
				return
		if interval >= currentPair.getHigh():
			speed = -speed
			interval = currentPair.getHigh()
		elif interval <= currentPair.getLow():
			speed = -speed
			interval = currentPair.getLow()
	super.update(elapsedTime)


func rightPressed():
	addToPair(blessMode, BLESS_MOVE_SPEED, BLESS_COST_SPEED_LOW, BLESS_COST_SPEED_HIGH)


func leftPressed():
	addToPair(blessMode, -BLESS_MOVE_SPEED, -BLESS_COST_SPEED_LOW, -BLESS_COST_SPEED_HIGH)


func addToPair(type, speed, costSpeedLow, costSpeedHigh):
	if blessMode == BLESS_LOW_HAND or blessMode == BLESS_HIGH_HAND:
		var pair = getPair()
		if pair != null:
			if blessMode == BLESS_LOW_HAND:
				var tempLow: int = pair.low + speed
				if tempLow >= 0 and tempLow <= pair.high:
					pair.low = tempLow
					pair.cost += costSpeedLow
			elif blessMode == BLESS_HIGH_HAND:
				var tempHigh: int = pair.high + speed
				if tempHigh >= maxi(pair.low, LOWEST_UPPER_BOUND) and tempHigh <= BLESS_SCALE:
					pair.high = tempHigh
					pair.cost += costSpeedHigh


## Java overloads: getPair() (pair of the current menu cursor) and
## getPair(int i).
func getPair(i = null):
	if i == null:
		i = activeNode.getMenuCursor()
	var l = Load.getCharacters()
	var pair = null
	if i < l.size():
		var cname = l[i].getName()
		pair = percents.get(cname)
	return pair


## Moves the hand to the previous child in the current menu.
func upPressed():
	if not saving:
		activeNode.previousChild()


## Moves the hand to the next child in the current menu.
func downPressed():
	if not saving:
		activeNode.nextChild()


## Backs one step in the menu; if the root has been reached the building is
## exited.
func circlePressed():
	if not saving and blessMode != BLESS_MODE_ANIMATE:
		blessMode = BLESS_NOT_ACTIVE
		var n = activeNode.getParent()
		if n != null:
			activeNode = n
			makeDefaultDialog()
			keeper = images[0]
		else:
			exit(Values.SWITCH_BACK)


## Takes the name of the node pressed, and executes different commands.
func crossPressed():
	if mode_ == NORMAL:
		crossPressedInNormalMode()
	elif mode_ == LEVEL_TUTORIAL:
		if levelTutorial.crossedPressed():
			mode_ = NORMAL
	elif mode_ == BLESS_TUTORIAL:
		if blessTutorial != null and blessTutorial.crossedPressed():
			mode_ = NORMAL
			activateBlessPage(activeNode.getCurrentChild())


func crossPressedInNormalMode():
	if not saving:
		var n = activeNode.getCurrentChild()
		if not n.isEnabled():
			return
		var choice: String = n.getName()
		if choice == "Save":
			activeNode = n
			initSaveMenu()
		elif choice == "Tutorial - Levels":
			levelTutorial = Tutorial.new("churchlevels", true)
			if levelTutorial.increment():
				mode_ = LEVEL_TUTORIAL
				levelTutorial.setActive(true)
		elif choice == "Resurrect":
			activeNode = n
			initResurrectMenu()
		elif choice == "Bless":
			blessTutorial = Tutorial.new("churchbless", false)
			if blessTutorial.increment():
				mode_ = BLESS_TUTORIAL
				blessTutorial.setActive(true)
			else:
				activateBlessPage(n)
		elif choice == "Exit":
			exit(Values.SWITCH_BACK)
		elif choice.contains("Slot"):
			makeNewDialog("Saving.", "")
			saving = true
			_saveThread(choice)
		elif choice == "Back":
			circlePressed()
		elif choice == "Done":
			if Load.getPartyItems().getGold() >= totalCost:
				Load.getPartyItems().addGold(-totalCost)
				handAnim = MenuHand.new(Values.DOWN)
				setCurrentPair(0)
				blessMode = BLESS_MODE_ANIMATE
				var s: String = str(place) + "blessing"
				Database.addStatus(s, 1)
			else:
				SoundPlayer.playSound(SoundMap.MENU_ERROR)
		else:
			if blessMode == BLESS_HIGH_HAND or blessMode == BLESS_LOW_HAND:
				var bm: int = absi(blessMode - 1)
				switchBlessMode(bm)
			else:
				SoundPlayer.playSound(SoundMap.MENU_ERROR)


## Java: the saving thread (run as a coroutine; call without await).
func _saveThread(c: String) -> void:
	await Scheduler.sleep(500)
	makeNewDialog("Saving..", "")
	await Scheduler.sleep(500)
	makeNewDialog("Saving...", "")
	await Scheduler.sleep(500)
	Save.getSave().saveGame(c, place)
	saving = false
	circlePressed()
	makeNewDialog("Game saved!", "Anything else?")


func activateBlessPage(n):
	activeNode = n
	fillBless()
	blessMode = BLESS_HIGH_HAND
	switchBlessMode(BLESS_LOW_HAND)
	text = HelpText.new("bless", 50, 50)
	if percents == null:
		percents = {}
		var l = Load.getCharacters()
		for c in l:
			percents[c.getName()] = PercentPair.new(0, LOWEST_UPPER_BOUND)


func setCurrentPair(index):
	var l = Load.getCharacters()
	counter = 0
	activeNode.setMenuCursor(index)
	if index < l.size():
		currentPair = percents.get(l[index].getName())
		interval = currentPair.getRandomInterval()
		speed = MAX_SPEED if J.random() >= 0.5 else -MAX_SPEED
	else:
		blessMode = BLESS_DONE
		activeNode.getCurrentChild().setEnabled(false)
		var newClass = getClass(place)
		var list = Load.getCharacters()
		for i in range(list.size()):
			list[i].setClass(newClass)
		for i in range(list.size()):
			var p = getPair(i)
			var c = list[i]
			c.setExpPercentOfNext(p.getLow())
			c.curePercent(1)
		activeNode.setEnabled(false)


func switchBlessMode(newBlessMode):
	if blessMode == BLESS_LOW_HAND:
		handLow.setDimmed(true)
		handHigh.setDimmed(false)
	elif blessMode == BLESS_HIGH_HAND:
		handLow.setDimmed(false)
		handHigh.setDimmed(true)
	blessMode = newBlessMode


func keeperHeight():
	return 105


## Creates the save menu. It changes the default dialog.
func initSaveMenu():
	fillSave()
	makeNewDialog("Which slot do you wish to use?", "")


## Creates the resurrect menu. It changes the default dialog.
func initResurrectMenu():
	if fillResurrect():
		makeNewDialog("Who do you wish do resurrect?", "")
	else:
		makeNewDialog("There are no partymembers in need of resurrection.", "")


## Draws the church.
func draw3D(g3D):
	var g = g3D
	if blessMode != BLESS_NOT_ACTIVE and mode_ != BLESS_TUTORIAL:
		AbstractPage.drawMenuBackgroundStatic(g, 6)
		AbstractPage.drawMenuBackgroundStatic(g, 5)
		var barDist: int = -20
		var barX: int = 180
		var costX: int = 560
		var active: int = activeNode.getMenuCursor()
		var cs = Load.getCharacters()
		g.drawStringSetSize("Cost", costX, BLESS_NAME_Y - 40, 30)
		totalCost = 0
		for i in range(cs.size()):
			var c = cs[i]
			var pair = percents.get(c.getName())
			var y: int = BLESS_NAME_Y + i * BLESS_NAME_DISTANCE
			g.drawStringSetSize(pair.getCost(), costX, y, 26)
			totalCost += pair.cost
			LevelUpBar.drawStatic(g, barX, y + barDist, pair.getLow(), pair.getHigh(), 1.7)
			if i == active:
				if blessMode == BLESS_MODE_ANIMATE:
					handAnim.setYpos(y + barDist - 30)
					handAnim.drawHand(g)
				else:
					handLow.setXpos(barX - 28 + pair.getLowHand())
					handLow.setYpos(y + barDist - 30)
					drawHand(g, handLow, BLUE)

					handHigh.setXpos(barX - 28 + pair.getHighHand())
					handHigh.setYpos(y + barDist - 30)

					drawHand(g, handHigh, GREEN)
					g.setColor(1)
		text.drawTopLayer(g)

		var ty: int = BLESS_NAME_Y + (cs.size() + 1) * BLESS_NAME_DISTANCE
		g.drawString("Total cost: ", costX - 120, ty)
		g.drawString(str(totalCost) + " gp", costX, ty)
		g.setFontSize(26)
		activeNode.drawAllChildren(g)
		g.setFontSize(MenuValues.MENU_FONT_SIZE)

		AbstractPage.drawMenuBackgroundStatic(g, 3)
		var x: int = MenuValues.MENU_TEXT_X
		g.drawString("Gold: " + str(Load.getPartyItems().getGold()) + " gp", x, 648)
		g.drawString("Steps: " + str(Load.getPartyItems().getSteps()), x, 689)
		g.drawString("Time: " + str(Load.getTime().getHours()) + ":" + str(Load.getTime().getMin()), x, 730)
		drawHelp(g)
	else:
		activeNode.drawAllChildren(g)
		if activeNode.getName() == "Save":
			SaveSlots.draw_dates_under(g, activeNode, MenuValues.MENU_FONT_SIZE)
	var n = activeNode.getParent()
	if n != null and activeNode.getName() == "Bless":
		n.drawChildren(g)
	var title = activeNode.getName()
	g.drawString(title, MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)
	if levelTutorial != null:
		levelTutorial.drawTopLayer(g)
	if blessTutorial != null:
		blessTutorial.drawTopLayer(g)


func drawHand(g, hand, v):
	if hand.isDimmed():
		hand.drawHand(g)
	else:
		g.setColor(1)
		hand.drawHandWithColor(g)
		g.setColor(v, 0.3)
		hand.drawHandWithColor(g)


func drawHelp(g):
	var helpx: int = 90
	var step: int = 195
	var helpy: int = 720
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.UP_DOWN], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.LEFT_RIGHT], helpxicons + step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + 2 * step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 3 * step, helpyicons)

	g.drawString("Select", helpx + 7, helpy)
	g.drawString("Move marker", helpx + step + 7, helpy)
	g.drawString("Switch marker", helpx + 2 * step - 7, helpy)
	g.drawString("Back", helpx + 3 * step - 7, helpy)


## Fills the root menu.
func fillRoot():
	var n = activeNode
	n.insertChild("Save")
	n.insertChild("Bless").setEnabled(canBeBlessed())
	n.insertChild("Tutorial - Levels")
	n.insertChild("Exit")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


func canBeBlessed():
	var s: String = str(place) + "blessing"
	return Database.getStatusFor(s) == -1


## Fills the save menu.
func fillSave():
	var n = activeNode
	n.removeChildren(true)
	if not n.hasChildren():
		for slot in SaveSlots.MANUAL:
			n.insertChild(slot)
		n.insertChild("Back")
		n.setDistance(SaveSlots.MENU_DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


## Fills the resurrect menu. Returns true if there is any character in need
## of resurrection.
func fillResurrect():
	var n = activeNode
	n.removeChildren(true)
	for i in range(Load.getCharacters().size()):
		var c = Load.getCharacters()[i]
		if not c.isAlive():
			n.insertChild(c.getName()).setPrice(200)
	n.insertChild("Back")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	return n.getSize() - 1 != 0


func fillBless():
	var n = activeNode
	n.removeChildren(true)
	for i in range(Load.getCharacters().size()):
		var c = Load.getCharacters()[i]
		n.insertChild(c.getName())
	n.insertChild("Done")
	n.insertChild("Back")
	n.setDistance(BLESS_NAME_DISTANCE)
	n.setPositions(BLESS_NAME_X, BLESS_NAME_Y)
	changeInput([GameMode.LEFT, GameMode.RIGHT], Values.DETECT_ALL)
	return n.getSize() - 1 != 0


static func setTestMap(info):
	testInfo = info


class PercentPair extends RefCounted:
	var low: int = 0
	var high: int = 0
	var cost: int = 0

	func _init(low = null, high = null) -> void:
		self.low = int(low)
		self.high = int(high)

	func setHigh(h):
		high = J.round(h * BLESS_SCALE)

	func setLow(l):
		low = J.round(l * BLESS_SCALE)

	func getRandomInterval():
		return J.round(low + (high - low) * J.random()) / BLESS_SCALE

	func getLowHand():
		return J.round(getLow() * 340)

	func getHand(v):
		return J.round(v * 340)

	func getHighHand():
		return J.round(getHigh() * 340)

	func getLow():
		return low / BLESS_SCALE

	func getHigh():
		return high / BLESS_SCALE

	func getCost():
		return str(cost) + " gp"
