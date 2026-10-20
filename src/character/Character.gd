class_name Character
extends Creature
## Port of character.Character.
##
## A character is a creature which the player uses, in contrast with enemies
## (who also are creatures). A character can equip weapons, armors, shields
## and a deck of cards.

const HAND_SIZE = 5

var rightHand = null
var leftHand = null
var armor = null
var deck = null
var deckGL = null
var image = ""
var roundCounter = 0
var element = 0
var charEnum = null


## Creates a character with the specified name, attributes (Array of
## floats) and menu image name.
func _init(p_name = null, p_attributes = null, pic = null) -> void:
	super(p_name, p_attributes)
	deck = Deck.new(self)
	if p_name == null:
		return
	if p_name == "Kin":
		charEnum = Values.characters.KIN
	elif p_name == "Celis":
		charEnum = Values.characters.CELIS
	elif p_name == "Borealis":
		charEnum = Values.characters.BOREALIS
	else:
		charEnum = Values.characters.ZALZI
	image = pic
	loadImage()
	initBattleDeck()


## Loads the menu image and draws the character frame on top of it.
func loadImage():
	var im: Image = ImageHandler.getImage(Values.MenuImages, image)
	var frame: Image = ImageHandler.getImage(Values.MenuImages, "charframe.png")
	if im == null:
		push_error("Character.loadImage: image not found: " + Values.MenuImages + image)
		return
	var g := ImageGraphics.new(im)
	g.drawImage(frame, 0, 0)
	ImageHandler.addPermanentlyConvertNow(image, im)


## Initializes the battle deck (number of shown cards and line length).
func initBattleDeck():
	deck.setNrOfShownCards(4)
	deck.setLineLength(4)


## Equips the given equipment of the given type.
func equip(ae, playSound):
	if ae is Armor:
		equipArmor(ae, playSound)
	elif ae is Weapon:
		equipWeapon(ae, playSound)
	else:
		equipLeftHand(ae, playSound)
	ae.setEquiped(true)


func equipArmor(ae, playSound):
	if armor != null:
		armor.setEquiped(false)
	armor = ae
	armor.setEquiped(true)
	if playSound:
		SoundPlayer.playSound(SoundMap.MENU_EQUIP_ARMOR)


func equipWeapon(ae, playSound):
	if rightHand != null:
		rightHand.setEquiped(false)
	rightHand = ae
	rightHand.setEquiped(true)
	if playSound:
		SoundPlayer.playSound(SoundMap.MENU_EQUIP_WEAPON)


func equipLeftHand(ae, playSound):
	if leftHand != null:
		leftHand.setEquiped(false)
	leftHand = ae
	leftHand.setEquiped(true)
	if playSound:
		SoundPlayer.playSound(SoundMap.MENU_EQUIP_SHIELD)


## Unequips the equipment that the given mode (EquipPage.ARMORS,
## .LEFT_HAND or .RIGHT_HAND) represents.
func unequip(mode):
	if mode == EquipPage.ARMORS:
		if armor != null:
			armor.setEquiped(false)
			SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_ARMOR)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
		armor = null
	elif mode == EquipPage.LEFT_HAND:
		if leftHand != null:
			leftHand.setEquiped(false)
			SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_SHIELD)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
		leftHand = null
	elif mode == EquipPage.RIGHT_HAND:
		if rightHand != null:
			rightHand.setEquiped(false)
			SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_WEAPON)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
		rightHand = null


## Increases the level by one.
func levelUp():
	setAttribute(LEVEL, getAttribute(LEVEL) + 1)


