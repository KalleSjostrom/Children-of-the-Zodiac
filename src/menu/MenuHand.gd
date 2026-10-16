class_name MenuHand
extends RefCounted
## Port of menu.MenuHand: the hand that is used to display choices in the
## game. It is normally found in the menus, but also in the battle and dialog
## questions. The hand can be used to point at anything and the direction of
## which the hand is pointing can be set. It is also possible to hide the hand.

static var handRight: String = ImageHandler.addPermanentlyLoadOnUse(
		Values.MenuImages + "hand1.png")
static var handDown: String = ImageHandler.addPermanentlyLoadOnUse(
		Values.MenuImages + "hand2.png")

const X = 0
const Y = 1

var hand = null
var pos: Array = [0, 0]
var show: bool = true
var dimmed: bool = false


## The constructor of MenuHand. dir is the direction of which the hand should
## point (Values.DOWN or Values.RIGHT).
func _init(dir = null) -> void:
	hand = handDown if dir == Values.DOWN else handRight


## Draws the hand on the given graphics if it is not hidden.
func drawHand(g):
	if show:
		if dimmed:
			g.dim(.3)
		g.drawImage(hand, pos[X], pos[Y])
		if dimmed:
			g.dim(1)


func drawHandWithColor(g):
	if show:
		g.drawImage(hand, pos[X], pos[Y])


## Sets the visibility of the menu hand.
func setVisible(p_show):
	show = p_show


## Sets the x position of the menu hand.
func setXpos(xpos):
	pos[X] = int(xpos)


## Sets the y position of the menu hand.
func setYpos(ypos):
	pos[Y] = int(ypos)


## Gets the y position of the menu hand.
func getYpos():
	return pos[Y]


func getXpos():
	return pos[X]


## Gets the position of the menu hand ([x, y], note: not Values.X/Y order).
func getPos():
	return pos


func getXOffset():
	return 40


func getYOffset():
	return 25


func setDimmed(p_dimmed):
	dimmed = p_dimmed


func isDimmed():
	return dimmed
