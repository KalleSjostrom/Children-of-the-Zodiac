class_name AbstractPage
extends SubGameMode
## Port of menu.AbstractPage: an abstraction of a page in the menu. The
## navigation methods (upPressed() etc., from SubGameMode) are called when the
## player presses a button; subclasses override the ones they need and
## implement draw3D().
##
## Port notes:
##  - The static drawMenuBackground(g, page|index[, used]) overloads are
##    drawMenuBackgroundStatic(g, page, used = null) (an instance method
##    drawMenuBackground(g) exists).
##  - BUTTON_ICONS and xoffset depend on the input managers, which do not
##    exist yet when this script is loaded. They are therefore computed lazily
##    (on first access, as the Java static initializer ran on first use of the
##    class) through static property getters.

static var EQUIP_PAGE: Array = [1, 7, 3, 5, 6]
static var START_PAGE: Array = [0, 1, 2, 3, 10, 11, 12]
static var STATUS_PAGE: Array = [1, 2, 3, 5, 6]
static var DECK_PAGE: Array = [1, 8, 9]
static var BESTIARY_PAGE: Array = [1, 2, 3, 4]

static var background: String = ImageHandler.addPermanentlyLoadNow(
		Values.MenuImages + "back.jpg")

static var images: Array = _createImages()

static var _buttonIcons = null
static var _xoffset: int = 0

## String[GameMode.UP + 3]: the button icon image names, indexed by button.
static var BUTTON_ICONS:
	get:
		_initButtonIcons()
		return _buttonIcons
	set(value):
		_buttonIcons = value

static var xoffset:
	get:
		_initButtonIcons()
		return _xoffset
	set(value):
		_xoffset = value

var activeNode = null
var font = Values.getFont(24)

static var pos: Array = _createPos()

var page = null


static func _createImages() -> Array:
	var ims: Array = J.array(16, "")
	for i in range(16):
		ims[i] = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "Pieces/" + str(i) + ".png")
	return ims


## The Java static initializer of BUTTON_ICONS / xoffset.
static func _initButtonIcons() -> void:
	if _buttonIcons != null:
		return
	_buttonIcons = J.array(GameMode.UP + 3, null)
	var map = null
	var folder = null
	if _isGamePadManager():
		map = createPSMap()
		folder = "PS"
		_xoffset = 4
	elif _isKeyBoardManager():
		map = createKeyBoardMap()
		folder = "KeyBoard"
		_xoffset = 0
	if map == null:
		push_error("AbstractPage: no input manager to create the button icons for")
		return
	for i in map:
		_buttonIcons[i] = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + folder + "/" + map[i] + ".png")


## GameCore.inputManager.isGamePadManager() (missing in the framework).
static func _isGamePadManager() -> bool:
	for m in GameCore.inputManager.managers:
		if m is InputGamePadManager:
			return true
	return false


## GameCore.inputManager.isKeyBoardManager() (missing in the framework).
static func _isKeyBoardManager() -> bool:
	for m in GameCore.inputManager.managers:
		if m is InputKeyBoardManager:
			return true
	return false


static func _createPos() -> Array:
	var p: Array = J.array(15, null)
	var left := 762
	var leftleft := 4
	# 0 = character start info kin
	p[0] = Values.createNormalPoint(leftleft, 5)
	# 1 = title piece
	p[1] = Values.createNormalPoint(left, 2)
	# 2 = main menu right
	p[2] = Values.createNormalPoint(left, 90)
	# 3 = gold / time / steps piece
	p[3] = Values.createNormalPoint(left, 610)
	# 4 = huge back for the beastary
	p[4] = Values.createNormalPoint(leftleft, 5)
	# 5 = detailed character info
	p[5] = Values.createNormalPoint(leftleft, 5)
	# 6 = detailed equip info
	p[6] = Values.createNormalPoint(leftleft, 325)
	# 7 = split middle right
	p[7] = Values.createNormalPoint(left, 90)
	# 8 = mini menu under title in deck page
	p[8] = Values.createNormalPoint(left, 90)
	# 9 = Huge deck underlay
	p[9] = Values.createNormalPoint(leftleft, 205)
	# 10 = character start info celis
	p[10] = Values.createNormalPoint(leftleft, 195)
	# 11 = character start info borealis
	p[11] = Values.createNormalPoint(leftleft, 385)
	# 12 = character start info zalzi
	p[12] = Values.createNormalPoint(leftleft, 575)
	# 13 = card store deck background
	p[13] = Values.createNormalPoint(leftleft, 408)
	# 14 = main menu right small top
	p[14] = Values.createNormalPoint(left, 92)
	return p


