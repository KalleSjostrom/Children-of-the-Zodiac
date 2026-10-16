class_name WeaponStore
extends AbstractStore
## Port of store.WeaponStore: a weapon shop in a village. In a weapon shop the
## player can buy or sell weapons, shields or armors. It uses the static
## methods of the equip page, in the menu, to draw parts of the store.

const NO_MODE = -1
static var testInfo = null
var currentCharacter = null
var storeName = ""
var stack: Array = []
var equipment = null
var current = null
## Java: WeaponStore.mode (hides GameMode.mode).
var mode_: int = NO_MODE
var menuMode: int = MENU
var equipped: int = 0
var total: int = 0
var tutorial = null
const RIGHT_HAND = "Weapons"
const LEFT_HAND = "Accessories"
const BODY = "Armors"


## Initiates the weapon store with the given information map.
func init(info, lab = null, hinders = null):
	if info == null:
		info = testInfo
	super.init(info)
	initStore()
	storeName = info.get("storeName")
	loadFromInfo(info)
	activeNode = MenuNode.new(null, "Weapon Store")
	fillRoot()
	setStoreImages(WEAPON_STORE)
	setMenuImagesUsed(0x000000ff)
	stack.append(MENU)

	logicLoading = false


## Called when the player presses a directional button. Depending on the
## state of the store, it moves the hand in the current menu.
func dirPressed(dir):
	if menuMode == BUY or menuMode == SELL:
		dirMenuPressed(activeNode, dir)
		updateCurrent()
	elif menuMode == MENU:
		dirMenuPressed(activeNode, dir)
	elif menuMode == CONFIRM_BUY or menuMode == CONFIRM_SELL:
		dirMenuPressed(confirmNode, dir)


## Called when the player presses the cross button.
func crossPressed():
	var n = activeNode.getCurrentChild()
	var choice: String = n.getName()
	var newMode: int = menuMode
	var back: bool = false

	if choice == "Back":
		circlePressed()
	elif choice == "Tutorial - Equipment":
		if menuMode == TUTORIAL:
			if tutorial.crossedPressed():
				menuMode = stack.pop_back()
		else:
			tutorial = Tutorial.new("weaponstore", true)
			if tutorial.increment():
				changeMenuMode(TUTORIAL)
				tutorial.setActive(true)
	elif choice == "Exit":
		exit(Values.SWITCH_BACK)
	else:
		if menuMode == MENU:
			if choice == "Buy":
				activeNode = MenuNode.switchNode(activeNode, n)
				fillBuy()
				newMode = BUY
			elif choice == "Sell":
				activeNode = MenuNode.switchNode(activeNode, n)
				fillSell()
				newMode = SELL
			elif choice == "Exit":
				exit(Values.SWITCH_BACK)
		elif menuMode == BUY:
			if choice == RIGHT_HAND:
				initiateEquipMenu(n, EquipPage.RIGHT_HAND)
			elif choice == LEFT_HAND:
				initiateEquipMenu(n, EquipPage.LEFT_HAND)
			elif choice == BODY:
				initiateEquipMenu(n, EquipPage.ARMORS)
			else:
				checkBuy(activeNode.getCurrentChild(), current)
				newMode = CONFIRM_BUY
		elif menuMode == SELL:
			if choice == RIGHT_HAND:
				initiateEquipMenu(n, EquipPage.RIGHT_HAND)
			elif choice == LEFT_HAND:
				initiateEquipMenu(n, EquipPage.LEFT_HAND)
			elif choice == BODY:
				initiateEquipMenu(n, EquipPage.ARMORS)
			else:
				confirmSell()
				newMode = CONFIRM_SELL
		elif menuMode == CONFIRM_BUY:
			var price: int = activeNode.getCurrentChild().getPrice()
			choice = confirmNode.getCurrentChild().getName()
			if choice.begins_with("Equip"):
				Load.getPartyItems().addGold(-price)
				currentCharacter.equip(current, true)
				Load.addEquipment(current)
				updateCurrent()
			elif choice.begins_with("Put"):
				Load.getPartyItems().addGold(-price)
				Load.addEquipment(current)
				updateCurrent()
			back = true
			confirmNode.setMenuCursor(0)
			menuMode = stack.pop_back()
		elif menuMode == CONFIRM_SELL:
			var price: int = activeNode.getCurrentChild().getPrice()
			choice = confirmNode.getCurrentChild().getName()
			if choice == "Sell":
				Load.getPartyItems().addGold(price)
				Load.removeEquipment(activeNode.getCurrentChild().getName())
			confirmNode.setMenuCursor(0)
			back = true
			menuMode = stack.pop_back()
			circlePressed()
			crossPressed()
		if not back:
			changeMenuMode(newMode)


