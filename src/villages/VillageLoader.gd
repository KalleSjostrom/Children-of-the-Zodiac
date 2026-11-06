class_name VillageLoader
extends MenuStarter
## Port of villages.VillageLoader: loads the village (images, villagers,
## doors, signs, loot, obstacles, ...) from a *.vil file.
##
## Java's HashMap<Integer, Sprite> sprites is keyed by hashCode(); this port
## uses get_instance_id() as the key.

static var staticStartPos: int = 0
var player = null
var dialog = Dialog.getDialog()
var sprites = {}
var buildingInfo = {}
var loots = []
var doors = []
var holeDoors = []
var signs = []
var background = null
var folderName = null
var storeName = null
var villageName = null
var startTime: int = 0
var backgroundWidth: int = 0
var backgroundHeight: int = 0
var actualHeight: int = 0
var actualWidth: int = 0
var obstacleHandler = null
var BACK_POS = null
var startPos: int = 0
var inside: bool = false

## Java: init(HashMap<String, String> info). Initializes the village loader
## and loads the village.
func init(name, lab = null, hinders = null):
	var info = name
	startPos = staticStartPos
	staticStartPos = 0

	var newInfo: Dictionary = {}
	newInfo.merge(info, true)
	newInfo["landname"] = "land" + str(newInfo.get("name"))
	self.load(newInfo)
	initGameMode(newInfo, Values.DETECT_ALL)


## Loads the information in the given map.
func load(info):
	var map: String = info.get("name")
	var folder: String = map + "/"
	var status: int = Database.getStatusFor(map)
	status = 0 if status < 0 else status
	var time = info.get("time")
	if time != null and time == "night":
		map += " at Night - " + str(status) + ".vil"
	else:
		map += " - " + str(status) + ".vil"
	infoMap = info
	var scene = village_scene_for(folder + map)
	assert(scene != null, "VillageLoader: no scene for the village " + folder + map)
	if scene == null:
		return
	# The scene the village is built from also draws it (Village.create_scene).
	scene.load_into(self)
	scene_root = scene
	startTime = J.currentTimeMillis()


## A new instance of the scene of the variant maps/Village/<vil>
## (VillageScene; the .vil file name names the variant), or null when there
## is none.
static func village_scene_for(vil: String) -> VillageScene:
	var path := VillageScene.path_for(Values.VillageMaps + vil)
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()


## Gets the villager with the given name (case insensitive).
func getVillager(name):
	for k in sprites:
		var s = sprites[k]
		if s is Villager:
			var v: Villager = s
			if String(v.getName()).to_lower() == String(name).to_lower():
				return v
	return null
