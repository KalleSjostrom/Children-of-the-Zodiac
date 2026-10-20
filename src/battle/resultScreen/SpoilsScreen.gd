class_name SpoilsScreen
extends ResultScreenBase
## Port of battle.resultScreen.SpoilsScreen: displays the spoils of battle
## (gold, experience, dropped item) and the experience bars / level ups.
##
## Port note: the Java constructor started a thread that slept 200 ms and
## then, until done, slept 70 ms while paused or 700 ms followed by next().
## This is a Scheduler.every tick (_threadTick) with the same timing.

const BAR_HEIGHT_DISTANCE = 35
static var x = [230, 335, 555, 680]
static var y = [240, 275, 310, 345, 380, 415, 450, 485]
const HP = 0
const DEFENSE = 1
const MAGIC_DEFENSE = 2
const ATTACK = 3
const MAGIC_ATTACK = 4
const SUPPORT = 5
const LEVEL = 6
const LAST_STEP = 6
const DECREASE_MILLISECONDS = 700
var bars = null
var exp: int = 0
var gold: int = 0
var step: int = 0
var droppedItem = null
var info = null
var done: bool = false
var pause: bool = false

# State of the replaced Java thread.
var _threadWait: float = 0.0
var _threadPendingNext: bool = false


## Creates a new result screen that should display the spoils of battle.
## enemy: an instance of the enemy (character.Enemy) the party defeated.
## enemySize: the number of such enemies that the party has defeated.
func _init(enemy = null, enemySize = null) -> void:
	super()
	bars = J.array(4, null)
	info = J.array(4, null)
	for i in range(info.size()):
		info[i] = LevelInfo.new()
	calcSpoils(enemy, enemySize)
	_threadWait = 200
	_threadPendingNext = false
	Scheduler.every(_threadTick)


## Replacement of the Java thread loop:
##   sleep(200); while (!done) { if (pause) sleep(70); else { sleep(700); next(); } }
func _threadTick(delta_ms) -> bool:
	_threadWait -= float(delta_ms)
	if _threadWait > 0:
		return true
	if _threadPendingNext:
		_threadPendingNext = false
		next()
	if done:
		return false
	if pause:
		_threadWait += 70
	else:
		_threadWait += DECREASE_MILLISECONDS
		_threadPendingNext = true
	if _threadWait < 0:
		_threadWait = 0
	return true


## Calculates the spoils gotten when defeating enemySize number of enemies
## of the same type as enemy.
func calcSpoils(enemy, enemySize):
	getSpoils(enemy, enemySize)
	var totalNrOfRounds: float = 0.0
	var characters = Load.getCharacters()
	for i in range(characters.size()):
		totalNrOfRounds += characters[i].getRoundCounter()
	var amountOfDecreases: float = DECREASE_MILLISECONDS / float(Values.LOGIC_INTERVAL)

	Bestiary.getBestiary().updateStats(enemy, enemySize)
	Load.getPartyItems().incrementBattle()
	Load.getPartyItems().addGold(gold)
	var varryExp: float = 0.1 * exp
	var staticExp: float = 0.9 * exp
	var staticFraction: float = 1.0 / characters.size()
	exp = 0
	for i in range(characters.size()):
		var c = characters[i]
		if c.isAlive():
			var varryingFraction: float = c.getRoundCounter() / totalNrOfRounds
			var gottenExp: int = J.round(varryingFraction * varryExp + staticFraction * staticExp)
			info[i].expDecrease = gottenExp / amountOfDecreases
			info[i].recievedExp = gottenExp
			info[i].expCounter = gottenExp
			info[i].canLevelUp = c.canLevelUp()
			info[i].expToNext = c.getExpToNextLevel()
			info[i].expLeftToNextLevel = c.getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL)

			exp += gottenExp
			if info[i].canLevelUp:
				c.addAttribute(Creature.EXPERIANCE, gottenExp)
				var cnext: int = c.getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL)
				if gottenExp <= cnext:
					c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -gottenExp)
					info[i].all = gottenExp
				else:
					c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -cnext)
					info[i].all = cnext
					info[i].rest = gottenExp - cnext
					Character.levelUpStatic(c)
					# At the last level of the class EXP_LEFT_TO_NEXT_LEVEL is
					# NO_INCREASE and the rest is lost. Java subtracted it anyway
					# (its 32-bit int wrapped around); here it would leave a
					# value just below NO_INCREASE, which canLevelUp() took for
					# a real one, and the next battle asked for a level that
					# does not exist (COTZ-003).
					if c.canLevelUp():
						c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -info[i].rest)
			info[i].expToNextNext = c.getExpToNextLevel()


