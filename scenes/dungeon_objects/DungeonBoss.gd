@tool
class_name DungeonBoss
extends DungeonObject
## A boss ("boss", legacy Boss): stepping into its cell starts the boss battle
## while it lives (Database status 1 under the boss's name). image is the
## boss's name; nothing is drawn.


func _new_inventory(node, map, status: int) -> Inventory:
	return InventoryBoss.new(node, image)


func _database_name_for(db_name: String) -> String:
	return Organizer.convert(image)
