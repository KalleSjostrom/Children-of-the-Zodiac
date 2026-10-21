class_name InventoryDoor
extends AbstractDoor
## Port of labyrinth.inventory.Door.
##
## This class is the inventory door. If the player finds the node where this
## inventory resides, the player can enter the door and be transported to the
## place named nextPlace.
##
## Port notes: the static Door.reset() is resetStatic(). The Java constructors
## Door(node, dir, openRoad, nextPlace, status, tok) and
## Door(node, dir, openRoad, nextPlace, status, tok, nrImages, texture) are
## merged (nrImages == null means 0 images and no texture).

static var doorCount = 0
var nextPlaces = []
var openRoad = null


## openRoad: the road(s) to open (C-R, ';' separated) after the player has
## passed this door the first time. nextPlace: the name of the next place.
## tok: the tokenizer containing some additional next places.
func _init(node = null, dir = null, openRoad = null, nextPlace = null, status = null, tok = null, nrImages = null, texture = null) -> void:
	super(node, dir, 0 if nrImages == null else nrImages, texture, status)
	init(openRoad, nextPlace, tok)


func setHaveBeen(lastNodesName = null):
	for np in nextPlaces:
		if lastNodesName == null or \
				Organizer.convert(np).to_lower() == Organizer.convert(lastNodesName).to_lower():
			_setHaveBeen()


func init(openRoad, nextPlace, tok):
	index = InventoryDoor.doorCount
	InventoryDoor.doorCount += 1
	self.openRoad = J.split(openRoad, ";")
	nextPlaces.append(nextPlace.replace("_", " "))
	while tok.hasMoreTokens():
		nextPlaces.append(tok.nextToken().replace("_", " "))


func initDraw(gl):
	if self is LadderDoor:
		super.initDraw(gl)


func setSettings():
	scale = 0.0026
	zOff = 1.9999


## Gets the index of this door. This is a number assigned to each door when
## they are created, used when initiating a labyrinth to know where to put the
## player.
func getDoorIndex():
	return index


func draw(gl, dir = null):
	if dir != null:
		super.draw(gl, dir)
		return
	# The door is just a texture which is drawn by the wall renderer.
	if images.size() > 0:
		super.draw(gl)


## Bridge (phase 2 step B): draw without the drawing (Inventory.place_view);
## only a door with images (a ladder) draws.
func place_view(g, dir = null):
	if images.size() > 0:
		return super.place_view(g)
	return {"visible": false}


func checkIfOpen():
	return true


func drawInMap(g, x, y, angle):
	if haveBeenIn:
		var t = ImageHandler.getTexture(LabyrinthMap.entrance[0])
		if t != null:
			Utils3D.draw3D(g.getGL(), t.getTexture(), x, y, 0, 0.1)
	super.drawInMap(g, x, y, angle)


## Exits the given labyrinth, enters the door and sets the next place in the
## labyrinth by calling setNextPlace() with the next place as argument.
func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = ((int(lab.getPlayerAngle()) - 90) / 90 + 4) % 4
	if playerDir == dir:
		for i in openRoad.size():
			var road: String = openRoad[i]
			if road != "dontopen":
				Database.addStatus("road" + road, 1) # road

		super.enter(lab, info)

		status = Database.getStatusFor(dataBaseName)
		lab.exitLabyrinth(Values.EXIT)
		status = 0 if status == -1 else status
		# A TriggerDoor marks its first arrival with status 2 (arrive), which
		# is not an index into nextPlaces (those doors have one place):
		# use the last place instead of reading past the end.
		var next: String = nextPlaces[mini(status, nextPlaces.size() - 1)]
		if next.contains("-pos"):
			var split: Array = J.split(next, "-pos")
			next = split[0]
			VillageLoader.staticStartPos = J.parseInt(split[1])
		lab.setNextPlace(next)
		if status < nextPlaces.size() - 1:
			Database.addStatus(dataBaseName, status + 1)
		_setHaveBeen()


static func resetStatic():
	doorCount = 0