func getSpoils(enemy, enemySize):
	exp = 0
	gold = 0
	var r := JRandom.new()
	for i in range(int(enemySize)):
		var number: float = r.nextFloat() / 5.0  # get val between 0 and .2
		var precent: float = 0.9 + number  # between 90 % and 110 %
		exp += J.round(enemy.getSpoilExp() * precent)

		number = r.nextFloat() / 5.0
		precent = 0.9 + number  # between 90 % and 110 %
		gold += J.round(enemy.getSpoilGold() * precent)
	var status: int = Database.getStatusFor(enemy.getDbName() + "drop")
	if status != 0 and J.random() < enemy.getDropRate():
		droppedItem = enemy.getSpoilItem()
		Load.getPartyItems().addItem(droppedItem)
		Database.addStatus(enemy.getDbName() + "drop", 0)


func update(elapsedTime):
	var characters = Load.getCharacters()
	for i in range(characters.size()):
		if step > 1 + i:
			var c = characters[i]
			if c.isAlive():
				step = info[i].update(elapsedTime, step, i == characters.size() - 1)


## Draws the spoils of battle (and level ups) on the given graphics.
func drawSpoils(g):
	drawBackground(g)
	drawSpoil(g)


## Draws the spoils of battle on the given graphics.
func drawSpoil(g):
	g.setFontSize(26)
	g.drawWithShadow("Result", 200, y[0])

	var totalgold: int = Load.getPartyItems().getGold()
	if step > 0:
		g.drawWithShadow("The enemy dropped " + str(gold) + " gp, " +
				"total: " + str(totalgold) + " gp", x[0], y[1])
		g.drawWithShadow("The party got " + str(exp) + " exp.", x[0], y[2])

	var characters = Load.getCharacters()
	for i in range(characters.size()):
		if step > 1 + i:
			var c = characters[i]
			if c.isAlive():
				var color: Color = JColor.WHITE
				var canLevelUp: bool = info[i].canLevelUp

				if info[i].hasLeveledUp:
					color = JColor.GREEN
					g.drawWithShadow("Level up!", x[3], y[3 + i], color)
					g.drawWithShadow(str(J.round(info[i].recievedExp)) + " exp", x[2], y[3 + i], color)
				elif not canLevelUp:
					g.drawWithShadow("Max level", x[3], y[3 + i], JColor.RED)
					g.drawWithShadow("0 exp", x[2], y[3 + i], JColor.RED)
				else:
					g.drawWithShadow(str(J.round(info[i].recievedExp)) + " exp", x[2], y[3 + i], JColor.WHITE)
				drawBars(g, i, info[i].etn, canLevelUp)

				g.drawWithShadow(c.getName(), x[0], y[3 + i], color)
			else:
				g.drawWithShadow(c.getName(), x[0], y[3 + i], JColor.RED)
	if step >= 2 + characters.size() and droppedItem != null:
		g.drawWithShadow("You found " + droppedItem.getName() + " laying on the ground!", x[0], y[3 + 4])


## Draws the experience bar with the given index.
func drawBars(g, barIndex, progress, canLevelUp):
	if bars[barIndex] == null:
		bars[barIndex] = LevelUpBar.new()
	bars[barIndex].update(progress)
	bars[barIndex].draw(g, x[1], 330 + barIndex * BAR_HEIGHT_DISTANCE, canLevelUp)


## Advances the screen one step.
func next():
	step += 1
	if step > Load.getCharacters().size():
		pause = true


## Called when the user presses the cross button. Skips ahead to the last
## piece of information, or returns true if the screen is done.
func crossPressed():
	if step > Load.getCharacters().size():
		pause = false
		done = true
	else:
		step = 100
		pause = true
	return done


class LevelInfo extends RefCounted:
	var rest: int = 0
	var all: int = 0
	var expCounter: float = 0.0
	var expToNext: float = 0.0
	var expToNextNext: float = 0.0
	var expLeftToNextLevel: float = 0.0
	var etn: float = 0.0
	var expDecrease: float = 0.0
	var recievedExp: float = 0.0
	var hasLeveledUp: bool = false
	var canLevelUp: bool = false

	func update(elapsedTime, step, updateStep):
		if canLevelUp:
			if expCounter > 0:
				expCounter -= expDecrease
				updateETN()

				if etn >= 1:
					hasLeveledUp = true
					if expToNextNext == LevelFactory.NO_INCREASE:
						# Reached the last level of the class: show the full
						# (red) bar of a maxed character instead of counting
						# towards a level that does not exist.
						canLevelUp = false
						return step
					expToNext = expToNextNext
					expLeftToNextLevel = expToNextNext
					all = rest
					rest = 0

					updateETN()
			elif updateStep:
				step = maxi(Load.getCharacters().size() + 2, step)
		return step

	func updateETN():
		var ec: float = expCounter - rest
		var yv: float = expLeftToNextLevel
		yv = yv + (ec - all)
		var xv: float = expToNext
		etn = (xv - yv) / xv
