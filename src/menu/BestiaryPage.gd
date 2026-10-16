class_name BestiaryPage
extends AbstractPage
## Port of menu.BestiaryPage: displays the enemies in the game. The player can
## look at the images of the enemies and see their stats, if the player has
## encountered an enemy enough times.
##
## Port note: the animation thread is a coroutine (Scheduler.sleep); anim
## holds the id of the running animation (null when none).

var stats = null
var anim = null
var enemy = null
var enemyIndex: int = 0
var enemyImage: int = 0
var nrOfEnemies: int = 0
var animate: bool = false
var animateButtonJustPressed: bool = false
var showEnemy: bool = false

## Counter used to tell the animation coroutines apart (thread interrupt).
var _animId: int = 0

func _init(enemyIndex = null, currentChild = null) -> void:
	activeNode = getRootNode()
	activeNode.setMenuCursor(currentChild)
	changeEnemy(enemyIndex)
	nrOfEnemies = Bestiary.getBestiary().getSize()
	self.enemyIndex = enemyIndex
	setPage(BESTIARY_PAGE)


func getRootNode():
	var n = MenuNode.new(null, "Bestiary")
	if not n.hasChildren():
		n.insertChild("Next")
		n.insertChild("Previous")
		n.insertChild("Animate")
		n.insertChild("Next Image")
		n.setDistance(MenuValues.DISTANCE)
		n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	return n


func changeEnemy(index):
	enemyIndex = MainMenu.getMainMenu().checkEnemyInRange(index)
	var s = Bestiary.getBestiary().getStats(enemyIndex)
	enemy = s.getEnemy()
	stats = s.getInfo()
	showEnemy = s.shouldShowImage()
	enemyImage = 0


func draw3D(g):
	super.drawStandard(g)
	g.drawString(str(enemyIndex + 1) + " / " + str(nrOfEnemies), 50, MenuValues.MENU_TITLE_Y)
	g.drawString(activeNode.getName(), MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y)
	activeNode.drawAllChildren(g)
	if showEnemy:
		g.drawImage(enemy.getImage(enemyImage), 0, 120, .9)
	drawStats(g)
	StartPage.drawScreenShot(g)
	StartPage.drawInfo(g)


func drawStats(g):
	var x: int = MenuValues.BESTIARY_STATS_X
	g.drawString("Name: " + str(stats[Bestiary.Stats.NAME]), x, getY(0) - 76)
	g.drawString("Hp: " + str(stats[Bestiary.Stats.HP]), x, getY(0))
	g.drawString("Agility: " + str(stats[Bestiary.Stats.AGILITY]), x, getY(1))
	g.drawString("Attack: " + str(stats[Bestiary.Stats.ATTACK]), x, getY(2))
	g.drawString("Magic: " + str(stats[Bestiary.Stats.MAGIC]), x, getY(3))
	g.drawString("Support: " + str(stats[Bestiary.Stats.SUPPORT]), x, getY(4))
	g.drawString("Defence: " + str(stats[Bestiary.Stats.DEFENSE]), x, getY(5))
	g.drawString("Magic Def.: " + str(stats[Bestiary.Stats.MAGIC_DEFENSE]), x, getY(6))
	g.drawString("Evade: " + str(stats[Bestiary.Stats.EVADE]) + " %", x, getY(7))
	g.drawString("Exp. dropped: " + str(stats[Bestiary.Stats.EXPERIANCE]), x, getY(8))
	g.drawString("Gold dropped: " + str(stats[Bestiary.Stats.GOLD]), x, getY(9))
	g.drawString("Times encountered: " + str(stats[Bestiary.Stats.BATTLE_COUNTER]), x, getY(10))


func getY(index):
	return MenuValues.BESTIARY_STATS_Y + MenuValues.DISTANCE * index


func upPressed():
	activeNode.previousChild()


func downPressed(playSound = null):
	activeNode.nextChild()


func R1Pressed():
	enemyIndex += 1
	changeEnemy(enemyIndex)


func L1Pressed():
	enemyIndex -= 1
	changeEnemy(enemyIndex)


func crossPressed(playSound = null):
	var mode = activeNode.getCurrentChild().getName()
	if mode == "Next":
		enemyIndex += 1
		changeEnemy(enemyIndex)
	elif mode == "Previous":
		enemyIndex -= 1
		changeEnemy(enemyIndex)
	elif mode == "Animate":
		stopAnimating()
		animateButtonJustPressed = true
		startAnimating()
	elif mode == "Next Image":
		enemyImage = enemy.nextImage(enemyImage)


func buttonPressed():
	if animateButtonJustPressed:
		animateButtonJustPressed = false
	else:
		stopAnimating()


func circlePressed(pressAnyWay = null):
	MainMenu.getMainMenu().initStartPage(4)


func startAnimating():
	animate = true
	_animId += 1
	anim = _animId
	_runAnimation(_animId)


## The body of the Java animation thread.
func _runAnimation(id: int) -> void:
	while animate and anim == id:
		await Scheduler.sleep(1000)
		if not animate or anim != id:
			break
		enemyImage = enemy.nextImage(enemyImage)


func stopAnimating():
	animate = false
	if anim != null:
		anim = null
		enemyImage = 0
