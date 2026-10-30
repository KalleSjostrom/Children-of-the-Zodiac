extends SceneTree
## The data check of phase 4.1 step A (docs/MODERNIZATION_PLAN.md 9.1):
## builds each world map and airship map both ways, from its .map file (the
## legacy map loaders) and from its scene (WorldMapScene.load_into), and
## compares the game modes field by field: the nodes (with their roads and
## directions), the roads (their line of coordinates with the angles, the
## dots, the closed state), the background (tiles, top layer, night layer),
## the player or the airship, the airship nodes' zones; then what
## Landscape.init and AirLandscape.init make of them (the current node, the
## visited nodes and roads from Visited and the Database's opened roads),
## the Database and Visited afterwards; and the index of the node names
## (LandscapeLoader.PlaceMapLoader against resources/world_map/place_index.tres).
## Run headless from the project root:
##
##   godot --headless --path . --script res://tools/import/verify_world_map.gd -- [options] [<file.map>...]
##
## Options:
##   --save=<slot>    the save loaded first, for the Database statuses (closed
##                    roads, the airship status) and the visited nodes and roads
##                    (default "Slot 1"; may be repeated)
## Without files: every .map file of maps/Landscape that has a scene.
##
## A world map is built once from each of its nodes by day, and once from its
## first node at night (Landscape.isNight: the "continue" music); an airship
## map from each of its nodes, with the Database status "airship" set to the
## map's number. The index's order is not compared (it is only looked up).
## The legacy AirLandscapeLoader keeps its map loader (a reference cycle,
## fixed in step B), so mapLoader is not compared. Prints PASS/FAIL per map,
## start, time and save; exit code 0 if all passed.

const MAX_REPORTED := 12
const MAP_DIR := "maps/Landscape/"

## LandscapeLoader and Landscape fields that the map file and init set.
const LANDSCAPE_FIELDS: Array[String] = ["nodes", "roads", "loadRoad", "background", "player",
	"nameBackGround", "currentNode", "visitedNodes", "visitedRoads", "infoMap", "nextPlace", "music"]
## AirLandscapeLoader and AirLandscape fields.
const AIRSHIP_FIELDS: Array[String] = ["nodes", "background", "airShip", "nameBackGround",
	"currentNode", "currentPlace", "infoMap", "nextPlace", "music"]

var _failed := 0
var _passed := 0
var _errors: Array[String] = []
var _pairs := {}


## Landscape reading the .map file.
class LegacyLandscape extends Landscape:
	func world_scene_for(_map_file):
		return null


## AirLandscape reading the .map file.
class LegacyAirLandscape extends AirLandscape:
	func airship_scene_for(_map_file):
		return null


func _init() -> void:
	var files: Array[String] = []
	var saves: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--save="):
			saves.append(a.trim_prefix("--save="))
		else:
			files.append(a)
	if saves.is_empty():
		saves.append("Slot 1")
	if files.is_empty():
		for f in GameResourceLoader.listFiles(MAP_DIR):
			if f.ends_with(".map") and WorldMapScene.path_for(f) != "":
				files.append(f)
	files.sort()
	Organizer.new()
	GameMode.mute = true
	GameCore.inputManager.addInputManager(FakeInputManager.new())
	GameCore.inputManager.createGameActions()
	GameCore.setGameAction()
	for save in saves:
		Load.loadGame(save)
		_verify_index(save)
		for f in files:
			if f.begins_with("land"):
				_verify_airship(f, save)
			else:
				_verify_world(f, save)
	print("VERIFIED %d builds: %d passed, %d failed" % [_passed + _failed, _passed, _failed])
	quit(1 if _failed > 0 else 0)


