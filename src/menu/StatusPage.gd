class_name StatusPage
extends AbstractPage
## Port of menu.StatusPage: the page in the menu where the player can see the
## current character's status. It is possible to switch to another character
## by pressing R1 or L1.
##
## Port notes: the Java static overloads are merged:
##   draw(g, c) / draw(g, c, compare) / draw(g, String s, xi, yi) /
##   draw(g, c, String s, attr, xi, yi)        -> draw(g, c, s, attr, xi, yi)
##   drawTop(g, c[, offset[, compare]])        -> drawTop(g, c, offset, compare)
##   drawSlots(g, c, compare) / drawSlots(g, slots, compareW, y)
##                                             -> drawSlots(g, slots, compareW, y)

## Bridge (phase 4.2 step B): the nodes of show_top and show_equip.
const STATUS_LINE_VIEW := "res://scenes/ui/StatusLine.tscn"
const EQUIP_ITEM_VIEW := "res://scenes/ui/EquipItem.tscn"

static var x = MenuValues.STATUS_X
static var y = J.copyArray(MenuValues.STATUS_Y)
var c = null
var characterIndex: int = 0

func _init(character = null, currentChild = null) -> void:
	c = Load.getCharacters()[character]
	characterIndex = character
	fillRoot()
	activeNode.setMenuCursor(currentChild)
	setPage(STATUS_PAGE)


func fillRoot(resetCursor = null):
	activeNode = MenuNode.new(null, "Status")
	if not activeNode.hasChildren():
		activeNode.insertChild("Back")
		activeNode.setDistance(MenuValues.DISTANCE)
		activeNode.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


func upPressed():
	activeNode.previousChild()


func downPressed(playSound = null):
	activeNode.nextChild()


func crossPressed(playSound = null):
	var mode = activeNode.getCurrentChild().getName()
	if mode == "Back":
		circlePressed()


func circlePressed(pressAnyWay = null):
	MainMenu.getMainMenu().initStartPage(3)


func R1Pressed():
	characterIndex += 1
	MainMenu.getMainMenu().initStatusPage(characterIndex, activeNode.getMenuCursor())


func L1Pressed():
	characterIndex -= 1
	MainMenu.getMainMenu().initStatusPage(characterIndex, activeNode.getMenuCursor())


func draw3D(g):
	drawStandard(g)
	activeNode.drawAllChildren(g)
	g.drawString(activeNode.getName(), MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)
	draw(g, c)
	StartPage.drawInfo(g)
	StartPage.drawScreenShot(g)
	drawHelp(g)


static func draw(g, c, s = null, attr = null, xi = null, yi = null):
	if xi != null:
		# draw(Graphics g, Character c, String s, int attr, int xi, int yi)
		g.drawString(str(s) + str(c.getAttribute(attr)), x[xi], y[yi])
	elif s is int:
		# draw(Graphics g, String s, int xi, int yi)
		g.drawString(str(c), x[s], y[attr])
	elif s == null:
		# draw(Graphics g, Character c)
		drawTop(g, c)
		drawAttributes(g, c)
	else:
		# draw(Graphics g, Character c, AbstractEquipment compare)
		drawTop(g, c, 0, s)
		drawAttributes(g, c)


static func drawAttributes(g, c):
	draw(g, c.get_(Creature.ATTACK), 0, 5)
	draw(g, c.get_(Creature.MAGIC_ATTACK), 1, 5)
	draw(g, c.get_(Creature.SUPPORT_ATTACK), 2, 5)
	draw(g, c.get_(Creature.AGILITY), 3, 5)

	draw(g, c.get_(Creature.DEFENSE), 0, 6)
	draw(g, c.get_(Creature.MAGIC_DEFENSE), 1, 6)
	draw(g, c.get_(Creature.HIT), 2, 6)
	draw(g, c.get_(Creature.EVADE), 3, 6)

	draw(g, c.get_(Creature.EXPERIANCE), 0, 7)
	draw(g, c.get_(Creature.EXP_LEFT_TO_NEXT_LEVEL), 1, 7)
	draw(g, c.get_(Creature.LEVEL), 2, 7)
	draw(g, c.get_(Creature.DECK_SIZE), 3, 7)


