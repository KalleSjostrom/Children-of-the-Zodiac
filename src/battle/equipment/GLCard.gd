class_name GLCard
extends FlatObj
## Port of battle.equipment.GLCard.
##
## This class purpose is to manage the card drawn in 3D when battling.
## It draws the ordinary Card object that the player has in his deck in 3D.
## It therefore has some methods for flipping and moving around the card
## in a 3D space.

static var MOVE_SPEED: float = BattleValues.CARD_MOVE_SPEED
const USE_COLOR_BALLS_ON_GRAY_IMAGES = true
var xTarget: float = 0.0
var yOffset: float = 0.0
var k: float = 0.0
var m: float = 0.0
var enabled: bool = true


## Creates a new GLCard and allocates memory for five textures.
## Front, back, gray scale and the balls (normal and gray).
func _init() -> void:
	super(5)
	xPos = BattleValues.DECK_POSITION
	xTarget = xPos
	rotation = BACK
	targetRotation = rotation


## Initializes the graphic of the card, like textures and coordinates.
func initDraw(g: Graphics):
	loadTexture(card.getImage(0), 0) # Base image
	loadTexture(BattleValues.CARD_BACK, 1)
	loadTexture(card.getGrayImage(0), 2) # Base gray image
	loadTexture(card.getImage(1), 3) # Ball image
	if USE_COLOR_BALLS_ON_GRAY_IMAGES:
		loadTexture(card.getImage(1), 4) # Ball image
	else:
		loadTexture(card.getGrayImage(1), 4) # Ball gray image

	setSize(0, BattleValues.CARD_SCALE)
	createCoords(7)

	var w: float = texture[3].getWidth() * BattleValues.CARD_SCALE
	var h: float = texture[3].getHeight() * BattleValues.CARD_SCALE
	var x: float = -(w / 2.0) + 0.1 * w
	var hx: float = w / 2.0 + 0.1 * w

	createCoordFor(x, hx, 2, X)
	createCoordFor(height / 2.0 - 2.2 * h, height / 2.0 - 1.2 * h, 2, Y)
	createCoordFor(0.01, 0.01, 2, Z)

	var tx: float = 2.6 * x
	createCoordFor(tx, tx + w, 3, X)
	copyCoords(3, 2, Y)
	copyCoords(3, 2, Z)

	tx = 0.5 * hx
	createCoordFor(tx, tx + w, 4, X)
	copyCoords(4, 2, Y)
	copyCoords(4, 2, Z)

	tx = 4.2 * x
	createCoordFor(tx, tx + w, 5, X)
	copyCoords(5, 2, Y)
	copyCoords(5, 2, Z)

	tx = 1.4 * hx
	createCoordFor(tx, tx + w, 6, X)
	copyCoords(6, 2, Y)
	copyCoords(6, 2, Z)


func makeCardDrawList(g, base, ball):
	match card.getLevel():
		1:
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[2])
		2:
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[3])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[4])
		3:
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[2])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[5])
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[6])


## Java overloads: draw(Graphics g) (empty) and draw(Graphics g, float y).
## Draws the card at the given y location on the battle plane
## (0, 0, -2 after the identity matrix has been loaded).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if alpha == null:
		return
	var y: float = alpha
	g.loadIdentity()
	g.translate(xPos, y + yOffset, BattleValues.STANDARD_Z_DEPTH)
	g.rotate(rotation, 0, 1, 0)
	if is_same(currentSide, BOTH_SIDES):
		for i in currentSide.size():
			var side: int = currentSide[i] + (0 if enabled else 1)
			if side == 0:
				makeCardDrawList(g, 0, 3)
			elif side == 1:
				drawTex(g, 1, 1, false)
			elif side == 2:
				makeCardDrawList(g, 2, 4)
	else:
		if enabled:
			makeCardDrawList(g, 0, 3)
		else:
			makeCardDrawList(g, 2, 4)


## Sets the target location (on the x axis) for this card.
func setTarget(newTarget, supportMode = null):
	xTarget = newTarget


## Moves the object towards the given target. If the position after the
## step is further away than before, the target is returned (no overshoot).
func move(pos, target, p_speed):
	var dist: float = absf(pos - target)
	var p: float = pos
	p += p_speed if target > p else -p_speed
	return target if absf(p - target) >= dist else p


## Resets this cards x position to the position of the deck and turns the
## card so that the back is showing.
func reset():
	xTarget = BattleValues.DECK_POSITION
	xPos = xTarget
	targetRotation = BACK
	rotation = targetRotation
	currentSide = BOTH_SIDES
	enabled = true
	yOffset = 0
	card.reset()


## Updates the rotation and moves the card towards its target location.
func update(progress = null):
	super.update()
	if xPos != xTarget:
		xPos = move(xPos, xTarget, MOVE_SPEED * Values.LOGIC_INTERVAL)
		if xPos == xTarget:
			flip(FRONT)
	if yOffset != 0:
		if k == INF:
			yOffset = move(yOffset, 0.0, BattleValues.CARD_MOVE_SPEED_2 * Values.LOGIC_INTERVAL)
		else:
			yOffset = (k * xPos) + m


## Sets this card in the weapon slot where x is the x position of the slot.
func setInSlot(x):
	xTarget = x
	yOffset = BattleValues.DECK_HEIGHT_CARDS
	calc(xPos, yOffset, xTarget, 0.0)


## Calculates k and m in y = kx + m from the given points.
func calc(x1, y1, x2, y2):
	var dx: float = float(x2) - float(x1)
	var dy: float = float(y2) - float(y1)
	if dx == 0.0:
		# Java float division by zero.
		k = INF if dy > 0 else (-INF if dy < 0 else NAN)
	else:
		k = dy / dx
	m = y2 - (k * x2)


## Sets if this card should be enabled for play or not (gray if not).
func setEnabled(p_enabled):
	enabled = p_enabled


## Gets the type of the underlying card.
func getType():
	return card.getType()


## Gets the Card object wrapped in this GLCard.
func getCard():
	return card


## Called when the rotation has finished: the card always faces up.
func rotateDone():
	currentSide = FRONT_SIDE


func isEnabled():
	return enabled