## PlaceMapLoader's map against the converter's index (as LandscapeLoader.createMap
## reads it), keys sorted.
func _verify_index(save: String) -> void:
	var legacy := {}
	LandscapeLoader.PlaceMapLoader.new(legacy)
	var index: WorldMapIndex = ResourceLoader.load(WorldMapIndex.PATH)
	var scene := {}
	scene.merge(index.maps)
	_start()
	_diff(_sorted(legacy), _sorted(scene), "index")
	_report("index [%s]" % save, "%d nodes" % legacy.size())


func _verify_world(file: String, save: String) -> void:
	var scene_path := WorldMapScene.path_for(file)
	var probe: WorldMapScene = (ResourceLoader.load(scene_path) as PackedScene).instantiate()
	var starts: Array[String] = []
	for node: WorldMapNode in probe.get_node("Nodes").get_children():
		starts.append(node.node_name)
	probe.free()
	for start in starts:
		_verify_world_start(file, start, false, save)
	_verify_world_start(file, starts[0], true, save)


func _verify_world_start(file: String, start: String, night: bool, save: String) -> void:
	var db: Dictionary = Database.status.duplicate(true)
	var visited := _visited_state()
	var info := {"name": file, "map": file, "music": "Landscape", "startNode": Organizer.convert(start)}
	var legacy := _build(db, visited, night, func() -> GameMode:
		var m := LegacyLandscape.new()
		m.init(info.duplicate())
		return m)
	var scene := _build(db, visited, night, func() -> GameMode:
		var m := Landscape.new()
		m.init(info.duplicate())
		return m)
	Database.status = db
	_set_visited_state(visited)
	_start()
	for field in LANDSCAPE_FIELDS:
		_diff(legacy["mode"].get(field), scene["mode"].get(field), field)
	for k in ["statics", "visited", "db"]:
		_diff(legacy[k], scene[k], k)
	var m = legacy["mode"]
	var closed := 0
	for r in m.roads:
		if r.isClosed():
			closed += 1
	_report("%s from %s%s [%s]" % [file, start, " at night" if night else "", save],
			"%d nodes, %d roads (%d closed), %d visited roads, %d top layer pieces%s" % [m.nodes.size(),
			m.roads.size(), closed, m.visitedRoads.size(), m.background.top.size(),
			", night layer" if m.background.nightTop != null else ""])


func _verify_airship(file: String, save: String) -> void:
	var status := file.get_basename().trim_prefix("land").to_int()
	var scene_path := WorldMapScene.path_for(file)
	var probe: WorldMapScene = (ResourceLoader.load(scene_path) as PackedScene).instantiate()
	var starts: Array[String] = []
	for node: AirshipNode in probe.get_node("Nodes").get_children():
		starts.append(node.node_name.trim_prefix("land"))
	probe.free()
	for start in starts:
		var db: Dictionary = Database.status.duplicate(true)
		db["airship"] = status
		var visited := _visited_state()
		var info := {"name": "airworld", "map": "land", "music": "Airship", "startNode": Organizer.convert(start)}
		var legacy := _build(db, visited, false, func() -> GameMode:
			var m := LegacyAirLandscape.new()
			m.init(info.duplicate())
			return m)
		var scene := _build(db, visited, false, func() -> GameMode:
			var m := AirLandscape.new()
			m.init(info.duplicate())
			return m)
		db.erase("airship")
		Database.status = db
		_set_visited_state(visited)
		_start()
		for field in AIRSHIP_FIELDS:
			_diff(legacy["mode"].get(field), scene["mode"].get(field), field)
		for k in ["statics", "visited", "db"]:
			_diff(legacy[k], scene[k], k)
		var zones := {}
		for n in legacy["mode"].nodes:
			zones[n.getZone()] = zones.get(n.getZone(), 0) + 1
		_report("%s from %s [%s]" % [file, start, save], "%d nodes, zones %s" % [legacy["mode"].nodes.size(), zones])


