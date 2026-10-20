class_name Battle
extends SubGameMode
## Port of battle.Battle: the sub game mode that runs the battle logic. The
## BattleManager (a GameMode) creates it. The battle has the modes Idling,
## Battling, Enemy turn, Game over, Animate, Result, Spoils, Exit, ...
##
## Port notes: the Java threads (open wound, delayed talking / game over) are
## Scheduler callbacks / coroutines; the finishRound Semaphore is removed.

## The list containing all the idling creatures in the battle.
var idling = []
## The list containing all the enemies in the battle.
var enemies = []
## The queue which creatures, who are ready to battle, are put in.
var queue = BattleQueue.new()

var animate = BattleAnimation.new()
var attackText = null
var characters = null
var monster = null
var manager = null
var attacker = null
var glCharacters = null
var clock = null
var legend = null
var tutorial = null
var glEnemies = null
var enemy = null
var currentDeck = null
var hand = null
var resultScreen = ResultScreen.new()
var spoilsScreen = null
var finishRound_ = null # Java Semaphore (not needed)
var update_: bool = false
var firstTimeFlee: bool = true
var dialog = null
var mode: int = 0
var enemySize: int = 0


## Constructs a new Battle (boss: true if against a boss, en: the enemy,
## freq: the frequencies of two / three enemies, manager: the BattleManager).
func _init(boss = null, en = null, freq = null, p_manager = null) -> void:
	self.manager = p_manager
	characters = Load.getCharactersAsCreatures()
	attacker = characters[0]
	BattleValues.setCharacterPosition(characters.size())
	enemy = en
	fillIdling(boss, freq)
	attackText = AttackText.getAttackText()
	attackText.reset()

	hand = GLHand.new(characters, enemies)
	var e = enemies[0]
	monster = getBoss(e) if boss else BattleEnemy.new(e)
	monster.setBattle(self)
	clock = Clock.new()
	legend = Legend.new()
	tutorial = Tutorial.new(p_manager.getName(), false)

	glCharacters = CharacterRow.new()
	glCharacters.init(boss)
	glEnemies = EnemyRow.new(enemies)
	glEnemies.init(boss)
	currentDeck = attacker.get2DDeck()


func init():
	if monster is BattleBoss:
		var b = monster
		if b.wantsToTalk(BossDialog.BEGINNING):
			mode = BattleManager.TALKING
			dialog = b.next(BossDialog.BEGINNING)
			glCharacters.hide()
			glEnemies.hide()
	if mode != BattleManager.TALKING:
		mode = BattleManager.IDLING
		glCharacters.show()
		glEnemies.show()


## Fills the idling list with all of the battle participants and chooses how
## many enemies to battle.
func fillIdling(boss, freq):
	for i in range(Load.getCharacters().size()):
		var c = Load.getCharacters()[i]
		idling.append(c)
	idling.append(enemy)
	enemies.append(enemy)
	var rand: int = 0
	if not boss:
		var pre: float = J.random()
		if pre <= freq[BattleManager.THREE_ENEMIES]:
			rand = 2
		elif pre <= freq[BattleManager.TWO_ENEMIES] + freq[BattleManager.THREE_ENEMIES]:
			rand = 1
	for i in range(rand):
		var newEnemy = enemy.copy()
		idling.append(newEnemy)
		enemies.append(newEnemy)
	enemySize = enemies.size()
	setUpdateTime(idling)


## Updates the battle. Depending on the mode, different parts are updated.
func update(elapsedTime = null):
	currentDeck.update()
	glCharacters.update()
	glEnemies.update()
	legend.update()
	monster.update(elapsedTime)
	attackText.update(elapsedTime)
	if mode == BattleManager.ANIMATE and animate != null:
		update_ = animate.update(elapsedTime)

		if update_:
			glEnemies.checkDead()

		if animate.isDone():
			var list = animate.getList()
			if list != null and not list.is_empty():
				resultScreen.setHitElements(list)
				glEnemies.check()
				hand.update()
				mode = BattleManager.RESULT
				if Creature.isTeamDead(enemies):
					killMonster()
				show()
			else:
				finishRoundForCharacters(false, true)
	if mode == BattleManager.SPOILS:
		spoilsScreen.update(elapsedTime)
	elif mode == BattleManager.IDLING:
		updateIdlingMode()
	elif mode == BattleManager.BATTLING:
		if clock.timesUp():
			finishRound()
	if mode == BattleManager.ENEMY_TURN:
		if monster.shouldHit():
			calcEnemyDamage()
			monster.resetHit()
		if not monster.isHitting():
			if mode == BattleManager.ENEMY_TURN:
				switchMode(BattleManager.IDLING)
	currentDeck.updatePos()


