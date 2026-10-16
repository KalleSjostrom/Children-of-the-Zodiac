class_name BattleAnimation
extends RefCounted
## Port of battle.Animation: the animation (particle systems) shown when a
## character plays cards. It also does the actual damage on the targets.
##
## Port note: the Java thread in nextSystem() (sleep 400 ms for offense
## cards, then add the next system) is a Scheduler.after() callback.

var currentSystem = []
var test = {}
var attackText = AttackText.getAttackText()
var list = null
var hitElements = []
var targets = null
var enemy = null
var attacker = null
var target: int = 0
var initialTarget: int = 0
var done: bool = false
var update_: bool = false
var animationDone: bool = false
var tempCurrent: int = -1
var characters = null


## Java overloads:
##   init(ArrayList<GLCard> cards, int targetIndex, ArrayList<Creature> creatureList,
##        BattleEnemy enemy, Character attacker, CharacterRow glCharacters)
##   init(String text, int index)  [shows the text next to the character]
func init(cards, targetIndex, creatureList = null, p_enemy = null, p_attacker = null, glCharacters = null):
	if cards is String:
		reset()
		animationDone = true
		var pos = BattleValues.getCharPosForText(targetIndex)
		# float off = text.length() * .05f;
		attackText.add(cards, pos[0], pos[1], true)
		return
	reset()
	self.list = cards
	self.enemy = p_enemy
	self.attacker = p_attacker
	characters = glCharacters

	targets = creatureList
	target = targetIndex
	initialTarget = targetIndex
	nextSystem()


## Resets this animation: clears the lists and the temporary values.
func reset():
	done = false
	animationDone = false
	tempCurrent = -1
	currentSystem = []
	hitElements.clear()
	test.clear()
	# attackText.reset()


## Changes the current system to the next one in the list (called when a
## particle system has exploded and the next should be fired).
func nextSystem():
	tempCurrent += 1
	if tempCurrent < list.size():
		var c = list[tempCurrent].getCard()
		var sleepTime: int = 400 if ClassRegistry.getClassName(c).contains("offense") else 0
		var currentList = list
		Scheduler.after(sleepTime, func(): _addSystem(c, currentList))
	else:
		animationDone = true


## The part of the Java thread in nextSystem() that runs after the sleep.
func _addSystem(c, currentList) -> void:
	if not is_same(currentList, list):
		return # a new animation was started during the sleep
	if tempCurrent >= list.size():
		# Java would throw in its thread here (list cleared during the sleep).
		animationDone = true
		return
	var s := AnimationSystem.new(tempCurrent, getSystem(c, getElement(c)))
	currentSystem.append(s)
	c.playSound()


## Gets the element of the card, or the attacker's element if it has none.
func getElement(c):
	var elem: int = c.getElement()
	if elem == AbstractCard.NO_ELEMENT:
		elem = attacker.getElement()
	return elem


## Gets the list of HitElements in this Animation.
func getList():
	return sortList(hitElements)


## Merges all the Hit Elements with the same card.
func sortList(he):
	var c = null
	var result = []
	for i in range(he.size()):
		var elem = he[i]
		var card = elem.getCard()
		if c == card:
			result[result.size() - 1].merge(elem)
		else:
			var t = test.get(card)
			if t == null:
				elem.setTest(initialTarget)
			else:
				elem.setTest(t)
			result.append(elem)
			c = card
	return result


## Gets the particle system packet for the given card.
func getSystem(c, color):
	var onEnemy: bool = targets[0] is Enemy
	var onAll: bool = list[tempCurrent].getCard().isAll()
	var info := AnimationInfo.new()
	info.setTarget(target)
	info.setOnEnemy(onEnemy)
	info.setOnAll(onAll)
	info.setEnemy(enemy)
	info.setAttacker(attacker)
	info.setCharacters(characters)
	info.setLevel(c.getLevel())
	var aps = c.getAnimation(info)

	return aps


## Draws the current particle systems and the attack texts.
func draw(g):
	if currentSystem != null:
		for s in currentSystem:
			var psp = s.getSystem()
			psp.draw(g)
	attackText.draw(g)


## Updates the current particle systems. Returns true if the animation has
## damaged an enemy and is in need of a graphical update.
func update(elapsedTime):
	if currentSystem.size() > 0:
		for s in currentSystem.duplicate():
			var psp = s.getSystem()
			psp.update(elapsedTime / 1000.0)

			if psp.isDestroyed() and not psp.isAdded():
				psp.add()
				var isEnemy: bool = targets[target] is Enemy

				attackTarget(isEnemy, s.index)
				if isEnemy:
					var e = hitElements[hitElements.size() - 1]
					enemy.setHideTimer(200, e.isCrit())
			if psp.isReady():
				nextSystem()
	elif animationDone:
		done = attackText.isDone()
	var i: int = 0
	while i < currentSystem.size():
		if currentSystem[i].getSystem().isDead():
			J.removeAt(currentSystem, i)
		else:
			i += 1
	return checkUpdate()


