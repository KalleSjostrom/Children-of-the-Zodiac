class_name MainMenu
extends GameMode
## Port of menu.MainMenu: the main menu of the game. The player can access
## this menu from almost every mode in the game. Here, changes can be made to
## the equipment such as armor, weapon and deck. It consists of a number of
## pages which all are subclasses of AbstractPage.
##
## Port notes: Java's init(HashMap info) is init(name, lab, hinders) (merged
## skeleton signature, the info map is the first argument and is ignored).
## The protected exit() (no arguments) is exit() with no arguments; exit(mode)
## is GameMode.exit(mode).

static var menu = null

var currentPage = null
var thumbNailScreen = null
var statusImage = ""
var deckImages: Array = J.array(4, null)
var loaded: bool = false

var inputLocked: bool = false


## Initiates the main menu. It creates its own information so it does not
## matter if the given info is null.
func init(name, lab = null, hinders = null):
	initGameMode({}, Values.DETECT_AS_KEY)
	GameEventListener.set2D()
	Organizer.getOrganizer().getPreviousMode().setMusicMode(
			SoundValues.FADE_OUT, SoundValues.SLOW, SoundValues.HALF)
	SoundPlayer.playSound(SoundMap.MENU_ENTER_MENU)
	fadein = false
	fadeout = false
	fadeValue = 1
	menu = self

	thumbNailScreen = getScreenShot()
	initStartPage(0)

	logicLoading = false


## Gets the MainMenu object currently in use. This is used by the page
## objects to communicate with the menu and to initiate other pages.
static func getMainMenu():
	return menu


## Gets the thumb nail screen shot from the previous mode, or null if that
## mode is not a MenuStarter.
func getScreenShot():
	var gm = Organizer.getOrganizer().getPreviousMode()
	if gm != null and gm is MenuStarter:
		return gm.getThumbnailScreenShot()
	return null


func locksInput():
	inputLocked = true


func unLockInput():
	inputLocked = false


## Forwards the pressed buttons to the current page and updates it.
func update(elapsedTime: float):
	if not inputLocked:
		var buttonPressed := true
		if gameActions[UP].isPressed():
			currentPage.upPressed()
		elif gameActions[RIGHT].isPressed():
			currentPage.rightPressed()
		elif gameActions[DOWN].isPressed():
			currentPage.downPressed()
		elif gameActions[LEFT].isPressed():
			currentPage.leftPressed()
		elif MenuStarter.isMenuButtonPressed(gameActions):
			currentPage.trianglePressed()
		elif gameActions[CIRCLE].isPressed():
			SoundPlayer.playSound(SoundMap.MENU_BACK)
			currentPage.circlePressed()
		elif gameActions[CROSS].isPressed():
			currentPage.crossPressed()
		elif gameActions[SQUARE].isPressed():
			currentPage.squarePressed()
		elif gameActions[R1].isPressed():
			currentPage.R1Pressed()
		elif gameActions[R2].isPressed():
			currentPage.R2Pressed()
		elif gameActions[L1].isPressed():
			currentPage.L1Pressed()
		elif gameActions[L2].isPressed():
			currentPage.L2Pressed()
		elif gameActions[SELECT].isPressed():
			currentPage.selectPressed()
		else:
			buttonPressed = false
		if buttonPressed:
			currentPage.buttonPressed()
	currentPage.update(elapsedTime)
	super.update(elapsedTime)


## Initiates the start page. menuIndex: where the menu hand should start.
func initStartPage(menuIndex):
	currentPage = StartPage.new(thumbNailScreen, menuIndex)


## Initiates the equip page with the given character index.
func initEquipPage(character, menuIndex, inSub):
	character = checkCharacterInRange(character)
	currentPage = EquipPage.new(character, menuIndex, inSub)


## Initializes the deck page for the given character.
func initDeckPage(character, activeDeck, currentDeck):
	character = checkCharacterInRange(character)
	var index: int = 0
	if currentDeck != null:
		index = currentDeck.getMenuCursor()
	currentPage = DeckPage.new(
			character, Load.getPartyItems().getMainDeck(),
			activeDeck, index)


## Wraps the given character index into the range of Load.getCharacters().
func checkCharacterInRange(character):
	var size: int = Load.getCharacters().size()
	if character < 0:
		character = size - 1
	elif character >= size:
		character = 0
	return character


## Initiates the status page.
func initStatusPage(character, current):
	character = checkCharacterInRange(character)
	currentPage = StatusPage.new(character, current)


## Initiates the bestiary page.
func initBestiaryPage(enemy, current):
	enemy = checkEnemyInRange(enemy)
	currentPage = BestiaryPage.new(enemy, current)


func initTutorialPage():
	currentPage = TutorialPage.new()


func initHelpPage():
	currentPage = HelpPage.new()


func initMapPage():
	currentPage = MapPage.new()


## Wraps the given enemy index into the range of the bestiary.
func checkEnemyInRange(enemyIndex):
	var size: int = Bestiary.getBestiary().getSize()
	if enemyIndex < 0:
		enemyIndex = size - 1
	elif enemyIndex >= size:
		enemyIndex = 0
	return enemyIndex


## Gets the background image for the status page.
func getStatusImage():
	return statusImage


## Java: exit() (switches back to the previous mode without fading) and the
## inherited GameMode.exit(int mode).
func exit(next = null, fadeBattleMusic = null):
	if next == null:
		exitWithoutFading(Values.SWITCH_BACK)
	else:
		super.exit(next)


## Sets up the drawing of the menu pages and draws the current page.
func draw(g, alpha = null):
	g.setColor(1)
	g.setAlphaFunc(.02)
	g.setFontSize(MenuValues.MENU_FONT_SIZE)
	currentPage.draw3D(g)
	super.draw(g)


func exitTo(startLocation):
	nextPlace = startLocation
	exit(Values.EXIT)


func setGameAction():
	super.setGameAction()
	initInput(Values.DETECT_AS_KEY)
