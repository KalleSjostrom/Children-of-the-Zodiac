@tool
class_name DungeonAegisComboButton
extends DungeonObject
## A symbol of the Temple of Aegis riddle ("aegisComboButton", legacy
## AegisComboButton): once all buttons of its group are on, open_door opens;
## a wrong one resets them.

@export var frames := 1
## Its symbol (the map image's number).
@export var image_nr := 0
## The other buttons of the group (database names; one that comes later in
## the file is missing, as in the legacy loader).
@export var buttons: PackedStringArray = []
## The door it opens (a database name), "" for none.
@export var open_door := ""


func _new_inventory(node, map, status: int) -> Inventory:
	return AegisComboButton.new(node, facing, frames, image, status, _buttons(map), _open_door(map), image_nr)


func _buttons(map) -> Array:
	var out: Array = []
	for b in buttons:
		out.append(map.getInventory(Organizer.convert(b)))
	return out


func _open_door(map):
	return map.getInventory(Organizer.convert(open_door)) if open_door != "" else null
