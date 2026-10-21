@tool
class_name DungeonDoor
extends DungeonObject
## A door ("door", "door--up", "door--down"; legacy Door): the wall it is on
## shows the door texture (a "wall" line), and the action button facing it
## leaves the floor for the next place. Its door index (mark) is the n of
## "<Area>--<Floor>-mark<n>" in main.bank.

## The roads it opens on the world map when first used, ";"-separated, or
## "dontopen".
@export var open_roads := ""
## Where it leads (main.bank places, "_" for spaces): the door's status picks
## one, the first time the first.
@export var next_places: PackedStringArray = []
## The door index: the place of this door among the floor's doors and hinder
## doors, in file order (InventoryDoor.doorCount).
@export var mark := 0


func _new_inventory(node, map, status: int) -> Inventory:
	var d := InventoryDoor.new(node, facing, open_roads, next_places[0], status,
			DungeonObject.tokens(next_places.slice(1)))
	_set_going(d)
	return d


func _marker_text() -> String:
	return "%s %d  mark%d" % [kind, cell, mark]
