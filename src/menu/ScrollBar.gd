class_name MenuScrollBar
extends RefCounted
## Port of menu.ScrollBar: the scroll bar drawn next to long menus and decks.

var x: int = 0
var y: int = 0
var height: int = 0
static var triangle: String = ImageHandler.addPermanentlyLoadNow(
		Values.MenuImages + "triang.png")
static var ball: String = ImageHandler.addPermanentlyLoadNow(
		Values.MenuImages + "ball.png")
static var IM_HEIGHT: int = 0
static var SCALE: float = .4

const BALL_HEIGHT_REL_BAR = 35
var minBallY: int = 0
var ballRange: int = 0

var initiated: bool = false


func _init(p_x = null, p_y = null, p_height = null) -> void:
	x = p_x
	y = p_y
	height = p_height


func draw(g, current, total):
	if not initiated:
		init()
		initiated = true
	g.loadIdentity()
	g.drawImage(triangle, x, y, SCALE)
	total -= 1
	var percent: float = 0.0 if total == 0 else (current / float(total))
	var ballY: float = minBallY + percent * ballRange
	g.drawImage(ball, x + 8, ballY, SCALE)
	g.drawImage(Values.MenuImages + "triangDown.png", x, y + height, SCALE)


func init():
	var gt: GameTexture = ImageHandler.getTexture(triangle)
	IM_HEIGHT = int(gt.getHeight() * SCALE)
	y = y - IM_HEIGHT / 2 - 5
	minBallY = y + BALL_HEIGHT_REL_BAR
	ballRange = height - (2 * (BALL_HEIGHT_REL_BAR)) + IM_HEIGHT / 2