func killMonster():
	monster.kill()
	if not (monster is BattleBoss and monster.continueBattleMusic()):
		manager.switchMusic("Level Up", 500)


## Called in the Idling mode: increments the speed of the creatures and
## starts the turn of the first one that is ready.
func updateIdlingMode():
	var i: int = 0
	while i < idling.size():
		var c = idling[i]
		if c.isAlive():
			c.incrementSpeed()
			if c.isReady():
				queue.enqueue(c)
				J.removeAt(idling, i)
		i += 1
	if not queue.isEmpty():
		var newChar = queue.dequeue()
		if newChar is Enemy:
			newChar.resetSpeed()
			enemy = newChar
			idling.append(enemy)
			switchMode(BattleManager.ENEMY_TURN)
		else:
			initNewRound(newChar)


## Sets the given character as the attacker of the next round and initiates
## the round (deck, clock, ...).
func initNewRound(character):
	attacker = character

	if character.get2DDeck().needsToShuffle():
		character.get2DDeck().shuffleAndDeal()
		var i: int = mini(character.getIndex(), BattleValues.CHAR_POS_FOR_TEXT.size() - 1)
		animate.init("Shuffle", i)
		mode = BattleManager.ANIMATE
	else:
		currentDeck = attacker.get2DDeck()
		currentDeck.initNewRound()
		clock.show()
		legend.show()
		clock.reset()
		hand.show()
		hand.reset()
		switchMode(BattleManager.BATTLING)
	attacker.setActive(true)
	attacker.setTurn(true)
	setActiveForAll(false)
	if tutorial.increment():
		mode = BattleManager.TUTORIAL
		tutorial.setActive(true)


## Initiates the drawing of the hand shown in battle.
func initDraw(g):
	clock.initDraw(g)
	legend.initDraw(g)
	hand.initDraw(g)
	hand.hide()


func drawTopLayer(g):
	if mode == BattleManager.RESULT:
		resultScreen.drawResult(g)
	elif mode == BattleManager.SPOILS:
		spoilsScreen.drawSpoils(g)
	legend.drawTopLayer(g)
	tutorial.drawTopLayer(g)


## Draws the current deck, the hand, the animation, the attack text ...
func drawBattle(g):
	if mode == BattleManager.TALKING:
		manager.setDialog(dialog)
	else:
		# The battle interface is 3D geometry at z = STANDARD_Z_DEPTH (-2),
		# the plane of the walls of the player's node: draw it without the
		# depth test, so that a wall there does not hide it (COTZ-011).
		g.ignore_depth_test = true
		currentDeck.draw(g)
		if update_:
			glEnemies.updateTexture(g)
			glCharacters.updateTexture(g)
			update_ = false
		hand.draw(g)
		legend.setSupport(isSupportMode())
		legend.draw(g)
		g.ignore_depth_test = false
		g.loadIdentity()
		if mode == BattleManager.ANIMATE:
			animate.draw(g)
		g.ignore_depth_test = true
		attackText.draw(g)
		g.ignore_depth_test = false


## Called when the cards have been played and the attack should be made.
func finishRound():
	var cards = currentDeck.finish()
	calcDamage(cards)
	clock.hide()
	legend.hide()
	clock.finish()
	hand.hide()
	glCharacters.setTarget(-1, false)

	if cards.size() == 0:
		finishRoundForCharacters(false, true)
	else:
		animate.init(
				cards, hand.getIndex(), hand.getSelTeam(),
				monster, attacker, glCharacters)
		mode = BattleManager.ANIMATE


func finishRoundForCharacters(didAction, setIdling):
	setActiveForAll(true)
	attacker.finishRound(didAction)
	idling.append(attacker)
	if setIdling:
		mode = BattleManager.IDLING


