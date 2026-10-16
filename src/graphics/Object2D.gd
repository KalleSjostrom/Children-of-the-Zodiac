class_name Object2D
extends TimeHideable
## Port of graphics.Object2D: a flat textured object drawn in 3D (cards,
## creatures, bars ...). coordList[i] = [[x0, x1], [y0, y1], [z0, z1]].
##
## Port note: Java's protected draw(g, texIndex, coordIndex[, drawFront])
## overloads are named drawTex(...) here; draw(g) is the abstract draw.

const X := 0
const Y := 1
const Z := 2
const INVISIBLE := -1

var texture: Array = []
var currentList := 0
var coordList: Array = []
var width := 3.0
var height := 3.0


func _init(size: int = 0) -> void:
	texture = []
	texture.resize(size)


func createCoords(size: int) -> void:
	createCoordList(size)
	createCoordFor(-width / 2, width / 2, 0, X)
	createCoordFor(-height / 2, height / 2, 0, Y)
	createCoordFor(0, 0, 0, Z)
	if size >= 2:
		copyCoords(1, 0, X)
		copyCoords(1, 0, Y)
		createCoordFor(-0.001, -0.001, 1, Z)


func createCoordList(size: int) -> void:
	coordList = []
	for i in size:
		coordList.append([[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]])


func copyCoords(destination: int, source: int, axle: int) -> void:
	coordList[destination][axle][0] = coordList[source][axle][0]
	coordList[destination][axle][1] = coordList[source][axle][1]


func createCoordFor(bottomLeft: float, topRight: float, index: int, axle: int) -> void:
	coordList[index][axle][0] = bottomLeft
	coordList[index][axle][1] = topRight


## Java: protected draw(Graphics g, int texIndex, int coordIndex[, boolean drawFront]).
func drawTex(g: Graphics, texIndex: int, coordIndex: int, drawFront = null) -> void:
	if texture[texIndex] != null:
		if drawFront == null or drawFront:
			Utils3D.draw3D(g, texture[texIndex].getTexture(), coordList[coordIndex])
		else:
			Utils3D.draw3DBackside(g, texture[texIndex].getTexture(), coordList[coordIndex])


## Java overloads loadTexture(String image, int index) and
## loadTexture(String path, String name, int index).
func loadTexture(a, b, c = null) -> void:
	var image = a
	var index = b
	if c != null:
		image = str(a) + str(b)
		index = c
	if image != null:
		texture[index] = ImageHandler.getTexture(image)


func setSize(index: int, scale: float) -> void:
	height = texture[index].getHeight() * scale
	width = texture[index].getWidth() * scale


func initDraw(g: Graphics) -> void:
	pass


func draw(g: Graphics) -> void:
	pass


func drawTopLayer(g: Graphics) -> void:
	pass
