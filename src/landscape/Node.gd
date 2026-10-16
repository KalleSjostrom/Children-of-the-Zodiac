class_name LandscapeNode
extends RefCounted
## Port of landscape.Node: a node in the landscape (village, crossroad or
## labyrinth).

var im = ""
var type = ""
var name = ""
var roads = J.array(4, null)
var x: int = 0
var y: int = 0
var drawx: int = 0
var drawy: int = 0
var visited: bool = false
var isSource_ = J.array(4, false)


func _init(X = null, Y = null, t = null, n = null) -> void:
	x = X
	y = Y
	type = t
	name = n
	im = Values.LandscapeImages + "crossroad.png"
	ImageHandler.addToCurrentLoadOnUse(im)
	drawx = x - 2
	drawy = y - 4


## Draws this node.
func draw(g):
	g.drawImage(im, drawx, drawy)


## Connects a road with the given direction to this place.
func setRoad(dir, r, isSource):
	self.isSource_[dir] = isSource
	roads[dir] = r


func visit():
	visited = true


func getRoad(dir):
	return roads[dir]


func isSource(dir):
	return isSource_[dir]


func getName():
	return name


func getType():
	return type


func isVisited():
	return visited


func getXpos():
	return x


func getYpos():
	return y
