class_name BossBattleArea
extends GameMode
## Port of battle.BossBattleArea: a game mode that only holds a (boss) battle,
## optionally with a battle background weather system. Implements the
## BattleStarter interface (duck typed).

var dialog = null
var card = null
var weatherSystem = null
var bm = null
var subGameModeInitiated: bool = false


## Java init(HashMap info): creates and starts the battle.
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_ALL)
	enterBattle(info)
	fixWeather(info.get("particles"))
	logicLoading = false


func fixWeather(name):
	if name != null:
		weatherSystem = ClassRegistry.newInstance("battleBacks." + str(name))


## Updates the weather and the battle.
func update(elapsedTime: float):
	if weatherSystem != null:
		weatherSystem.update()
	bm.update(elapsedTime)
	super.update(elapsedTime)


## Java enterBattle(HashMap info): starts battling (the music is replaced by
## "No Music" for the battle manager).
func enterBattle(boss, bossName = null):
	var info = boss
	bm = BattleManager.new()
	bm.setBattleStarter(self)
	var newInfo = {}

	for s in info.keys():
		if s != "music":
			newInfo[s] = info.get(s)
		else:
			newInfo["music"] = "No Music"

	bm.init(newInfo)
	subGameModeInitiated = false


## Ends the game: fades out and sets the next place to the game over screen.
func gameOver():
	exit("Game Over Screen", true)


## Java overloads exit(String next, boolean fadeBattleMusic) (BattleStarter)
## and the inherited GameMode.exit(int mode).
func exit(next = null, fadeBattleMusic = null):
	if next is int:
		super.exit(next)
		return
	if not isFading():
		if fadeBattleMusic and bm != null and bm is BattleManager:
			bm.setMusicMode(
					SoundValues.FADE_OUT, 4000,
					SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN)
		setFadeOutSpeed(0.01)
		nextPlace = next
		super.exit(Values.EXIT)


## Draws the weather, the battle and the dialog.
func draw(g, alpha = null):
	if weatherSystem != null:
		weatherSystem.draw(g, false)
	drawExtra(g, false)

	GameEventListener.set2DNow(g)
	if dialog != null:
		g.setColor(1)
		Dialog.getDialog().draw(g)
		if card != null:
			DeckPage.drawCardInfo(g, card, 530)
	g.push()
	drawExtra(g, true)
	g.pop()
	super.draw(g)


## Draws the battle (initiating the drawing the first time).
func drawExtra(g, topLayer):
	if not subGameModeInitiated:
		bm.initDraw(g)
		subGameModeInitiated = true
	if topLayer:
		bm.drawTopLayer(g)
	else:
		bm.draw(g)


func setNextPlace(next):
	self.nextPlace = next


## Used by the organizer to check what to initialize next.
func checkNextPlace():
	return nextPlace


func exitLabyrinth(exitMode):
	super.exit(exitMode)


## Java overloads:
##   drawDialog(String first, String second)
##   drawDialog(boolean firstDialogImage, String name, String first, String second)
##   drawDialog(DialogSequence dia)
func drawDialog(firstDialogImage, name = null, first = null, second = null, whisper = null):
	if firstDialogImage is bool:
		drawDialog(DialogSequence.new(name, first, second, firstDialogImage, false))
	elif name != null:
		drawDialog(DialogSequence.new(firstDialogImage, name))
	else:
		dialog = firstDialogImage
		Dialog.getDialog().setDS(dialog)


func exitDialog():
	if dialog != null:
		dialog = null
		card = null


func leaveBattle():
	pass


func notifySwitchMusic(p_music, fadeSpeed):
	super.switchMusic(p_music, fadeSpeed)


func overwriteStarterMusic(p_music, p_oggPlayer):
	print("Overwrite")
	# Null when this area's music is "No Music" and no switchMusic has run yet,
	# e.g. Menthuattack2 killed before Wrath_of_Ophiuchus (Java threw an NPE).
	if self.oggPlayer != null:
		self.oggPlayer.exit()
	self.oggPlayer = p_oggPlayer
	self.music = p_music
