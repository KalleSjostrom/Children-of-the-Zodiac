class_name Riddle
extends Inventory
## Port of labyrinth.inventory.Riddle.
##
## This class is the inventory riddle. If the player finds the node where this
## inventory resides, a riddle game mode is started letting the player read
## and solve the riddle.

var name = ""
var riddleClass = ""
var hinders = null


## name: the name of the riddle file to execute. riddleClass: the class name
## (in package miniGames) of the riddle game. hinders: the hinders to open.
func _init(node = null, dir = null, name = null, image = null, status = null, riddleClass = null, hinders = null) -> void:
	super(node, dir, 1, image, status)
	self.hinders = hinders
	self.name = name
	self.riddleClass = riddleClass


func setSettings():
	scale = BattleValues.CARD_SCALE
	info = getSettings()
	if info != null:
		heightOffset = info.getHeightOffset()
		zOff = info.getZOffset()
		scale2 = info.getScale()
	else:
		zOff = 1.99
		heightOffset = 1.65
		scale2 = 4


## Activates the riddle by calling enterRiddle() in the given labyrinth with
## the riddle file name.
func activate(labyrinth):
	labyrinth.enterRiddle(name, "miniGames." + riddleClass, hinders)


func getMapImage():
	return LabyrinthMap.riddle[0]


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
