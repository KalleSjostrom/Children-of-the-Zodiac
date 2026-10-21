class_name MapLoader
extends AbstractMapLoader
## Port of labyrinth.MapLoader: parses a .map labyrinth file (nodes, inventory,
## textures, light/fog/material settings).

const FOG = 0
const LIGHT_0 = 1
const LIGHT_1 = 2
const MATERIAL = 3
const INV_MATERIAL = 4
const SKY = 5
const SETTING_VALUE_SIZE = 6
const USE_CARPET_FLOOR = 6
const USE_PILLAR_WALLS = 7
const USE_SNOW = 8
const USE_FIRE = 9
const USE_RAIN = 10
const SETTING_SIZE = 11
const FLOOR = 0
const WALL = 1
const ROOF = 2
const CARPET_FLOOR = 3
const PILLAR_WALLS = 4
var labyrinthName = ""
var mission = null
var map = null
var stepsToBattle = [13, 20]
var settingValues = J.array(SETTING_VALUE_SIZE, null)
var settings = null
var textures = null
var fog = getFogMap()
var light = getLightMap()
var material = getMaterialMap()
var sky = getSkyMap()
var battleMusic = ["Battle", "Fight the Demons"]
static var textureNorm = null
const FOG_RED = 0
const FOG_GREEN = 1
const FOG_BLUE = 2
const FOG_ALPHA = 3
const FOG_DENSITY = 4
const FOG_START = 5
const FOG_END = 6
const LIGHT_AMBIENT = 0
const LIGHT_DIFFUSE = 4
const LIGHT_SPECULAR = 8
const LIGHT_POSITION = 12
const LIGHT_ATTENUATION = 16
const MATERIAL_AMBIENT = 0
const MATERIAL_DIFFUSE = 4
const MATERIAL_SPECULAR = 8
const MATERIAL_EMISSION = 12
const MATERIAL_SHININESS = 16
const SKY_TOP_COLOR = 0
const SKY_BOTTOM_COLOR = 4

func _init(name = null) -> void:
	stepsToBattle[1] -= stepsToBattle[0]
	labyrinthName = name
	InventoryDoor.resetStatic()
	map = LabyrinthMap.new()
	textures = []
	settings = J.array(SETTING_SIZE, false)
	textureNorm = J.array2d(5, 2, 0)
	# Phase 2 step A (docs/ARCHITECTURE.md section 10): a converted floor is
	# built from its scene, which replays what parsing the file would do.
	var scene = dungeon_scene_for(name)
	if scene != null:
		scene.load_into(self)
		scene.free()
	else:
		parseFile(name)


## Bridge (phase 2, docs/ARCHITECTURE.md section 10): a new instance of the
## floor's scene (DungeonScene, made by tools/import/map_to_scene.gd), or
## null when the floor is not converted or with --legacy=dungeons; the floor
## is then read from its .map file.
func dungeon_scene_for(name):
	if Main.is_legacy("dungeons"):
		return null
	var path := DungeonScene.path_for(GameResourceLoader.resolve(Values.LabyrinthMaps + str(name)))
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()

func getFogMap():
	var m := {}
	m["red"] = FOG_RED
	m["green"] = FOG_GREEN
	m["blue"] = FOG_BLUE
	m["alpha"] = FOG_ALPHA
	m["density"] = FOG_DENSITY
	m["start"] = FOG_START
	m["end"] = FOG_END
	return m

func getLightMap():
	var m := {}
	m["ambient"] = LIGHT_AMBIENT
	m["diffuse"] = LIGHT_DIFFUSE
	m["specular"] = LIGHT_SPECULAR
	m["position"] = LIGHT_POSITION
	m["attenuation"] = LIGHT_ATTENUATION
	return m

func getMaterialMap():
	var m := {}
	m["ambient"] = MATERIAL_AMBIENT
	m["diffuse"] = MATERIAL_DIFFUSE
	m["specular"] = MATERIAL_SPECULAR
	m["emission"] = MATERIAL_EMISSION
	m["shininess"] = MATERIAL_SHININESS
	return m

