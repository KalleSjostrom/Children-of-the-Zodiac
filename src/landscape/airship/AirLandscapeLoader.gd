class_name AirLandscapeLoader
extends MenuStarter
## Port of landscape.airship.AirLandscapeLoader: loads the airship world map
## (land<airship status>.map).
##
## Bridge (phase 4.1, docs/ARCHITECTURE.md section 13): a map with a scene
## (scenes/world_map/land<n>.tscn) is built from it (WorldMapScene.load_into:
## the background, then the nodes; step A) instead of parsing the file, and
## the scene stays the mode's scene_root and draws the map (step B,
## AirLandscape.draw). --legacy=airship keeps the .map files and the legacy
## drawing.

var nodes = []
var nameBackGround = ""
var airShip = null
var background = null
var mapLoader = null


## Java: public void init(HashMap<String, String> info). The first argument
## is the info map.
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_ALL)
	var scene = airship_scene_for("land" + str(Database.getStatusFor("airship")) + ".map")
	if scene != null:
		scene.load_into(self)
		scene_root = scene
		releaseAll()
		return
	loadImages()
	var map: String = "land" + str(Database.getStatusFor("airship")) + ".map"
	mapLoader = AirLandscapeLoaderMapLoader.new(self)
	mapLoader.parseFile(map)
	# Port fix (phase 4.1): the map loader refers back to this loader (Java's
	# inner class reference), and the RefCounted cycle kept every airship mode
	# alive after it was left (LandscapeLoader had the same cycle). It is not
	# used after parsing.
	mapLoader = null
	releaseAll()


## Java: private void loadImages().
func loadImages(name = null, nightLayer = null, extra = null):
	airShip = AirShip.new()
	airShip.init()
	background = DoubleBackground.new(
			Values.ORIGINAL_RESOLUTION[Values.X],
			Values.ORIGINAL_RESOLUTION[Values.Y])
	var bg: Array = J.array(2, "")
	# Bridge (phase 4.1 step A): the scene names the image (WorldMapScene's
	# background_name, the airship status's).
	if name != null:
		bg[0] = "World/" + str(name)
	else:
		bg[0] = "World/World" + str(Database.getStatusFor("airship"))
	bg[1] = "World"
	background.setLandscapeImages(bg, false)
	nameBackGround = ImageHandler.addToCurrentLoadOnUse(
			Values.MenuImages + "Pieces/1.png")


## Bridge (phase 4.1 step A): a new instance of the scene of the airship map
## file map_file (WorldMapScene), or null when it has none or with
## --legacy=airship (the file is parsed).
func airship_scene_for(map_file):
	if Main.is_legacy("airship"):
		return null
	var path := WorldMapScene.path_for(str(map_file))
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()


func getNode(name):
	name = String(name).strip_edges()
	for i in range(nodes.size()):
		var s: String = nodes[i].getName()
		if s.begins_with("land"):
			s = s.replace("land", "")
		if s.to_lower() == name.to_lower():
			return nodes[i]
	return null


## Loads the nodes of the airship landscape from a *.map file in
## Values.LandscapeMaps. Holds a reference to the outer loader.
class AirLandscapeLoaderMapLoader extends AbstractMapLoader:
	var currentZone: int = 0
	var outer = null

	func _init(p_outer = null) -> void:
		outer = p_outer

	## Java: protected void parseFile(String filename).
	func parseFile(path: String, filename: String = ""):
		if filename == "":
			super.parseFile(Values.LandscapeMaps, path)
		else:
			super.parseFile(path, filename)

	func executeCommand(command: String, tokenizer: StringTokenizer):
		var tok: StringTokenizer = tokenizer
		if command == "node":
			var X: int = J.parseInt(tok.nextToken())
			var Y: int = J.parseInt(tok.nextToken())
			var type: String = tok.nextToken()
			var name: String = tok.nextToken()
			var node = AirLandNode.new(X, Y, type, name.replace("_", " "))
			node.setZone(currentZone)
			outer.nodes.append(node)
		elif command == "start":
			var zone: String = tok.nextToken()
			if zone == "west":
				currentZone = Landscape.WEST_CONTINENT
			elif zone == "east":
				currentZone = Landscape.EAST_CONTINENT
			elif zone == "north":
				currentZone = Landscape.NORTH_CONTINENT