static func drawTop(g, c, offset = null, compare = null):
	if offset == null:
		offset = 0
	var yCopy = null
	if offset != 0:
		yCopy = J.copyArray(y)
		for i in range(y.size()):
			y[i] += offset
	g.drawImage(c.getImage(), x[0], y[0])
	draw(g, c.getName(), 1, 1)
	draw(g, c, "Class: ", Creature.CLASS, 3, 1)
	draw(g, c, "Level: ", Creature.LEVEL, 4, 1)
	if not c.isAlive():
		draw(g, "Dead", 2, 1)
	else:
		draw(g, "Hp: " + str(c.getLife()), 2, 1)
	draw(g, "Off. Slots: ", 1, 2)
	draw(g, "Def. Slots: ", 1, 3)
	drawSlots(g, c, compare)
	if yCopy != null:
		y = yCopy


static func drawSlots(g, slots, compareW, yPos = null):
	if yPos == null:
		_drawCharacterSlots(g, slots, compareW)
		return
	var type: Array = J.array(3, 0)
	var t: Array = J.array(3, 0)
	if compareW != null:
		for i in range(compareW.size()):
			type[compareW[i].getType()] += 1
		for i in range(slots.size()):
			t[slots[i].getType()] += 1
		var drawn: int = 0
		for i in range(t.size()):
			var number: int = maxi(t[i], type[i])
			for j in range(number):
				if j < mini(t[i], type[i]):
					# Normal color
					g.setImageColor(1, 1, 1, 1)
				elif j < t[i]:
					# Red
					g.setImageColor(.75, 0, 0, 1)
				elif j < type[i]:
					# Green
					g.setImageColor(0, .75, 0, 1)
				var name: String = "small" + Values.MenuImages + str(i) + "slot.png"
				g.drawImage(name, drawn * Slot.DISTANCE + 307, yPos)
				drawn += 1
	else:
		for i in range(slots.size()):
			var s = slots[i]
			g.drawImage(s.getSmallImage(), i * Slot.DISTANCE + 307, yPos)
	g.setImageColor(1, 1, 1, 1)


## Java: private static void drawSlots(Graphics g, Character c, AbstractEquipment compare).
static func _drawCharacterSlots(g, c, compare) -> void:
	var w = c.getWeapon()
	if w != null:
		var wslots = compare.getSlots() if compare is Weapon else null
		drawSlots(g, w.getSlots(), wslots, y[8])
	var defSlots = Slot.merge(c.getArmor(), c.getLeftHand())
	var slots = null
	if compare is Armor:
		slots = compare.getSlots()
		var leftHand = c.getLeftHand()
		if leftHand != null:
			slots = Slot.merge(leftHand.getSlots(), slots)
	elif compare is Shield:
		slots = compare.getSlots()
		var armor = c.getArmor()
		if armor != null:
			slots = Slot.merge(armor.getSlots(), slots)
	drawSlots(g, defSlots, slots, y[9])


