class_name Building
extends GameMode
## Port of store.Building: the abstract super class of all the buildings in
## the game (the inside of stores, inns, churches...). Buildings are entered
## through the doors (store.Door). Drawn in the 1024 x 768 space.

const MENU = 0
const BUY = 1
const SELL = 2
const CONFIRM_BUY = 3
const CONFIRM_SELL = 4
const TUTORIAL = 5
const BASE = 6

static var INN = [1, 14, 3]
static var WEAPON_STORE = [1, 14, 3, 5, 6, 7]
static var CHURCH = [1, 14]
static var CARD_STORE = [1, 14, 3, 13, 0]

var activeNode = null # menu.Node (MenuNode)
var background: String = ""
var keeper: String = ""

var name = ""
var firstLine = ""
var secondLine = ""
var dialog: Array = [null, null]
var lastDialog: Array = [null, null]
var menusUsed = null # boolean[]
var dialogIsShowing: bool = true
var store = null # int[]


## Creates a new building, it initiates the GameMode with the detect init
## value which means that only the first press of a button is detected.
## (Java: init(HashMap info); the merged signature's first argument is the
## information map.)
func init(info, lab = null, hinders = null):
	initGameMode(info, Values.DETECT_INIT)
	Dialog.getDialog().resetDialog()


func setStoreImages(p_store):
	store = p_store


## Java overloads: loadFromInfo(info) (keeper = info.get("keeper")) and
## loadFromInfo(info, altKeeper). Gets the background, keeper, name and the
## default dialog from the information map.
func loadFromInfo(info, altKeeper = null):
	if altKeeper == null:
		altKeeper = info.get("keeper")
	background = ImageHandler.addToCurrentLoadOnUse(
			Values.StoreImages + str(info.get("background")))
	keeper = ImageHandler.addToCurrentLoadOnUse(Values.StoreImages + str(altKeeper))
	name = info.get("name")
	firstLine = info.get("firstLine")
	secondLine = info.get("secondLine")
	makeDefaultDialog()


## Overwrites the current dialog with a new one.
func makeNewDialog(fl, sl):
	dialog[0] = fl
	dialog[1] = sl


## Overwrites the current dialog with the default one.
func makeDefaultDialog():
	makeNewDialog(firstLine, secondLine)


func copyDialog():
	lastDialog[0] = dialog[0]
	lastDialog[1] = dialog[1]


func setDialogCopyAsACurrent():
	dialog[0] = lastDialog[0]
	dialog[1] = lastDialog[1]


## Sets which menu images to use when drawing (one hex digit per strip).
func setMenuImagesUsed(used):
	menusUsed = J.array(store.size(), false)
	var mask: int = 0x0000000f
	for i in menusUsed.size():
		menusUsed[i] = (used & mask) == mask
		mask <<= 4


## Sets the visibility of the dialog.
func setDialogVisibility(dis):
	dialogIsShowing = dis


## Updates the building (checks the input).
func update(elapsedTime: float):
	checkGameInput()
	super.update(elapsedTime)


## Checks if the player has pressed a button and calls the corresponding
## xxxPressed() method.
func checkGameInput():
	if gameActions[UP].isPressed():
		upPressed()
	elif gameActions[RIGHT].isPressed():
		rightPressed()
	elif gameActions[DOWN].isPressed():
		downPressed()
	elif gameActions[LEFT].isPressed():
		leftPressed()
	elif gameActions[TRIANGLE].isPressed():
		trianglePressed()
	elif gameActions[CIRCLE].isPressed():
		circlePressed()
	elif gameActions[CROSS].isPressed():
		crossPressed()
	elif gameActions[SQUARE].isPressed():
		squarePressed()


## Draws the menu background strips that have been set to be used.
func drawMenuBackground(g):
	AbstractPage.drawMenuBackgroundStatic(g, store, menusUsed)


## Draws the standard things in a building: background, dialog, keeper and
## the menu background.
func drawStandard(g):
	g.drawImage(background, 0, 0)
	if dialogIsShowing:
		Dialog.getDialog().draw(g, true, name, dialog[0], dialog[1], false)
	g.drawCenteredImage(keeper, keeperHeight())
	drawMenuBackground(g)


func keeperHeight():
	return 205


## Draws the building.
func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(MenuValues.MENU_FONT_SIZE)
	g.setAlphaFunc(0.02)
	Graphics.setTextColor(0, 0, 0)
	drawStandard(g)
	draw3D(g)
	super.draw(g)


## Sets the previous (Values.UP) or next (Values.DOWN) child of the given
## node as the current child.
static func dirMenuPressed(n, dir):
	if dir == Values.UP:
		n.previousChild()
	elif dir == Values.DOWN:
		n.nextChild()


## Override to draw the subclasses of Building.
func draw3D(g3D):
	pass


func upPressed():
	pass


func rightPressed():
	pass


func downPressed():
	pass


func leftPressed():
	pass


func trianglePressed():
	pass


func circlePressed():
	pass


func crossPressed():
	pass


func squarePressed():
	pass


func R1Pressed():
	pass


func R2Pressed():
	pass


func L1Pressed():
	pass


func L2Pressed():
	pass


func selectPressed():
	pass
