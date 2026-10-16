class_name AbstractDeck
extends Hideable
## Port of battle.equipment.AbstractDeck.
##
## This class is an abstraction of a deck drawn in 3D. It extends hideable
## which makes the decks possible to hide.

## The x positions of the eight slots in battle.
static var xs = [-0.7, -0.5, -0.3, -0.1, 0.1, 0.3, 0.5, 0.7]
var nrOfSlots: int = 0
var selectedCard: int = -1

## Java loaded these permanently in a static initializer; here they are
## loaded on first use (see getImages()).
static var images = null
var largeDist: float = 0.034


## Creates a new deck object with the given number of textures.
func _init(size = null) -> void:
	super(size if size != null else 0)


## Lazily creates the static image list (Java: static block).
static func _getImages() -> Array:
	if images == null:
		images = ["", "", ""]
		images[0] = ImageHandler.addPermanentlyLoadNow(Values.BattleImages + "transball.png")
		images[1] = ImageHandler.addPermanentlyLoadNow(Values.BattleImages + "save.png")
		images[2] = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "hand2.png")
	return images


## Creates the coordinates for the deck. It uses getY to get the height
## of the deck, the x value is gotten from the first xs value.
## The object is centered around the position.
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	createCoordList(3)
	setPos(BattleValues.DECK_POSITION - 0.04, getY())

	setCoords(width, height, 0)
	setCoords(saveW, saveH, 1)

	var x: float = saveW / 2.0
	var y: float = saveH / 2.0
	var z: float = -saveW
	var nx: float = -x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist
	var nx2: float = x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist
	nx += 0.04
	nx2 += 0.04
	var ny: float = -y - 0.04
	var ny2: float = y - 0.04

	createCoordFor(nx, nx2, 1, X)
	createCoordFor(ny, ny2, 1, Y)
	createCoordFor(z, z, 1, Z)

	x = -0.085
	y = -0.49
	z = 0.0

	createCoordFor(x, x + handW, 2, X)
	createCoordFor(y, y + handH, 2, Y)
	createCoordFor(z, z, 2, Z)


func setCoords(w, h, i):
	var x: float = w / 2.0
	var y: float = h / 2.0
	var z: float = -w
	var nx: float = -x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist
	var nx2: float = x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist

	createCoordFor(nx, nx2, i, X)
	createCoordFor(-y, y, i, Y)
	createCoordFor(z, z, i, Z)


## Initiates the drawing: loads the textures used and creates the
## coordinates of the slots, the save slot and the pointer hand.
func initDraw(g: Graphics):
	var imgs := _getImages()
	loadTexture(imgs[0], 0)
	loadTexture(imgs[1], 1)
	loadTexture(imgs[2], 2)
	setSize(2, BattleValues.HAND_SCALE)
	var handH: float = height
	var handW: float = width

	setSize(1, BattleValues.CARD_SCALE)
	var saveH: float = height
	var saveW: float = width

	setSize(0, BattleValues.CARD_SCALE)

	createCoords(saveW, saveH, handW, handH)
	g.setAlphaFunc(0)

	coordList[1][X][0] = coordList[1][X][0] + nrOfSlots * BattleValues.CARD_DISTANCE_BETWEEN + largeDist
	coordList[1][X][1] = coordList[1][X][1] + nrOfSlots * BattleValues.CARD_DISTANCE_BETWEEN + largeDist


## Draws the slots on the current location.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	translate(g)

	var cl: Array = J.array2d(3, 2, 0.0)
	cl[X][0] = coordList[0][X][0]
	cl[X][1] = coordList[0][X][1]
	cl[Y][0] = coordList[0][Y][0]
	cl[Y][1] = coordList[0][Y][1]
	cl[Z][0] = coordList[0][Z][0]
	cl[Z][1] = coordList[0][Z][1]
	for i in nrOfSlots:
		Utils3D.draw3D(g, texture[0].getTexture(), cl)
		cl[X][0] += BattleValues.CARD_DISTANCE_BETWEEN
		cl[X][1] += BattleValues.CARD_DISTANCE_BETWEEN
	Utils3D.draw3D(g, texture[1].getTexture(), coordList[1])


## Draws all the cards in the given deck (Array of GLCard). The selected card
## is drawn a units above the rest.
func drawDeck(g, deck, a = null):
	var add: float = 0.0 if a == null else float(a)
	for i in deck.size():
		if i == selectedCard:
			deck[i].draw(g, getYtrans() + add)
			var off: int = maxi(nrOfSlots - deck.size(), 0)
			drawHand(g, i + off, 0)
		else:
			deck[i].draw(g, getYtrans())


## Draws the pointer hand at the position xs[index] + offset.
func drawHand(g, index, offset):
	if visible:
		g.loadIdentity()
		g.translate(xs[index] + offset + 0.01, 0, BattleValues.STANDARD_Z_DEPTH)
		Utils3D.draw3D(g, texture[2].getTexture(), coordList[2])


## Draws only the first card of the given deck.
## (GLDeck overrides this: called without arguments it is GLDeck's private
## drawTopCard() that takes the top card from the deck.)
func drawTopCard(g = null, deck = null):
	if deck != null and deck.size() > 0:
		deck[0].draw(g, getYtrans())


## Sets the number of slots to the given number.
func setNrOfSlots(nr):
	nrOfSlots = nr - 1


## Gets the height of the deck if it is not translated (abstract).
func getY():
	return 0.0