## Prepares the result screen for the attack with the given cards.
func calcDamage(cards):
	var targetTeam = hand.getSelTeam()
	resultScreen.init(targetTeam)
	update_ = true


## Calculates the damage made on a character by the enemy (EnemyLogic).
func calcEnemyDamage():
	var target: int = EnemyLogic.calcEnemyDamage(enemy, enemies, characters, attackText, self)
	for i in range(glCharacters.size()):
		var c = glCharacters.get_(i).getCreature()
		if not c.isAlive():
			c.resetBoost()
	if not checkIfEnemiesAreDead(false):
		if target != CharacterRow.NO_TARGET:
			if target == CharacterRow.ON_ALL:
				for i in range(glCharacters.size()):
					glCharacters.get_(i).setHideTimer(150, EnemyLogic.getCriticalHit())
				glCharacters.show()
			else:
				glCharacters.get_(target).setHideTimer(150, EnemyLogic.getCriticalHit())
			checkIfPartyIsDead()
		update_ = true
	if mode == BattleManager.ENEMY_TURN:
		checkOpenWound()


func checkOpenWound():
	if enemy.hasOpenWound():
		show()
		mode = BattleManager.WAITING
		_openWoundThread()


## The Java thread of checkOpenWound() (a coroutine, called without await).
func _openWoundThread() -> void:
	await Scheduler.sleep(1000)
	var found: bool = false
	var i: int = 0
	while i < glEnemies.size() and not found:
		var e = glEnemies.get_(i)
		found = e.getCreature() == enemy
		if found:
			e.setHideTimer(150, false)
			var pos = BattleValues.getEnemyPosForText(i)
			var val: int = enemy.updateOpenWound()
			attackText.addCenter(
					"Open wound!",
					pos[0], pos[1], false, AttackText.textSize.SMALLEST)
			attackText.addCenter(
					str(val),
					pos[0], pos[1] - AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT,
					false, AttackText.textSize.SMALLEST)
			update_ = true
		i += 1
	await Scheduler.sleep(1000)

	glEnemies.check()
	var enemyDead: bool = Creature.isTeamDead(enemies)
	if enemyDead:
		hide()
		attackText.reset()
		killMonster()
		checkIfEnemiesAreDead(true)
	else:
		switchMode(BattleManager.IDLING)
	show()


## Checks if all of the characters are dead; if so, game over (or talking).
func checkIfPartyIsDead():
	if Creature.isTeamDead(characters):
		monster.setDialog(BossDialog.PARTY_DEAD)
		if monster.wouldLikeToTalk():
			mode = J.INT_MAX
			Scheduler.after(2500, func():
				mode = BattleManager.TALKING
				dialog = monster.next(BossDialog.PARTY_DEAD))
		else:
			gameOver(2500)


## Checks if all the enemies are dead. If so the spoils mode is entered.
func checkIfEnemiesAreDead(endForCharacters):
	var enemiesDead: bool = Creature.isTeamDead(enemies)
	if enemiesDead:
		monster.setDialog(BossDialog.ENEMY_DEAD)
		var nextPlace = monster.getNextPlace()
		if monster.wouldLikeToTalk():
			mode = J.INT_MAX
			Scheduler.after(800, func():
				mode = BattleManager.TALKING
				dialog = monster.next(BossDialog.ENEMY_DEAD))

			var switchMusic: bool = true
			if nextPlace != null:
				var info = Organizer.getOrganizer().getInformationFor(nextPlace)
				switchMusic = str(info.get("music")).to_lower() != str(manager.music).to_lower()
			if switchMusic:
				manager.switchMusic("No Music", 500)
			else:
				manager.dontFadeBattleMusic()
			glCharacters.setTarget(CharacterRow.NO_TARGET, false)
			hide()
			finishRoundForCharacters(true, false)
		elif nextPlace != null:
			var info = Organizer.getOrganizer().getInformationFor(nextPlace)
			if str(info.get("music")).to_lower() == str(manager.music).to_lower():
				manager.dontFadeBattleMusic()
			manager.setNextPlace(monster.getNextPlace())
			exit(BattleManager.EXIT_TO_NEXT)
			glCharacters.setTarget(CharacterRow.NO_TARGET, false)
			hide()
			finishRoundForCharacters(true, false)
		else:
			finishRoundForCharacters(true, false)
			spoilsScreen = SpoilsScreen.new(enemy, enemySize)
			mode = BattleManager.SPOILS
	elif endForCharacters:
		finishRoundForCharacters(true, true)
	return enemiesDead


