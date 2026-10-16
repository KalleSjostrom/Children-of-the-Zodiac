class_name FlatObj
extends Object2D
## Port of battle.equipment.FlatObj.
##
## This class implements the similar behavior from both the GLCard and GLSlot
## classes. Both of these extends this class. Similar abilities includes
## double texture (front and back), able to rotate and to choose which side to
## draw if not drawing both.

## The rotation in degrees when showing the front of this flat object.
const FRONT = 0

## The rotation in degrees when showing the back of this flat object.
const BACK = 180

static var FRONT_SIDE = [0]
static var BACK_SIDE = [1]
static var BOTH_SIDES = [FRONT_SIDE[0], BACK_SIDE[0]]

var card = null
var currentSide = BOTH_SIDES
var rotation: float = 0.0
var targetRotation: float = 0.0
var xPos: float = 0.0
var speed: float = BattleValues.CARD_FLIP_SPEED
var startRotation: float = 0.0


## Constructs a new FlatObj with the given number of textures.
func _init(size = null) -> void:
	super(size if size != null else 0)


## This method updates the rotation. If the object has rotated half
## way the method rotatedHalfWay() is called and when the rotation is
## done, the rotateDone() method is called. These methods does not
## do anything and is free to override.
func update(progress = null):
	if targetRotation != rotation:
		rotation += (speed if targetRotation == BACK else -speed) * Values.LOGIC_INTERVAL
		hasRotatedHalfWay()
		if targetRotation == rotation:
			rotateDone()


## Checks if the object has rotated half the way to its target.
func hasRotatedHalfWay():
	var b: bool = absf(rotation - targetRotation) < absf(rotation - startRotation)
	if b:
		startRotation = targetRotation
		rotatedHalfWay()
	return b


## Rotates the object to the given side (FRONT or BACK).
func flip(side):
	startRotation = rotation
	targetRotation = side


## Sets the card that should be stored in this object.
func setCard(p_card):
	card = p_card


## Called when the rotation is done. Empty; override to implement an effect.
func rotateDone():
	pass


## Called when the object has rotated half way. Empty; override to implement
## an effect.
func rotatedHalfWay():
	pass
