@tool
class_name DungeonAddDoor
extends DungeonHinderDoor
## A door that opens when floor buttons have added its status up to
## open_status ("addDoor", legacy AdditiveHinderDoor).

@export var open_status := 0


func _new_door(node, status: int) -> HinderDoor:
	var d := AdditiveHinderDoor.new(node, facing, frames, image, status, next_place, village_start)
	d.setOpenStatus(open_status)
	return d
