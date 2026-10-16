class_name EquipPage
extends AbstractPage
## Port of menu.EquipPage: the page in the menu where the player can equip
## weapons, armors and left handed items.

const RIGHT_HAND = 0
const LEFT_HAND = 1
const ARMORS = 2
static var x = MenuValues.STATUS_X
static var y = MenuValues.STATUS_Y
var c = null
var mode: int = 0
var characterIndex: int = 0

func _init(character = null, menuIndex = null, inSubMenu = null) -> void:
	c = Load.getCharacters()[character]
	characterIndex = character
	activeNode = MenuNode.new(null, "Equip")
	fillRoot(true)
	activeNode.setMenuCursor(menuIndex)
	if inSubMenu:
		crossPressed()
	setPage(EQUIP_PAGE)


func fillRoot(resetCursor = null):
	var n = activeNode
	n.removeChildren(resetCursor)
	n.insertChild(WeaponStore.RIGHT_HAND + ":").setEquipment(c.getWeapon())
	n.insertChild(WeaponStore.LEFT_HAND + ":").setEquipment(c.getLeftHand())
	n.insertChild(WeaponStore.BODY + ":").setEquipment(c.getArmor())
	n.setDistance(55)
	n.setPositions(MenuValues.MENU_TEXT_X, 135)
	n.updateHandPos()


func fillEquip():
	var n = activeNode
	mode = n.getParent().getMenuCursor()
	n.removeChildren(true)
	var equipment = null
	if mode == ARMORS:
		equipment = Load.getArmorFor(c.getEnum())
	elif mode == RIGHT_HAND:
		equipment = Load.getWeaponFor(c.getEnum())
	else:
		equipment = Load.getLeftHandForStatic(c.getEnum())
	for i in range(equipment.size()):
		var ae = equipment[i]
		n.insertChild(ae.getName()).setEquipment(ae)
	n.insertChild("Remove").setNoNumber()
	n.setStandardWeaponWithBB()


func upPressed():
	if activeNode.hasChildren():
		activeNode.previousChild()


func downPressed(playSound = null):
	if activeNode.hasChildren():
		activeNode.nextChild()


func crossPressed(playSound = null):
	var fromMain: bool = activeNode.getParent() == null
	if fromMain:
		SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
		activeNode = activeNode.getCurrentChild()
		activeNode.setActive(true)
		fillEquip()
	else:
		var ae = activeNode.getCurrentChild().getEquipment()
		var name = activeNode.getCurrentChild().getName()
		if name == "Remove":
			c.unequip(mode)
		else:
			c.equip(ae, true)
		circlePressed()
		fillRoot(false)


func circlePressed(pressAnyWay = null):
	var n = activeNode.getParent()
	if n != null:
		activeNode = MenuNode.switchNode(activeNode, n)
	else:
		MainMenu.getMainMenu().initStartPage(1)


func R1Pressed():
	SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER)
	characterIndex += 1
	initEquipPage(characterIndex)


func L1Pressed():
	SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER)
	characterIndex -= 1
	initEquipPage(characterIndex)


func initEquipPage(charIndex):
	var inSub: bool = activeNode.getParent() != null
	var menuIndex: int
	if inSub:
		menuIndex = activeNode.getParent().getMenuCursor()
	else:
		menuIndex = activeNode.getMenuCursor()
	MainMenu.getMainMenu().initEquipPage(charIndex, menuIndex, inSub)


func draw3D(g):
	super.drawStandard(g)
	var ae = activeNode.getCurrentChild().getEquipment()
	var n = activeNode.getParent()
	var index: int = -1 if n == null else n.getMenuCursor()

	drawStatus(g, c, ae, index)
	drawEquip(g, ae)
	var p = activeNode.getParent()
	if p != null:
		p.drawChildrenFreely(g, false, false, false, true, true)
		activeNode.drawChildrenFreely(g, false, false, true, false, false)
	else:
		activeNode.drawChildrenFreely(g, false, false, false, true, true)
	var tx: int = MenuValues.MENU_TEXT_X
	g.drawString(activeNode.getName().replace(":", ""), tx, MenuValues.MENU_TITLE_Y)
	StartPage.drawInfo(g)
	drawHelp(g)


static func drawStatus(g, p_c, ae, p_mode):
	if p_c != null:
		var equipped = null
		if p_mode == RIGHT_HAND:
			equipped = p_c.getWeapon()
		elif p_mode == LEFT_HAND:
			equipped = p_c.getLeftHand()
		elif p_mode == ARMORS:
			equipped = p_c.getArmor()
		var change = AbstractEquipment.getChange(p_c, ae, equipped)

		Graphics.setTextColor(JColor.BLACK)
		if ae == equipped:
			ae = null
		StatusPage.draw(g, p_c, ae)

		if p_mode != -1:
			for i in range(2):
				for j in range(4):
					var nr: int = i * 4 + j
					var index: int = Values.ATTRIBUTE_MAP[nr]
					drawChange(p_c.get_(index), x[j], y[i + 5], change[index], g)


static func drawChange(line, px, py, change, g):
	if change == 0:
		return
	elif change < 0:
		var cc: int = change * -1
		g.drawString(str(line) + " -" + str(cc), px, py)
		Graphics.setTextColor(JColor.RED)
		g.drawString(str(line) + " -" + str(cc), px - 1, py - 1)
	elif change > 0:
		g.drawString(str(line) + " +" + str(change), px, py)
		Graphics.setTextColor(JColor.GREEN)
		g.drawString(str(line) + " +" + str(change), px - 1, py - 1)
	Graphics.setTextColor(JColor.BLACK)


static func drawEquip(g, ae):
	if ae != null:
		StatusPage.drawEquip(g, ae, 324)


static func drawInformation(g, ae, py):
	# The body is commented out in the Java source.
	pass


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
	g.drawString("Back", helpx + 2 * step, helpy)

	helpx += 3 * step + 100
	helpxicons += 3 * step + 90
	step += 70

	g.drawString("Change character", helpx, helpy)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons, helpyicons)
