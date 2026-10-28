class_name AbstractCard
extends RefCounted
## Port of cards.AbstractCard.
##
## This class stores information about a card,
## such as name, position, level and so on.
##
## Java: public abstract class AbstractCard implements Comparable<Card>
## (compareTo is implemented in Card).

const NO_ELEMENT = 0
const FIRE_ELEMENT = 1
const ICE_ELEMENT = 2
const WIND_ELEMENT = 3
const EARTH_ELEMENT = 4
const NR_ELEMENT_MODES = 5
const CRITICAL_INCREASE = 2
const ELEMENT_INCREASE = 2

const TURNS_TO_BOOST_MANY = 2
const TURNS_TO_BOOST_FEW = 1

const CRITICAL_PRECENT = 0.03
static var EMPTY = [0.0, 0.0, 0.0]

static var STANDARD_ATTACK = [1.5, 1.8, 2.1]
static var STANDARD_ATTACK_HIGH = [2.1, 2.4, 2.7]
static var STANDARD_ATTACK_LOW = [1.2, 1.5, 1.8]
static var STANDARD_ATTACK_LV4 = [3.0, 3.0, 3.0]

static var SPECIAL_ATTACK = [1.65, 1.95, 2.25]

static var STANDARD_BOOST = [0.25, 0.3, 0.35]
static var STANDARD_BOOST_LOW = [0.15, 0.2, 0.25]

static var STANDARD_SUPORT = [1.7, 2.0, 2.3]
static var STANDARD_SUPORT_LOW = [1.4, 1.7, 2.0]

static var STANDARD_EFFECT_CHANCE = [0.4, 0.7, 1.0]

static var STANDARD_CHANCE = [0.4, 0.7, 1.0]
static var STANDARD_CHANCE_LOW = [0.2, 0.4, 6.0]
static var RESURRECT_CURE = [0.7, 1.4, 2.1]

const OFFENSE = 0
const MAGIC = 1
const SUPPORT = 2
const NEUTRAL = 3

const NORMAL = 0
const GRAY = 1

const BASE = 0
const BALL = 1

var element: int = 0
var level: int = 0
var type: int = 0
var all: bool = false

## String[2][2]: [NORMAL|GRAY][BASE|BALL] -> texture name.
var images = J.array2d(2, 2, null)
## String[4]
var info = null
var name: String = ""

## Java: private final float[] PERCENT = createAttackPercent();
## (created lazily on first use, see _getPercent()).
var PERCENT = null
## Java: private final float[] EFFECT_CHANCE_PERCENT = createEffectChancePercent();
var EFFECT_CHANCE_PERCENT = null
var price: int = 0
var slotType: int = -1

var _percentCreated: bool = false
var _effectChancePercentCreated: bool = false


## Initiates a new card with the given information.
##
## level: the level of the card.
## all: true if this card should be an all card (hit on all enemies).
## type: the type of the card (OFFENSE, MAGIC, SUPPORT, NEUTRAL).
## price: the price of the card.
func init(level, all, type, price):
	var simpleName: String = getSimpleName()
	self.name = getNameWithSpaces(simpleName)
	self.all = all
	setLevel(level)
	setImage()
	setElement()
	self.type = type
	self.price = price

	createSortingValue()
	self.info = createInfo()
	createShortInfo()


## Java: getClass().getSimpleName().
func getSimpleName():
	return ClassRegistry.getSimpleName(self)


#####################
#     CREATORS      #
#####################

## Puts together the information about this card.
func createInfo():
	var inf: Array = J.array(4, "")
	var singleAll: String = " (all)" if isAll() else "(single)"
	inf[0] = getName() + " - Level: " + str(getLevel()) + "   " + singleAll
	var text = createTextInfo()
	inf[1] = text[0]
	inf[2] = text[1]
	inf[3] = text[2]
	return inf


## Creates the chance percent of this card. If this method is not
## overridden the chance percent will be set to 1, 1, 1.
func createCheancePercent():
	return [1.0, 1.0, 1.0]


func createEffectChancePercent():
	return [1.0, 1.0, 1.0]


## Copies this card and returns the copy.
func copyCard():
	return Card.createCard(ClassRegistry.getClassName(self), level, all, type, price)


#####################
#  DRAWING METHODS  #
#####################

## Java overloads:
##   drawCard(g, x, y)                        -> size .7
##   drawCard(g, x, y, float size)            -> NORMAL, this level
##   drawCard(g, x, y, size, int type, int level)
func drawCard(g, x, y, size = null, type = null, level = null):
	if size == null:
		drawCard(g, x, y, 0.7)
		return
	if type == null:
		drawCard(g, x, y, size, NORMAL, self.level)
		return
	var s: float = float(size)
	var yy: int = int(y + s * 25)
	g.drawImage(images[type][BASE], x, y, s)
	if level == 1:
		g.drawImage(images[type][BALL], x + (s * 65), yy, s)
	elif level == 2:
		g.drawImage(images[type][BALL], x + (s * 50), yy, s)
		g.drawImage(images[type][BALL], x + (s * 80), yy, s)
	elif level == 3:
		g.drawImage(images[type][BALL], x + (s * 40), yy, s)
		g.drawImage(images[type][BALL], x + (s * 65), yy, s)
		g.drawImage(images[type][BALL], x + (s * 90), yy, s)


