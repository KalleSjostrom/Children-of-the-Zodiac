@tool
class_name DungeonButton
extends DungeonObject
## A lever ("button", legacy Button): the action button pulls it (its frames
## play, 250 ms each) and sets the status of the doors in hinders to its own
## (1 on).

## The number of images of the series.
@export var frames := 1
## The database names of the doors it opens, as the .map file writes them;
## also doors on other floors (a DummyDoor stands for those).
@export var hinders: PackedStringArray = []


func _new_inventory(node, map, status: int) -> Inventory:
	return InventoryButton.new(node, facing, frames, image, status, DungeonObject.hinders_for(map, hinders))