func getSkyMap():
	var m := {}
	m["top"] = SKY_TOP_COLOR
	m["bottom"] = SKY_BOTTOM_COLOR
	return m

## Java parseFile(String filename) delegating to parseFile(LabyrinthMaps, filename).
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.LabyrinthMaps, path)
	else:
		super.parseFile(path, filename)

func getMap():
	return map

func executeCommand(command: String, tokenizer: StringTokenizer):
	var t: StringTokenizer = tokenizer
	if command == "dir":
		var source: int = J.parseInt(t.nextToken())
		var dir: int = J.parseInt(t.nextToken())
		var destination: int = J.parseInt(t.nextToken())
		InsertNodes(source, dir, destination)
	elif command == "mapEnd":
		sort()
	elif command == "size":
		map.setSize(J.parseInt(t.nextToken()))
	elif command == "battleMusic":
		battleMusic[0] = Organizer.convertKeepCase(t.nextToken())
		if t.hasMoreTokens():
			battleMusic[1] = Organizer.convertKeepCase(t.nextToken())
	elif command == "mapPos":
		var mapPos: Array = J.array(2, 0)
		mapPos[0] = J.parseInt(t.nextToken())
		mapPos[1] = J.parseInt(t.nextToken())
		map.setMapPos(mapPos)
	elif command == "inv":
		var i = Inventory.createInventory(t, map, labyrinthName)
		if i != null:
			map.putInventory(i.getDatabaseName(), i)
	elif command == "mission":
		mission = []
		mission.append(t.nextToken())
		mission.append(Organizer.convert(t.nextToken()))
		while t.hasMoreTokens():
			var args: Array = Parser.getArgument(t.nextToken())
			if args[0] == "trigger":
				var val: Array = Parser.getText(t, args[1])
				var dbName: String = val[0]
				var value: int = J.parseInt(val[1])
				var s: String = args[0] + "&&" + dbName + "&&" + str(value)
				mission.append(Organizer.convert(s))
			elif args[0] == "dialog":
				var val: Array = Parser.getText(t, args[1])
				mission.append(args[0] + "&&" + val[0] + "&&" + val[1])
			elif args[0] == "extranext":
				var val: Array = Parser.getText(t, args[1])
				mission.append(args[0] + "&&" + val[0] + "&&" + val[1])
	elif command == "steps":
		stepsToBattle = J.array(2, 0)
		stepsToBattle[0] = J.parseInt(t.nextToken())
		stepsToBattle[1] = J.parseInt(t.nextToken()) - stepsToBattle[0]
	elif command == "fog":
		settings[FOG] = true
		var fogSettings: Array = J.array(7, 0.0)
		while t.hasMoreTokens():
			var s: Array = J.split(t.nextToken(), "=")
			var key: String = s[0]
			var index: int = fog.get(key)
			fogSettings[index] = J.parseFloat(s[1])
		settingValues[FOG] = fogSettings
	elif command == "light0":
		addSettings(LIGHT_0, t, light)
	elif command == "light1":
		addSettings(LIGHT_1, t, light)
	elif command == "material":
		addSettings(MATERIAL, t, material)
	elif command == "invMaterial":
		addSettings(INV_MATERIAL, t, material)
	elif command == "sky":
		addSettings(SKY, t, sky)
	elif command == "enemyColor":
		var color: Array = J.array(4, 0.0)
		color[0] = J.parseFloat(t.nextToken())
		color[1] = J.parseFloat(t.nextToken())
		color[2] = J.parseFloat(t.nextToken())
		color[3] = J.parseFloat(t.nextToken())
		BattleEnemy.setColorStatic(color)
	elif command == "useSnow":
		settings[USE_SNOW] = true
	elif command == "useFire":
		settings[USE_FIRE] = true
	elif command == "useRain":
		settings[USE_RAIN] = true
	elif command == "floorTex":
		addTexture("Floors/" + t.nextToken())
	elif command == "SfloorTex":
		settings[USE_CARPET_FLOOR] = true
		var s: String = t.nextToken()
		textureNorm[CARPET_FLOOR][0] = J.parseInt(t.nextToken())
		textureNorm[CARPET_FLOOR][1] = textureNorm[CARPET_FLOOR][0] + 5
		for i in range(5):
			var tex: String = s.replace(".jpg", str(i) + ".jpg")
			addTexture("Floors/" + tex)
	elif command == "roofTex":
		addTexture("Roofs/" + t.nextToken())
	elif command == "wallTex":
		addTexture("Walls/" + t.nextToken())
	elif command == "SwallTex":
		settings[USE_PILLAR_WALLS] = true
		var s: String = t.nextToken()
		textureNorm[PILLAR_WALLS][0] = J.parseInt(t.nextToken())
		textureNorm[PILLAR_WALLS][1] = textureNorm[PILLAR_WALLS][0] + 4
		for i in range(4):
			var tex: String = s.replace(".png", str(i) + ".png")
			addTexture("Walls/" + tex)
	elif command == "wall":
		var nr: int = J.parseInt(t.nextToken())
		var addr: int = J.parseInt(t.nextToken())
		var dir: int = J.parseInt(t.nextToken())
		dir = Values.getCounterAngle(dir)
		map.getNode(addr).setWall(dir, nr)
	elif command == "roof" or command == "floor":
		var nr: int = J.parseInt(t.nextToken())
		var addr: int = J.parseInt(t.nextToken())
		if command == "roof":
			map.getNode(addr).setRoof(nr)
		else:
			map.getNode(addr).setFloor(false, nr)
	elif command == "normal":
		var kind: String = t.nextToken()
		if kind == "floor":
			textureNorm[FLOOR][0] = J.parseInt(t.nextToken())
			textureNorm[FLOOR][1] = J.parseInt(t.nextToken())
		elif kind == "wall":
			textureNorm[WALL][0] = J.parseInt(t.nextToken())
			textureNorm[WALL][1] = J.parseInt(t.nextToken())
		elif kind == "roof":
			textureNorm[ROOF][0] = J.parseInt(t.nextToken())
			textureNorm[ROOF][1] = J.parseInt(t.nextToken())