## Changes the menu mode to the given mode, pushing the current menu mode on
## the stack so that it can be retrieved when the player presses circle.
func changeMenuMode(newMode):
	stack.append(menuMode)
	menuMode = newMode


## Backs one step in the current menu. If the root is found, this method
## exits the store.
func circlePressed():
	var n = activeNode.getParent()
	if n != null:
		if menuMode == CONFIRM_SELL or menuMode == CONFIRM_BUY:
			n = activeNode.getCurrentChild()
			confirmNode.setMenuCursor(0)
			menuMode = stack.pop_back()
			circlePressed()
			crossPressed()
		else:
			activeNode = MenuNode.switchNode(activeNode, n)
			mode_ = NO_MODE
			if stack.size() == 0:
				stack.append(0)
			setMenuImagesUsed(0x000000ff)
			menuMode = stack.pop_back()
	else:
		exit(Values.SWITCH_BACK)


## Updates the information about the equipment that the hand is pointing at.
## Should be called when the hand is moved.
func updateCurrent():
	if mode_ != NO_MODE:
		var n = activeNode.getCurrentChild()
		current = WeaponStoreFactory.getStoreFactory().getEquipmentByName(
				equipment, n.getName())
		currentCharacter = Load.getCharacterWithForWhom(current.getForWhom())
		updateNumbers()


## Initiates the equip menu (EquipPage.RIGHT_HAND, LEFT_HAND or ARMORS).
func initiateEquipMenu(n, mode):
	self.mode_ = mode
	activeNode = n
	activeNode.setActive(true)
	fillEquipment(mode)
	if activeNode.hasChildren():
		setMenuImagesUsed(0x00ffff0f)
		setDialogVisibility(false)
		updateCurrent()
	else:
		activeNode.setEnabled(false)
		circlePressed()


## Draws the weapon store on the given graphics.
func draw3D(g3D):
	var g = g3D
	if mode_ != NO_MODE:
		activeNode.drawChildrenFreely(g, true, false, false, true, false)
	else:
		activeNode.drawAllChildren(g)

	var n = activeNode.getParent()
	if n != null and n.isActive():
		activeNode.getParent().drawChildren(g)

	var title = activeNode.getName()
	g.drawString(title, MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)

	if mode_ != NO_MODE:
		EquipPage.drawStatus(g, currentCharacter, current, mode_)
		EquipPage.drawEquip(g, current)
		drawInfo(g)
	if menuMode == CONFIRM_BUY:
		drawConfirmDialog(g)
	elif menuMode == CONFIRM_SELL:
		drawConfirmSellDialog(g)
	elif menuMode == TUTORIAL:
		tutorial.drawTopLayer(g)


## Draws the confirm sell dialog asking if the player would like to sell
## the current equipment.
func drawConfirmSellDialog(g):
	g.fadeOldSchool(0.5)
	g.setColor(1)
	var n = activeNode.getCurrentChild()
	g.drawImage(AbstractPage.images[14], 400, 300)
	g.drawString(n.getName() + ": " + str(n.getPrice()) + " gp", 430, 360)
	confirmNode.drawAllChildren(g)


## Updates the total amount of owned and equipped equipment of the current
## kind.
func updateNumbers():
	equipped = 0
	var ae = Load.getEquipments().get(activeNode.getCurrentChild().getName())
	if ae != null:
		total = ae.getNumber()
		equipped = 1 if ae.isEquiped() else 0
	else:
		total = 0


## Draws the equipped/total counts and the party's gold.
func drawInfo(g):
	var x: int = MenuValues.MENU_TEXT_X

	g.drawString("Equipped: " + str(equipped), x, 648)
	g.drawString("Total: " + str(total), x, 689)
	g.drawString("Gold: " + str(Load.getPartyItems().getGold()), x, 730)


## Fills the root menu.
func fillRoot():
	var n = activeNode
	n.insertChild("Buy")
	n.insertChild("Sell")
	n.insertChild("Tutorial - Equipment")
	n.insertChild("Exit")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


func fillPositiveConfirm(n):
	n.insertChild("Equip")
	n.insertChild("Put in inventory")


## Fills the confirm node with the answers to the question whether the
## player would like to sell the selected item.
func confirmSell():
	confirmNode.removeChildren(true)
	confirmNode.insertChild("Keep")
	confirmNode.insertChild("Sell")
	confirmNode.setDistance(MenuValues.DISTANCE)
	confirmNode.setPositions(480, 430)


