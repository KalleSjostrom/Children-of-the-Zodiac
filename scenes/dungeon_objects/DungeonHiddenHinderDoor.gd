@tool
class_name DungeonHiddenHinderDoor
extends DungeonHinderDoor
## A hidden door ("hiddenHinderDoor", legacy HiddenHinderDoor): it opens after
## the third push (status 3).


func _new_door(node, status: int) -> HinderDoor:
	return HiddenHinderDoor.new(node, facing, frames, image, status, next_place, village_start)
