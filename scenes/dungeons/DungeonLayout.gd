@tool
class_name DungeonLayout
extends Resource
## The layout of a dungeon floor: its cells with their neighbours and texture
## slots (DungeonCell), and the floor's place in the menu's map page. Written
## by tools/import/map_to_scene.gd from a .map file; DungeonFloor builds the
## walls, floors and roofs from it (with the DungeonStyle's textures), and
## DungeonScene.load_into builds the legacy LabyrinthMap and its nodes from
## it (step A).

## The size line of the .map file (LabyrinthMap.size).
@export var size := 0
## The mapPos line: the floor's place on the menu's map page
## (LabyrinthMap.mapPos [column, row]; LabyrinthInfo orders the floors by it).
@export var map_pos := Vector2i.ZERO
## The cells in the order of the legacy node map: the order in which the
## "dir" lines first name them. The walls are drawn in this order and the
## menu map and the minimap walk it, so it is kept.
@export var cells: Array[DungeonCell] = []


## The cell with the given address, or null.
func cell_at(address: int) -> DungeonCell:
	for c in cells:
		if c.address == address:
			return c
	return null
