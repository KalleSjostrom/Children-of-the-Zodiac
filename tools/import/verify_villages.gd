extends SceneTree
## The data check of phase 1 step A (docs/MODERNIZATION_PLAN.md 6.3): builds
## each village variant both ways, from its .vil file (VillageLoaderMapLoader)
## and from its scene (VillageScene.load_into), and compares the resulting
## legacy objects field by field: the loader's fields and everything they
## reference (background and its tiles, top layer and particle systems, the
## player and party, obstacles, doors, signs, loot, buildings, villagers with
## their dialogs and instructions), plus the Database statuses the load
## wrote, the state of the random generators and the wind afterwards. Run
## headless from the project root:
##
##   godot --headless --path . --script res://tools/import/verify_villages.gd -- [options] <place>...
##
## Options:
##   --scenes=<dir>   where the place folders are (default res://scenes/villages;
##                    a dry run of vil_to_scene.gd --out=<dir>)
##   --save=<slot>    the save loaded first, for the party and the Database
##                    statuses (default "Slot 1"; may be repeated)
##   --all            every place in the scenes folder
##
## Each variant is built once for every start position its .vil file names.
## The obstacles are compared as a set: a scene lists the base scene's
## shared obstacles first, and the legacy collision test checks all of them.
## Prints PASS/FAIL per variant, start and save; exit code 0 if all passed.

const VIL_DIR := "maps/Village/"
const MAX_REPORTED := 12

## VillageLoader fields that the .vil file sets.
const LOADER_FIELDS: Array[String] = ["folderName", "villageName", "background", "player",
	"obstacleHandler", "BACK_POS", "backgroundWidth", "backgroundHeight", "actualWidth",
	"actualHeight", "inside", "infoMap", "doors", "holeDoors", "signs", "loots", "buildingInfo",
	"sprites", "startPos"]

var _scene_dir := "res://scenes/villages"
var _failed := 0
var _passed := 0
var _errors: Array[String] = []
var _pairs := {}


func _init() -> void:
	var places: Array[String] = []
	var saves: Array[String] = []
	var all := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenes="):
			_scene_dir = a.trim_prefix("--scenes=").trim_suffix("/")
		elif a.begins_with("--save="):
			saves.append(a.trim_prefix("--save="))
		elif a == "--all":
			all = true
		else:
			places.append(a)
	if saves.is_empty():
		saves.append("Slot 1")
	if all:
		places.assign(Array(DirAccess.get_directories_at(_scene_dir)))
	Organizer.new()
	for save in saves:
		Load.loadGame(save)
		for place in places:
			_verify_place(place, save)
	print("VERIFIED %d builds: %d passed, %d failed" % [_passed + _failed, _passed, _failed])
	quit(1 if _failed > 0 else 0)


func _verify_place(place: String, save: String) -> void:
	var files: Array = GameResourceLoader.listFiles(VIL_DIR + place).filter(
			func(f: String) -> bool: return f.ends_with(".vil"))
	for f: String in files:
		var scene_path := "%s/%s/%s.tscn" % [_scene_dir, place, f.get_basename()]
		if not ResourceLoader.exists(scene_path):
			print("FAIL %s/%s [%s]: no scene %s" % [place, f, save, scene_path])
			_failed += 1
			continue
		for start in _start_numbers(place + "/" + f):
			_verify(place, f, scene_path, start, save)


## The start numbers a .vil file names (0 when it has none or only "start").
func _start_numbers(vil: String) -> Array[int]:
	var out: Array[int] = [0]
	for line in GameResourceLoader.readText(VIL_DIR + vil).replace("\r", "").split("\n"):
		var cmd := line.strip_edges().get_slice(" ", 0)
		if cmd.begins_with("start") and cmd.length() > 5 and cmd.substr(5).is_valid_int():
			var n := cmd.substr(5).to_int()
			if not out.has(n):
				out.append(n)
	return out


