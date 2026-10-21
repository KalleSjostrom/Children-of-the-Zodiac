@tool
class_name DungeonChest
extends DungeonObject
## A chest ("chest" line, legacy Chest): opened with the action button from
## the cell before it; its status is 1 once opened. A series of frames
## (closed, open) or one image (a stub, a sandstone).

## The number of images of the series (the line's frame count).
@export var frames := 1
## What it holds: Chest.GOLD (0, content_name is the amount), EQUIPMENT (1),
## CARD (2) or ITEM (3).
@export var content_type := 0
@export var content_name := ""
## The rest of the line: a card's level and whether all characters get it.
@export var content_info: PackedStringArray = []


func _new_inventory(node, map, status: int) -> Inventory:
	return Chest.new(node, facing, frames, image, content_type, content_name, Array(content_info), status)
