class_name LandscapeLoader
extends MenuStarter
## Port of landscape.LandscapeLoader: loads the landscape from a world*.map
## file.

var roads = []
var nameBackGround = ""
var background = null
var player = null
var mapLoader = null
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
	mapLoader = LandscapeLoaderMapLoader.new(self)
	var sn = info.get("startNode")
	var landscape = _getPlaceMap().get(sn)
	if landscape == null:
		push_error("LandscapeLoader: no landscape map for start node " + str(sn))
	else:
		mapLoader.parseFile(landscape)
	releaseAll()


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
	PlaceMapLoader.new(map)
	return map


static func checkPlace(startNode):
	return _getPlaceMap().get(Organizer.convert(startNode))


## Loads the information about the landscape from a *.map file in
## Values.LandscapeMaps. Holds a reference to the outer loader.
class LandscapeLoaderMapLoader extends AbstractMapLoader:
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
			var node = LandscapeNode.new(X, Y, type, name.replace("_", " "))
			outer.nodes.append(node)
		elif command == "road":
			var address: int = getInt(tok)
			var source = outer.getNode(tok.nextToken().replace("_", " "))
			var dirToDest: int = getInt(tok)
			var dest = outer.getNode(tok.nextToken().replace("_", " "))
			var dirToSource: int = getInt(tok)
			var closed: bool = Database.getStatusFor("road" + str(address)) == 0
			outer.loadRoad = Road.new(address, source, dest, closed)
			source.setRoad(dirToDest, outer.loadRoad, true)
			dest.setRoad(dirToSource, outer.loadRoad, false)
			outer.roads.append(outer.loadRoad)
		elif command == "co":
			var a: int = getInt(tok)
			var b: int = getInt(tok)
			outer.loadRoad.addCoordinates(a, b)
		elif command == "oc":
			outer.loadRoad.done()
		elif command == "background":
			outer.loadImages(tok.nextToken())

	## Gets the integer that the given tokenizer parses.
	func getInt(t):
		return J.parseInt(t.nextToken())


## Maps every node name (Organizer.convert) to its world*.map file.
class PlaceMapLoader extends AbstractMapLoader:
	var map = null
	var current = ""

	func _init(map = null) -> void:
		self.map = map
		parseFile("")

	## Java: protected void parseFile(String filename) (the name is ignored).
	func parseFile(path: String, filename: String = ""):
		if filename != "":
			super.parseFile(path, filename)
			return
		current = "world0.map"
		super.parseFile(Values.LandscapeMaps, current)
		current = "world1.map"
		super.parseFile(Values.LandscapeMaps, current)
		current = "world2.map"
		super.parseFile(Values.LandscapeMaps, current)

	func executeCommand(command: String, tokenizer: StringTokenizer):
		var t: StringTokenizer = tokenizer
		if command == "node":
			while t.hasMoreTokens():
				command = t.nextToken()
			var s: String = Organizer.convert(command)
			map[s] = current
