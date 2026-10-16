class_name Creature
extends RefCounted
## Port of character.Creature.
##
## This abstract class represents a creature in the game. A creature can
## either be a character or an enemy.

# Attributes for both characters and enemies.
const HP = 0

const DEFENSE = 1
const MAGIC_DEFENSE = 2
const AGILITY = 3
const EVADE = 4
const HIT = 5
const ATTACK = 6
const MAGIC_ATTACK = 7
const SUPPORT_ATTACK = 8
const MAX_HP = 9

# Attributes for only characters.
const EXP_LEFT_TO_NEXT_LEVEL = 10
const DECK_SIZE = 11
const CLASS = 12
const EXPERIANCE = 13
const LEVEL = 14

# Attributes for only enemies.
const ELEMENT = 10
const GOLD_SPOILS = 11
const EXPERIENCE_SPOILS = 12
const CRITICAL_HIT_PRECENT = 13

const HAS_NO_ARMOR = 0
const ARMOR_ALREADY_CRUSHED = 1
const ARMOR_CRUSHED = 2

static var map = createMap()
static var attributeMap = createAttributeMap()

var defenseBoost = Boost.new()
var magicDefenseBoost = Boost.new()
var attackBoost = Boost.new()
var magicBoost = Boost.new()
var lifeBoost = Boost.new()
var speedBoost = Boost.new()
var supportBoost = Boost.new()

var name = ""
var openWound_ = 0
var progress = 0.0
var alive = true
var resurrected = false
var tempCrushed = false
var active = true
var inTurn = false

## The attributes (Java float[]): an Array of floats.
var attributes = null
var updateTime = 0.0


## Creates a creature from the given name and attributes.
func _init(p_name = null, att = null) -> void:
	if p_name != null:
		name = p_name
	attributes = att
	progress = float(JRandom.new().nextInt(100))


## Creates a map from the attributes to a string telling which attribute it
## is. ATTACK becomes "Attack: ".
static func createMap():
	var m := {}
	m[ATTACK] = "Attack: "
	m[MAGIC_ATTACK] = "Magic Off: "
	m[SUPPORT_ATTACK] = "Support: "
	m[AGILITY] = "Agility: "
	m[DEFENSE] = "Defence: "
	m[MAGIC_DEFENSE] = "Magic Def: "
	m[HIT] = "Hit: "
	m[EVADE] = "Evade: "
	m[EXPERIANCE] = "Exp: "
	m[EXP_LEFT_TO_NEXT_LEVEL] = "Next Lv: "
	m[LEVEL] = "Level: "
	m[DECK_SIZE] = "Decksize: "
	return m


static func createAttributeMap():
	var m := {}
	m["hp"] = MAX_HP
	m["attack"] = ATTACK
	m["support"] = SUPPORT_ATTACK
	m["magic"] = MAGIC_ATTACK
	m["defense"] = DEFENSE
	m["magicDefense"] = MAGIC_DEFENSE
	m["agility"] = AGILITY
	m["evade"] = EVADE
	m["hit"] = HIT
	m["deckSize"] = DECK_SIZE
	m["expToNext"] = EXP_LEFT_TO_NEXT_LEVEL
	return m


static func getMap():
	return map


static func getAttributMap():
	return attributeMap


## Kills this creature.
func kill():
	attributes[HP] = 0.0
	alive = false


## Fully cures this creature, whether it's dead or not.
func fullLife():
	alive = true
	attributes[HP] = attributes[MAX_HP]


## Resets the current speed (progress in battle).
func resetSpeed():
	progress = 0.0


## Checks if the creature is alive (and updates the alive flag).
func isAlive():
	alive = attributes[HP] > 0
	return alive


## Fully cures this creature. But only if it is alive.
func fullCure():
	if isAlive():
		fullLife()


## Cures this creature with the given amount, if the creature is alive.
## Can not heal more than the creatures max life.
## Returns the amount that has been healed.
func cure(amount):
	if isAlive() or resurrected:
		resurrected = false
		var HpFromMax: int = J.round(attributes[MAX_HP] - attributes[HP])
		attributes[HP] += float(amount)
		if attributes[HP] > attributes[MAX_HP]:
			attributes[HP] = attributes[MAX_HP]
			return HpFromMax
		return J.round(amount)
	return 0


