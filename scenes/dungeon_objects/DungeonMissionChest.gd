@tool
class_name DungeonMissionChest
extends DungeonObject
## A chest of a floor's mission ("missionChest", legacy MissionChest): it
## talks, a "gift" line opens it, then the mission counts on.

## [speaker, line 1, line 2] of each dialog, as Parser.getText cut them.
@export var dialogs: Array[PackedStringArray] = []


func _new_inventory(node, map, status: int) -> Inventory:
	var inv := MissionChest.new(node, facing, 2, image, status, StringTokenizer.new())
	# MissionChest reads its dialogs from the line unless it is done (status 1).
	if status != 1:
		inv.dialogs = DungeonObject.legacy_dialogs(dialogs)
		if inv.dialogs.size() > 0:
			inv.currentSpeaker = inv.dialogs[0][0]
	return inv
