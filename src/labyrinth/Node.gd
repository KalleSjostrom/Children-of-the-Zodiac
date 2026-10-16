class_name LabyrinthNode
extends RefCounted
## Port of labyrinth.Node: a position in the labyrinth. The player can walk
## between these nodes via edges and the graph.
##
## Port note: Java's setWall(dir, nr) and setWall(dir, i, j) are merged into
## setWall(direction, i, j = null).

const DISTANCE = 4
const WIDTH = 4
const FLOOR_HEIGHT = -2
const ROOF_HEIGHT = 2
const SIZE = 16

var neighbors = null
var inventory = null
var position = null
var visited: bool = false
var seen: bool = false
var walls = null
var nrOfNeighbors: int = 0
var address: int = 0
var roof: int = 0
var floor: int = 0
var carpetFloor = null

const scale = 1.4


func _init(p_address = null) -> void:
	neighbors = [null, null, null, null]
	address = int(p_address)
	var x: int = address / SIZE
	var z: int = (address % SIZE) - (SIZE - 1)
	position = LabyrinthPosition.new(x, z)
	walls = [-1, -1, -1, -1]


## Java: setWall(int dir, int nr) and setWall(int direction, int i, int j).
func setWall(direction, i, j = null) -> void:
	if j == null:
		walls[direction] = i
	else:
		walls[direction] = i if walls[direction] == 0 else j


func setRoof(nr) -> void:
	roof = nr


func setFloor(useCarpetFloor, offset) -> void:
	if useCarpetFloor:
		addCarpetFloor(offset)
	else:
		floor = offset


func addCarpetFloor(offset) -> void:
	carpetFloor = Horizontal.new(position.getX(), position.getZ())
	var sum: int = 0
	var array: Array = J.array(nrOfNeighbors, 0)
	var j: int = 0
	for i in 4:
		if neighbors[i] != null:
			array[j] = i
			sum += array[j]
			j += 1
	match nrOfNeighbors:
		1:
			carpetFloor.setEnd(sum if sum % 2 == 0 else Values.getCounterAngle(sum), offset)
		2:
			var even: bool = sum % 2 == 0
			if even:
				carpetFloor.setStraight(sum, offset)
			else:
				if sum == 3:
					sum += 0 if array[1] == 3 else 4
				carpetFloor.setHook(sum, offset)
		3:
			carpetFloor.setTCross(sum, offset)
		4:
			carpetFloor.setCross(offset)


func setWalls(usePillarWalls, tex) -> void:
	if usePillarWalls:
		PillarWalls.addPillarWalls(self, tex, nrOfNeighbors)
	else:
		for i in 4:
			if neighbors[i] == null:
				walls[i] = tex


func drawRoof(g, direction) -> void:
	if direction == roof:
		draw(g, ROOF_HEIGHT)


func drawFloors(g, direction) -> void:
	if carpetFloor != null:
		carpetFloor.draw(g, -2, 4, direction)
	elif direction == floor:
		draw(g, FLOOR_HEIGHT)


func drawOneFloor(g) -> void:
	draw(g, FLOOR_HEIGHT)


func draw(g, height) -> void:
	var x: float = position.getX() - 2
	var z: float = position.getZ() + 2
	var h: float = height
	var gl = g.getGL()
	if height == FLOOR_HEIGHT:
		gl.glNormal3f(0, 1, 0)
		gl.glTexCoord2f(0, 1); gl.glVertex3f(x, h, z)
		gl.glTexCoord2f(1, 1); gl.glVertex3f(x + WIDTH, h, z)
		gl.glTexCoord2f(1, 0); gl.glVertex3f(x + WIDTH, h, z - WIDTH)
		gl.glTexCoord2f(0, 0); gl.glVertex3f(x, h, z - WIDTH)
	else:
		gl.glNormal3f(0, -1, 0)
		gl.glTexCoord2f(0, 0); gl.glVertex3f(x, h, z - WIDTH)
		gl.glTexCoord2f(1, 0); gl.glVertex3f(x + WIDTH, h, z - WIDTH)
		gl.glTexCoord2f(1, 1); gl.glVertex3f(x + WIDTH, h, z)
		gl.glTexCoord2f(0, 1); gl.glVertex3f(x, h, z)


func drawWall(g, texture, flip, tangent) -> void:
	for i in 4:
		if walls[i] != -1 and walls[i] == texture:
			drawOneWall(g, i, flip)


