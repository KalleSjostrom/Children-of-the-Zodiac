class_name StatusPage
extends RefCounted
## Port of menu.StatusPage: the status line of a character (its portrait,
## name, class, level, life and slots) and an item's status, which the start,
## deck, equip and tutorial pages and the Weapon Store show.
##
## The page itself (the menu's status page: MainMenu.initStatusPage, opened
## only from itself, plan Appendix) and the legacy drawing of its static
## helpers (draw, drawTop, drawAttributes, drawSlots, drawEquip; --legacy=
## status) are removed (closing phase 4.2, plan 9.2); git history has them up
## to 9a9c2341. What stays are their twins (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): place_top, show_top, place_attributes,
## place_slots, show_equip.

## Bridge (phase 4.2 step B): the nodes of show_top and show_equip.
const STATUS_LINE_VIEW := "res://scenes/ui/StatusLine.tscn"
const EQUIP_ITEM_VIEW := "res://scenes/ui/EquipItem.tscn"

static var x = MenuValues.STATUS_X
static var y = J.copyArray(MenuValues.STATUS_Y)


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
