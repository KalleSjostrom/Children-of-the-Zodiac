class_name AbstractDoor
extends Inventory
## Port of labyrinth.inventory.AbstractDoor.
##
## Port note: enter(lab, info) is Java's protected enter(Labyrinth,
## InventoryInfo). HinderDoor merges its own enter(Labyrinth) into the same
## method (see HinderDoor.gd).

const STRAIGHT = 0
const DOWN = 1
const UP = 2
var direction: int = STRAIGHT
var nameInMain = null
var index: int = 0


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null) -> void:
	super(n, dir, nrOfTexs, image, status)


func setGoingUp(goingUp):
	direction = UP if goingUp else DOWN


func checkHaveBeen():
	super.checkHaveBeen()
	var temp: Array = J.split(dataBaseName, "\\.")
	nameInMain = Organizer.convert(temp[0]) + "-mark" + str(index)
	haveBeenIn = Database.getStatusFor(dataBaseName + "havebeenin") == 1


## (abstract)
func checkIfOpen():
	return false


func getMapImage():
	if checkIfOpen():
		return getMapImageWhenOpen()
	return getMapImageWhenClosed()


func getMapImageWhenOpen():
	var image = null
	match direction:
		STRAIGHT:
			image = LabyrinthMap.doorOpen[(dir + 2) % 4]
		UP:
			image = LabyrinthMap.stairs[1]
		DOWN:
			image = LabyrinthMap.stairs[0]
	return image


## Java: protected void enter(Labyrinth lab, InventoryInfo info).
func enter(lab, info = null):
	if info == null:
		match direction:
			UP:
				SoundPlayer.playSound(SoundMap.LABYRINTH_STONE_STAIRS)
			DOWN:
				SoundPlayer.playSound(SoundMap.LABYRINTH_STONE_STAIRS)
	elif info.hasSoundEffect():
		SoundPlayer.playSound(info.getSoundEffect())


func getMapImageWhenClosed():
	return LabyrinthMap.doorClosed[(dir + 2) % 4]


func drawInMap(g, x, y, angle):
	if mapImageMoveWithMap():
		var s = getMapImage()
		if s != null:
			var gt = ImageHandler.getTexture(s)
			var tex = gt.getTexture() if gt != null else null
			if tex != null:
				Utils3D.draw3D(g, tex, x, y, 0, 0.1)
	else:
		super.drawInMap(g, x, y, angle)


func mapImageMoveWithMap():
	if checkIfOpen():
		return direction == STRAIGHT
	return true


func shouldDrawWhenOnlySeen():
	return false


func isPassable(dir):
	return (self.dir + 2) % 4 != dir


func isPassableOnThis(dir):
	return (self.dir) % 4 != dir


func isDirectedTowards(dir):
	return self.dir == dir


func setStatus(value):
	Database.addStatus(dataBaseName, value)
	status = value


func getStatus():
	return status


func getNameInMain():
	return nameInMain