func addSettings(settingIndex, t, m):
	settings[settingIndex] = true
	var lightValues: Array = J.array(19, 0.0)
	while t.hasMoreTokens():
		var s: Array = J.split(t.nextToken(), "=")
		var key: String = s[0]
		var index: int = m.get(key)
		var args: Array = J.split(s[1], ";")
		for i in range(args.size()):
			lightValues[index + i] = J.parseFloat(args[i])
	settingValues[settingIndex] = lightValues

func addTexture(path):
	var tex := LabyrinthTexture.new(path)
	textures.append(tex)

func InsertNodes(source, direction, destination):
	var sourceNode
	var destNode
	sourceNode = map.getNode(source)
	if sourceNode == null:
		sourceNode = LabyrinthNode.new(source)
		map.put(source, sourceNode)
	destNode = map.getNode(destination)
	if destNode == null:
		destNode = LabyrinthNode.new(destination)
		map.put(destination, destNode)
	sourceNode.putNeighbours(Values.getCounterAngle(direction), destNode)
	destNode.putNeighbours(direction, sourceNode)

func sort():
	var nodes = map.getNodes()
	for addr in nodes:
		var n = nodes[addr]
		var tex: int = textureNorm[PILLAR_WALLS if settings[USE_PILLAR_WALLS] else WALL][0]
		n.setWalls(settings[USE_PILLAR_WALLS], tex)
		tex = textureNorm[CARPET_FLOOR if settings[USE_CARPET_FLOOR] else FLOOR][0]
		n.setFloor(settings[USE_CARPET_FLOOR], tex)
		n.setRoof(textureNorm[ROOF][0])

func getRenderer():
	var renderer := LabyrinthRenderer.new(textures)
	renderer.setMap(map)
	renderer.setSettings(settings, settingValues)
	return renderer

func getStepsToBattle():
	return stepsToBattle

func getMission():
	return mission

func getBattleMusic():
	return battleMusic
