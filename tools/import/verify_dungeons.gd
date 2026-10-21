extends SceneTree
## The data check of phase 2 step A (docs/MODERNIZATION_PLAN.md 7.4): builds
## each converted floor both ways, from its .map file (MapLoader parsing it)
## and from its scene (DungeonScene.load_into), and compares the results
## field by field: the MapLoader (the map: nodes with their links, walls,
## floors, roofs and carpets, the inventory with its database names and
## everything the objects reference; the textures and slot ranges, the look
## settings and values, steps, battle music, mission), the static state the
## loader sets (MapLoader.textureNorm, the enemy colour, the door count,
## LadderDoor.goingUp, PillarWalls.node), then what Labyrinth.init builds on
## it (the Graph, the renderer, the weather system, the mission), the
## Database statuses afterwards and the state of the random generators. Run
## headless from the project root:
##
##   godot --headless --path . --script res://tools/import/verify_dungeons.gd -- [options] "<Area>--<Floor>"...
##
## Options:
##   --scenes=<dir>   where the area folders are (default res://scenes/dungeons;
##                    a dry run of map_to_scene.gd --out=<dir> has them in
##                    <dir>/scenes)
##   --save=<slot>    the save loaded first, for the Database statuses and the
##                    saved floor maps (default "Slot 1"; may be repeated)
##   --all            every floor scene in the scenes folder
##   --meshes         also compare the walls' mesh: the legacy display list
##                    (Labyrinth.init3D's renderSky and LabyrinthRenderer.draw,
##                    compiled by Graphics) with DungeonFloor.build, surface by
##                    surface and array by array, both in GL's default state.
##                    Needs a renderer: run it without --headless
##
## AbstractMapLoader's parse bookkeeping (lastLine, lineCount, comment) is not
## compared: nothing reads it after the parse. Prints PASS/FAIL per floor and
## save; exit code 0 if all passed.

const MAX_REPORTED := 12

## MapLoader fields that the .map file sets.
const LOADER_FIELDS: Array[String] = ["labyrinthName", "mission", "map", "stepsToBattle", "settingValues",
	"settings", "textures", "fog", "light", "material", "sky", "battleMusic"]

var _scene_dir := "res://scenes/dungeons"
var _meshes := false
var _graphics: Graphics
var _failed := 0
var _passed := 0
var _errors: Array[String] = []
var _pairs := {}


## MapLoader reading the .map file.
class LegacyLoader extends MapLoader:
	func _init(name: String) -> void:
		super(name)

	func dungeon_scene_for(_name):
		return null


## MapLoader building the floor from a scene.
class SceneLoader extends MapLoader:
	static var scene_path := ""

	func _init(name: String) -> void:
		super(name)

	func dungeon_scene_for(_name):
		return (ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene).instantiate()


func _init() -> void:
	var floors: Array[String] = []
	var saves: Array[String] = []
	var all := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenes="):
			_scene_dir = a.trim_prefix("--scenes=").trim_suffix("/")
		elif a.begins_with("--save="):
			saves.append(a.trim_prefix("--save="))
		elif a == "--all":
			all = true
		elif a == "--meshes":
			_meshes = true
		else:
			floors.append(a.trim_suffix(".map"))
	if saves.is_empty():
		saves.append("Slot 1")
	if all:
		for area in DirAccess.get_directories_at(_scene_dir):
			for f in DirAccess.get_files_at(_scene_dir + "/" + area):
				if f.ends_with(".tscn"):
					floors.append(area + "--" + f.get_basename())
	floors.sort()
	Organizer.new()
	for save in saves:
		Load.loadGame(save)
		for f in floors:
			_verify(f, save)
	print("VERIFIED %d builds: %d passed, %d failed" % [_passed + _failed, _passed, _failed])
	quit(1 if _failed > 0 else 0)


func _verify(floor_name: String, save: String) -> void:
	var scene_path := "%s/%s/%s.tscn" % [_scene_dir, floor_name.get_slice("--", 0), floor_name.get_slice("--", 1)]
	var label := "%s [%s]" % [floor_name, save]
	if not ResourceLoader.exists(scene_path):
		print("FAIL %s: no scene %s" % [label, scene_path])
		_failed += 1
		return
	var probe: Node = (ResourceLoader.load(scene_path) as PackedScene).instantiate()
	var map_name: String = probe.get("map_name")
	probe.free()
	var db: Dictionary = Database.status.duplicate(true)
	var visited := _visited_state()
	var legacy := _build(db, visited, func() -> MapLoader: return LegacyLoader.new(map_name))
	SceneLoader.scene_path = scene_path
	var scene := _build(db, visited, func() -> MapLoader: return SceneLoader.new(map_name))
	Database.status = db
	_set_visited_state(visited)
	_errors.clear()
	_pairs.clear()
	for field in LOADER_FIELDS:
		_diff(legacy["loader"].get(field), scene["loader"].get(field), field)
	for k in ["statics", "graph", "renderer", "weather", "mission", "visited", "db", "random"]:
		_diff(legacy[k], scene[k], k)
	if _meshes:
		MapLoader.textureNorm = legacy["statics"].textureNorm
		_diff_meshes(legacy["renderer"], scene_path)
	if _errors.is_empty():
		var map = legacy["loader"].map
		print("PASS %s: %d nodes, %d objects, %d textures" % [label, map.getNodes().size(),
				map.getNrOfInventories(), legacy["loader"].textures.size()])
		_passed += 1
	else:
		print("FAIL %s: %d differences" % [label, _errors.size()])
		for e in _errors.slice(0, MAX_REPORTED):
			print("    " + e)
		_failed += 1


