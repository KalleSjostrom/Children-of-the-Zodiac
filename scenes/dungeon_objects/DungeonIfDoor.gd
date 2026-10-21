@tool
class_name DungeonIfDoor
extends DungeonDoor
## A door whose destination depends on a status ("ifDoor", legacy IfDoor):
## next_places are "<status>==<value>", the place while it holds (once), and
## the place otherwise.


func _new_inventory(node, map, status: int) -> Inventory:
	return IfDoor.new(node, facing, open_roads, next_places[0], status,
			DungeonObject.tokens(next_places.slice(1)))
