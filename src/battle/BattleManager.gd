class_name BattleManager
extends GameMode
## Port of battle.BattleManager: the game mode that manages a battle. It draws
## the enemy and the rows of characters / enemies and uses a Battle (sub game
## mode) for the logic. It is driven by a BattleStarter (labyrinth, boss
## battle area, ...), which receives leaveBattle(), exit(), gameOver(), ...
##
## Port notes: Java switchMusic(music) [500 ms] is switchMusic(music, 500);
## Java's private exit() is exit() without arguments (exit(int) of GameMode is
## still reached with an int argument).

const IDLING = 0
const BATTLING = 1
const ENEMY_TURN = 2
const GAME_OVER = 3
const ANIMATE = 4
const RESULT = 5
const EXIT = 6
const TALKING = 7
const EXIT_TO_NEXT = 8
const SPOILS = 9
const WAITING = 10
const TUTORIAL = 11
const THREE_ENEMIES = 1
const TWO_ENEMIES = 0
var battle = null
var objects = null
var enemy = null
var characters = null
var enemies = null
var starter = null
var fadeBattleMusic: bool = true
var prevName = ""
var first: bool = false


## Initiates the game mode with the given information (Java init(HashMap info)).
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_INIT)
	objects = []
	var boss: bool = J.parseBoolean(info.get("boss"))
	var ef = EnemyFactory.getEnemyFactory()
	var en
	var freq
	if boss:
		en = ef.getBoss(info.get("name"))
		freq = [0.0, 0.0]
	else:
		var eg = ef.getEnemyGroup(info.get("name"))
		en = eg.getRandomEnemy()
		freq = eg.getFrequency(en)

	battle = Battle.new(boss, en, freq, self)
	characters = battle.getCharacterRow()
	enemies = battle.getEnemyRow()
	enemy = battle.getEnemy()
	var chars = Load.getCharacters()
	for i in range(chars.size()):
		var c = chars[i]
		c.resetBattleStats()
	objects.append(enemy)
	objects.append(characters)
	objects.append(enemies)
	gameActions[GameMode.RIGHT].changeBehavior(Values.DETECT_AS_KEY)
	gameActions[GameMode.LEFT].changeBehavior(Values.DETECT_AS_KEY)

	logicLoading = false
	loadingDone()
	battle.init()


## Sets the BattleStarter (labyrinth, ...) whose leaveBattle() etc. is called
## when the battle is over.
func setBattleStarter(p_starter):
	self.starter = p_starter


## Updates the battle and handles the input.
func update(elapsedTime: float):
	battle.update(elapsedTime)

	match battle.getMode():
		BATTLING:
			if gameActions[GameMode.UP].isPressed():
				battle.upPressed()
			elif gameActions[GameMode.RIGHT].isPressed():
				battle.rightPressed()
			elif gameActions[GameMode.DOWN].isPressed():
				battle.downPressed()
			elif gameActions[GameMode.LEFT].isPressed():
				battle.leftPressed()
			elif gameActions[GameMode.TRIANGLE].isPressed():
				battle.trianglePressed()
			elif gameActions[GameMode.CIRCLE].isPressed():
				battle.circlePressed()
			elif gameActions[GameMode.CROSS].isPressed():
				battle.crossPressed()
			elif gameActions[GameMode.SQUARE].isPressed():
				battle.squarePressed()
			elif gameActions[GameMode.R1].isPressed():
				battle.R1Pressed()
			elif gameActions[GameMode.L1].isPressed():
				battle.L1Pressed()
			elif gameActions[GameMode.SELECT].isPressed():
				# battle.toggleHelp();
				battle.switchMode(BattleManager.EXIT)
				mode = BattleManager.EXIT
				exit()
			else:
				var r2: bool = gameActions[GameMode.R2].isPressedDontReset()
				var l2: bool = gameActions[GameMode.L2].isPressedDontReset()

				if r2 and l2:
					battle.flee()
				elif gameActions[GameMode.R2].isPressed():
					battle.R2Pressed()
				elif gameActions[GameMode.L2].isPressed():
					battle.L2Pressed()
				else:
					battle.resetFlee()
		EXIT:
			exit()
		EXIT_TO_NEXT:
			starter.exit(nextPlace, fadeBattleMusic)
		GAME_OVER:
			starter.gameOver()
			battle.setMode(WAITING)
		_:
			if gameActions[GameMode.CROSS].isPressed():
				battle.crossPressed()
	super.update(elapsedTime)


## exit(): Java's private exit() (leaves the battle via the starter).
## exit(int mode): GameMode.exit(mode).
func exit(next = null, p_fadeBattleMusic = null):
	if next is int:
		super.exit(next)
		return
	if starter != null:
		starter.leaveBattle()
	var list = Load.getCharacters()
	for i in range(list.size()):
		list[i].resetBattleStats()


func getBattleMode():
	return battle.getMode()


## Initiates the drawing of all the objects and of the battle.
func initDraw(g):
	for i in range(objects.size()):
		var o = objects[i]
		o.initDraw(g)
	battle.initDraw(g)


## Draws the battle.
func draw(g, alpha = null):
	g.loadIdentity()
	for i in range(objects.size()):
		objects[i].draw(g)

	battle.drawBattle(g)


## Java overloads switchMusic(music) [fadeSpeed 500] and switchMusic(music, fadeSpeed):
## notifies the starter (the starter switches the music).
func switchMusic(name: String, fadeSpeed: int):
	print("Switch music " + name)
	starter.notifySwitchMusic(name, fadeSpeed)
	# super.switchMusic(music, fadeSpeed);


func setNextPlace(next):
	nextPlace = next


func setDialog(dialog):
	if dialog == null:
		starter.exitDialog()
	else:
		starter.drawDialog(dialog)


func drawTopLayer(g):
	for i in range(objects.size()):
		objects[i].drawTopLayer(g)
	battle.drawTopLayer(g)


func dontFadeBattleMusic():
	fadeBattleMusic = false
	starter.overwriteStarterMusic(music, oggPlayer)
