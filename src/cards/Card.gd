class_name Card
extends AbstractCard
## Port of cards.Card.
##
## This class extends the abstract card with the additional functions of
## sorting and damage calculating when attacking.

const IMMUNE = 0
const HIT = 1
const MISS = 2

const PREFERENCE = 0
const DEFENSE_BOOST = 1
var storeStatus: int = 0
var sortingValue: String = ""
var databaseName = null
## Port addition (COTZ-014): the attacks rolled by roll_hits, target ->
## HitElement, until use() takes them (rolled_hit).
var rolledHits := {}


## Port addition (COTZ-014): rolls this card's attack on the creatures its
## animation goes to (AnimationInfo.getTargetCreatures) when the animation
## starts, so that the animation can leave a missed enemy alone (Earth's
## shake, Destroyer's slice; Java rolled at the impact and shook anyway).
## True unless every one of them is missed. use() returns the rolls.
func roll_hits(info) -> bool:
	rolledHits.clear()
	if not info.isOnEnemy() or info.getTargetCreatures().is_empty():
		return true
	var hit := false
	for target in info.getTargetCreatures():
		var he = attack(target, info.getAttacker())
		rolledHits[target] = he
		hit = hit or not he.isMiss(0)
	return hit


## use() of a card that rolls its hits before the animation: the roll for
## the target, else a new attack.
func rolled_hit(target, attacker):
	var he = rolledHits.get(target)
	if he == null:
		return attack(target, attacker)
	rolledHits.erase(target)
	return he


## This method creates the value that this card should have.
## This value is then used when sorting the cards. The value of the
## card is calculated by the appending the following numbers:
## type, name, level, all (0 if true).
func createSortingValue():
	var i: int = 0 if all else 1
	sortingValue = str(getType()) + getName() + str(level) + str(i)


## Implements the compareTo() method (Comparable<Card>).
##
## Returns a negative value if this card is less than the given card, 0 if
## equal and a positive value if greater.
func compareTo(c):
	return J.compareTo(sortingValue, c.sortingValue)


func getSortingValue():
	return sortingValue


## Java overloads:
##   createCard(StringTokenizer tokenizer)
##   createCard(String name, StringTokenizer tokenizer)
##   createCard(String name, int level, boolean all)
##   createCard(String name, int level, boolean all, int type, int price)
## name is the Java class name to instantiate, e.g. cards.offense.BattleCard.
static func createCard(name, level = null, all = null, type = null, price = null):
	if name is StringTokenizer:
		var tokenizer: StringTokenizer = name
		var n: String = tokenizer.nextToken()
		return createCard(n, tokenizer)
	if level is StringTokenizer:
		var tokenizer: StringTokenizer = level
		var lvl: int = J.parseInt(tokenizer.nextToken())
		var a: bool = false
		var p: int = 0
		if tokenizer.hasMoreTokens():
			var val: String = tokenizer.nextToken()
			if val == "true" or val == "false":
				a = J.parseBoolean(val)
				if tokenizer.hasMoreTokens():
					p = J.parseInt(tokenizer.nextToken())
			else:
				p = J.parseInt(val)
		return createCard(name, lvl, a, getTypeStatic(name), p)
	if type == null:
		return createCard(name, level, all, getTypeStatic(name), 0)
	var card = ClassRegistry.newInstance(name)
	# Java printed a stack trace; null for the caller (in a release build).
	assert(card != null, "Card.createCard: no card class " + str(name))
	if card == null:
		return null
	card.init(level, all, type, price)
	return card


## Java: static int getType(String name).
static func getTypeStatic(name):
	var t: int = 0
	if name.contains("offense"):
		t = AbstractCard.OFFENSE
	elif name.contains("magic"):
		t = AbstractCard.MAGIC
	elif name.contains("support"):
		t = AbstractCard.SUPPORT
	elif name.contains("neutral"):
		t = AbstractCard.NEUTRAL
	return t


## This method copies this card and returns the copy.
func copyCard():
	return createCard(ClassRegistry.getClassName(self), level, all, type, getPrice())


## This method only maps the short prefixes o, s, m and n into
## cards.offense, cards.support, cards.magic and cards.neutral.
static func getPrefix(prefix):
	var ret: String = ""
	if prefix == "o":
		ret = "cards.offense."
	elif prefix == "s":
		ret = "cards.support."
	elif prefix == "m":
		ret = "cards.magic."
	elif prefix == "n":
		ret = "cards.neutral."
	return ret


