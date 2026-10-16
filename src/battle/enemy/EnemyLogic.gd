class_name EnemyLogic
extends RefCounted
## Port of battle.enemy.EnemyLogic: chooses the enemy moves and targets and
## calculates the damage of the enemy attacks.
## Port note: makeMove(Enemy, ArrayList) and makeMove(AttackInfo) are merged;
## a single AttackInfo argument selects the second overload.

static var target: int = 0
static var criticalHit: bool = false
static var lastAttack = null
static var battle = null


## Calculates which party member the enemy should hit (never a dead one).
static func calcTarget(characters):
	if lastAttack.getType() == Slot.SUPPORT:
		target = CharacterRow.NO_TARGET
	elif lastAttack.isAll():
		target = CharacterRow.ON_ALL
	else:
		var alive: Array = []
		for i in characters.size():
			if characters[i].isAlive():
				alive.append(i)
		var rand := JRandom.new()
		target = alive[rand.nextInt(alive.size())]
	return target


## Calculates the damage made by an enemy and fills attackText with the
## results. Returns the index of the target in characters.
static func calcEnemyDamage(enemy, enemies, characters, attackText, p_battle):
	EnemyLogic.battle = p_battle
	if lastAttack.getTarget() == CharacterRow.NO_TARGET:
		return CharacterRow.NO_TARGET
	var type: int = lastAttack.getType()
	var effects: Array = lastAttack.getEffects()
	if type == Slot.SUPPORT:
		if lastAttack.isAll():
			for i in enemies.size():
				calcSupport(enemies[i], attackText, i, effects)
		else:
			calcSupport(enemy, attackText, target, effects)
	else:
		if lastAttack.isAll():
			for i in characters.size():
				if characters[i].isAlive():
					attackTarget(enemy, characters, attackText, i, effects)
		else:
			attackTarget(enemy, characters, attackText, target, effects)
		enemy.updateBoosts()
		return target

	return -1


static func calcSupport(enemy, attackText, index, effects):
	var type: int = lastAttack.getType()
	var power: float = lastAttack.getPower()

	var damage: int = doit(enemy, null, attackText, effects, null, power)
	if damage == -1:
		return

	var amountToHeal: int = J.round(enemy.getBattleAttack(type) * power)

	var x: float
	var y: float
	if index == target:
		x = 0
		y = -0.6
	else:
		var pos: Array = BattleValues.getEnemyPosForText(index)
		x = pos[0]
		y = pos[1]
	attackText.addCenter(str(amountToHeal), x, y, true, AttackText.textSize.LARGE)
	enemy.addHP(amountToHeal, true)
	enemy.updateBoosts()


static func attackTarget(enemy, characters, attackText, p_target, effects):
	var type: int = lastAttack.getType()
	var power: float = lastAttack.getPower()
	var pos: Array = BattleValues.getCharPosForText(p_target)

	var targetChar = null
	if p_target >= 0:
		targetChar = characters[p_target]
	var damage: int = doit(enemy, targetChar, attackText, effects, pos, power)
	if damage == -1 or targetChar == null:
		return

	var attack: int = J.round(enemy.getBattleAttack(type) * power)
	var defense: int = targetChar.getBattleDefense(type)
	damage = maxi(attack - defense, 0)

	var attElem: int = lastAttack.getElement()
	if attElem == Card.NO_ELEMENT:
		attElem = enemy.getElement()
	var defElem: int = targetChar.getElement()
	damage = Card.addElementContribution(attElem, defElem, damage)

	if Battle.calcMiss(targetChar, enemy, 0):
		attackText.addCenter("Miss", pos[0], pos[1], false)
	else:
		var addition: String = ""
		var crit: float = enemy.getAttribute(Creature.CRITICAL_HIT_PRECENT)
		var critPre: float = crit / 100.0
		criticalHit = J.random() < critPre
		if criticalHit:
			addition = "Crit"
			damage *= AbstractCard.CRITICAL_INCREASE
		if damage > 0:
			targetChar.damage(damage)
			if not targetChar.isAlive():
				if targetChar.getName() == "Kin" or targetChar.getName() == "Borealis":
					SoundPlayer.playSound(SoundMap.BATTLE_KIN_BOREALIS_DYING)
				elif targetChar.getName() == "Celis" or targetChar.getName() == "Zalzi":
					SoundPlayer.playSound(SoundMap.BATTLE_CELIS_ZALZI_DYING)
			attackText.addCenter(addition + str(damage), pos[0], pos[1], false)
			doit2(effects, enemy, attackText, damage)
		else:
			attackText.addCenter("No Damage", pos[0], pos[1], false)


