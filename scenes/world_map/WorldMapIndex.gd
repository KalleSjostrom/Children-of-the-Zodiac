class_name WorldMapIndex
extends Resource
## Which world map each world map node is on: what
## LandscapeLoader.PlaceMapLoader reads from world0.map, world1.map and
## world2.map (in that order; a later file wins a name), for
## LandscapeLoader.checkPlace (the map a "land<node>" place loads, the zone of
## the visited nodes and roads). tools/import/world_to_scene.gd writes it
## (resources/world_map/place_index.tres) with the scenes; phase 4.1 step A,
## docs/ARCHITECTURE.md section 13.

const PATH := "res://resources/world_map/place_index.tres"

## The node's name as Organizer.convert makes it (lower case, "_" read as a
## space) -> its map file ("world0.map"), in PlaceMapLoader's order.
@export var maps: Dictionary[String, String] = {}
