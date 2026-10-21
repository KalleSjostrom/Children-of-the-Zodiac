@tool
class_name DungeonTriggerDoor
extends DungeonDoor
## A door with a trigger file ("triggerDoor", legacy TriggerDoor): arriving
## at it the first time shows the dialogs of maps/Labyrinth/Triggers/
## <trigger>.trig, sets its triggers and can offer a tutorial.

## The trigger file's name (without .trig, "_" for spaces).
@export var trigger := ""


func _new_inventory(node, map, status: int) -> Inventory:
	var d := TriggerDoor.new(node, facing, open_roads, trigger, status, DungeonObject.tokens(next_places))
	_set_going(d)
	return d
