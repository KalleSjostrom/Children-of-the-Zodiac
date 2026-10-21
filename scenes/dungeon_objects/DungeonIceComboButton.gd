@tool
class_name DungeonIceComboButton
extends DungeonAegisComboButton
## A note of the Ice Cavern riddle ("iceComboButton", legacy IceComboButton):
## a combo button with its own sound.

## The sound it plays ("_" for spaces).
@export var sound := ""


func _new_inventory(node, map, status: int) -> Inventory:
	return IceComboButton.new(node, facing, frames, image, status, _buttons(map), _open_door(map), image_nr,
			sound.replace("_", " "))
