class_name AirLandscapeLoader
extends MenuStarter
## Port of landscape.airship.AirLandscapeLoader: loads the airship world map
## (land<airship status>.map).

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
	loadImages()
	var map: String = "land" + str(Database.getStatusFor("airship")) + ".map"
	mapLoader = AirLandscapeLoaderMapLoader.new(self)
	mapLoader.parseFile(map)
	releaseAll()


## Java: private void loadImages().
func loadImages(name = null, nightLayer = null, extra = null):
	airShip = AirShip.new()
	airShip.init()
	background = DoubleBackground.new(
			Values.ORIGINAL_RESOLUTION[Values.X],
			Values.ORIGINAL_RESOLUTION[Values.Y])
	var bg: Array = J.array(2, "")
	bg[0] = "World/World" + str(Database.getStatusFor("airship"))
	bg[1] = "World"
	background.setLandscapeImages(bg, false)
	nameBackGround = ImageHandler.addToCurrentLoadOnUse(
			Values.MenuImages + "Pieces/1.png")


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