func curePercent(f):
	return cure(attributes[MAX_HP] * f)


## Sets this creature as active (drawn in color in battle).
func setActive(p_active):
	active = p_active


## Sets whether this creature has the turn in battle.
func setTurn(turn):
	inTurn = turn


## Adds the given value to the given attribute and returns the new value.
func addAttribute(attribute, value):
	attributes[attribute] += value
	return getAttribute(attribute)


func setAttribute(attribute, values):
	attributes[attribute] = float(values)


func isActive():
	return active


func hasTurn():
	return inTurn


## Increments the progress bar for this creature (battle idling mode).
func incrementSpeed():
	progress += updateTime * maxf(speedBoost.getCurrentBoost(), 0.1)


## Checks if this creature is ready to fight.
func isReady():
	return progress >= 100


## Checks if all the creatures in the given list are dead.
static func isTeamDead(list):
	var foundAliveChar := false
	var i := 0
	while i < list.size() and not foundAliveChar:
		foundAliveChar = list[i].isAlive()
		i += 1
	return not foundAliveChar


## Checks if one of the creatures in the given list is dead.
static func isOneInTeamDead(list):
	var foundDeadChar := false
	var i := 0
	while i < list.size() and not foundDeadChar:
		foundDeadChar = not list[i].isAlive()
		i += 1
	return foundDeadChar


## Damages this creature with the given amount. If the life goes below zero
## the creature is killed. Returns the amount actually damaged.
func damage(p_damage):
	var ret: int = getHP() if p_damage > getHP() else p_damage
	attributes[HP] -= p_damage
	if attributes[HP] <= 0:
		kill()
	return ret


func getHP():
	return J.round(attributes[HP])


## Java overloads: getAttribute(int attribute) returns the rounded value of
## the attribute; getAttribute() returns the attribute array itself.
func getAttribute(attribute = null):
	if attribute == null:
		return attributes
	return J.round(attributes[attribute])


## Gets the life formatted as "hp/maxHp".
func getLife():
	return str(getAttribute(HP)) + "/" + str(getAttribute(MAX_HP))


func getProgress():
	return progress


func getLifePrecent():
	return float(attributes[HP]) / float(attributes[MAX_HP])


func getName():
	return name


## Resets temporary values that only have effect until the current hand
## is played.
func resetTempValues():
	tempCrushed = false


## Gets the boosts (attack, defense, magic attack, magic defense, life) as
## 0 (none), 1 (boosted) or -1 (lowered).
func getBoosts():
	var a := J.array(5, 0)
	a[0] = getBoostValue(attackBoost.getCurrentBoost())
	a[1] = getBoostValue(defenseBoost.getCurrentBoost())
	a[2] = getBoostValue(magicBoost.getCurrentBoost())
	a[3] = getBoostValue(magicDefenseBoost.getCurrentBoost())
	a[4] = getBoostValue(lifeBoost.getCurrentBoost())
	return a


func getBoostList():
	var list := []
	list.append(attackBoost)
	list.append(defenseBoost)
	list.append(magicBoost)
	list.append(magicDefenseBoost)
	list.append(lifeBoost)
	list.append(speedBoost)
	list.append(supportBoost)
	return list


func getBoostValue(b):
	return 0 if b == 1 else (1 if b > 1 else -1)


func hasOpenWound():
	return lifeBoost.getCurrentBoost() < 1


func updateOpenWound():
	var val: int = getLifeBoost()
	damage(val)
	lifeBoost.update()
	return val


func getLifeBoost():
	return J.round(lifeBoost.getCurrentBoost() * attributes[Creature.MAX_HP])


## Updates all the boosts and wounds this creature has, if any.
func updateBoosts():
	if lifeBoost.getCurrentBoost() < 1:
		if self is Character:
			updateOpenWound()
	elif lifeBoost.getCurrentBoost() > 1:
		cure(getLifeBoost())
		lifeBoost.update()
	speedBoost.update()
	attackBoost.update()
	magicBoost.update()
	defenseBoost.update()
	magicDefenseBoost.update()