## Java overloads (all protected):
##   attack(target, attacker)
##   attack(target, attacker, boolean ignoreCheck)
##   attack(target, attacker, float critPrecent)
##   attack(target, attacker, float critPrecent, boolean ignoreCheck)
##   attack(target, attacker, String effect, boolean ignoreCheck)
##   attack(target, attacker, float critPrecent, String effect, boolean ignoreCheck)
##   attack(target, attacker, float critPrecent, String effect,
##          int attackType, int defenseType, int extraAttack, boolean ignoreCheck)
## Carries out an attack made by the attacker on the given target and
## returns the HitElement containing the information about the attack.
func attack(target, attacker, critPrecent = null, effect = null, attackType = null, defenseType = null, extraAttack = null, ignoreCheck = null):
	if critPrecent == null:
		return attack(target, attacker, false)
	if critPrecent is bool and effect == null:
		return attack(target, attacker, CRITICAL_PRECENT, critPrecent)
	if critPrecent is String:
		# attack(target, attacker, String effect, boolean ignoreCheck)
		return attack(target, attacker, CRITICAL_PRECENT, critPrecent, effect)
	if effect == null:
		# attack(target, attacker, float critPrecent)
		return attack(target, attacker, critPrecent, false)
	if effect is bool:
		# attack(target, attacker, float critPrecent, boolean ignoreCheck)
		return attack(target, attacker, critPrecent, "", effect)
	if attackType is bool or attackType == null:
		# attack(target, attacker, float critPrecent, String effect, boolean ignoreCheck)
		var ic: bool = false if attackType == null else attackType
		return attack(target, attacker, critPrecent, effect, getType(), getType(), 0, ic)
	var he = null
	if not ignoreCheck:
		he = checkPreferences(target, attacker, self, null)
	if he == null:
		he = actuallAttack(target, attacker, critPrecent, effect, attackType, defenseType, extraAttack)
	return he


## Java overloads: checkPreferences(target, attacker, attackingCard, text)
## and checkPreferences(target, attacker, attackingCard, text, sureHit).
static func checkPreferences(target, attacker, attackingCard, text, sureHit = null):
	if sureHit == null:
		sureHit = false
	var he = null
	var ret: int = checkPreferences2(
			target, attacker, text, sureHit,
			ClassRegistry.getClassName(attackingCard),
			ClassRegistry.getSimpleName(attackingCard))
	match ret:
		IMMUNE:
			he = HitElement.new(attackingCard, -1, HitElement.IMMUNE, "")
		HIT:
			if text != null:
				he = HitElement.new(attackingCard, -1, HitElement.NORMAL, text)
		MISS:
			he = HitElement.new(attackingCard, -1, HitElement.MISS, "")
	return he


static func checkPreferences2(target, attacker, text, sureHit, fullName, simpleName):
	var ret = getPreferences(target, attacker, text, sureHit, fullName, simpleName)
	var preference: float = ret[PREFERENCE]
	var defenseBoost: float = ret[DEFENSE_BOOST]
	var retVal: int

	if preference == 0:
		retVal = IMMUNE
	else:
		if sureHit or not Battle.calcMiss(target, attacker, defenseBoost):
			retVal = HIT
		else:
			retVal = MISS
	return retVal


static func checkPreferences3(target, attacker, text, sureHit, ac, fullName, simpleName):
	var ret = getPreferences(target, attacker, text, sureHit, fullName, simpleName)
	var preference: float = ret[PREFERENCE]
	var defenseBoost: float = ret[DEFENSE_BOOST]
	var retVal: int

	if preference == 0:
		retVal = IMMUNE
	else:
		if sureHit or (Values.rand.nextFloat() <= (ac.getEffectChanceToHit() - defenseBoost)):
			retVal = HIT
		else:
			retVal = MISS
	return retVal


static func getPreferences(target, attacker, text, sureHit, fullName, simpleName):
	var defenseBoost: float = 0.0
	var preference: float = -1.0
	if target is Enemy:
		var e: Enemy = target
		if fullName.contains("magic"):
			preference = e.getCardPreference("magic")
		elif fullName.contains("neutral"):
			preference = e.getCardPreference("neutral")
		elif fullName.contains("offense"):
			preference = e.getCardPreference("offense")
		elif fullName.contains("support"):
			preference = e.getCardPreference("support")
		var p: float = e.getCardPreference(simpleName)
		if preference == -1:
			preference = p
		elif p != -1:
			preference = minf(preference, p)
		# check preferences!!
		if preference > 0:
			defenseBoost = preference / 100.0
	return [preference, defenseBoost]


