class_name AdditiveHinderDoor
extends HinderDoor
## Port of labyrinth.inventory.AdditiveHinderDoor: a hinder door that opens
## when its status (added to by floor buttons) reaches openStatus.

var openStatus: int = 0


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, nextPlace = null, vStartPos = null) -> void:
	super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos)


func checkIfOpen():
	status = Database.getStatusFor(dataBaseName)
	return status == openStatus


func setOpenStatus(status):
	openStatus = status


func addStatus(i):
	status = Database.getStatusFor(dataBaseName)
	status += i
	Database.addStatus(dataBaseName, status)