## Java: static levelUp(Character c). Levels up the character and sets the
## attributes of the new level.
static func levelUpStatic(c):
	var info = LevelFactory.getLevelFor(
			c.getName(), c.getAttribute(Creature.LEVEL) + 1,
			c.getAttribute(Creature.CLASS))
	if info == null:
		# Already at the last level of the class (COTZ-003).
		c.setAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, LevelFactory.NO_INCREASE)
		return
	c.levelUp()

	c.setAttribute(
			Creature.EXP_LEFT_TO_NEXT_LEVEL,
			info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL))

	for attr in info.keys():
		var newValue: int = info[attr]
		if newValue != LevelFactory.NO_INCREASE:
			c.setAttribute(attr, newValue)
	c.setAttribute(Creature.HP, c.getAttribute(Creature.MAX_HP))


## Cures this character from the dead.
func cureFromDead():
	alive = true
	resurrected = true


## Gets the total offense (with boosts) for the given type (Slot.ATTACK,
## Slot.MAGIC or Slot.SUPPORT). Only for use in battle.
func getBattleAttack(type):
	var att: float = 0.0
	if type == Slot.ATTACK:
		att = J.round(attackBoost.getCurrentBoost() * getTotalAttack())
	elif type == Slot.MAGIC:
		att = J.round(magicBoost.getCurrentBoost() * getTotalMagicAttack())
	elif type == Slot.SUPPORT:
		att = getTotalSupport()
	return J.round(att)


## Gets the total defense (with boosts) for the given type (Slot.ATTACK or
## Slot.MAGIC). Only for use in battle.
func getBattleDefense(type):
	var def: float = 0.0
	if type == Slot.ATTACK:
		def = J.round(defenseBoost.getCurrentBoost() * getTotalDefense())
	elif type == Slot.MAGIC:
		def = J.round(magicDefenseBoost.getCurrentBoost() * getTotalMagicDefense())
	return J.round(def)


func getTotalAttack():
	var attack: float = getTotalTemplate(ATTACK)
	return J.round(attack)


func getTotalMagicAttack():
	var magic: float = getTotalTemplate(MAGIC_ATTACK)
	return J.round(magic)


func getTotalSupport():
	var support: float = getTotalTemplate(SUPPORT_ATTACK)
	return J.round(support)


## Gets the total defense, including the bonus for the defense mode.
func getTotalDefense():
	var defense: float = getTotalTemplate(DEFENSE)
	defense = addDefenseMode(defense)
	return J.round(defense)


## Gets the total magical defense, including the bonus for the defense mode.
func getTotalMagicDefense():
	var totalMagicDefense: float = getTotalTemplate(MAGIC_DEFENSE)
	totalMagicDefense = addDefenseMode(totalMagicDefense)
	return J.round(totalMagicDefense)


func getTotalTemplate(attrib):
	var base: int = getAttribute(attrib)
	var total: float = base
	if leftHand != null:
		total += leftHand.getAttribute(attrib) * base
	if rightHand != null:
		total += rightHand.getAttribute(attrib) * base
	if armor != null and not tempCrushed:
		total += armor.getAttribute(attrib) * base
	return total


## Adds the defense bonus if the character is in battle in defense mode.
func addDefenseMode(defense):
	var d: float = defense
	if deckGL != null:
		d *= 1.5 if deckGL.isDefenseMode() else 1.0
	return d


func getDeck():
	return deck


func getWeapon():
	return rightHand


func getLeftHand():
	return leftHand


func getArmor():
	return armor


func getRightHandName():
	if rightHand != null:
		return rightHand.getName()
	return ""


func getLeftHandName():
	if leftHand != null:
		return leftHand.getName()
	return ""


func getArmorName():
	if armor != null:
		return armor.getName()
	return ""


## Gets the name of the big image that is shown in the menu.
func getImage(number = null):
	return image


func getDeckSize():
	return deck.getDeckSize()


## Sets the GLDeck (the deck drawn in battle) of this character.
func set2DDeck(p_deck):
	deckGL = p_deck
	deckGL.setNeedUpdate(true)


## Gets the GLDeck of this character, updating it if the deck has changed.
func get2DDeck():
	if deck.hasChanged():
		if deckGL != null:
			deckGL.update(self)
			deckGL.setNeedUpdate(true)
		deck.resetChange()
	return deckGL