## Gets the mode of speed: BattleValues.HASTE, .SLOW or -1 for default.
func getSpeedMode():
	var mode: int = -1
	var boost: float = speedBoost.getCurrentBoost()
	if boost < 1:
		mode = BattleValues.SLOW
	elif boost > 1:
		mode = BattleValues.HASTE
	return mode


## Cures (p_cure == true) or damages this creature with the given hp.
func addHP(hp, p_cure):
	if p_cure:
		return cure(hp)
	return damage(hp)


## Resets all the possible boosts that this creature can have.
func resetBoost():
	defenseBoost.reset()
	magicDefenseBoost.reset()
	attackBoost.reset()
	magicBoost.reset()
	lifeBoost.reset()
	speedBoost.reset()


func boostDefense(turns, percent):
	defenseBoost.add(turns, percent)


func boostAttack(turns, percent):
	attackBoost.add(turns, percent)


func boostSupport(turns, percent):
	supportBoost.add(turns, percent)


func boostMagicDefense(turns, percent):
	magicDefenseBoost.add(turns, percent)


func boostMagicAttack(turns, percent):
	magicBoost.add(turns, percent)


func boostSpeed(turns, percent):
	speedBoost.add(turns, percent)


func boostLife(turns, percent):
	lifeBoost.add(turns, percent)


## Wounds this creature and sets it to bleed for some rounds.
func openWound():
	lifeBoost.add(AbstractCard.TURNS_TO_BOOST_MANY, -0.9)


## Sets the amount to increment the progress with in each battle update.
func setTime(u):
	updateTime = u


# ---------------------------------------------------------------------------
# Abstract methods (implemented by Character and Enemy)
# ---------------------------------------------------------------------------

func getBattleDefense(type):
	return 0


func getTotalAttack():
	return 0


func getTotalMagicAttack():
	return 0


func getTotalDefense():
	return 0


func getTotalMagicDefense():
	return 0


func crushArmor():
	return HAS_NO_ARMOR


func getElement():
	return 0


func changeElement(element):
	pass


func changeElementBack():
	pass


## A boost for one of the attributes (attack, defense and so on).
## Each entry of the boost list is [turns, percent].
class Boost extends RefCounted:
	const TURNS = 0
	const PERCENT = 1
	var boost = []
	var currentBoost = 1.0

	## Adds a new boost lasting the given amount of turns.
	func add(turns, percent):
		var found := false
		var i := 0
		while i < boost.size() and not found:
			var b = boost[i]
			if (percent < 0 and b[PERCENT] > 0) or (percent > 0 and b[PERCENT] < 0):
				# Adding negative boosts to a list of positive ones, or vice
				# versa: the current list is cleared and the new boost added.
				boost.clear()
			else:
				# Same kind of boost as already present: the most effective
				# one is used first.
				if (percent < 0 and percent < b[PERCENT]) or (percent > 0 and percent > b[PERCENT]):
					found = true
					boost.insert(i, [float(turns), float(percent)])
			i += 1
		if not found:
			boost.append([float(turns), float(percent)])
		currentBoost = 1 + boost[0][PERCENT]

	## Clears all boosts in this list.
	func reset():
		boost.clear()
		currentBoost = 1.0

	## Updates the boosts in this list (one turn passed).
	func update():
		if boost.size() > 0:
			var i := 0
			while i < boost.size():
				if boost[i][TURNS] > 0:
					boost[i][TURNS] -= 1
				else:
					boost.remove_at(i)
					i -= 1
				i += 1
			currentBoost = 1 + boost[0][PERCENT] if boost.size() > 0 else 1.0

	func getCurrentBoost():
		return currentBoost

	func dispelNegativeEffectWithChance(chance):
		if Values.rand.nextFloat() <= chance:
			if boost.size() > 0:
				var i := 0
				while i < boost.size():
					if boost[i][PERCENT] < 0:
						boost.remove_at(i)
					else:
						i += 1
				currentBoost = 1 + boost[0][PERCENT] if boost.size() > 0 else 1.0