## One build from the same starting state: the Database, Visited, the night
## (Landscape.music_, which init resets) and the seeded random generators.
func _build(db: Dictionary, visited: Array, night: bool, make: Callable) -> Dictionary:
	Database.status = db.duplicate(true)
	_set_visited_state(visited)
	J.setDeterministic(1)
	Values.rand.setSeed(2)
	Landscape.music_ = Landscape.CONTINUE_MUSIC if night else Landscape.NORMAL
	var mode: GameMode = make.call()
	return {"mode": mode, "statics": {"music": Landscape.music_, "parserLine": Parser.lineNr,
			"random": [J.random(), Values.rand.nextInt(1000000)]},
		"visited": _visited_state(), "db": Database.status.duplicate(true)}


func _visited_state() -> Array:
	var v: Visited = Visited.getVisited()
	return [v.visitedNodes.duplicate(true), v.visitedRoads.duplicate(true)]


func _set_visited_state(state: Array) -> void:
	var v: Visited = Visited.getVisited()
	v.visitedNodes = state[0].duplicate(true)
	v.visitedRoads = state[1].duplicate(true)


static func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys.map(func(k) -> Array: return [k, d[k]])


func _start() -> void:
	_errors.clear()
	_pairs.clear()


func _report(label: String, summary: String) -> void:
	if _errors.is_empty():
		print("PASS %s: %s" % [label, summary])
		_passed += 1
	else:
		print("FAIL %s: %d differences" % [label, _errors.size()])
		for e in _errors.slice(0, MAX_REPORTED):
			print("    " + e)
		_failed += 1


## Compares a and b recursively (script variables of objects, arrays,
## dictionaries) and records the differences. Objects are paired: the same
## legacy object reached twice must be the same object on the other side.
func _diff(a, b, path: String) -> void:
	if _errors.size() > 200:
		return
	if typeof(a) != typeof(b):
		_errors.append("%s: %s vs %s" % [path, _short(a), _short(b)])
		return
	match typeof(a):
		TYPE_OBJECT:
			_diff_objects(a, b, path)
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			if a.size() != b.size():
				_errors.append("%s: size %d vs %d" % [path, a.size(), b.size()])
				return
			for i in a.size():
				_diff(a[i], b[i], "%s[%d]" % [path, i])
		TYPE_DICTIONARY:
			var ka: Array = a.keys()
			var kb: Array = b.keys()
			if ka != kb:
				_errors.append("%s: keys %s vs %s" % [path, _short(ka), _short(kb)])
				return
			for k in ka:
				_diff(a[k], b[k], "%s[%s]" % [path, str(k)])
		TYPE_CALLABLE:
			pass
		_:
			if a != b:
				_errors.append("%s: %s vs %s" % [path, _short(a), _short(b)])


func _diff_objects(a: Object, b: Object, path: String) -> void:
	if a == b:
		return
	if a == null or b == null:
		_errors.append("%s: %s vs %s" % [path, _short(a), _short(b)])
		return
	var ida := a.get_instance_id()
	if _pairs.has(ida):
		if _pairs[ida][0] != b.get_instance_id():
			_errors.append("%s: not the same object as at %s" % [path, _pairs[ida][1]])
		return
	_pairs[ida] = [b.get_instance_id(), path]
	var sa: Script = a.get_script()
	var sb: Script = b.get_script()
	if a.get_class() != b.get_class() or (sa != sb and not (a is GameMode)):
		_errors.append("%s: %s vs %s" % [path, _short(a), _short(b)])
		return
	if a is Resource and sa == null:
		if a.resource_path != b.resource_path or a.resource_path == "":
			_errors.append("%s: %s vs %s" % [path, _short(a), _short(b)])
		return
	for p in a.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_diff(a.get(p["name"]), b.get(p["name"]), path + "." + p["name"])


func _short(v) -> String:
	if v is Object and v != null:
		var s: Script = v.get_script()
		return "<%s%s>" % [v.get_class(), (" " + s.resource_path.get_file()) if s != null else ""]
	return str(v).left(120)
