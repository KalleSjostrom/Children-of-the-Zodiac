@tool
class_name DungeonSavePoint
extends DungeonObject
## A save point ("save", legacy Save): arriving cures the party and shuffles
## the decks, and the menu can save; its particles (SaveSystem, 2000 of them)
## stand around the cell. A "-save" place starts here.


func _new_inventory(node, map, status: int) -> Inventory:
	return InventorySave.new(node, facing)


func _marker_text() -> String:
	return "save %d" % cell
