class_name HinderDoor
extends AbstractDoor
## Port of labyrinth.inventory.HinderDoor.
##
## This class is the inventory hinder. An inventory is a thing in the
## labyrinth, that the player can find. If the player finds the node where
## this inventory resides, the Database class is called to find out whether
## the door is locked or not.
##
## Port notes:
## * enter(lab, info = null) merges Java's protected HinderDoor.enter(Labyrinth)
##   (info == null) and AbstractDoor.enter(Labyrinth, InventoryInfo)
##   (info != null, which plays the sound effect of info).
## * draw(gl, dir = null): dir == null is Java's draw(Graphics); otherwise the
##   inherited Inventory.draw(GL2, int).

var nextPlace = ""
var villageStartPos: int = 0
var showingDialog: bool = false
const LOCKED = 0
const CLOSED = 1
# const OPENED = 2


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, nextPlace = null, vStartPos = null) -> void:
	super(n, dir, nrOfTexs, image, status)
	index = InventoryDoor.doorCount
	InventoryDoor.doorCount += 1
	self.nextPlace = nextPlace
	villageStartPos = -1 if vStartPos == null else vStartPos


func getDoorIndex():
	return index


## To be called when the player enters the labyrinth.
func setHaveBeen(lastNodesName = null):
	if lastNodesName == null or \
			Organizer.convert(nextPlace).to_lower() == Organizer.convert(lastNodesName).to_lower():
		_setHaveBeen()


func draw(gl, dir = null):
	if dir != null:
		super.draw(gl, dir)
		return
	var g = gl
	var tex: int = 0 if checkIfOpen() else 1
	texture[tex].bind(g)
	g.beginQuads()
	node.drawOneWall(g, self.dir, false)
	g.end()


## Bridge (phase 2 step B): draw without the drawing (Inventory.place_view):
## it reads its status (checkIfOpen) and binds the open or the locked image,
## drawn as its node's wall; "frame" is 0 when open, 1 when locked.
func place_view(g, dir = null):
	var tex: int = 0 if checkIfOpen() else 1
	texture[tex].bind(g)
	var state: Dictionary = g.render_state_3d()
	var quads := DungeonQuads.new(g)
	node.drawOneWall(quads, self.dir, false)
	return {"visible": true, "frame": tex, "state": state, "quad": quads.eye_space()}


func setSettings():
	scale = BattleValues.CARD_SCALE


func checkIfOpen():
	status = Database.getStatusFor(dataBaseName)
	return status != LOCKED


## Exits the given labyrinth, enters the door and sets the next place in the
## labyrinth by calling setNextPlace() with nextPlace as argument.
func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = Values.angleToDirection(lab.getPlayerAngle())
	if playerDir == dir:
		status = Database.getStatusFor(dataBaseName)
		if checkIfOpen():
			enter(lab)
		else:
			if not showingDialog:
				lab.drawDialog("The door is locked!", "")
			showingDialog = not showingDialog


func enter(lab, info = null):
	if info != null:
		# Java: AbstractDoor.enter(Labyrinth, InventoryInfo).
		super.enter(lab, info)
		return
	# status = OPENED
	# Database.addStatus(dataBaseName, status)
	var next = lab.getMissionNext()
	if next != null:
		Organizer.getOrganizer().updateNextPlaceFor(next, nextPlace)
		lab.resetMissionNext()
	else:
		next = nextPlace
	if villageStartPos != -1:
		VillageLoader.staticStartPos = villageStartPos
	self.info = getSettings()
	super.enter(lab, self.info)
	lab.exitLabyrinth(Values.EXIT)
	lab.setNextPlace(next)
	_setHaveBeen()


func open():
	setStatus(CLOSED)
