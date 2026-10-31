class_name MenuScrollBar
extends RefCounted
## Port of menu.ScrollBar: the scroll bar drawn next to long menus and decks.

## Bridge (phase 4.2 step B): the node that shows a bar (show_bar).
const VIEW := "res://scenes/ui/PageScrollBar.tscn"

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


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): draw without
## the drawing: the same state changes (the lazy init, loadIdentity, the three
## images' binds). Returns the three images as Graphics.place_image places
## them (the top triangle, the ball, the bottom triangle), for a PageScrollBar
## node (a list's in MenuList, the deck page's and the card store's on their
## own).
func place_bar(g, current, total) -> Array:
	if not initiated:
		init()
		initiated = true
	g.loadIdentity()
	var images := [g.place_image(triangle, x, y, SCALE)]
	total -= 1
	var percent: float = 0.0 if total == 0 else (current / float(total))
	var ballY: float = minBallY + percent * ballRange
	images.append(g.place_image(ball, x + 8, ballY, SCALE))
	images.append(g.place_image(Values.MenuImages + "triangDown.png", x, y + height, SCALE))
	return images


## Bridge (phase 4.2 step B): draw without the drawing (place_bar), and the
## frame's next PageScrollBar node on the UI layer shows the bar where it
## would have been drawn (Graphics.show_ui): for the bars a page or store
## draws itself (DeckPage's two; a list's bar is part of its MenuList).
func show_bar(g, current, total) -> void:
	var images := place_bar(g, current, total)
	var view = g.show_ui(VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_bar(images, g.canvas_material())


func init():
	var gt: GameTexture = ImageHandler.getTexture(triangle)
	IM_HEIGHT = int(gt.getHeight() * SCALE)
	y = y - IM_HEIGHT / 2 - 5
	minBallY = y + BALL_HEIGHT_REL_BAR
	ballRange = height - (2 * (BALL_HEIGHT_REL_BAR)) + IM_HEIGHT / 2
