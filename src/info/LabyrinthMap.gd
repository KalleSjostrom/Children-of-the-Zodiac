class_name LabyrinthMap
extends RefCounted
## Port of info.LabyrinthMap.
##
## Port note: the static image name arrays are created in _static_init (Java
## static field initializers). Dictionary iteration order is insertion order
## (Java HashMap order differs; only affects draw order).

var name = ""
var nodes = {}
var inve = {}
var mapPos = null
var size: int = 0
static var arrows = null
static var doorClosed = null
static var doorOpen = null
static var stairs = null
static var chest = null
static var entrance = null
static var tool = null
static var lever = null
static var bomb = null
static var riddle = null
static var save = null
static var aegisOn = null
static var aegisOff = null
static var notes = null
static var miner = null
static var directions = null
static var SIZE: int = 47
static var OFFSET_X: int = 80
static var OFFSET_Y: int = -70
static var SIZE2: float = 0.12

static func _static_init() -> void:
	arrows = get_(4, "arrow")
	doorClosed = get_(4, "closed")
	doorOpen = get_(4, "open")
	stairs = get_(2, "stairs")
	chest = get_(2, "chest")
	entrance = get_(1, "entrance")
	tool = get_(2, "tool")
	lever = get_(2, "lever")
	bomb = get_(2, "bomb")
	riddle = get_(1, "riddle")
	save = get_(1, "save")
	aegisOn = get_(4, "aegis")
	aegisOff = get_(4, "aegisoff")
	notes = get_(2, "smallnote")
	miner = get_(2, "miner")
	directions = get_(1, "direction")

static func get_(size, name):
	var s: Array = J.array(size, null)
	if size == 1:
		s[0] = ImageHandler.addPermanentlyLoadOnUse(Values.MenuImages + name + ".png")
	else:
		for i in range(size):
			s[i] = ImageHandler.addPermanentlyLoadOnUse(Values.MenuImages + name + str(i) + ".png")
	return s

func setName(name):
	self.name = name

func getName():
	return name

func getNodes():
	return nodes

func getNode(address):
	return nodes.get(address)

func put(source, sourceNode):
	nodes[source] = sourceNode

func draw(g, currentNode, currentDir, pos, drawAll, calcPercent):
	var y: int
	var x: int
	var counter: int = 0
	var isOnFloor: bool = false
	for address in nodes:
		var n = nodes[address]
		if n.isVisited() or (n.isSeen() and n.hasInventory()):
			counter += 1
			if n == currentNode:
				isOnFloor = true
	if pos != null:
		if isOnFloor:
			Graphics.setTextColor(0, 0, 0)
			g.drawSingleCenteredText(self.getName(), pos[1] * 330 + 86, 1, 0, 24, pos[0] * 215 + 171)
			Graphics.setTextColor(0.2, 0.8, 0.2)
			g.drawSingleCenteredText(self.getName(), pos[1] * 330 + 85, 1, -1, 24, pos[0] * 215 + 170)
			Graphics.setTextColor(0, 0, 0)
		else:
			g.drawSingleCenteredText(self.getName(), pos[1] * 330 + 85, 1, -1, 24, pos[0] * 215 + 170)
	else:
		g.drawSingleCenteredText(self.getName(), 60, 1, 0, 34, 380)
	g.setFontSize(MenuValues.MENU_FONT_SIZE)
	for address in nodes:
		var n = nodes[address]
		y = (address % 16) * SIZE + OFFSET_Y
		x = (address / 16) * SIZE + OFFSET_X
		n.drawInMap(g, x, y, currentNode == n, currentDir, isOnFloor, drawAll)
	var percent: int
	if calcPercent:
		percent = J.round((counter / float(nodes.size())) * 100)
	else:
		percent = counter
	return percent

## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): draw without
## the drawing, for the menu's Automap node: the same state changes in the
## same order (the text colours, the font sizes 24 or 34 and 22, startText
## and finishText of the floor's name, each node's colours and binds and the
## Database reads and writes of its map image: LabyrinthNode.place_in_map).
## Returns {"percent": draw's, "names": the floor's name (and its shadow on
## the player's floor) as [text, position (its centre), font size, colour,
## bold, alignment] each, "images": the pieces, icons and arrow as
## Graphics.place_image places them in the floor's space, in drawing order,
## "modelview": the modelview they are drawn under (Graphics.modelview_2d:
## the identity for one floor, the overview's scale and translates)}.
func place_map(g, currentNode, currentDir, pos, drawAll, calcPercent) -> Dictionary:
	var y: int
	var x: int
	var counter: int = 0
	var isOnFloor: bool = false
	for address in nodes:
		var n = nodes[address]
		if n.isVisited() or (n.isSeen() and n.hasInventory()):
			counter += 1
			if n == currentNode:
				isOnFloor = true
	var floor := {"names": [], "images": [], "modelview": g.modelview_2d()}
	if pos != null:
		if isOnFloor:
			Graphics.setTextColor(0, 0, 0)
			_place_centered(g, self.getName(), pos[1] * 330 + 86, 1, 0, 24, pos[0] * 215 + 171, floor.names)
			Graphics.setTextColor(0.2, 0.8, 0.2)
			_place_centered(g, self.getName(), pos[1] * 330 + 85, 1, -1, 24, pos[0] * 215 + 170, floor.names)
			Graphics.setTextColor(0, 0, 0)
		else:
			_place_centered(g, self.getName(), pos[1] * 330 + 85, 1, -1, 24, pos[0] * 215 + 170, floor.names)
	else:
		_place_centered(g, self.getName(), 60, 1, 0, 34, 380, floor.names)
	g.setFontSize(MenuValues.MENU_FONT_SIZE)
	for address in nodes:
		var n = nodes[address]
		y = (address % 16) * SIZE + OFFSET_Y
		x = (address / 16) * SIZE + OFFSET_X
		n.place_in_map(g, x, y, currentNode == n, currentDir, isOnFloor, drawAll, floor.images)
	if calcPercent:
		floor.percent = J.round((counter / float(nodes.size())) * 100)
	else:
		floor.percent = counter
	return floor


## Graphics.drawSingleCenteredText(string, y, alpha, c, fontSize, center)
## without the drawing: its font size, startText and finishText, and the line
## centred on center in the text colour and alpha startText leaves.
static func _place_centered(g, string, y, alpha, c, fontSize, center, into: Array) -> void:
	g.setFontSize(fontSize)
	g.startText(alpha, c)
	into.append([str(string), Vector2i(center, y), g.getFontSize(), Graphics.text_color(g.text_alpha()),
			Graphics.font_bold(), HORIZONTAL_ALIGNMENT_CENTER])
	g.finishText()


func draw2(g, f, orig, lastOrig, angle):
	var address: int
	var x: float
	var y: float
	for key in nodes:
		var n = nodes[key]
		address = n.getAddress()
		if n.isVisited() or n.isSeen():
			y = address % 16
			x = address / 16
			var oy: float = (1 - f) * (orig % 16) + f * (lastOrig % 16)
			var ox: float = (1 - f) * (orig / 16) + f * (lastOrig / 16)
			var yDist: float = abs(y - oy)
			var xDist: float = abs(x - ox)
			if yDist < 4 and xDist < 4:
				y -= oy
				x -= ox
				y *= -SIZE2
				x *= SIZE2
				var dist: float = yDist + xDist
				var step: float = 1.0 / 4.0
				g.setColor(1, 1, 1, 1 - dist * step)
				n.drawInSmallMap(g, x, y, angle)
				g.setColor(1)

## Java returns an Iterator<String>; here an Array of the keys.
func getInventories():
	return inve.keys()

func getInventory(name):
	return inve.get(name)

func putInventory(databaseName, i):
	inve[databaseName] = i

func getMapPos():
	return mapPos

func setMapPos(mapPos):
	self.mapPos = mapPos

func getNrOfInventories():
	return inve.size()

static func convert(name):
	var s: Array = J.split(name, "--")
	var lab: Array = J.array(2, null)
	lab[0] = Organizer.convertKeepCase(s[0])
	lab[1] = Load.prepare(s[1])
	return lab

static func convertForSave(lab):
	return Organizer.convertBack(lab[0]) + "--" + Organizer.convertBack(lab[1])

func getNrVisitedNode():
	var v: int = 0
	for n in nodes.values():
		if n.hasInventory():
			var inv = n.getInventory()
			var visited: bool = n.isVisited()
			var seen: bool = inv.shouldDrawWhenOnlySeen() and n.isSeen()
			var special: bool = (inv is InventoryBoss) and n.isSeen()
			v += 1 if (visited or seen or special) else 0
		else:
			v += 1 if n.isVisited() else 0
	return v

func isFullyVisited():
	var nrVisited: int = getNrVisitedNode()
	return nodes.size() == nrVisited

func setSize(size):
	self.size = size

func getSize():
	return size
