class_name WorldMapIndex
extends Resource
## Which world map each world map node is on: what the legacy
## LandscapeLoader.PlaceMapLoader read from world0.map, world1.map and
## world2.map (in that order; a later file wins a name), for
## LandscapeLoader.checkPlace (the map a "land<node>" place loads, the zone of
## the visited nodes and roads). The world map converter wrote it
## (resources/world_map/place_index.tres) with the scenes; phase 4.1 step A,
## docs/ARCHITECTURE.md section 13. The converter, PlaceMapLoader and the
## .map files are deleted (plan 9.1): a node added to a map scene goes in
## here by hand.

const PATH := "res://resources/world_map/place_index.tres"

## The node's name as Organizer.convert makes it (lower case, "_" read as a
## space) -> its map file ("world0.map"), in PlaceMapLoader's order.
@export var maps: Dictionary[String, String] = {}