## Carries out an attack made by the attacker on the given target. This
## method uses the given critPrecent as the chance to hit a critical blow.
func actuallAttack(target, attacker, critPrecent, effect, attackType, defenseType, extraAttack):
	var baseAttack: int = attacker.getBattleAttack(attackType) + extraAttack
	var defense: int = target.getBattleDefense(defenseType)

	var elem: int = target.getElement()

	var heroElem: int = attacker.getElement() if getElement() == NO_ELEMENT else getElement()
	var percent: float = getAttackPercent()

	var attack_: float = J.round(baseAttack * percent)
	var hitType: int = HitElement.NORMAL
	var damage: int = int(maxf(attack_ - defense, 0))
	if elem != Card.NO_ELEMENT and ClassRegistry.getClassName(self) == "cards.offense.ChameleonStrike":
		damage *= ELEMENT_INCREASE
	else:
		damage = J.round(addElementContribution(heroElem, elem, damage))

	if damage > 0:
		if Values.rand.nextFloat() < critPrecent:
			hitType = HitElement.CRIT
			damage *= CRITICAL_INCREASE
	else:
		damage = 0
	if damage > 0 and target is Enemy:
		damage = Difficulty.scale_ally_damage(damage)
	return HitElement.new(self, damage, hitType, effect)


static func addElementContribution(attackerElement, defenderElement, damage):
	var d: float = float(damage)
	if defenderElement != NO_ELEMENT and attackerElement != NO_ELEMENT:
		if defenderElement == attackerElement:
			d /= 2
		else:
			match defenderElement % 2:
				0:
					if defenderElement - attackerElement == 1:
						d *= ELEMENT_INCREASE
				1:
					if defenderElement - attackerElement == -1:
						d *= ELEMENT_INCREASE
	return J.round(d)


func setDatabaseName(dbName):
	databaseName = dbName


func setStoreStatus(storeStatus):
	self.storeStatus = storeStatus


func getDatabaseName():
	return databaseName


func getStoreStatus():
	return storeStatus


func setShortInfo(si):
	pass


## This method should be implemented with the specific rules of the
## card. It is called when the card is used by the given attacker
## on the given target. Returns the HitElement of the attack.
func use(target, attacker):
	return null


## Returns the ParticleSystemPacket animating this card.
func getAnimation(info):
	return null


func playSound():
	var soundEffectDelay = getSoundEffectDelay()
	var soundEffect = getSoundEffect()
	var size: int = mini(soundEffect.size(), getLevel())
	var found: bool = false
	var i: int = 0
	while i < size and not found:
		found = soundEffectDelay[0] > 0
		i += 1
	if found:
		_playSoundSequence(soundEffectDelay, soundEffect, size)
	else:
		for j in range(size):
			SoundPlayer.playSound(soundEffect[j])


## Replaces the Java sound thread: plays the sounds with the given delays
## (runs as a coroutine, call without await).
func _playSoundSequence(soundEffectDelay, soundEffect, size: int) -> void:
	for i in range(size):
		await Scheduler.sleep(soundEffectDelay[i])
		SoundPlayer.playSound(soundEffect[i])


func getSoundEffect():
	return [""]


func getSoundEffectDelay():
	return [0]


static func setSourceTargetVectorToLength(lenght, settings):
	var t = settings.getVector(AnimSettings.TARGET)
	var s = settings.getVector(AnimSettings.SOURCE)
	var temp = t.subtract(s)
	temp.normalizeLocal().multLocal(float(lenght))
	t = s.add(temp)
	settings.setVector(AnimSettings.TARGET, t)


static func setTargetSourceVectorToLength(lenght, settings):
	var t = settings.getVector(AnimSettings.TARGET)
	var s = settings.getVector(AnimSettings.SOURCE)
	var temp = s.subtract(t)
	temp.normalizeLocal().multLocal(float(lenght))
	s = t.add(temp)
	settings.setVector(AnimSettings.SOURCE, s)


func canBeMerged():
	return true
