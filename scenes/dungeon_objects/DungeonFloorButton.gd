@tool
class_name DungeonFloorButton
extends DungeonButton
## A plate on the floor ("floorButton", legacy FloorButton): stepping on it
## adds 1 to the status of the doors in hinders (addDoor). Drawn as the
## cell's floor tile.


func _new_inventory(node, map, status: int) -> Inventory:
	return FloorButton.new(node, facing, frames, image, status, DungeonObject.hinders_for(map, hinders))
