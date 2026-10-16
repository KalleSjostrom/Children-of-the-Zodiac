class_name Graph
extends RefCounted
## Port of labyrinth.Graph: the path in a labyrinth as a graph of nodes.

var angle: int = 0
var map = null
var labyrinth = null
var inventories = null

func _init(name = null, labyrinthMap = null) -> void:
	InventoryDoor.doorCount = 0
	Database.visitLabyrinth(name.replace("_", " ").replace(".map", ""), labyrinthMap)
	map = labyrinthMap
	updateMap()

func getNodes():
	return map.getNodes()

func getNode(address):
	return map.getNode(address)

func getStartNode(i):
	if i == -1:
		return saveLocation()
	return doorLocation(i)

func saveLocation():
	for invs in map.getInventories():
		var inv = map.getInventory(invs)
		if inv is InventorySave:
			var d = inv
			angle = d.getDirection()
			var n = d.getNode()
			return n
	return null

func doorLocation(index):
	for invs in map.getInventories():
		var inv = map.getInventory(invs)
		if inv is InventoryDoor:
			var d = inv
			if d.getDoorIndex() == index:
				angle = Values.getCounterAngle(d.getDirection())
				return d.getNode()
		elif inv is HinderDoor:
			var d = inv
			if d.getDoorIndex() == index:
				angle = Values.getCounterAngle(d.getDirection())
				return d.getNode()
	return null

func getAngle():
	return angle

func activateInventory(currentNode, labyrinth):
	var inv = getInventory(currentNode)
	inv.activate(labyrinth)

func getInventory(node):
	for k in map.getInventories():
		var inv = map.getInventory(k)
		if inv.getNode() == node:
			return inv
	return null

func checkForHinder(currentNode, nextNode, dir):
	var inv = currentNode.getInventory()
	var hinderFound: bool = false
	if inv != null:
		if inv is HinderDoor:
			var hinderIsPassable: bool = inv.isPassableOnThis(dir)
			hinderFound = check(nextNode, dir) if hinderIsPassable else true
		elif inv is InventoryDoor:
			var hinderIsPassable: bool = inv.isPassableOnThis(dir)
			hinderFound = check(nextNode, dir) if hinderIsPassable else true
	else:
		hinderFound = check(nextNode, dir)
	return hinderFound

func check(node, dir):
	var inv = node.getInventory()
	var hinderFound: bool = false
	if inv != null:
		hinderFound = not inv.isPassable(dir)
	return hinderFound

func checkBossNode(currentNode, labyrinth):
	var inv = currentNode.getInventory()
	if inv != null and inv is InventoryBoss:
		var boss = inv
		if boss.isAlive():
			boss.enterBossBattle(labyrinth)
			return true
		currentNode.setInventory(null)
	return false

## Java: Arrays.sort(inventories) with Inventory.compareTo, a stable merge
## sort that puts inventories using material after the others. Done here as
## a stable partition (same result).
func sortInventory():
	var all: Array = []
	for k in map.getInventories():
		all.append(map.getInventory(k))
	var first: Array = []
	var last: Array = []
	for inv in all:
		if inv.useMaterial():
			last.append(inv)
		else:
			first.append(inv)
	inventories = first + last

func initDrawInventory(g):
	for k in map.getInventories():
		g.loadIdentity()
		var in_ = map.getInventory(k)
		in_.initDraw(g)

func drawInventory(g):
	for i in range(inventories.size()):
		var inv = inventories[i]
		if inv is InventorySave:
			inv.draw(g, labyrinth.getPlayerAngle())
		else:
			inv.draw(g)

func setLabyrinth(lab):
	labyrinth = lab

func isNodeVisible(target):
	var dir: int = labyrinth.getPlayerAngle()
	var ca: int = labyrinth.getCurrentNode().getAddress()
	var ta: int = target.getAddress()
	if dir > -45 and dir <= 45:
		return ta % 16 == ca % 16 and ta >= ca
	elif dir < 135 and dir > 45:
		return ta / 16 == ca / 16 and ta >= ca
	elif dir < -45 and dir >= -135:
		return ta / 16 == ca / 16 and ta <= ca
	else:
		return ta % 16 == ca % 16 and ta <= ca

func isDirectedTowards(n, dir):
	return getInventory(n).isDirectedTowards(dir)

func updateMap():
	for k in map.getInventories():
		var inv = map.getInventory(k)
		inv.updateStatus()