static func calcMiss(target, p_attacker, defenseBoost):
	var hit: float = p_attacker.getAttribute(Creature.HIT) / 100.0
	var evade: float = (target.getAttribute(Creature.EVADE) / 100.0) + defenseBoost
	var actuallHit: float = hit - evade
	var hitMiss: float = Values.rand.nextFloat()
	return hitMiss > actuallHit


## Triangle: attacks with the cards already in the weapon.
func trianglePressed():
	SoundPlayer.playSound(SoundMap.BATTLE_FINISH_ROUND)
	finishRound()


## Cross: the "enter" or "select" button; depends on the current mode.
func crossPressed(playSound = null):
	match mode:
		BattleManager.BATTLING:
			if not currentDeck.isFull():
				currentDeck.chooseSelectedCard()
		BattleManager.RESULT:
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT)
			checkIfPartyIsDead()
			checkIfEnemiesAreDead(true)
		BattleManager.SPOILS:
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT)
			if spoilsScreen.crossPressed():
				exit()
		BattleManager.TUTORIAL:
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT)
			if tutorial.crossedPressed():
				mode = BattleManager.BATTLING
		BattleManager.TALKING:
			dialog = monster.next()
			if dialog == null:
				manager.setDialog(null)
				var i: int = monster.getDialogIndex()
				match i:
					BossDialog.ENEMY_DEAD:
						manager.setNextPlace(monster.getNextPlace())
						exit(BattleManager.EXIT_TO_NEXT)
					BossDialog.PARTY_DEAD:
						gameOver(500)
					_:
						if monster.shouldHitAfterTalk():
							switchMode(BattleManager.ENEMY_TURN)
						else:
							mode = BattleManager.IDLING
							glCharacters.show()
							glEnemies.show()


func exitToNext():
	manager.setNextPlace(monster.getNextPlace())
	exit(BattleManager.EXIT_TO_NEXT)


## Circle: discards the selected card in the deck.
func circlePressed(pressAnyWay = null):
	SoundPlayer.playSound(SoundMap.BATTLE_DISCARD_CARD)
	currentDeck.discardCard()


## Square: saves the selected card in the deck.
func squarePressed():
	SoundPlayer.playSound(SoundMap.BATTLE_SAVE_CARD)
	currentDeck.saveCard()


## L2 does exactly the same as R2.
func L2Pressed():
	R2Pressed()


## R2: flips the weapon (attack / defense mode) if no card has been played.
func R2Pressed():
	var m: int = currentDeck.flipMode()
	if m != -1:
		var defMode: bool = m == GLWeapon.DEFENSE_MODE
		hand.setPos(defMode, Load.getCharacterIndex(attacker.getName()))
		if defMode:
			glCharacters.setTarget(hand.getIndex(), true)
		else:
			glCharacters.setTarget(-1, false)
		SoundPlayer.playSound(SoundMap.BATTLE_FLIP_MODE)


func isSupportMode():
	return currentDeck.getMode() == GLWeapon.DEFENSE_MODE


## L1: moves the hand to the left.
func L1Pressed():
	SoundPlayer.playSound(SoundMap.BATTLE_CHARACTER_NAVIGATE)
	hand.previous()
	if isSupportMode():
		glCharacters.setTarget(hand.getIndex(), true)
	else:
		glCharacters.setTarget(-1, false)


## R1: moves the hand to the right.
func R1Pressed():
	SoundPlayer.playSound(SoundMap.BATTLE_CHARACTER_NAVIGATE)
	hand.next()
	if isSupportMode():
		glCharacters.setTarget(hand.getIndex(), true)
	else:
		glCharacters.setTarget(-1, false)


## Left: moves the select cursor one step to the left.
func leftPressed():
	currentDeck.selectLeft()


