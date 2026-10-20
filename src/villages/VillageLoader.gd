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
	if scene != null:
		# The scene the village is built from also draws it (Village.create_scene).
		scene.load_into(self)
		scene_root = scene
	else:
		VillageLoaderMapLoader.new(self).parseFile(folder + map)
	startTime = J.currentTimeMillis()


## Bridge (phase 1, docs/ARCHITECTURE.md): a new instance of the scene made
## from the .vil file maps/Village/<vil> (VillageScene, built by
## tools/import/vil_to_scene.gd), or null when the place is not converted
## or with --legacy=villages; the village is then read from the .vil file
## and drawn by the legacy code.
static func village_scene_for(vil: String) -> VillageScene:
	if Main.is_legacy("villages"):
		return null
	var path := VillageScene.path_for(GameResourceLoader.resolve(Values.VillageMaps + vil))
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()


## Java: private loadImages(String name, boolean nightLayer, int extra).
func loadImages(name = null, nightLayer = null, extra = null):
	background = DoubleBackground.new(backgroundWidth, backgroundHeight, actualWidth, actualHeight)
	if DoubleBackground.USE_CUT:
		background.init(name, nightLayer)
	else:
		background.init(name, nightLayer, extra)


## Gets the villager with the given name (case insensitive).
func getVillager(name):
	for k in sprites:
		var s = sprites[k]
		if s is Villager:
			var v: Villager = s
			if String(v.getName()).to_lower() == String(name).to_lower():
				return v
	return null


