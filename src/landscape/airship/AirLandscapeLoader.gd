class_name AirLandscapeLoader
extends MenuStarter
## Port of landscape.airship.AirLandscapeLoader: loads the airship world map
## (land<airship status>.map).
##
## Bridge (phase 4.1, docs/ARCHITECTURE.md section 13): the map is built from
## its scene (scenes/world_map/land<n>.tscn; WorldMapScene.load_into: the
## background, then the nodes; step A), which stays the mode's scene_root and
## draws the map (step B, AirLandscape.draw). The .map files, their parse
## (AirLandscapeLoaderMapLoader) and --legacy=airship are removed (closing
## phase 4.1, plan 9.1).

var nodes = []
var nameBackGround = ""
var airShip = null
var background = null


## Java: public void init(HashMap<String, String> info). The first argument
## is the info map.
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_ALL)
	var map: String = "land" + str(Database.getStatusFor("airship")) + ".map"
	var scene = airship_scene_for(map)
	if scene != null:
		scene.load_into(self)
		scene_root = scene
	else:
		# The images, and no nodes, as a missing map file left it.
		loadImages()
		push_error("AirLandscapeLoader: no scene for the airship map " + map)
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
## file map_file (WorldMapScene), or null when it has none.
func airship_scene_for(map_file):
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
