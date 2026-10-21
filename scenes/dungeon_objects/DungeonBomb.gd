@tool
class_name DungeonBomb
extends DungeonObject
## A rock to blow up for a floor's mission ("bomb", legacy MissionBomb): it
## blocks the way until its dialogs are done (status 1). A speaker
## "<n>-<name>" only talks at mission status n.

## [speaker, line 1, line 2] of each dialog, as Parser.getText cut them.
@export var dialogs: Array[PackedStringArray] = []


func _new_inventory(node, map, status: int) -> Inventory:
	var inv := MissionBomb.new(node, facing, 1, image, status, StringTokenizer.new())
	if status != 1:
		inv.dialogs = DungeonObject.legacy_dialogs(dialogs)
		if inv.dialogs.size() > 0:
			inv.currentSpeaker = inv.dialogs[0][0]
	return inv
