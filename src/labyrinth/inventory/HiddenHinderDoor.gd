class_name HiddenHinderDoor
extends HinderDoor
## Port of labyrinth.inventory.HiddenHinderDoor: a hinder door that opens
## after it has been touched three times. It is not shown on the map while
## closed.


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, nextPlace = null, vStartPos = null) -> void:
	super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos)


func checkIfOpen():
	status = Database.getStatusFor(dataBaseName)
	return status >= 3


func getMapImageWhenClosed():
	return null


## Exits the given labyrinth, enters the door and sets the next place in the
## labyrinth by calling setNextPlace() with nextPlace as argument.
func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = Values.angleToDirection(lab.getPlayerAngle())
	if playerDir == dir:
		status = Database.getStatusFor(dataBaseName)
		Database.addStatus(dataBaseName, status + 1)
		if checkIfOpen():
			super.activate(lab)
