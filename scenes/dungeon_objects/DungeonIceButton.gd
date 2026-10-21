@tool
class_name DungeonIceButton
extends DungeonButton
## A note of an ice riddle ("iceButton", legacy IceButton): a lever with its
## own sound.

## The sound it plays ("_" for spaces).
@export var sound := ""


func _new_inventory(node, map, status: int) -> Inventory:
	return IceButton.new(node, facing, frames, image, status, DungeonObject.hinders_for(map, hinders),
			sound.replace("_", " "))