## Right: moves the select cursor one step to the right.
func rightPressed():
	currentDeck.selectRight()


## Shows the enemies and the characters.
func show():
	glEnemies.show()
	glCharacters.show()


func testShowCharacters():
	glCharacters.testShowCharacters()


func testHideCharacters():
	glCharacters.testHideCharacters()


## Hides the enemies and the characters.
func hide():
	glEnemies.hide()
	glCharacters.hide()


func toggleHelp():
	legend.toggleLegend()


## Flees from battle (small chance per call; called while R2 + L2 are held).
func flee():
	if J.random() < 0.002:
		hide()
		mode = BattleManager.EXIT
	if firstTimeFlee:
		clock.initFlee()
		firstTimeFlee = false


## Resets the fleeing procedure (removes the "Fleeing" text).
func resetFlee():
	firstTimeFlee = true
	clock.resetFlee()


## Creates the boss class battle.bosses.<DbName> (capitalized) for the enemy,
## or a plain Boss if there is no such class.
func getBoss(p_enemy):
	var b = null
	var n: String = p_enemy.getDbName()
	var first: String = J.substring(n, 0, 1)
	var rest: String = J.substring(n, 1)
	var javaName: String = "battle.bosses." + first.to_upper() + rest
	if ClassRegistry.JAVA_TO_PATH.has(javaName):
		b = ClassRegistry.forName(javaName).new(p_enemy)
	else:
		b = BattleBoss.new(p_enemy)
	return b


func getEnemyRow():
	return glEnemies


func getCharacterRow():
	return glCharacters


func getEnemy():
	return monster


func getMode():
	return mode


## Switches the current mode to the given one.
func switchMode(m):
	if mode == BattleManager.ENEMY_TURN:
		show()
	mode = m
	if mode == BattleManager.ENEMY_TURN:
		var attack
		monster.increment()
		if monster.wouldLikeToTalk():
			mode = BattleManager.TALKING
			dialog = monster.next()
			hide()
		else:
			var target: int
			if monster is BattleBoss:
				var b = monster
				attack = b.makeMove(int(enemies[0].getLifePrecent() * 100))
			else:
				attack = EnemyLogic.makeMove(enemy, characters)
			target = monster.getTarget(characters, attack)
			glCharacters.setTarget(target, false)
			if target != CharacterRow.ON_ALL:
				hide()
			else:
				glEnemies.hide()
			monster.hit(attack, target)


## Sets the update time of the creatures in the battle (the time the progress
## bar takes to fill), relative between the creatures.
static func setUpdateTime(list):
	var timePerPerson: float = 3000 # in milliseconds.
	var test: float = 100.0 / (timePerPerson / Values.LOGIC_INTERVAL)

	var sum: float = 0
	for i in range(list.size()):
		var c = list[i]
		sum += c.getAttribute(Creature.AGILITY)
	for i in range(list.size()):
		var c = list[i]
		var updateTime: float = (c.getAttribute(Creature.AGILITY) / sum)
		updateTime *= list.size() * test
		c.setTime(updateTime)


## Sets all the idling characters (and the queue) to active or inactive.
func setActiveForAll(active):
	for i in range(idling.size()):
		if idling[i] is Character:
			idling[i].setActive(active)
	queue.setActive(active)


func setBsattleManager(p_manager):
	self.manager = p_manager


## Java overloads changeMusic(name) [manager.switchMusic(name) = 500 ms] and
## changeMusic(name, time).
func changeMusic(name, time = null):
	manager.switchMusic(name, 500 if time == null else int(time))


func setDialog(p_dialog):
	manager.setDialog(DialogSequence.new(p_dialog))


## Java overloads exit(int exitMode) and exit() [BattleManager.EXIT].
func exit(exitMode = null):
	if exitMode == null:
		exitMode = BattleManager.EXIT
	mode = exitMode
	if monster is BattleBoss:
		Database.addStatus(enemy.getDbName(), 0)
		monster.trigger()


func gameOver(time):
	mode = J.INT_MAX
	Scheduler.after(time, func(): mode = BattleManager.GAME_OVER)


func setMode(p_mode):
	self.mode = p_mode