func _verify(place: String, file: String, scene_path: String, start: int, save: String) -> void:
	var db: Dictionary = Database.status.duplicate(true)
	var wind := _wind_state()
	var legacy := _build(place, start, db, wind, func(vl) -> void:
		VillageLoader.VillageLoaderMapLoader.new(vl).parseFile(place + "/" + file))
	var scene := _build(place, start, db, wind, func(vl) -> void:
		var s: VillageScene = (ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene).instantiate()
		s.load_into(vl)
		s.free())
	Database.status = db
	_errors.clear()
	_pairs.clear()
	for field in LOADER_FIELDS:
		var a = legacy["loader"].get(field)
		var b = scene["loader"].get(field)
		if field == "obstacleHandler" and a != null and b != null:
			_diff(a.boundingLines, b.boundingLines, "obstacleHandler.boundingLines")
			_diff(_sorted_obstacles(a), _sorted_obstacles(b), "obstacleHandler.obstacles")
		elif field == "sprites":
			_diff(a.values(), b.values(), "sprites")
		else:
			_diff(a, b, field)
	_diff(legacy["db"], scene["db"], "Database.status")
	_diff(legacy["random"], scene["random"], "random generators")
	_diff(legacy["wind"], scene["wind"], "wind")
	var label := "%s/%s start %d [%s]" % [place, file, start, save]
	if _errors.is_empty():
		print("PASS %s: %d sprites, %d obstacles, %d doors, %d hole doors, %d signs, %d loot" % [label,
			legacy["loader"].sprites.size(), legacy["loader"].obstacleHandler.obstacles.size() if legacy["loader"].obstacleHandler else 0,
			legacy["loader"].doors.size(), legacy["loader"].holeDoors.size(), legacy["loader"].signs.size(),
			legacy["loader"].loots.size()])
		_passed += 1
	else:
		print("FAIL %s: %d differences" % [label, _errors.size()])
		for e in _errors.slice(0, MAX_REPORTED):
			print("    " + e)
		_failed += 1


## One build from the same starting state: the Database, the seeded random
## generators and the wind.
func _build(place: String, start: int, db: Dictionary, wind: Array, load: Callable) -> Dictionary:
	Database.status = db.duplicate(true)
	J.setDeterministic(1)
	Values.rand.setSeed(2)
	BodiesParticleSystem.rand.setSeed(3)
	_set_wind(wind)
	var vl := Village.new()
	vl.startPos = start
	vl.infoMap = {"name": place, "landname": "land" + place}
	load.call(vl)
	return {"loader": vl, "db": Database.status.duplicate(true),
		"random": [J.random(), Values.rand.nextInt(1000000), BodiesParticleSystem.rand.nextInt(1000000)],
		"wind": _wind_state()}


## The shared wind of the smoke particles (WindCommand): its force (which
## the warm-up of the particles turns), magnitude and turbulence.
func _wind_state() -> Array:
	var w = BodiesParticleSystem.windCommand
	return [w.wind.x, w.wind.y, w.wind.z, w.windMagnitude, w.turbulence]


func _set_wind(state: Array) -> void:
	var w = BodiesParticleSystem.windCommand
	w.setForce(Vector3f.new(state[0], state[1], state[2]))
	w.windMagnitude = state[3]
	w.setTurbulence(state[4])


func _sorted_obstacles(handler) -> Array:
	var rects: Array = handler.obstacles.map(func(o) -> Array:
		return [o.topLeft[0], o.topLeft[1], o.bottomRight[0], o.bottomRight[1]])
	rects.sort()
	return rects


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
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, \
				TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_VECTOR2_ARRAY:
			if a.size() != b.size():
				_errors.append("%s: size %d vs %d" % [path, a.size(), b.size()])
				return
			for i in a.size():
				_diff(a[i], b[i], "%s[%d]" % [path, i])
		TYPE_DICTIONARY:
			var ka: Array = a.keys()
			var kb: Array = b.keys()
			if ka.size() != kb.size():
				_errors.append("%s: keys %s vs %s" % [path, _short(ka), _short(kb)])
				return
			for i in ka.size():
				# Object keys (MasterSlaveEmitter's pools by system) are paired
				# like any other object; other keys must be equal.
				if ka[i] is Object:
					_diff(ka[i], kb[i], "%s.keys()[%d]" % [path, i])
				elif ka[i] != kb[i]:
					_errors.append("%s: keys %s vs %s" % [path, _short(ka), _short(kb)])
					return
				_diff(a[ka[i]], b[kb[i]], "%s[%s]" % [path, str(ka[i]) if not ka[i] is Object else str(i)])
		TYPE_CALLABLE:
			pass
		TYPE_FLOAT:
			if a != b and not (is_nan(a) and is_nan(b)):
				_errors.append("%s: %s vs %s" % [path, var_to_str(a), var_to_str(b)])
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
	if sa != sb or a.get_class() != b.get_class():
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
