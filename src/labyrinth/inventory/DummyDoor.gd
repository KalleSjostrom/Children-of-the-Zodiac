class_name DummyDoor
extends Inventory
## Port of labyrinth.inventory.DummyDoor: a placeholder hinder that only
## holds a status in the database (used when a hinder named by a button does
## not exist in the labyrinth).
##
## Port note: the Java field dataBaseName (hiding Inventory.dataBaseName) is
## dataBaseName_.

var dataBaseName_ = ""


func _init(name = null) -> void:
	super(null, 0, 0, null, 0)
	dataBaseName_ = Organizer.convert(name)


func activate(labyrinth):
	pass


func setSettings():
	pass


func setStatus(value):
	status = value
	Database.addStatus(dataBaseName_, value)


func addStatus(i):
	status = Database.getStatusFor(dataBaseName_)
	status += i
	Database.addStatus(dataBaseName_, status)


func getMapImage():
	return null


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return false


func shouldDrawWhenOnlySeen():
	return false
