class_name WorldMapNode
extends Marker2D
## A node of the world map: a "node" line of maps/Landscape/world<n>.map, a
## village, labyrinth or crossroad the player walks to along the roads. The
## position is the node's (x, y) in screen pixels (the legacy
## LandscapeNode.getXpos/getYpos), where the player stands; the Marker child
## is crossroad.png where LandscapeNode.draw puts it (x - 2, y - 4), drawn for
## every kind of node once it is visited.
##
## Phase 4.1 (docs/ARCHITECTURE.md section 13): WorldMapScene.load_into
## builds a LandscapeNode from it (step A); the node shows while its legacy
## node is visited (step B).

## The node's type as the line names it: "village", "labyrinth" or
## "crossroad" (Landscape enters a village or a labyrinth with CROSS; a
## crossroad shows no name).
@export var kind := "village"
## The node's name as LandscapeLoader reads it ("_" read as a space): the
## place it leads to ("Forest of Reil--Deep Forest-mark0", "Alares"). Roads
## name their ends by it, and the first node of a name wins.
@export var node_name := ""
