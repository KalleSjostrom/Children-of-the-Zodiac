class_name Inn
extends AbstractStore
## Port of store.Inn: an Inn in a village. In the inn, the player can rest
## (fully curing the party) and trade the maps of fully explored labyrinths
## for prizes.

static var testInfo = null
var delay: bool = false
var menuMode: int = MENU
var currentLoot = null
static var SELL_MAP: int = BASE
static var SHOW_PRIZE: int = BASE + 1
const SELL_MAP_NAME = "Trade map info"
## Java: static final, created when the class loads. Created lazily here (in
## init) because Card.createCard needs other classes' static state.
static var prizes = null
const LAB_PRIZE_REDEEMED = 1

## Time (ms) when checkExit first saw this mode done with delay set; replaces
## the blocking Values.sleep(7000) of the original checkExit.
var _delayStart: int = -1


## Creates the inn from the map containing the information about the inn.
## See loadFromInfo() in Building.
func init(info, lab = null, hinders = null):
	if info == null:
		info = testInfo
	if prizes == null:
		prizes = createPrices()
	super.init(info)
	initStore()
	activeNode = MenuNode.new(null, "Inn")
	nextPlace = info.get("villageName")
	fillDay()
	loadFromInfo(info)
	if hasStoredTriggers():
		makeNewDialog("The first night is free!", "")
	setStoreImages(INN)
	setMenuImagesUsed(0x00000fff)

	logicLoading = false


## Updates the menu and checks the game input.
func update(elapsedTime: float):
	# While waiting for the delayed exit (Java blocked the main loop in
	# checkExit), no input is handled.
	if isDone() and delay:
		return
	super.update(elapsedTime)


func dirPressed(dir):
	if menuMode == SELL_MAP:
		dirMenuPressed(activeNode, dir)
	elif menuMode == MENU:
		dirMenuPressed(activeNode, dir)
	elif menuMode == CONFIRM_BUY:
		dirMenuPressed(confirmNode, dir)


## Called if the circle button has been pressed. It exits the inn.
func circlePressed():
	if menuMode == SELL_MAP:
		var n = activeNode.getParent()
		if n != null:
			setDialogCopyAsACurrent()
			activeNode = n
			menuMode = MENU
	elif menuMode == SHOW_PRIZE:
		menuMode = SELL_MAP
		currentLoot = null
	else:
		exit(Values.SWITCH_BACK)


## Called when the cross button is pressed. It executes the current node.
func crossPressed():
	var n = activeNode.getCurrentChild()
	var playerChoice: String = n.getName()
	if playerChoice == "Exit":
		exit(Values.SWITCH_BACK)
		return
	elif playerChoice == "Back":
		circlePressed()
		return
	elif playerChoice == SELL_MAP_NAME:
		var list: Array = getSellMapList()
		if list.size() > 0:
			copyDialog()
			makeNewDialog("Trade the maps you've fully explored for nice prizes!", "")
			menuMode = SELL_MAP
			activeNode = n
			activeNode.setActive(true)
			fillSellMap(list)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
		return
	var choice: String
	if menuMode == MENU:
		checkBuy(activeNode.getCurrentChild().getPrice())
		menuMode = CONFIRM_BUY
	elif menuMode == SHOW_PRIZE:
		menuMode = SELL_MAP
		currentLoot = null
	elif menuMode == SELL_MAP:
		var labName: String = activeNode.getCurrentChild().getName()
		currentLoot = prizes.get(labName)
		Database.addStatus(labName, LAB_PRIZE_REDEEMED)
		activeNode.getCurrentChild().setEnabled(false)
		Load.collectLoot(currentLoot)
		menuMode = SHOW_PRIZE
	elif menuMode == CONFIRM_BUY:
		n = confirmNode.getCurrentChild()
		choice = n.getName()
		if choice == "Call it a night":
			var price: int = activeNode.getCurrentChild().getPrice()
			Load.getPartyItems().addGold(-price)
			setMusicFadeOutSpeed(SoundValues.FAST)
			goToDay()
			var inn = self
			# Java: a thread sleeping 100 ms, then waiting for the music fade.
			Scheduler.after(100, func():
				Scheduler.waitUntil(func(): return not inn.isMusicFadingDown(),
						func(): SoundPlayer.playSound(SoundMap.VILLAGE_SLEEP)))
		confirmNode.setMenuCursor(0)
		menuMode = MENU