## Loads the information about the village from a *.vil file. Java inner
## class: the outer village loader is passed as vl.
class VillageLoaderMapLoader extends AbstractMapLoader:
	var vl = null
	var sign = null
	var nightLayer: bool = false
	var extraName = null
	var backgroundFolder = null
	var villagerFolder = null

	func _init(villageLoader = null) -> void:
		vl = villageLoader

	## Java overloads: parseFile(String filename) (in Values.VillageMaps)
	## and the inherited parseFile(path, filename).
	func parseFile(path: String, filename: String = ""):
		if filename == "":
			super.parseFile(Values.VillageMaps, path)
		else:
			super.parseFile(path, filename)

	func executeCommand(command: String, tokenizer: StringTokenizer):
		var tok := tokenizer
		if command == "o":
			var x: int = J.parseInt(tok.nextToken())
			var y: int = J.parseInt(tok.nextToken())
			var x2: int = J.parseInt(tok.nextToken())
			var y2: int = J.parseInt(tok.nextToken())
			vl.obstacleHandler.addObstacle(Values.createNormalPoint(x, y),
					Values.createNormalPoint(x2, y2), vl.player.getHeight(), vl.player.getWidth())
		elif command == "inside":
			vl.inside = true
		elif command.begins_with("start"):
			var s: String = command.replace("start", "")
			if s != "":
				var sp: int = J.parseInt(s)
				if sp == vl.startPos:
					initPlayerPos(tok)
			elif vl.player == null:
				initPlayerPos(tok)
		elif command.contains("landname"):
			vl.infoMap["landname"] = "land" + tok.nextToken()
		elif command.begins_with("lootL"):
			if vl.loots.size() > 0:
				var l = vl.loots[vl.loots.size() - 1]
				l.addString(lastLine.replace("lootLine ", ""))
		elif command == "loot":
			var l = Loot.getLoot(tok, vl.villageName)
			if l != null:
				vl.loots.append(l)
		elif command == "door":
			vl.doors.append(StoreDoor.getDoor(tok, vl.villageName))
		elif command == "wind":
			var wind: String = tok.nextToken()
			var array: Array = J.split(wind, ";")
			var windForce := Vector3f.new()
			for i in range(3):
				windForce.set_(i, J.parseFloat(array[i]))
			var turbulence: float = J.parseFloat(tok.nextToken())
			BodiesParticleSystem.setWind(windForce, turbulence)
		elif command == "holeDoor":
			vl.holeDoors.append(StoreDoor.getDoor(tok, vl.villageName))
		elif command == "doorSignFl":
			var s := Sign.new()
			s.addText(lastLine.replace("doorSignFl", ""))
			vl.doors[vl.doors.size() - 1].setSign(s)
		elif command == "doorSignSl":
			var s = vl.doors[vl.doors.size() - 1].getSign()
			s.addText(lastLine.replace("doorSignSl", ""))
		elif command == "holeDoorSignFl":
			var s := Sign.new()
			s.addText(lastLine.replace("holeDoorSignFl", ""))
			vl.holeDoors[vl.holeDoors.size() - 1].setSign(s)
		elif command == "holeDoorSignSl":
			var s = vl.holeDoors[vl.holeDoors.size() - 1].getSign()
			s.addText(lastLine.replace("holeDoorSignSl", ""))
		elif command == "sign":
			var x: int = J.parseInt(tok.nextToken())
			var y: int = J.parseInt(tok.nextToken())
			var w: int = -1
			if tok.hasMoreTokens():
				w = J.parseInt(tok.nextToken())
			var dirs := []
			if tok.hasMoreTokens():
				var ds: Array = J.split(tok.nextToken(), ";")
				for s in ds:
					dirs.append(J.parseInt(s))
			else:
				dirs.append(0)
			sign = Sign.new(x, y, w, dirs)
		elif command == "signL":
			sign.addText(lastLine.replace("signL ", ""))
			vl.signs.append(sign)
		elif command == "signL2":
			sign.addText(lastLine.replace("signL2 ", ""))
		elif command == "villager":
			var name: String = tok.nextToken().replace("_", " ")
			var status: int = Database.getStatusFor(name)
			if status == -1:
				print("VillageLoader: could not find: " + name
						+ " in the database. Using default value!")
				status = 1
				Database.addStatus(name, status)
			var found: bool = false
			var hadTokens: bool = tok.hasMoreTokens()
			while tok.hasMoreTokens() and not found:
				found = J.parseInt(tok.nextToken()) == status
			if not hadTokens or found:
				var v := Villager.new(name, villagerFolder, status)
				vl.sprites[v.get_instance_id()] = v
		elif command == "particlesystem":
			var loader = SystemLoader.getLoader()
			while tok.hasMoreTokens():
				var name: String = tok.nextToken()

				var villagerLayer: bool = false
				var activate: bool = true
				var layer: int = DoubleBackground.UPPER_LAYER
				var activationStatus: int = -1
				if name.contains(":"):
					var temp: Array = J.split(name, ":")
					name = temp[0]
					layer = J.parseInt(temp[1])
					if temp.size() > 2:
						activate = J.parseBoolean(temp[2])
					if temp.size() > 3:
						activationStatus = J.parseInt(temp[3])
					villagerLayer = layer == DoubleBackground.VILLAGER_LAYER

				var system = loader.buildSystem(name)
				for p in system:
					p.setName(name)
					p.setActive(activate)
					p.setActivateStatus(activationStatus)
				if villagerLayer:
					for p in system:
						vl.sprites[p.get_instance_id()] = p
				else:
					for p in system:
						vl.background.addSystem(p, layer)
				for p in system:
					p.warmUp()
		elif command == "background":
			vl.folderName = tok.nextToken().replace("_", " ")
			if vl.folderName.contains("--"):
				var parts: Array = J.split(vl.folderName, "--")
				vl.villageName = parts[0]
				backgroundFolder = vl.villageName + parts[1]
			else:
				vl.villageName = vl.folderName
				backgroundFolder = vl.folderName
			nightLayer = not J.parseBoolean(tok.nextToken()) # stands for day
			if tok.hasMoreTokens():
				extraName = tok.nextToken().replace("_", " ")
			villagerFolder = vl.villageName
		elif command == "villagerFolder":
			villagerFolder = Organizer.convertKeepCase(tok.nextToken())
		elif command == "back":
			vl.backgroundWidth = J.parseInt(tok.nextToken())
			vl.backgroundHeight = J.parseInt(tok.nextToken())
			var extra: int = 0
			vl.actualWidth = vl.backgroundWidth
			vl.actualHeight = vl.backgroundHeight
			if tok.hasMoreTokens():
				var s: String = tok.nextToken()
				if s.contains("as="):
					s = s.replace("as=", "")
					var sa: Array = J.split(s, ":")
					vl.actualWidth = J.parseInt(sa[0])
					vl.actualHeight = J.parseInt(sa[1])
				else:
					extra = J.parseInt(s)
			if extraName != null:
				vl.background = DoubleBackground.new(vl.backgroundWidth, vl.backgroundHeight,
						vl.actualWidth, vl.actualHeight)
				if DoubleBackground.USE_CUT:
					vl.background.init(backgroundFolder, extraName, nightLayer)
				else:
					vl.background.init(backgroundFolder, extraName, nightLayer, extra)
			else:
				vl.loadImages(backgroundFolder, nightLayer, extra)
		elif command == "offset":
			var width: int = J.parseInt(tok.nextToken())
			var height: int = J.parseInt(tok.nextToken())
			vl.background.setOffset(width, height)
		elif command == "music":
			vl.infoMap["music"] = tok.nextToken()
		elif command == "building":
			var info: Dictionary = {}
			var buildingName: String = tok.nextToken()
			info["storeName"] = buildingName
			info["background"] = tok.nextToken()
			info["keeper"] = tok.nextToken()
			info["name"] = tok.nextToken().replace("_", " ")
			info["firstLine"] = tok.nextToken().replace("_", " ")
			var secondLine: String = Organizer.convertKeepCase(tok.nextToken())
			info["secondLine"] = secondLine
			info["music"] = tok.nextToken().replace("_", " ")
			info["villageName"] = vl.villageName
			info["folderName"] = vl.folderName
			vl.buildingInfo[buildingName] = info
		elif command == "animObj":
			var name: String = tok.nextToken()
			var x: int = J.parseInt(tok.nextToken())
			var y: int = J.parseInt(tok.nextToken())
			var pos: Array = Values.createNormalPoint(x, y)
			var size: int = 4
			if tok.hasMoreTokens():
				size = J.parseInt(tok.nextToken())
			var ao := AnimatedObjects.new(vl.folderName, name, pos, size)
			vl.sprites[ao.get_instance_id()] = ao

	## Initiates the player and its positions. It also sets the position of
	## the background.
	func initPlayerPos(tok):
		var x: int = J.parseInt(tok.nextToken())
		var y: int = J.parseInt(tok.nextToken())
		var a: int = J.parseInt(tok.nextToken())
		vl.BACK_POS = [vl.backgroundHeight, vl.backgroundWidth]
		var pos: Array = Values.createNormalFloatPoint(x, y)
		if vl.obstacleHandler == null:
			vl.obstacleHandler = ObstacleHandler.new(vl.BACK_POS)
		vl.player = Player.new(pos, a)

		var ox: int = Values.ORIGINAL_RESOLUTION[Values.X]
		var oy: int = Values.ORIGINAL_RESOLUTION[Values.Y]

		var hx: int = ox / 2
		var hy: int = oy / 2

		var backgroundX: int = x - hx
		var backgroundY: int = y - hy

		if backgroundX < 0:
			backgroundX = 0
		elif backgroundX > vl.backgroundWidth - ox:
			backgroundX = vl.backgroundWidth - ox

		if backgroundY < 0:
			backgroundY = 0
		elif backgroundY > vl.backgroundHeight - oy:
			backgroundY = vl.backgroundHeight - oy
		vl.background.setPos(Values.X, -1 * backgroundX)
		vl.background.setPos(Values.Y, -1 * backgroundY)
		vl.backgroundHeight -= vl.player.getHeight()
		vl.backgroundWidth -= vl.player.getWidth()
