@tool
class_name DungeonHinderDoor
extends DungeonObject
## A door that can be locked ("hinderDoor", "--up", "--down"; legacy
## HinderDoor): the wall it is on shows image0 while open and image1 while
## locked (Database status 0); a lever or a riddle opens it. Its door index
## (mark) counts with the doors.

## The number of images (2: open, locked).
@export var frames := 2
## Where it leads (a main.bank place, "_" for spaces).
@export var next_place := ""
## The start position in a village it leads to (VillageLoader.staticStartPos),
## -1 for none.
@export var village_start := -1
## The door index (see DungeonDoor.mark).
@export var mark := 0


func _new_inventory(node, map, status: int) -> Inventory:
	var d := _new_door(node, status)
	_set_going(d)
	return d


func _new_door(node, status: int) -> HinderDoor:
	return HinderDoor.new(node, facing, frames, image, status, next_place, village_start)


func _marker_text() -> String:
	return "%s %d  mark%d" % [kind, cell, mark]
