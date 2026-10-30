class_name AirshipNode
extends Marker2D
## A node of an airship map: a "node" line of maps/Landscape/land<n>.map, a
## place the airship lands at. The position is the node's (x, y) in screen
## pixels; the airship's name plate shows the node's name within 20 px of it
## (AirLandscape.checkNode), and CROSS lands there. Nothing draws the node
## (the Marker2D's cross shows it in the editor only).
##
## Phase 4.1 (docs/ARCHITECTURE.md section 13): WorldMapScene.load_into
## builds an AirLandNode from it (step A).

## The node's type as the line names it ("village", "labyrinth"; a
## "crossroad" would never show a name).
@export var kind := "village"
## The node's name as AirLandscapeLoader reads it ("_" read as a space), with
## the "land" prefix of the world map node the airship lands at
## ("landAlares"; one name of land2.map has none).
@export var node_name := ""
## The world map the node is on (Landscape.WEST_CONTINENT 0, EAST_CONTINENT 1,
## NORTH_CONTINENT 2): the "start west|east|north" line before it. Landing
## sets the Database status "Landscape" to it.
@export var zone := 0
