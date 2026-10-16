class_name GLWeapon
extends Hideable
## Port of battle.equipment.GLWeapon: the slots residing in the weapon (and
## armor/shield in defense mode). The player puts the chosen cards here.

const OFFENSE_MODE = 0
const DEFENSE_MODE = 1
var cards: Array = []
var slots: Array = []
var icon = null
var sizes = null
var enabled = null
var currentMode: int = OFFENSE_MODE


## Creates a new GLWeapon based on the information in the given character.
func _init(c = null) -> void:
	super(2)
	cards = []
	slots = []
	setSlots(c)
	setAxis(Y_AXIS)
	setLimit(false)
	setMovementSpeed(false)
	setPos(BattleValues.DECK_POSITION - 0.065, BattleValues.WEAPON_SLOTHEIGHT)
	instantHide()


## Fills the list of GLSlots with the slots in the weapon of the character.
func setSlots(c):
	var w = c.getWeapon()
	var as_: Array = []
	if w != null:
		as_ = w.getSlots()
	var ds: Array = Slot.merge(c.getArmor(), c.getLeftHand())

	icon = WeaponModeIcon.new(BattleValues.WEAPON_SLOT_X)
	sizes = [as_.size(), ds.size()]
	var size: int = maxi(as_.size(), ds.size())
	var s1 = null
	var s2 = null
	for i in size:
		s1 = as_[i] if i < as_.size() else null
		s2 = ds[i] if i < ds.size() else null
		slots.append(GLSlot.new(s1, s2, AbstractDeck.xs[i]))
	setFreeSlots()


func initDraw(g: Graphics):
	icon.initDraw(g)
	for i in slots.size():
		slots[i].initDraw(g)


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	super.translate(g)
	icon.draw(g, getYtrans())
	for i in slots.size():
		slots[i].draw(g, getYtrans())
	g.setAlphaFunc(0.5)
	drawDeck(g, cards)
	g.setAlphaFunc(0)


## Draws all the cards in the given deck.
func drawDeck(g, deck, a = null):
	for i in deck.size():
		deck[i].draw(g, getYtrans())


## Computes how many free slots there are of each type (Slot types as index).
func setFreeSlots():
	enabled = J.array(3, 0)
	for i in sizes[currentMode]:
		if slots[i].isFree(currentMode):
			enabled[slots[i].getKind(currentMode)] += 1
	return enabled


## Receives a card and puts it in the first slot it fits. Returns the number
## of free slots of each type, or null if the card did not fit.
func receive(card):
	if card.isEnabled() and cards.size() < slots.size():
		var index: int = -1
		var i: int = 0
		while i < slots.size() and index == -1:
			var slot = slots[i]
			if slot.doesFit(card, currentMode):
				index = i
				slot.setCard(card.card)
				card.card.putInSlot(slot.getKind(currentMode))
			i += 1
		if index != -1:
			card.setInSlot(AbstractDeck.xs[index])
			cards.append(card)
			enabled[card.getType()] -= 1
			return enabled
	return null


func empty():
	for i in slots.size():
		slots[i].clearSlot()
	cards.clear()
	setFreeSlots()


## Switches between offense and defense mode. Returns the new mode, or -1 if
## the weapon is not empty.
func switchSide():
	if cards.size() == 0:
		currentMode = (currentMode + 1) % 2
		icon.toggleSide()
		for i in slots.size():
			slots[i].toggleSide()
		setFreeSlots()
		return currentMode
	return -1


func setToAttackMode():
	if currentMode == DEFENSE_MODE:
		switchSide()


func isFull():
	return cards.size() == sizes[currentMode]


func getCards():
	return cards


func getFreeSlots():
	return enabled


func getMode():
	return currentMode


func updatePos():
	for i in cards.size():
		cards[i].update()
