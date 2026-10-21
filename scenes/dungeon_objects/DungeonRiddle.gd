@tool
class_name DungeonRiddle
extends DungeonObject
## A riddle ("riddle", legacy Riddle): the action button starts the mini game
## riddle_class (src/miniGames), which opens the doors in hinders when solved.

## The riddle's data name (maps/MiniGames).
@export var riddle_name := ""
## The mini game class without "miniGames." ("SlidePuzzle", ...).
@export var riddle_class := ""
## The database names of the doors it opens.
@export var hinders: PackedStringArray = []


func _new_inventory(node, map, status: int) -> Inventory:
	return Riddle.new(node, facing, riddle_name, image, status, riddle_class, DungeonObject.hinders_for(map, hinders))