static func doit(enemy, character, attackText, effects, pos, power):
	var hit = doit1(effects, enemy, attackText, character, pos)
	var damage: int = 0
	if hit != null:
		if hit == Death.TEXT:
			damage = character.damage(character.getAttribute(Creature.HP))
			character.damage(damage)
			attackText.addCenter(hit, pos[0], pos[1], false)
		doit2(effects, enemy, attackText, damage)
		return -1
	return -1 if power == 0 else damage


static func doit1(effects, enemy, text, p_target, pos):
	var y: float = 0.0
	for eae in effects:
		var name: String = eae.getName()
		if name == "Element Change":
			enemy.changeElement(eae.getValuei())
			text.addCenter(Elements.TEXT, 0, y, true)
		elif name == "Heal":
			var percent: float = eae.getValuef()
			var ahp: int = enemy.curePercent(percent)
			text.addCenter("Healed " + str(ahp), 0, y, true)
		elif name == "Dispel":
			var chance: float = eae.getValuef()
			var list: Array = enemy.getBoostList()
			for b in list:
				b.dispelNegativeEffectWithChance(chance)
			text.addCenter("Dispel", 0, y, true)
		elif name == "DownTo":
			var hp: int = eae.getValuei()
			var damage: int = p_target.cure(hp - p_target.getAttribute(Creature.HP))
			text.addCenter(str(-damage), pos[0], pos[1], false)
		elif name == "Renew":
			var percent: float = eae.getValuef()
			enemy.curePercent(percent)
			text.addCenter("Renewed!", 0, y, true)
		elif name == "Death":
			var percent: float = eae.getValuef()
			if Values.rand.nextFloat() <= percent:
				return Death.TEXT
		elif name == "cardPref":
			enemy.addCardPreferences(eae.getValues(), eae.getValuei())
		elif name == "dialog":
			battle.setDialog(eae.getDialog())
		elif name == "music":
			battle.changeMusic(eae.getValues())
		elif name.begins_with("Boost "):
			name = name.replace("Boost ", "")
			var boost: float = eae.getValuef()
			var c = null
			if boost < 0:
				c = p_target
				text.addCenter(name, pos[0], pos[1], false)
				# TODO (original): Don't play multiple times if on all character.
				SoundPlayer.playSound(SoundMap.MAGICS_STATUS_DOWN)
			else:
				c = enemy
				text.addCenter(name, 0, y, true)
				SoundPlayer.playSound(SoundMap.MAGICS_STATUS_UP)
			if name.begins_with("Magic Attack"):
				c.boostMagicAttack(eae.getValuei(), boost)
			elif name.begins_with("Attack"):
				c.boostAttack(eae.getValuei(), boost)
			elif name.begins_with("Support"):
				c.boostSupport(eae.getValuei(), boost)
			elif name.begins_with("Magic Defense"):
				c.boostMagicDefense(eae.getValuei(), boost)
			elif name.begins_with("Defense"):
				c.boostDefense(eae.getValuei(), boost)
			elif name.begins_with("Agility"):
				c.boostSpeed(eae.getValuei(), boost)
			elif name.begins_with("Hp"):
				c.boostLife(eae.getValuei(), boost)
			elif name.begins_with("All"):
				c.boostDefense(eae.getValuei(), boost)
				c.boostMagicDefense(eae.getValuei(), boost)
				c.boostAttack(eae.getValuei(), boost)
				c.boostMagicAttack(eae.getValuei(), boost)
		y += AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT
	return null


static func doit2(effects, enemy, text, damage):
	for eae in effects:
		var name: String = eae.getName()
		if name == "Drain":
			var hp: float = eae.getValuef() * damage
			var ahp: int = enemy.cure(hp)
			text.addCenter("Drained " + str(ahp), 0, 0, true)


static func getCriticalHit():
	return criticalHit


static func makeMove(enemy, characters = null):
	if characters == null and enemy is AttackInfo:
		lastAttack = enemy
		return lastAttack
	var type: int = enemy.getAttackType()
	lastAttack = enemy.getInfo().getRandomAttack(type)
	if lastAttack.getType() == Slot.SUPPORT:
		var hp: float = enemy.getAttribute(Creature.HP)
		var maxhp: float = enemy.getAttribute(Creature.MAX_HP)
		if hp / maxhp > 0.5:
			lastAttack = enemy.getInfo().getRandomAttack(
					enemy.getAttackTypeExcluedSupport())
	return lastAttack