func crushArmor():
	return HAS_NO_ARMOR


## Called just after the player has played all the cards in the weapon
## slots and attacked.
func finishRound(didAction):
	if didAction:
		roundCounter += 1
	resetSpeed()
	setTurn(false)
	updateBoosts()


## Gets the index of this character in the list of characters in Load.
func getIndex():
	return charEnum.getIndex()


## Called when the battle is exited: removes temporary element settings,
## armor crushes and boosts.
func resetBattleStats():
	active = true
	inTurn = false
	roundCounter = 0
	changeElementBack()
	resetTempValues()
	resetBoost()


func changeElement(p_element):
	element = p_element


func changeElementBack():
	element = AbstractCard.NO_ELEMENT


func getElement():
	return element


## Java get(int): a string showing the given attribute, like "Attack: 21".
func get_(attribute):
	var val: int = getTotal(attribute)
	var value := str(val)
	if val == LevelFactory.NO_INCREASE:
		value = "-"
	var prefix = getMap().get(attribute)
	return ("null" if prefix == null else str(prefix)) + value


## Gets the total value of the given attribute (character + weapon + armor
## + left hand).
func getTotal(att):
	var attr: float = getAttribute(att)
	var total: float = attr
	if getWeapon() != null:
		total += attr * getWeapon().getAttribute(att)
	if getArmor() != null:
		total += attr * getArmor().getAttribute(att)
	if getLeftHand() != null:
		total += attr * getLeftHand().getAttribute(att)
	return J.round(total)


## Gets the experience limit of the current level (used for the experience
## bar on the spoils screen).
func getExpToNextLevel():
	var lvl: int = getAttribute(Creature.LEVEL)
	var cClass: int = getAttribute(Creature.CLASS)
	var info = LevelFactory.getLevelFor(getName(), lvl, cClass)
	if info == null:
		return LevelFactory.NO_INCREASE
	return info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL)


func setExpPercentOfNext(p):
	var toNext: int = getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL)
	var receivedExp: int = J.round(p * toNext)
	setAttribute(Creature.EXPERIANCE, receivedExp)
	addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -receivedExp)


func getNameFor(i):
	return getMap().get(i)


func canLevelUp():
	return getAttribute(EXP_LEFT_TO_NEXT_LEVEL) != LevelFactory.NO_INCREASE


## Repairs a character loaded from a save written before the max level fix
## (COTZ-003): such saves hold EXP_LEFT_TO_NEXT_LEVEL values just below
## NO_INCREASE at the last level of a class, and a level past the last one
## when a level up was cut short by the error. Characters without a level
## table are left alone.
func repairLevel() -> void:
	var cClass: int = getAttribute(CLASS)
	var lvl: int = getAttribute(LEVEL)
	var last: int = lvl
	while last > 1 and LevelFactory.getLevelFor(getName(), last, cClass) == null:
		last -= 1
	var info = LevelFactory.getLevelFor(getName(), last, cClass)
	if info == null:
		return
	if last < lvl:
		setAttribute(LEVEL, last)
	if info.get(EXP_LEFT_TO_NEXT_LEVEL) == LevelFactory.NO_INCREASE:
		setAttribute(EXP_LEFT_TO_NEXT_LEVEL, LevelFactory.NO_INCREASE)


func getRoundCounter():
	return roundCounter


func setClass(newClass):
	var c: int = getAttribute(CLASS)
	if c < newClass:
		fullCure()
		setAttribute(CLASS, newClass)
		setAttribute(LEVEL, 1)
		var info: Dictionary = LevelFactory.getLevelFor(name, 1, newClass)

		setAttribute(Creature.EXPERIANCE, 0)
		setAttribute(
				Creature.EXP_LEFT_TO_NEXT_LEVEL,
				info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL))

		for attr in info.keys():
			var newValue: int = info[attr]
			if newValue != LevelFactory.NO_INCREASE:
				setAttribute(attr, newValue)


func getEnum():
	return charEnum
