@tool
class_name DungeonSimpleRiddle
extends DungeonObject
## An inscription ("simpleRiddle", legacy SimpleRiddle): shows its dialogs.

## [speaker, line 1, line 2] of each dialog, as Parser.getText cut them.
@export var dialogs: Array[PackedStringArray] = []


func _new_inventory(node, map, status: int) -> Inventory:
	var inv := SimpleRiddle.new(node, facing, 1, image, status, StringTokenizer.new())
	if status != 1:
		inv.dialogs = DungeonObject.legacy_dialogs(dialogs)
	return inv
