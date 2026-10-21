@tool
class_name DungeonVillager
extends DungeonObject
## A person to rescue for a floor's mission ("villager", legacy Villager): it
## talks, then counts the mission on and is gone (status 1).

## [speaker, line 1, line 2] of each dialog, as Parser.getText cut them.
@export var dialogs: Array[PackedStringArray] = []


func _new_inventory(node, map, status: int) -> Inventory:
	var inv := InventoryVillager.new(node, facing, 1, image, status, StringTokenizer.new())
	# The villager reads its dialogs from the line unless rescued (status 1).
	if status != 1:
		inv.dialogs = DungeonObject.legacy_dialogs(dialogs)
		if inv.dialogs.size() > 0:
			inv.currentSpeaker = inv.dialogs[0][0]
	return inv
