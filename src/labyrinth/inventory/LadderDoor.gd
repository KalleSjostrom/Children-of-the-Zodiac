class_name LadderDoor
extends InventoryDoor
## Port of labyrinth.inventory.LadderDoor: a door drawn as a ladder (up or
## down). The static goingUp is set by Inventory.createInventory just before
## the constructor runs; setSettings() copies it to thisGoingUp.

static var goingUp: bool = false
var thisGoingUp: bool = false


func _init(node = null, dir = null, openRoad = null, image = null, status = null, tok = null, next = null) -> void:
	super(node, dir, openRoad, next, status, tok, 1, image)


func setSettings():
	scale = BattleValues.CARD_SCALE
	thisGoingUp = LadderDoor.goingUp
	info = getSettings()
	heightOffset = info.getHeightOffset()
	zOff = info.getZOffset()
	scale2 = info.getScale()


func getMapImage():
	return LabyrinthMap.stairs[1 if thisGoingUp else 0]


func isPassable(dir):
	return false


func mapImageMoveWithMap():
	return false


func isPassableOnThis(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
