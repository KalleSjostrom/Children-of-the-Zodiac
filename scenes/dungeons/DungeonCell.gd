@tool
class_name DungeonCell
extends Resource
## One cell of a dungeon floor (a legacy LabyrinthNode): a 4 x 4 x 4 cube of
## the floor grid, with its neighbours and the texture slots of its walls,
## floor and roof (DungeonStyle.textures). Part of a DungeonLayout, which
## tools/import/map_to_scene.gd writes from the "dir", "wall", "floor",
## "roof", "normal" and texture lines of a .map file.
##
## The address numbers the 16-wide grid row by row: world x = (address / 16)
## * 4 + 2, world z = (address % 16 - 15) * 4 - 2 at the cell's centre
## (LabyrinthNode, LabyrinthPosition). Directions are Values.UP (0, address
## + 1, world +z), RIGHT (1, address - 16, world -x), DOWN (2, address - 1,
## world -z) and LEFT (3, address + 16, world +x).

## The cell's address in the 16-wide grid.
@export var address := 0
## The neighbour's address in each direction (UP, RIGHT, DOWN, LEFT), -1 for
## none. A side without a neighbour has a wall (unless a "wall" line put one
## on a connected side too).
@export var neighbours := PackedInt32Array([-1, -1, -1, -1])
## The texture slot of the wall on each side, -1 for no wall
## (LabyrinthNode.walls, after the .map file's "wall" lines).
@export var walls := PackedInt32Array([-1, -1, -1, -1])
## The texture slot of the floor (LabyrinthNode.floor; unused when the cell
## has a carpet).
@export var floor := 0
## The texture slot of the roof (LabyrinthNode.roof; floors with a sky draw
## no roof).
@export var roof := 0
## A carpet floor (DungeonStyle.carpet_floors): the floor is the texture slot
## carpet_slot, turned by carpet_rotation (Values.UP .. LEFT), which
## LabyrinthNode.addCarpetFloor chose from the neighbours (Horizontal).
@export var has_carpet := false
@export var carpet_slot := 0
@export var carpet_rotation := 0
## "dir" lines that repeat a link of this cell. The legacy loader counts
## every line in the neighbour count (LabyrinthNode.nrOfNeighbors), which
## chooses the carpet and pillar shapes; a content quirk of a few floors
## (Frozen Forest--Forest Passage), kept.
@export var extra_links := 0


## The number of neighbours as the legacy loader counts them.
func neighbour_count() -> int:
	var n := extra_links
	for a in neighbours:
		if a != -1:
			n += 1
	return n


## The centre of the cell in dungeon units (LabyrinthPosition of the node;
## y is the middle of the cube).
func center() -> Vector3:
	@warning_ignore("integer_division")
	return Vector3((address / 16) * 4 + 2, 0, (address % 16 - 15) * 4 - 2)