## Damages the targets with the card at the given index.
func attackTarget(onEnemy, index):
	update_ = true
	var c = list[index].getCard()
	var onAll: bool = c.isAll()
	var damage: int = 0
	var testElem = null
	var cureElement = null
	if onAll:
		for i in range(targets.size()):
			if targets[i].isAlive() or c is Resurrect:
				var newElement = c.use(targets[i], attacker)
				var tempCure = newElement.getCureElement()
				if tempCure != null:
					if cureElement == null:
						cureElement = tempCure
					else:
						cureElement.cureMerge(tempCure)
				hitElements.append(newElement)
				damage += damageEnemy(i, onEnemy, newElement, index)
	else:
		if targets[target].isAlive() or c is Resurrect:
			testElem = c.use(targets[target], attacker)
			damage = damageEnemy(target, onEnemy, testElem, index)
			hitElements.append(testElem)
			cureElement = testElem.getCureElement()
	if onEnemy and c.getType() != Slot.SUPPORT:
		enemy.changeColor(currentSystem[0].getSystem().getColor())

	# Only for drain!
	if cureElement != null:
		attacker.cure(cureElement.getAttackDamage())
		createAttackTextForAttacker(cureElement)


## Damages the creature, creates the attack text and returns the damage.
func damageEnemy(enemyIndex, p_enemy, he, current):
	var c = targets[enemyIndex]
	var alive: bool = c.isAlive()
	var damage: int = c.addHP(he.getAttackDamage(), he.isSupport())
	if enemyIndex == target and alive and not c.isAlive():
		# Main target is dead!
		clearList(current)

	var elem: bool = he.getCard() is Elements
	if p_enemy and enemyIndex == target:
		createAttackText(he)
	else:
		var support: bool
		if elem:
			support = not p_enemy
		else:
			support = he.isSupport()
		createAttackText(enemyIndex, he, p_enemy, support, p_enemy and (enemyIndex == target))
	if elem and he.didHit():
		c.changeElement(he.getCard().getElement())
	return damage


## Clears some of the animations when the main target has died.
func clearList(current):
	if Creature.isTeamDead(targets):
		list.clear()
	else:
		# If the attack continues after the main target is dead
		target += 1
		target %= targets.size()
		for i in range(current + 1, list.size()):
			var c = list[i].getCard()
			test[c] = target


## Java overloads:
##   createAttackText(HitElement he)                       [enemy in the middle]
##   createAttackText(int i, HitElement he, boolean enemy, boolean support, boolean large)
##   createAttackText(HitElement he, float x, float y, boolean support, boolean large)
func createAttackText(i, he = null, p_enemy = null, support = null, large = null):
	if he == null:
		# createAttackText(HitElement he)
		_createAttackTextAt(i, 0, 0, i.isSupport(), true)
	elif i is HitElement:
		_createAttackTextAt(i, he, p_enemy, support, large)
	else:
		var pos
		if p_enemy:
			pos = BattleValues.getEnemyPosForText(i)
		else:
			pos = BattleValues.getCharPosForText(i)
		var x: float = pos[0] # + (enemy ? 0 : i * pos[2])
		var y: float = pos[1] # + (enemy ? i * pos[2] : 0)
		_createAttackTextAt(he, x, y, support, large)


func _createAttackTextAt(he, x: float, y: float, support: bool, large: bool) -> void:
	var s = he.getEffectText(0)
	if s != null and s != "":
		attackText.addCenter(s, x, y, support, AttackText.getSize(large))
		if he.getActuallAttackDamage() != -1:
			y -= AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT
			attackText.addCenter(
					he.getActuallAttackDamage(), x, y, support, AttackText.getSize(large))
	else:
		attackText.addCenter(he.getAttackDamage(), x, y, support, AttackText.getSize(large))


## Creates the attack text shown at the attacker (e.g. "Drained 53").
func createAttackTextForAttacker(he):
	var pos = BattleValues.getCharPosForText(attacker.getIndex())
	var x: float = pos[0] # + attacker.getIndex() * pos[2]
	var y: float = pos[1]
	var s = he.getEffectText(0)
	attackText.addCenter(("null" if s == null else str(s)) + " " + str(he.getAttackDamage()), x, y, true)


## Returns the update flag and resets it to false.
func checkUpdate():
	if update_:
		update_ = false
		return true
	return false


## Checks if the animation is done.
func isDone():
	return done


class AnimationSystem extends RefCounted:
	var psp = null
	var index: int = 0

	func _init(p_index = null, system = null) -> void:
		self.index = p_index
		psp = system

	func getSystem():
		return psp


class AnimationInfo extends RefCounted:
	var nrTarget: int = 0
	var target: int = 0
	var onEnemy: bool = false
	var onAll: bool = false
	var enemy = null
	var attacker = null
	var characters = null
	var level: int = 0

	func _init() -> void:
		pass

	func getNrTarget():
		return nrTarget

	func getTarget():
		return target

	func isOnEnemy():
		return onEnemy

	func isOnAll():
		return onAll

	func getEnemy():
		return enemy

	func getAttacker():
		return attacker

	func getCharacters():
		return characters

	func getLevel():
		return level

	func setNrTarget(p_nrTarget):
		self.nrTarget = p_nrTarget

	func setTarget(p_target):
		self.target = p_target

	func setOnEnemy(p_onEnemy):
		self.onEnemy = p_onEnemy

	func setOnAll(p_onAll):
		self.onAll = p_onAll

	func setEnemy(p_enemy):
		self.enemy = p_enemy

	func setAttacker(p_attacker):
		self.attacker = p_attacker

	func setCharacters(p_characters):
		self.characters = p_characters

	func setLevel(p_level):
		self.level = p_level
