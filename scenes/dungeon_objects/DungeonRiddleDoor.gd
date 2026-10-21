@tool
class_name DungeonRiddleDoor
extends DungeonHinderDoor
## A door a riddle opens ("riddleDoor", legacy RiddleDoor).


func _new_door(node, status: int) -> HinderDoor:
	return RiddleDoor.new(node, facing, frames, image, status, next_place, village_start)