func getSellMapList():
	var exploredLabs: Array = []

	var labs = Database.getVisitedLabyrinths()
	var list = Database.getVisitedLabyrinthsList()
	for s in list:
		var info = labs.get(s)
		var b: bool = info.isFullyExplored()
		if b:
			var labName = info.getLabyrinthName()
			var status: int = Database.getStatusFor(labName)
			if status != LAB_PRIZE_REDEEMED:
				exploredLabs.append(labName)
	return exploredLabs


func fillSellMap(list):
	var n = activeNode
	n.removeChildren(true)
	if not n.hasChildren():
		for s in list:
			n.insertChild(s)
		n.insertChild("Back")
		n.setDistance(MenuValues.DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


## Loads the day.
func goToDay():
	for i in range(Load.getCharacters().size()):
		Load.getCharacters()[i].fullCure()
	if str(nextPlace).contains("night"):
		push_warning("The next place in Inn should not contain the word night")
	delay = checkStoredTriggers()
	if delay:
		return
	nextPlace = str(nextPlace).to_lower().replace(" ", "_")
	delay = true
	exit(Values.SWITCH_BACK)


## Java blocked the main loop for 7 s (Values.sleep(7000)) before returning
## the mode when delay was set; here the exit is postponed for 7 s instead.
func checkExit():
	if isDone():
		if delay:
			var now: int = J.currentTimeMillis()
			if _delayStart < 0:
				_delayStart = now
			if now - _delayStart < 7000:
				return Values.NO_MODE_IS_SELECTED
		return mode
	return Values.NO_MODE_IS_SELECTED


## Checks the stored triggers. If any is found with the name "inn" it will
## load the stored trigger instead of going to night or day.
func checkStoredTriggers():
	var tname: String = str(infoMap.get("villageName")) + "inn"
	var s = Database.getStoredTriggers(tname)
	if s != null:
		nextPlace = s
		Database.clearStoredTriggers(tname)
		exit(Values.VILLAGE_STORY)
	return s != null


func hasStoredTriggers():
	var tname: String = str(infoMap.get("villageName")) + "inn"
	var s = Database.getStoredTriggers(tname)
	return s != null


## Draws the inn.
func draw3D(g3D):
	var g = g3D
	var title = activeNode.getName()
	g.drawString(title, MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)
	StartPage.drawInfo(g)
	activeNode.drawChildrenFreely(g, true, false, false, false, false)
	if menuMode == CONFIRM_BUY:
		drawConfirmDialog(g, "Rent a room", activeNode.getCurrentChild().getPrice())
	elif menuMode == SHOW_PRIZE:
		Dialog.drawGiftStatic(g, "You got the a prize: " + str(currentLoot.getContentName()), "", currentLoot)


## Fills the menu to display when day time.
func fillDay():
	var price: int = 0 if hasStoredTriggers() else 50
	var n = activeNode
	n.insertChild("Rest").setPrice(price)
	var list: Array = getSellMapList()
	var smn = n.insertChild(SELL_MAP_NAME)
	smn.setEnabled(list.size() > 0)

	var maxY: int = MenuValues.MENU_TEXT_Y + 3 * MenuValues.DISTANCE
	smn.setBoundingBox(MenuValues.MENU_TEXT_Y, maxY, 978)

	n.insertChild("Exit")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


static func setTestMap(info):
	testInfo = info


func fillPositiveConfirm(n):
	n.insertChild("Call it a night")


static func createPrices():
	var prices: Dictionary = {}

	var reilCard = Card.createCard("cards.magic.Wind", 2, false, Slot.MAGIC, 200)
	var reilLoot = Loot.new("Earth", Loot.CARD, reilCard)
	reilLoot.setContentName("Earth")
	prices["Forest of Reil"] = reilLoot

	var griveraCard = Card.createCard("cards.offense.CriticalBlow", 2, true, Slot.ATTACK, 2000)
	var griveraLoot = Loot.new("Critical Blow", Loot.CARD, griveraCard)
	griveraLoot.setContentName("Critical Blow")
	prices["Grivera"] = griveraLoot

	var centralCard = Card.createCard("cards.magic.Fire", 2, false, Slot.MAGIC, 2000)
	var centralLoot = Loot.new("Fire", Loot.CARD, centralCard)
	centralLoot.setContentName("Fire")
	prices["Central Pass"] = centralLoot

	# TODO: Which slot type? Doesn't matter.
	var greatCard = Card.createCard("cards.neutral.TheElementOfIce", 1, true, 1, 2000)
	var greatLoot = Loot.new("Ice Element", Loot.CARD, greatCard)
	greatLoot.setContentName("Ice Element")
	prices["The Great Mine"] = greatLoot

	var eastCard = Card.createCard("cards.offense.BattleCard", 2, false, Slot.ATTACK, 2000)
	var eastLoot = Loot.new("Battle Card", Loot.CARD, eastCard)
	eastLoot.setContentName("Battle Card")
	prices["East Passage"] = eastLoot

	var briCard = Card.createCard("cards.support.Focus", 1, true, Slot.SUPPORT, 2000)
	var briLoot = Loot.new("Focus", Loot.CARD, briCard)
	briLoot.setContentName("Focus")
	prices["Forest of Bri"] = briLoot

	var cesadurCard = Card.createCard("cards.offense.ChameleonStrike", 1, false, Slot.ATTACK, 0)
	var cesadurLoot = Loot.new("Chameleon Strike", Loot.CARD, cesadurCard)
	cesadurLoot.setContentName("Chameleon Strike")
	prices["Mt. Cesadur"] = cesadurLoot

	var pensaraCard = Card.createCard("cards.support.Fungi", 1, true, Slot.SUPPORT, 0)
	var pensaraLoot = Loot.new("Fungi", Loot.CARD, pensaraCard)
	pensaraLoot.setContentName("Fungi")
	prices["Pensara Forest"] = pensaraLoot

	var fireCard = Card.createCard("cards.magic.Earth", 3, false, Slot.MAGIC, 0)
	var fireLoot = Loot.new("Earth", Loot.CARD, fireCard)
	fireLoot.setContentName("Earth")
	prices["Fire Cavern"] = fireLoot

	var prisonCard = Card.createCard("cards.offense.SpiritAssault", 1, false, Slot.ATTACK, 0)
	var prisonLoot = Loot.new("Spirit Assault", Loot.CARD, prisonCard)
	prisonLoot.setContentName("Spirit Assault")
	prices["Pensara Prison"] = prisonLoot

	var dormaCard = Card.createCard("cards.support.HerbOfVitality", 1, true, Slot.SUPPORT, 0)
	var dormaLoot = Loot.new("Herb of Vitality", Loot.CARD, dormaCard)
	dormaLoot.setContentName("Herb of Vitality")
	prices["Dorma's Forest"] = dormaLoot

	var desertCard = Card.createCard("cards.offense.CrushingSaber", 3, true, Slot.ATTACK, 0)
	var desertLoot = Loot.new("Crushing Saber", Loot.CARD, desertCard)
	desertLoot.setContentName("Crushing Saber")
	prices["Berca Desert"] = desertLoot

	var sewersCard = Card.createCard("cards.magic.Flare", 1, false, Slot.MAGIC, 0)
	var sewersLoot = Loot.new("Flare", Loot.CARD, sewersCard)
	sewersLoot.setContentName("Flare")
	prices["The Sewers"] = sewersLoot

	var aegisCard = Card.createCard("cards.magic.Death", 1, true, Slot.MAGIC, 0)
	var aegisLoot = Loot.new("Death", Loot.CARD, aegisCard)
	aegisLoot.setContentName("Death")
	prices["Temple of Aegis"] = aegisLoot

	var frozenCard = Card.createCard("cards.support.Resurrect", 3, false, Slot.SUPPORT, 0)
	var frozenLoot = Loot.new("Resurrect", Loot.CARD, frozenCard)
	aegisLoot.setContentName("Resurrect") # (sic) as in the original
	prices["Frozen Forest"] = frozenLoot

	var iceCard = Card.createCard("cards.magic.SacredBeam", 3, false, Slot.MAGIC, 0)
	var iceLoot = Loot.new("Sacred Beam", Loot.CARD, iceCard)
	iceLoot.setContentName("Sacred Beam")
	prices["Ice Cavern"] = iceLoot

	var empyrianCard = Card.createCard("cards.magic.Ultima", 1, true, Slot.MAGIC, 0)
	var empyrianLoot = Loot.new("Ultima", Loot.CARD, empyrianCard)
	empyrianLoot.setContentName("Ultima")
	prices["Empyrian Temple"] = empyrianLoot

	var menthuCard = Card.createCard("cards.support.Resurrect", 3, true, Slot.SUPPORT, 0)
	var menthuLoot = Loot.new("Resurrect", Loot.CARD, menthuCard)
	menthuLoot.setContentName("Resurrect")
	prices["Menthu's Lair"] = menthuLoot
	return prices