## Bridge (phase 3 step B): drawCard(g, x, y, size) without the drawing: its
## images bound as it binds them (Graphics.skip_image). Returns the picture's
## texture, the ball's (null when no ball is drawn) and the level.
func place_card(g) -> Array:
	var base = g.skip_image(images[NORMAL][BASE])
	var ball = null
	if level >= 1 and level <= 3:
		for i in range(level):
			ball = g.skip_image(images[NORMAL][BALL])
	return [base, ball, level]


## Draws the card on the given graphics in black and white.
## Java overloads: drawGrayCard(g, x, y) and drawGrayCard(g, x, y, size).
## Note: as in the original, the three argument version draws the normal
## (colored) card.
func drawGrayCard(g, x, y, size = null):
	if size == null:
		drawCard(g, x, y, 0.7)
	else:
		drawCard(g, x, y, size, GRAY, level)


#####################
# GETTERS & SETTERS #
#####################

func getGrayImage(type):
	return images[GRAY][type]


func getImage(type):
	return images[NORMAL][type]


## Gets the cards level.
func getLevel():
	return level


func _getPercent():
	if not _percentCreated:
		PERCENT = createAttackPercent()
		_percentCreated = true
	return PERCENT


func _getEffectChancePercent():
	if not _effectChancePercentCreated:
		EFFECT_CHANCE_PERCENT = createEffectChancePercent()
		_effectChancePercentCreated = true
	return EFFECT_CHANCE_PERCENT


## Gets the attack percent of this card at its current level. This is the
## amount of percent that this card should boost the attackers attack.
func getAttackPercent():
	return _getPercent()[level - 1]


func getEffectChanceToHit():
	return _getEffectChancePercent()[level - 1]


## Gets the type of the card. Could be either of Slot.ATTACK, Slot.MAGIC
## or Slot.SUPPORT.
func getType():
	if type == NEUTRAL and slotType != -1:
		return slotType
	return type


func putInSlot(kind):
	slotType = kind


func reset():
	slotType = -1


## Checks if this card is an all-card (takes damage on all enemies).
func isAll():
	return all


## Converts the given name that follow the java method naming convention
## in normal readable form. This means that the name HerbOfVitality will
## become Herb Of Vitality.
static func getNameWithSpaces(p_name):
	var n: String = p_name
	var sb: String = ""
	while true:
		# Java: m.find(1) - the first upper case letter at index >= 1.
		var i: int = -1
		for k in range(1, n.length()):
			var c: int = n.unicode_at(k)
			if c >= 65 and c <= 90:
				i = k
				break
		if i == -1:
			break
		var found: String = J.substring(n, 0, i)
		n = J.substring(n, i)
		if found.length() != 0:
			sb += found + " "
	sb += n
	return sb


## Gets the name of the card. This is the name to display for the player
## I.e not cards.neutral.TheElementOfEarth but only Earth Element.
func getName():
	return name


## Gets the cards element. This is either FIRE_ELEMENT, ICE,
## EARTH, WIND, or NO_ELEMENT at all.
func getElement():
	return element


## Gets the information about this card (name line + three line "story").
func getInfo():
	return info


## Sets the element of this card. If this method is not overridden
## the element will be set to the default element NO_ELEMENT.
func setElement():
	element = NO_ELEMENT


## Java overloads:
##   public setImage()                       -> sets the base and ball images
##   private setImage(String name, int type)
func setImage(name = null, type = null):
	if name == null:
		setImage(self.name, BASE)
		setImage("blueball" if all else "ball", BALL)
		return
	var normalName: String = Values.Cards + name + ".png"
	var grayName: String = Values.Cards + name + "gray.png"
	# Java's ImageHandler.addPermanentlyConvertNow only stored the image when
	# the name was not known yet; skip the (costly) conversion in that case.
	if ImageHandler.permanentList.has(normalName) and ImageHandler.permanentList.has(grayName):
		images[NORMAL][type] = normalName
		images[GRAY][type] = grayName
		return
	var im: Image = ImageHandler.getImage(Values.Cards, name + ".png")
	if im == null:
		push_error("AbstractCard.setImage: missing card image " + normalName)
		images[NORMAL][type] = normalName
		images[GRAY][type] = grayName
		return
	var gray: Image = GraphicHelp.toGrayScale(im)
	if not ImageHandler.permanentList.has(normalName):
		images[NORMAL][type] = ImageHandler.addPermanentlyConvertNow(normalName, im)
	else:
		images[NORMAL][type] = normalName
	if not ImageHandler.permanentList.has(grayName):
		images[GRAY][type] = ImageHandler.addPermanentlyConvertNow(grayName, gray)
	else:
		images[GRAY][type] = grayName


## Sets the cards level.
func setLevel(level):
	self.level = level


## Gets the price of this specific card.
func getPrice():
	return price


####################
# ABSTRACT METHODS #
####################

## Creates the information about this card (three lines).
func createTextInfo():
	return ["", "", ""]


## Creates the array containing the attacking strength of this card.
func createAttackPercent():
	return null


## Creates the value to compare with other cards when sorting.
func createSortingValue():
	pass


func createShortInfo():
	pass


func getVeryShortInfo():
	return null