## One build from the same starting state (the Database, the seeded random
## generators, the static state the loader changes), followed by what
## Labyrinth.init builds on the loader.
func _build(db: Dictionary, visited: Array, make: Callable) -> Dictionary:
	Database.status = db.duplicate(true)
	_set_visited_state(visited)
	J.setDeterministic(1)
	Values.rand.setSeed(2)
	WeatherParticle.rand.setSeed(3)
	SaveParticle.rand.setSeed(4)
	BattleEnemy.setColorStatic([0.5, 0.5, 0.5, 0.5])
	LadderDoor.goingUp = false
	PillarWalls.node = null
	var loader: MapLoader = make.call()
	var statics := {"textureNorm": MapLoader.textureNorm.duplicate(true), "enemyColor": BattleEnemy.color,
		"enemySource": BattleEnemy.source, "enemyUsedColor": BattleEnemy.usedColor,
		"doorCount": InventoryDoor.doorCount, "ladderGoingUp": LadderDoor.goingUp, "pillarNode": PillarWalls.node,
		"parserLine": Parser.lineNr}
	var name: String = loader.labyrinthName
	var graph := Graph.new(name, loader.getMap())
	var renderer = loader.getRenderer()
	var weather = renderer.getWeatherSystem()
	var mission = MissionFactory.createMission(loader.getMission())
	var info = Database.getMap(name)
	return {"loader": loader, "statics": statics, "graph": graph, "renderer": renderer, "weather": weather,
		"mission": mission, "visited": [info.getFloors() if info != null else null, Database.getLastVisitedLabyrinth()],
		"db": Database.status.duplicate(true),
		"random": [J.random(), Values.rand.nextInt(1000000), WeatherParticle.rand.nextInt(1000000),
			SaveParticle.rand.nextInt(1000000)]}


## --meshes: the legacy display list of renderer against DungeonFloor.build
## for the scene, in the same GL state.
func _diff_meshes(renderer, scene_path: String) -> void:
	if _graphics == null:
		var host := Node2D.new()
		root.add_child(host)
		_graphics = Graphics.new(GLBackend.new(host, host))
	var g := _graphics
	g.beginFrame(true)
	renderer.addLight(g)
	renderer.setMaterial(g)
	renderer.addFog(g)
	renderer.init(g)
	var list := g.generateList()
	g.compileDrawList(list)
	g.setTextureEnabled(false)
	g.setLightEnabled(false)
	g.clearColor(0)
	var st := g.render_state_3d()
	var gl := {"color": g.getCurrentColor(), "normal": g.current_normal(), "uv": g.current_tex_coord(),
		"additive": st.additive, "opaque": st.opaque, "alpha_func": st.alpha_func, "alpha_ref": st.alpha_ref,
		"depth_test": st.depth_test, "depth_write": st.depth_write, "cull": st.cull}
	renderer.renderSky(g)
	g.setTextureEnabled(true)
	g.setLightEnabled(true)
	renderer.draw(g)
	g.endList()
	var legacy: ArrayMesh = g._lists[list].mesh
	g.deleteList(list)
	var scene: DungeonScene = (ResourceLoader.load(scene_path) as PackedScene).instantiate()
	var floor_node := scene.get_node(^"Layout") as DungeonFloor
	floor_node.build(scene.style, gl)
	# [mesh, surface] of the floor's instances, in order.
	var mine: Array = []
	for c in floor_node.get_children(true):
		if c is MeshInstance3D and c.mesh != null:
			for k in c.mesh.get_surface_count():
				mine.append([c.mesh, k])
	var surfaces: int = legacy.get_surface_count() if legacy != null else 0
	if surfaces != mine.size():
		_errors.append("mesh: %d surfaces vs %d" % [surfaces, mine.size()])
	for i in mini(surfaces, mine.size()):
		var m: Mesh = mine[i][0]
		var j: int = mine[i][1]
		var la := legacy.surface_get_arrays(i)
		var ma: Array = m.surface_get_arrays(j)
		_diff(legacy.surface_get_format(i), m.surface_get_format(j), "mesh[%d].format" % i)
		for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_COLOR]:
			_diff(la[k], ma[k], "mesh[%d].arrays[%d]" % [i, k])
		var lm: ShaderMaterial = legacy.surface_get_material(i)
		var mm: ShaderMaterial = m.surface_get_material(j)
		if lm.get_shader_parameter("tex") != mm.get_shader_parameter("tex"):
			_errors.append("mesh[%d]: texture %s vs %s" % [i, lm.get_shader_parameter("tex"), mm.get_shader_parameter("tex")])
	scene.free()


## The visited labyrinths (Database.visitLabyrinth, which Graph calls): the
## infos, their floors, the list and the last visited one.
func _visited_state() -> Array:
	var floors := {}
	for k in Database.visitedLabyrinth:
		floors[k] = Database.visitedLabyrinth[k].floors.duplicate()
	return [Database.visitedLabyrinth.duplicate(), floors, Database.visitedLabyrinthList.duplicate(),
		Database.lastVisitedLabyrinth]


func _set_visited_state(state: Array) -> void:
	Database.visitedLabyrinth = state[0].duplicate()
	for k in state[1]:
		Database.visitedLabyrinth[k].floors = state[1][k].duplicate()
	Database.visitedLabyrinthList = state[2].duplicate()
	Database.lastVisitedLabyrinth = state[3]


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
				TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, \
				TYPE_PACKED_COLOR_ARRAY:
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
