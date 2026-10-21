@tool
class_name DungeonLadderDoor
extends DungeonDoor
## A ladder ("ladderDoor", legacy LadderDoor): a door drawn as a ladder image
## in front of the wall, up or down.

## Up (true) or down the ladder (its map image).
@export var going_up := false


func _new_inventory(node, map, status: int) -> Inventory:
	LadderDoor.goingUp = going_up
	return LadderDoor.new(node, facing, open_roads, image, status,
			DungeonObject.tokens(next_places.slice(1)), next_places[0])