func drawOneWall(g, dir, flip) -> void:
	var x: float = position.getX() - 2
	var z: float = position.getZ() + 2
	flip = true
	var gl = g.getGL()
	match dir:
		0:
			# Back wall // SOUTH
			gl.glNormal3f(0, 0, -1.0)
			gl.glTexCoord2f(0 if flip else 1, 1); gl.glVertex3f(x, FLOOR_HEIGHT, z)
			gl.glTexCoord2f(0 if flip else 1, 0); gl.glVertex3f(x, ROOF_HEIGHT, z)
			gl.glTexCoord2f(1 if flip else 0, 0); gl.glVertex3f(x + WIDTH, ROOF_HEIGHT, z)
			gl.glTexCoord2f(1 if flip else 0, 1); gl.glVertex3f(x + WIDTH, FLOOR_HEIGHT, z)
		1:
			# Left Wall // WEST
			gl.glNormal3f(1, 0, 0)
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, ROOF_HEIGHT, z)
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, FLOOR_HEIGHT, z)
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, FLOOR_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, ROOF_HEIGHT, z - WIDTH)
		2:
			# Front Wall // NORTH
			gl.glNormal3f(0, 0, 1.0)
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, ROOF_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, FLOOR_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + WIDTH, FLOOR_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + WIDTH, ROOF_HEIGHT, z - WIDTH)
		3:
			# Right Wall // EAST
			gl.glNormal3f(-1.0, 0, 0)
			gl.glTexCoord2f(1 if flip else 0, 0); gl.glVertex3f(x + WIDTH, ROOF_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(1 if flip else 0, 1); gl.glVertex3f(x + WIDTH, FLOOR_HEIGHT, z - WIDTH)
			gl.glTexCoord2f(0 if flip else 1, 1); gl.glVertex3f(x + WIDTH, FLOOR_HEIGHT, z)
			gl.glTexCoord2f(0 if flip else 1, 0); gl.glVertex3f(x + WIDTH, ROOF_HEIGHT, z)


## Gets the neighbor node that lies in the given direction from this node.
func getNode(direction):
	return neighbors[direction]


func putNeighbours(direction, node) -> void:
	neighbors[direction] = node
	nrOfNeighbors += 1


## Gets the position (LabyrinthPosition) of this node.
func getPos():
	return position


func hasInventory() -> bool:
	return inventory != null


func checkInventory() -> bool:
	return inventory != null and (inventory is Chest or inventory is InventoryButton)


func setInventory(inv) -> void:
	inventory = inv


func getInventory():
	return inventory


func visit() -> void:
	if not visited:
		visited = true
		for n in neighbors:
			if n != null:
				n.setSeen(true)


func arrive(lab) -> void:
	if hasInventory():
		inventory.arrive(lab)


func setSeen(p_seen) -> void:
	seen = p_seen


func isVisited() -> bool:
	return visited


func isSeen() -> bool:
	return seen


func setVisitedAndSeen(isVisited_, isSeen_) -> void:
	visited = isVisited_
	seen = isSeen_


func getNeighbor(i):
	return neighbors[i]


func addToWall(direction, offset) -> void:
	walls[direction] += offset


func getNeighbors():
	return neighbors


func getAddress() -> int:
	return address


func drawInMap(g, x, y, onThis, dir, isOnFloor, drawAll) -> void:
	var drawAnyway: bool = false
	if isSeen():
		if hasInventory():
			var inv = getInventory()
			drawAnyway = inv.shouldDrawWhenOnlySeen()
	if isVisited() or drawAnyway:
		g.setColor(1)
		g.drawImage(MapPage.mappiece2, x, y, scale)
		if hasInventory():
			var s = getInventory().getMapImage()
			if s != null:
				if getInventory().hasBeenIn():
					g.drawImage(LabyrinthMap.entrance[0], x, y, scale)
				g.drawImage(s, x, y, scale)
		if onThis:
			g.setImageColor(1, 0.85, 0, 1)
			if drawAll:
				g.drawImage(LabyrinthMap.arrows[(dir + 2) % 4], x - 24, y - 24, scale * 2.2)
			else:
				g.drawImage(LabyrinthMap.arrows[(dir + 2) % 4], x, y, scale * 1)
			g.setImageColor(1, 1, 1, 1)
	elif isSeen():
		g.drawImage(MapPage.mappiece, x, y, scale)


func drawInSmallMap(g, x, y, angle) -> void:
	var drawAnyway: bool = false
	if isSeen():
		if hasInventory():
			var inv = getInventory()
			drawAnyway = inv.shouldDrawWhenOnlySeen()
	if isVisited() or drawAnyway:
		var t: GameTexture = ImageHandler.getTexture(MapPage.mappiece2)
		Utils3D.draw3D(g, t.getTexture(), x, y, 0, 0.1)
		if hasInventory():
			var inv = getInventory()
			if inv.hasBeenIn():
				t = ImageHandler.getTexture(LabyrinthMap.entrance[0])
				Utils3D.draw3D(g, t.getTexture(), x, y, 0, 0.1)
			inv.drawInMap(g, x, y, angle)
	elif isSeen():
		var t: GameTexture = ImageHandler.getTexture(MapPage.mappiece)
		Utils3D.draw3D(g, t.getTexture(), x, y, 0, 0.1)


func test(g, x, y, start, angle) -> void:
	var drawAnyway: bool = false
	if isSeen():
		if hasInventory():
			var inv = getInventory()
			drawAnyway = inv.shouldDrawWhenOnlySeen()
	if isVisited() or drawAnyway:
		var t: GameTexture = ImageHandler.getTexture(MapPage.mappiece2)
		Utils3D.draw3D(g, t.getTexture(), x, y, 0, 0.1)
		if hasInventory():
			var inv = getInventory()
			inv.drawInMap(g, x, y, angle)
	elif isSeen():
		var t: GameTexture = ImageHandler.getTexture(MapPage.mappiece)
		Utils3D.draw3D(g, t.getTexture(), x, y, 0, 0.1)