## Sets the page layout to use. The predefined ones are the XXX_PAGE arrays.
func setPage(p_page):
	page = p_page


static func createWiiMap():
	var map := {}
	map[GameMode.TRIANGLE] = "wii+"
	map[GameMode.CROSS] = "wii2"
	map[GameMode.CIRCLE] = "wii1"
	map[GameMode.SQUARE] = "wii-"
	map[GameMode.L1] = "wiiB"
	map[GameMode.L2] = "wiiA"
	map[GameMode.R1] = "wiiB"
	map[GameMode.R2] = "wiiA"
	map[GameMode.L1R1] = "wiiB"
	map[GameMode.L2R2] = "wiiA"
	map[GameMode.SELECT] = "wiiShake"
	map[GameMode.START] = "wiiHome"
	map[GameMode.UP_DOWN] = "wiiUpDown"
	map[GameMode.LEFT_RIGHT] = "wiiLeftRight"
	return map


static func createKeyBoardMap():
	var map := {}
	map[GameMode.TRIANGLE] = "w"
	map[GameMode.CROSS] = "s"
	map[GameMode.CIRCLE] = "d"
	map[GameMode.L1] = "q"
	map[GameMode.L2] = "1"
	map[GameMode.R1] = "e"
	map[GameMode.R2] = "3"
	map[GameMode.L1R1] = "keyboardQE"
	map[GameMode.L2R2] = "keyboard13"
	map[GameMode.SELECT] = "space"
	map[GameMode.SQUARE] = "a"
	map[GameMode.START] = "enter"
	map[GameMode.UP_DOWN] = "keyboardUpDown"
	map[GameMode.LEFT_RIGHT] = "keyboardLeftRight"
	return map


static func createPSMap():
	var map := {}
	map[GameMode.TRIANGLE] = "playstationTriangle"
	map[GameMode.CROSS] = "playstationCross"
	map[GameMode.CIRCLE] = "playstationCircle"
	map[GameMode.L1] = "playstationLeft1"
	map[GameMode.L2] = "playstationLeft2"
	map[GameMode.R1] = "playstationRight1"
	map[GameMode.R2] = "playstationRight2"
	map[GameMode.L1R1] = "playstationRL1"
	map[GameMode.L2R2] = "playstationRL2"
	map[GameMode.SELECT] = "playstationSelect"
	map[GameMode.SQUARE] = "playstationSquare"
	map[GameMode.START] = "playstationStart"
	map[GameMode.UP_DOWN] = "playstationUpDown"
	map[GameMode.LEFT_RIGHT] = "playstationLeftRight"
	return map


## Draws the menu background (the pieces of this page's layout).
func drawMenuBackground(g):
	drawMenuBackgroundStatic(g, page)


## Java overloads drawMenuBackground(g, int index),
## drawMenuBackground(g, int[] page) and
## drawMenuBackground(g, int[] page, boolean[] used).
static func drawMenuBackgroundStatic(g, p_page, used = null):
	if p_page is int:
		var index: int = p_page
		g.drawImage(images[index], pos[index][Values.X], pos[index][Values.Y])
	elif used == null:
		for i in range(p_page.size()):
			var index: int = p_page[i]
			g.drawImage(images[index], pos[index][Values.X], pos[index][Values.Y])
	else:
		for i in range(p_page.size()):
			if used[i]:
				var index: int = p_page[i]
				g.drawImage(images[index], pos[index][Values.X], pos[index][Values.Y])


## Gets the position of the hand used in the menu.
func getHandPos():
	return activeNode.getHandPos()


## Gets the images used in the menus (also used by the stores).
static func getImages():
	return images


## Draws the standard graphics that all the pages should draw: the
## background and the page layout.
func drawStandard(g3D):
	g3D.setFontSize(MenuValues.MENU_FONT_SIZE)
	Graphics.setTextColor(JColor.BLACK)
	g3D.drawImage(background, 0, 0)
	drawMenuBackground(g3D)


func trianglePressed():
	SoundPlayer.playSound(SoundMap.MENU_EXIT)
	MainMenu.getMainMenu().exit()


## Draws the page on the given graphics (abstract).
func draw3D(g):
	pass


func update(elapsedTime = null):
	pass


static func getExecuteButtonIcon():
	return BUTTON_ICONS[GameMode.TRIANGLE]