static func drawEquip(g, ae, offset):
	var yCopy = null
	if offset != 0:
		yCopy = J.copyArray(y)
		for i in range(y.size()):
			y[i] += offset
	g.drawImage(ae.getImage(), x[0] + 25, y[0])
	draw(g, ae.getName(), 1, 1)
	var yPos: int = y[8] if ae is Weapon else y[9]
	draw(g, "Off. Slots:", 1, 2)
	draw(g, "Def. Slots:", 1, 3)
	drawSlots(g, ae.getSlots(), null, yPos)

	draw(g, "Attack: " + str(int(ae.getAttack() * 100)) + " %", 0, 6)
	draw(g, "Magic Off: " + str(int(ae.getMagic() * 100)) + " %", 1, 6)
	draw(g, "Support: " + str(int(ae.getSupport() * 100)) + " %", 2, 6)
	draw(g, "Agility: " + str(int(ae.getAgility() * 100)) + " %", 3, 6)

	draw(g, "Defence: " + str(int(ae.getDefense() * 100)) + " %", 0, 7)
	draw(g, "Magic Def: " + str(int(ae.getMagicDefense() * 100)) + " %", 1, 7)
	draw(g, "Hit: " + str(int(ae.getHit() * 100)) + " %", 2, 7)
	draw(g, "Evade: " + str(int(ae.getEvade() * 100)) + " %", 3, 7)

	EquipPage.drawInformation(g, ae, MenuValues.EQUIP_TEXT_Y + offset)
	if yCopy != null:
		y = yCopy


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): drawTop without
## the drawing: the same state changes in the same order (the offset added to
## the static y and y replaced by its copy, the images' binds, isAlive,
## drawString's setColor(color) after every text, drawSlots' image colours).
## Returns what the StatusLine node shows: {"offset", "portrait"
## (Graphics.place_image's), "texts", "colors", "size", "bold", "slots" (the
## weapon's and the armour's, [texture, tint] each)}.
static func place_top(g, c, offset = null, compare = null) -> Dictionary:
	if offset == null:
		offset = 0
	var yCopy = null
	if offset != 0:
		yCopy = J.copyArray(y)
		for i in range(y.size()):
			y[i] += offset
	var top := {"offset": offset, "size": g.getFontSize(), "bold": Graphics.font_bold(),
			"texts": PackedStringArray(), "colors": []}
	top.portrait = g.place_image(c.getImage(), x[0], y[0])
	_place_text(g, str(c.getName()), top)
	_place_text(g, "Class: " + str(c.getAttribute(Creature.CLASS)), top)
	_place_text(g, "Level: " + str(c.getAttribute(Creature.LEVEL)), top)
	if not c.isAlive():
		_place_text(g, "Dead", top)
	else:
		_place_text(g, "Hp: " + str(c.getLife()), top)
	_place_text(g, "Off. Slots: ", top)
	_place_text(g, "Def. Slots: ", top)
	top.slots = _place_character_slots(g, c, compare)
	if yCopy != null:
		y = yCopy
	return top


## Bridge (phase 4.2 step B): drawTop at a menu page's call site, or with
## --legacy=status off its twin (show_top). The Weapon Store keeps drawTop
## (through EquipPage.drawStatus) until the stores' part.
static func draw_top(g, c, offset = null, compare = null) -> void:
	if Main.is_legacy("status"):
		drawTop(g, c, offset, compare)
	else:
		show_top(g, c, offset, compare)