## Fills the buy menu.
func fillBuy():
	var n = activeNode
	n.removeChildren(true)
	if not n.hasChildren():
		n.insertChild(RIGHT_HAND).setEnabled(not checkBuyEquipmentIsEmpty(EquipPage.RIGHT_HAND))
		n.insertChild(LEFT_HAND).setEnabled(not checkBuyEquipmentIsEmpty(EquipPage.LEFT_HAND))
		n.insertChild(BODY).setEnabled(not checkBuyEquipmentIsEmpty(EquipPage.ARMORS))
		n.insertChild("Back")
		n.setDistance(MenuValues.DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


## Fills the sell menu.
func fillSell():
	var n = activeNode
	n.removeChildren(true)
	var rh = n.insertChild(RIGHT_HAND)
	rh.setEnabled(not checkSellEquipmentIsEmpty(EquipPage.RIGHT_HAND))
	var maxY: int = MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON + 3 * MenuValues.DISTANCE_ROOM_FOR_PRICE
	rh.setBoundingBox(MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978)

	var lf = n.insertChild(LEFT_HAND)
	lf.setEnabled(not checkSellEquipmentIsEmpty(EquipPage.LEFT_HAND))
	lf.setBoundingBox(MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978)

	var b = n.insertChild(BODY)
	b.setEnabled(not checkSellEquipmentIsEmpty(EquipPage.ARMORS))
	b.setBoundingBox(MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978)
	n.insertChild("Back")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


## Checks if the store's equipment list for the given mode is empty.
func checkBuyEquipmentIsEmpty(mode):
	if mode == EquipPage.RIGHT_HAND:
		equipment = WeaponStoreFactory.getStoreFactory().getRightHandFor(storeName)
		return equipment.size() == 0
	elif mode == EquipPage.ARMORS:
		equipment = WeaponStoreFactory.getStoreFactory().getArmorsFor(storeName)
		return equipment.size() == 0
	elif mode == EquipPage.LEFT_HAND:
		equipment = WeaponStoreFactory.getStoreFactory().getLeftHandFor(storeName)
		return equipment.size() == 0
	return false


## Checks if the party's (unequipped) equipment list for the given mode is
## empty.
func checkSellEquipmentIsEmpty(mode):
	if mode == EquipPage.RIGHT_HAND:
		equipment = Load.convertWeaponListToAbstractRemoveEquipped()
		return equipment.size() == 0
	elif mode == EquipPage.ARMORS:
		equipment = Load.convertArmorListToAbstractRemoveEquipped()
		return equipment.size() == 0
	elif mode == EquipPage.LEFT_HAND:
		equipment = Load.convertShieldListToAbstractRemoveEquipped()
		return equipment.size() == 0
	return false


## Fills the equipment menu with equipment of the given mode.
func fillEquipment(mode):
	var n = activeNode
	n.removeChildren(false)
	var div: int = 1
	if menuMode == BUY:
		if mode == EquipPage.RIGHT_HAND:
			equipment = WeaponStoreFactory.getStoreFactory().getRightHandFor(storeName)
		elif mode == EquipPage.ARMORS:
			equipment = WeaponStoreFactory.getStoreFactory().getArmorsFor(storeName)
		elif mode == EquipPage.LEFT_HAND:
			equipment = WeaponStoreFactory.getStoreFactory().getLeftHandFor(storeName)
	elif menuMode == SELL:
		if mode == EquipPage.RIGHT_HAND:
			equipment = Load.convertWeaponListToAbstractRemoveEquipped()
		elif mode == EquipPage.ARMORS:
			equipment = Load.convertArmorListToAbstractRemoveEquipped()
		elif mode == EquipPage.LEFT_HAND:
			equipment = Load.convertShieldListToAbstractRemoveEquipped()
		div = 2
	for i in range(equipment.size()):
		var ae = equipment[i]
		var child = n.insertChild(ae.getName())
		child.setPrice(int(ae.getPrice()) / div)
		if div == 1:
			var gold: int = Load.getPartyItems().getGold()
			child.setEnabled(ae.getPrice() <= gold)
			if not Load.isCharacterActive(ae.getForWhom()):
				child.setEnabled(false)
	n.setDistance(MenuValues.DISTANCE_ROOM_FOR_PRICE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON)
	n.updateHandPos()


static func setTestMap(info):
	testInfo = info
