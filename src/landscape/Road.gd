class_name Road
extends RefCounted
## Port of landscape.Road: connects nodes (places) with walkable roads.

var line = []
var dots = []
var destNode = null
var sourceNode = null
var isSource: bool = false
var closed: bool = false
var X: int = -1
var Y: int = -1
var address: int = 0
var step: int = 0


## Creates a new road with the given address, source node, destination node
## and closed status.
func _init(a = null, s = null, d = null, close = null) -> void:
	address = a
	sourceNode = s
	destNode = d
	closed = close


func setIsSource(s):
	isSource = s


## Gets the destination node.
func getDest():
	return destNode if isSource else sourceNode


func visit():
	destNode.visit()
	sourceNode.visit()


func getAddress():
	return address


## Moves the player on this road. Returns the angle of the player or -1.
func movePlayer(player, step):
	var angle: int = -1
	if not closed:
		if isSource and step < line.size():
			var l = line[step]
			player.setXandY(l.x, l.y)
			angle = l.angle
		elif step >= 0 and step < line.size():
			var l = line[(line.size() - 1) - step]
			player.setXandY(l.x, l.y)
			angle = (l.angle + 2) % 4
	return angle


## Java overloads: addCoordinates(int x, int y) adds one coordinate (and a
## move dot); addCoordinates(x1, y1, x2, y2) adds the line between two points.
func addCoordinates(x1, y1, x2 = null, y2 = null):
	if x2 == null:
		var x: int = x1
		var y: int = y1
		dots.append(MoveDot.new(x, y))
		if X != -1:
			addCoordinates(X, Y, x, y)
		X = x
		Y = y
		return
	var angle: int = 0
	if absi(x2 - x1) > absi(y2 - y1):
		angle = Values.LEFT if x1 > x2 else Values.RIGHT
	else:
		angle = Values.UP if y1 > y2 else Values.DOWN

	var splitNumber: float = 7.0

	var Xtemp: float = (x2 - x1) / splitNumber
	var Ytemp: float = (y2 - y1) / splitNumber
	var i: int = 0
	while i <= splitNumber:
		line.append(Coordinate.new(x1 + int(Xtemp * i), y1 + int(Ytemp * i), angle))
		i += 1


## Called by the loader at the end of each road. Removes the first and last
## dot (the source and destination node).
func done():
	J.removeAt(dots, 0)
	J.removeAt(dots, dots.size() - 1)


## Draws this road on the given graphics.
func drawRoad(g):
	for i in range(dots.size()):
		dots[i].draw(g)


func isClosed():
	return closed


func open():
	closed = false


func setClosed(close):
	closed = close


## A coordinate: x, y and the angle of the player standing on it.
class Coordinate extends RefCounted:
	var x: int = 0
	var y: int = 0
	var angle: int = 0

	func _init(x = null, y = null, a = null) -> void:
		self.x = x
		self.y = y
		angle = a


## A small dot in between of each node.
class MoveDot extends RefCounted:
	var dot = ""
	var xpos: int = 0
	var ypos: int = 0

	func _init(x = null, y = null) -> void:
		xpos = x
		ypos = y
		dot = Values.LandscapeImages + "movedot.png"
		ImageHandler.addToCurrentLoadOnUse(dot)

	func draw(g):
		g.drawImage(dot, xpos, ypos)