## Bridge (phase 4.2 step B): drawTop without the drawing (place_top), and the
## frame's next StatusLine node on the UI layer shows the line where it would
## have been drawn (Graphics.show_ui).
static func show_top(g, c, offset = null, compare = null) -> void:
	var mat = g.canvas_material()
	var top := place_top(g, c, offset, compare)
	var view = g.show_ui(STATUS_LINE_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_line(top.offset, top.portrait, top.texts, Array(top.colors, TYPE_COLOR, "", null),
				top.size, top.bold, top.slots, mat)


## drawString of a status text without the drawing: its colour, and
## drawString's setColor(color).
static func _place_text(g, text: String, into: Dictionary) -> void:
	into.texts.append(text)
	into.colors.append(Graphics.text_color(1.0))
	g.setColor(g.color)


## drawAttributes without the drawing: the twelve values (attack … deck
## size, in drawing order) as [text, colour] each, with drawString's
## setColor(color) after each.
static func place_attributes(g, c) -> Array:
	var values := []
	for attribute in [Creature.ATTACK, Creature.MAGIC_ATTACK, Creature.SUPPORT_ATTACK,
			Creature.AGILITY, Creature.DEFENSE, Creature.MAGIC_DEFENSE, Creature.HIT, Creature.EVADE,
			Creature.EXPERIANCE, Creature.EXP_LEFT_TO_NEXT_LEVEL, Creature.LEVEL, Creature.DECK_SIZE]:
		values.append([str(c.get_(attribute)), Graphics.text_color(1.0)])
		g.setColor(g.color)
	return values


## drawSlots(g, slots, compareW, y) without the drawing: each slot's image
## bound in its colour (white; red for one the comparison takes away, green
## for one it adds), then the image colour back to white. Returns [texture,
## tint] per slot drawn, in drawing order.
static func place_slots(g, slots, compareW) -> Array:
	var placed := []
	var type: Array = J.array(3, 0)
	var t: Array = J.array(3, 0)
	if compareW != null:
		for i in range(compareW.size()):
			type[compareW[i].getType()] += 1
		for i in range(slots.size()):
			t[slots[i].getType()] += 1
		for i in range(t.size()):
			var number: int = maxi(t[i], type[i])
			for j in range(number):
				if j < mini(t[i], type[i]):
					g.setImageColor(1, 1, 1, 1)
				elif j < t[i]:
					g.setImageColor(.75, 0, 0, 1)
				elif j < type[i]:
					g.setImageColor(0, .75, 0, 1)
				placed.append(_place_slot(g, "small" + Values.MenuImages + str(i) + "slot.png"))
	else:
		for i in range(slots.size()):
			placed.append(_place_slot(g, slots[i].getSmallImage()))
	g.setImageColor(1, 1, 1, 1)
	return placed


static func _place_slot(g, image) -> Array:
	var tint: Color = g.getCurrentColor()
	var t = g.skip_image(image)
	return [t.getGodotTexture() if t != null else null, tint]


## _drawCharacterSlots without the drawing: [the weapon's slots ([] without
## a weapon), the armour's and left hand's] (place_slots each).
static func _place_character_slots(g, c, compare) -> Array:
	var rows := [[], []]
	var w = c.getWeapon()
	if w != null:
		var wslots = compare.getSlots() if compare is Weapon else null
		rows[0] = place_slots(g, w.getSlots(), wslots)
	var defSlots = Slot.merge(c.getArmor(), c.getLeftHand())
	var slots = null
	if compare is Armor:
		slots = compare.getSlots()
		var leftHand = c.getLeftHand()
		if leftHand != null:
			slots = Slot.merge(leftHand.getSlots(), slots)
	elif compare is Shield:
		slots = compare.getSlots()
		var armor = c.getArmor()
		if armor != null:
			slots = Slot.merge(armor.getSlots(), slots)
	rows[1] = place_slots(g, defSlots, slots)
	return rows


## Bridge (phase 4.2 step B): drawEquip without the drawing: the same state
## changes (the offset added to the static y and y replaced by its copy, the
## images' binds, drawString's setColor(color) after every text, the slots'
## image colour), and the frame's next EquipItem node on the UI layer shows
## the item where it would have been drawn (Graphics.show_ui).
static func show_equip(g, ae, offset) -> void:
	var mat = g.canvas_material()
	var yCopy = null
	if offset != 0:
		yCopy = J.copyArray(y)
		for i in range(y.size()):
			y[i] += offset
	var item := {"texts": PackedStringArray(), "colors": []}
	var size: int = g.getFontSize()
	var bold: bool = Graphics.font_bold()
	var picture: Array = g.place_image(ae.getImage(), x[0] + 25, y[0])
	_place_text(g, str(ae.getName()), item)
	var weapon: bool = ae is Weapon
	_place_text(g, "Off. Slots:", item)
	_place_text(g, "Def. Slots:", item)
	var slots := place_slots(g, ae.getSlots(), null)
	_place_text(g, "Attack: " + str(int(ae.getAttack() * 100)) + " %", item)
	_place_text(g, "Magic Off: " + str(int(ae.getMagic() * 100)) + " %", item)
	_place_text(g, "Support: " + str(int(ae.getSupport() * 100)) + " %", item)
	_place_text(g, "Agility: " + str(int(ae.getAgility() * 100)) + " %", item)
	_place_text(g, "Defence: " + str(int(ae.getDefense() * 100)) + " %", item)
	_place_text(g, "Magic Def: " + str(int(ae.getMagicDefense() * 100)) + " %", item)
	_place_text(g, "Hit: " + str(int(ae.getHit() * 100)) + " %", item)
	_place_text(g, "Evade: " + str(int(ae.getEvade() * 100)) + " %", item)
	EquipPage.drawInformation(g, ae, MenuValues.EQUIP_TEXT_Y + offset)
	if yCopy != null:
		y = yCopy
	var view = g.show_ui(EQUIP_ITEM_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_item(offset, picture, item.texts, Array(item.colors, TYPE_COLOR, "", null), size,
				bold, weapon, slots, mat)


func drawHelp(g, drawAll = null):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 720
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + step, helpyicons)

	g.drawString("Exit", helpx, helpy)
	g.drawString("Back", helpx + step, helpy)

	helpx += 3 * step + 100
	helpxicons += 3 * step + 90
	step += 70

	g.drawString("Change character", helpx, helpy)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons, helpyicons)
