class_name GLSlot
extends FlatObj
## Port of battle.equipment.GLSlot.
##
## This class is GL wrapper for the objects of the Slot class. This is
## done to be able to draw them in 3D space. It has two slots, one for each
## mode of the weapon.

var slots = null


## Creates a new slot2D containing the given slots (offense and defense side
## of the weapon) at the x coordinate x.
func _init(slot1 = null, slot2 = null, x = null) -> void:
	super(2)
	slots = [slot1, slot2]
	xPos = 0.0 if x == null else float(x)
	rotation = FRONT
	targetRotation = rotation


## Loads the textures and creates the position coordinates.
func initDraw(g: Graphics):
	loadTextures()
	createCoordList(2)

	createCoordFor(-width / 2, width / 2, 0, X)
	createCoordFor(-height / 2, height / 2, 0, Y)
	createCoordFor(-0.001, -0.001, 0, Z)

	copyCoords(1, 0, X)
	copyCoords(1, 0, Y)
	createCoordFor(0.001, 0.001, 1, Z)

	drawTex(g, 0, 0, true)
	drawTex(g, 1, 1, false)


## Loads the textures used: the first slot as first texture and the second
## slot as second texture (only when non null).
func loadTextures():
	loadTexture(null if slots[0] == null else slots[0].getImage(), 0)
	loadTexture(null if slots[1] == null else slots[1].getImage(), 1)
	if slots[0] != null:
		setSize(0, BattleValues.SLOT_SCALE)
	elif slots[1] != null:
		setSize(1, BattleValues.SLOT_SCALE)
	else:
		height = 0.2
		width = 0.2


## Java overloads: draw(Graphics g) (empty) and draw(Graphics g, float y).
## Draws the slot at the given y position. Loads the identity matrix.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if alpha == null:
		return
	var y: float = alpha
	update()
	g.loadIdentity()
	g.translate(xPos, y, BattleValues.STANDARD_Z_DEPTH - 0.001)
	g.rotate(rotation, 0, 1, 0)
	if currentList == 0:
		drawTex(g, 0, 0, true)
	else:
		drawTex(g, 1, 1, false)


## Gets the type of slot stored on the given side (GLWeapon.OFFENSE_MODE or
## GLWeapon.DEFENSE_MODE).
func getKind(currentMode):
	return slots[currentMode].getType()


## Checks if there is a card in this slot.
func hasCard():
	return card != null


## Turns the slot around.
func toggleSide():
	if targetRotation != FRONT:
		targetRotation = FRONT
	else:
		targetRotation = BACK


## Called when the object has rotated half way: switches the drawn side.
func rotatedHalfWay():
	currentList = 1 if targetRotation == BACK else 0


## Throws away the card residing in this slot.
func clearSlot():
	card = null


## Checks if the slot in the given mode is free to use.
func isFree(currentMode):
	return slots[currentMode] != null and not hasCard()


func doesFit(p_card, currentMode):
	var cardFits: bool = false
	if isFree(currentMode):
		var t: int = slots[currentMode].getType()
		if p_card.getCard().getType() == AbstractCard.NEUTRAL:
			cardFits = t == Slot.MAGIC or t == Slot.SUPPORT
		else:
			cardFits = t == p_card.getType()
	return cardFits
