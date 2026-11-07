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


## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): drawHand (the
## hand, dimmed to .3 or not, unless it is hidden) without the drawing: the
## dim's colour changes and drawImage's bind
## (Graphics.skip_image). Returns [image, x, y, tint (the colour it would be
## drawn in)], or [] when the hand is hidden.
func place_hand(g) -> Array:
	if not show:
		return []
	if dimmed:
		g.dim(.3)
	var tint: Color = g.getCurrentColor()
	g.skip_image(hand)
	if dimmed:
		g.dim(1)
	return [hand, pos[X], pos[Y], tint]


## Bridge (phase 4.2 step B, the stores, docs/ARCHITECTURE.md section 14):
## drawHand without the drawing, as an image Graphics.place_image places it
## ([texture, rect, tint]; [] when the hand is hidden), for a node that shows
## the hand among other images (the Church's bless markers).
func place_hand_image(g) -> Array:
	if not show:
		return []
	if dimmed:
		g.dim(.3)
	var placed: Array = g.place_image(hand, pos[X], pos[Y])
	if dimmed:
		g.dim(1)
	return placed


## Bridge (phase 4.2 step B): drawHandWithColor (the hand in the current
## colour) without the drawing (place_hand_image without the dim). The legacy
## drawHand and drawHandWithColor are removed (closing phase 4.2, plan 9.2).
func place_hand_with_color(g) -> Array:
	if not show:
		return []
	return g.place_image(hand, pos[X], pos[Y])


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
