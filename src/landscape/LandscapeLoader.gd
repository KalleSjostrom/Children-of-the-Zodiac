class_name LandscapeLoader
extends MenuStarter
## Port of landscape.LandscapeLoader: loads the landscape of a world*.map
## file.
##
## Bridge (phase 4.1, docs/ARCHITECTURE.md section 13): the map is built from
## its scene (scenes/world_map/<file>.tscn; WorldMapScene.load_into, step A),
## which stays the mode's scene_root and draws the map (step B,
## Landscape.draw_scene); the index of the node names (PlaceMapLoader's) is
## resources/world_map/place_index.tres. The .map files, their parse
## (LandscapeLoaderMapLoader, PlaceMapLoader) and --legacy=world_map are
## removed (closing phase 4.1, plan 9.1).

var roads = []
var nameBackGround = ""
var background = null
var player = null
var loadRoad = null
var nodes = []
## Java: private static final placeMap = createMap(); created lazily here,
## use _getPlaceMap().
static var placeMap = null


## Java: public void init(HashMap<String, String> info). The first argument
## is the info map.
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_ALL)
	var sn = info.get("startNode")
	var landscape = _getPlaceMap().get(sn)
	if landscape == null:
		push_error("LandscapeLoader: no landscape map for start node " + str(sn))
	else:
		var scene = world_scene_for(landscape)
		if scene != null:
			scene.load_into(self)
			scene_root = scene
		else:
			push_error("LandscapeLoader: no scene for the world map " + str(landscape))
	releaseAll()


## Port fix: the nodes and their roads refer to each other, and reference
## counting cannot free that graph after the mode is left; the nodes drop
## their roads when the mode is freed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for n in nodes:
			n.roads = J.array(4, null)


## Java: private void loadImages(String name). Loads all the images.
func loadImages(name = null, nightLayer = null, extra = null):
	player = LandPlayer.new()
	player.init()
	background = DoubleBackground.new(
			Values.ORIGINAL_RESOLUTION[Values.X],
			Values.ORIGINAL_RESOLUTION[Values.Y])
	var bg: Array = J.array(2, "")
	bg[0] = str(name) + "/" + str(name)
	bg[1] = name
	var night: bool = Landscape.isNight()
	background.setLandscapeImages(bg, night)
	nameBackGround = ImageHandler.addToCurrentLoadOnUse(
			Values.MenuImages + "Pieces/1.png")


## Gets the place (node) with the given name (case insensitive).
func getNode(name):
	name = String(name).strip_edges()
	for i in range(nodes.size()):
		if String(nodes[i].getName()).to_lower() == name.to_lower():
			return nodes[i]
	push_warning("Could not find the node: " + name)
	return null


## Gets the road with the given address.
func getRoad(address):
	for i in range(roads.size()):
		if roads[i].getAddress() == address:
			return roads[i]
	return null


## Opens (or closes) the roads in the given map address -> status.
func openClosedRoads(roads):
	for key in roads:
		var val: int = roads.get(key)
		var r = getRoad(key)
		if r != null:
			r.setClosed(val == 0)


static func _getPlaceMap():
	if placeMap == null:
		placeMap = createMap()
	return placeMap


static func createMap():
	var map := {}
	var index = place_index()
	if index != null:
		Parser.reset()
		map.merge(index.maps)
	else:
		push_error("LandscapeLoader: no place index " + WorldMapIndex.PATH)
	return map


## Bridge (phase 4.1 step A): a new instance of the scene of the world map
## file map_file (WorldMapScene), or null when it has none.
func world_scene_for(map_file):
	var path := WorldMapScene.path_for(str(map_file))
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()


## Bridge (phase 4.1 step A): PlaceMapLoader's index as the converter wrote
## it (WorldMapIndex), or null when it is missing.
static func place_index():
	if not ResourceLoader.exists(WorldMapIndex.PATH):
		return null
	return ResourceLoader.load(WorldMapIndex.PATH)


static func checkPlace(startNode):
	return _getPlaceMap().get(Organizer.convert(startNode))
