extends SceneTree
## Converts .map files of maps/Labyrinth into dungeon scenes
## (docs/MODERNIZATION_PLAN.md 7.1 to 7.3; the conventions are in
## docs/ARCHITECTURE.md section 10, the workflow in docs/CONVERTING_DUNGEONS.md).
## Run headless from the project root (or through tools/import/map_to_scene.sh):
##
##   godot --headless --path . --script res://tools/import/map_to_scene.gd -- [options] "<Area>--<Floor>"...
##
## For a floor maps/Labyrinth/<Area>--<Floor>.map it writes:
##   resources/dungeon_layouts/<Area>--<Floor>.tres   the DungeonLayout: cells,
##                                links, texture slots, carpets
##   resources/dungeon_styles/<Area>.tres          the DungeonStyle most floors of
##                                the area share (ties: the first floor by name)
##   resources/dungeon_styles/<Area>--<Floor>.tres the style of a floor whose
##                                look differs from it
##   resources/sprite_frames/labyrinth/<folder>/<image>.tres  the frames of an
##                                object image series (chest0.png, chest1.png)
##   scenes/dungeons/<Area>/<Floor>.tscn           the floor scene: inherits
##                                scenes/dungeons/DungeonScene.tscn, one object
##                                scene of scenes/dungeon_objects/ per "inv" line
## and sets detect_3d/compress_to to disabled in the .import files of the
## textures it uses, so that the editor does not VRAM-compress them when a
## floor scene shows them in 3D (the legacy drawing uses the same textures).
##
## Options:
##   --all           every .map file of maps/Labyrinth
##   --out=<dir>     write the layouts, styles and scenes into <dir>
##                   (layouts/, styles/, scenes/<Area>/), for dry runs
##   --data-only     no SpriteFrames and no .import changes (the object views
##                   get no frames); with --out for a dry run outside the project
##
## The .map files are read by MapLoader itself (a subclass that records what
## it parses), so every value is what the legacy loader reads; its warnings
## name the file and the line of every token the legacy loader misreads
## (unknown commands and keys, tokens that are not numbers, missing nodes
## and images). Scenes are saved with PackedScene.pack() and
## ResourceSaver.save() and the node unique_ids are removed, so that
## converting twice writes the same files. tools/import/verify_dungeons.gd
## checks the result.

const MAP_DIR := "maps/Labyrinth/"
const TEMPLATE := "res://scenes/dungeons/DungeonScene.tscn"
const SCENE_DIR := "res://scenes/dungeons"
const LAYOUT_DIR := "res://resources/dungeon_layouts"
const STYLE_DIR := "res://resources/dungeon_styles"
const FRAMES_DIR := "res://resources/sprite_frames/labyrinth"
const OBJECTS := "res://scenes/dungeon_objects/"
const TEXTURES := "res/Labyrinth/"

## Inventory.createInventory's kinds in the order it tests them: [test, kind,
## object scene]. "=" tests the whole command, "^" its start.
const KINDS := [["=", "chest", "DungeonChest"], ["=", "riddle", "DungeonRiddle"],
	["=", "floorButton", "DungeonFloorButton"], ["=", "button", "DungeonButton"],
	["=", "iceButton", "DungeonIceButton"], ["=", "aegisComboButton", "DungeonAegisComboButton"],
	["=", "iceComboButton", "DungeonIceComboButton"], ["^", "door", "DungeonDoor"],
	["^", "triggerDoor", "DungeonTriggerDoor"], ["^", "ladderDoor", "DungeonLadderDoor"],
	["=", "ifDoor", "DungeonIfDoor"], ["^", "hinderDoor", "DungeonHinderDoor"],
	["^", "hiddenHinderDoor", "DungeonHiddenHinderDoor"], ["^", "riddleDoor", "DungeonRiddleDoor"],
	["^", "addDoor", "DungeonAddDoor"], ["=", "bomb", "DungeonBomb"], ["=", "villager", "DungeonVillager"],
	["=", "simpleRiddle", "DungeonSimpleRiddle"], ["=", "missionChest", "DungeonMissionChest"],
	["=", "boss", "DungeonBoss"], ["=", "save", "DungeonSavePoint"]]

var _data_only := false
var _layout_dir := LAYOUT_DIR
var _style_dir := STYLE_DIR
var _scene_dir := SCENE_DIR
var _failed := 0
var _warnings := 0
var _frames := {} # image series -> frame count, for the frames already written
var _imports := {} # .import files already fixed


func _init() -> void:
	var floors: Array[String] = []
	var all := false
	for a in OS.get_cmdline_user_args():
		if a == "--data-only":
			_data_only = true
		elif a.begins_with("--out="):
			var out := a.trim_prefix("--out=").trim_suffix("/")
			_layout_dir = out + "/layouts"
			_style_dir = out + "/styles"
			_scene_dir = out + "/scenes"
		elif a == "--all":
			all = true
		else:
			floors.append(a.trim_suffix(".map"))
	if all:
		for f: String in GameResourceLoader.listFiles(MAP_DIR):
			if f.ends_with(".map"):
				floors.append(f.get_basename())
	if floors.is_empty():
		print("usage: map_to_scene.gd -- [--data-only] [--out=<dir>] [--all] \"<Area>--<Floor>\"...")
		quit(2)
		return
	floors.sort()
	Organizer.new()
	for d in [_layout_dir, _style_dir, _scene_dir]:
		DirAccess.make_dir_recursive_absolute(d)
	var area_styles := {}
	for f in floors:
		var area := f.get_slice("--", 0)
		if not area_styles.has(area):
			area_styles[area] = _area_style(area)
		_convert(f, area_styles[area])
	print("CONVERTED %d floors, %d failed, %d warnings" % [floors.size(), _failed, _warnings])
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# Reading a .map file
# ---------------------------------------------------------------------------

## MapLoader, recording what it parses: the "inv" lines (with their legacy
## inventories, which MapLoader creates as it does in the game, from an empty
## Database), the warnings, and the enemy colour (not set: it is static).
class MapReader extends MapLoader:
	var file := ""
	var warnings: Array[String] = []
	var inv_lines: Array[Dictionary] = []
	var enemy_color = null
	var seen_end := false
	var links := {}

	func _init(p_file: String) -> void:
		file = p_file
		super(p_file)

	## Always the .map file (MapLoader builds converted floors from their scene).
	func dungeon_scene_for(_name):
		return null

	func warn(text: String) -> void:
		warnings.append("%s:%d: %s" % [file, lineCount, text])

	func executeCommand(command: String, t: StringTokenizer):
		var words := StringTokenizer.new(lastLine)
		words.nextToken()
		var w: PackedStringArray = []
		while words.hasMoreTokens():
			w.append(words.nextToken())
		match command:
			"dir":
				_ints(w, [0, 1, 2], 3)
				if seen_end:
					warn("dir after mapEnd: mapEnd's sort gave its nodes no walls")
				var link := " ".join(w)
				if links.has(link):
					warn("repeated link 'dir %s': the legacy loader counts it as a neighbour again (LabyrinthNode.nrOfNeighbors; DungeonCell.extra_links)" % link)
				links[link] = true
				super.executeCommand(command, t)
			"mapEnd":
				seen_end = true
				super.executeCommand(command, t)
			"size", "mapPos", "steps":
				_ints(w, range(w.size()), {"size": 1, "mapPos": 2, "steps": 2}[command])
				super.executeCommand(command, t)
			"wall", "roof", "floor":
				var n := 3 if command == "wall" else 2
				_ints(w, range(n), n)
				if w.size() >= n and map.getNode(J.parseInt(w[1])) == null:
					warn("%s on node %s, which no dir line has: ignored (the legacy loader stops on it)" % [command, w[1]])
					return
				super.executeCommand(command, t)
			"normal":
				if w.size() < 3 or not ["floor", "wall", "roof"].has(w[0]):
					warn("normal '%s' is not floor, wall or roof: ignored" % " ".join(w))
				_ints(w, [1, 2], 3)
				super.executeCommand(command, t)
			"SfloorTex", "SwallTex":
				_ints(w, [1], 2)
				super.executeCommand(command, t)
			"fog":
				for kv in w:
					_key(kv, fog, "fog")
				super.executeCommand(command, t)
			"light0", "light1", "material", "invMaterial", "sky":
				var keys: Dictionary = {"light0": light, "light1": light, "material": material,
					"invMaterial": material, "sky": sky}[command]
				for kv in w:
					_key(kv, keys, command)
				super.executeCommand(command, t)
			"enemyColor":
				if w.size() < 4:
					warn("enemyColor has %d values, not 4" % w.size())
				var c: Array = [0.0, 0.0, 0.0, 0.0]
				for i in mini(4, w.size()):
					_float(w[i])
					c[i] = J.parseFloat(w[i])
				enemy_color = c
			"inv":
				_inv(w, t)
			"battleMusic", "mission", "useSnow", "useFire", "useRain", "floorTex", "roofTex", "wallTex":
				super.executeCommand(command, t)
			_:
				warn("unknown command '%s', ignored (as by the legacy loader)" % command)

	func _inv(w: PackedStringArray, t: StringTokenizer) -> void:
		if w.size() < 5:
			warn("inv line with %d tokens, the legacy loader reads 5 or more" % w.size())
		var kind := w[0] if w.size() > 0 else ""
		var known := false
		for k in KINDS:
			if (k[0] == "=" and kind == k[1]) or (k[0] == "^" and kind.begins_with(k[1])):
				known = true
				break
		if not known:
			warn("unknown inv kind '%s': the legacy loader exits the game on it; left out" % kind)
			return
		_ints(w, [1, 2], 3)
		var address := J.parseInt(w[1]) if w.size() > 1 else 0
		if map.getNode(address) == null:
			warn("inv %s on node %d, which no dir line has: left out (the legacy loader stops on it)" % [kind, address])
			return
		var before: int = map.getNrOfInventories()
		var inv = Inventory.createInventory(t, map, labyrinthName)
		if inv == null:
			return
		var replaced: bool = map.getInventory(inv.getDatabaseName()) != null
		map.putInventory(inv.getDatabaseName(), inv)
		if replaced:
			warn("a second %s on node %d has the same database name; it replaces the first in the map's list" % [kind, address])
		inv_lines.append({"line": lineCount, "words": w, "inv": inv, "replaces": replaced, "count": before})

	## Warns about the tokens at the indices that are not integers (J.parseInt
	## reads them as their float value or 0), and about missing ones.
	func _ints(w: PackedStringArray, indices, expected: int) -> void:
		if w.size() < expected:
			warn("%d values, the legacy loader reads %d" % [w.size(), expected])
		for i in indices:
			if i < w.size():
				var s := w[i].strip_edges().trim_prefix("+")
				if not s.is_valid_int():
					warn("'%s' is not an integer, read as %d" % [w[i], J.parseInt(w[i])])

	func _float(s: String) -> void:
		var f := s.strip_edges().trim_suffix("f").trim_suffix("F").trim_suffix("d").trim_suffix("D").trim_prefix("+")
		if not f.is_valid_float() and not f.is_valid_int():
			warn("'%s' is not a number, read as %s" % [s, str(J.parseFloat(s))])

	func _key(kv: String, keys: Dictionary, command: String) -> void:
		var s: Array = J.split(kv, "=")
		if s.size() < 2 or not keys.has(s[0]):
			warn("%s: unknown key in '%s' (the legacy loader stops on it)" % [command, kv])
			return
		for v in J.split(s[1], ";"):
			_float(v)


## The style of every floor of the area, and the one most floors share
## (ties: the first floor by name).
func _area_style(area: String) -> Dictionary:
	var counts := {}
	var first := {}
	var names: Array = []
	for f: String in GameResourceLoader.listFiles(MAP_DIR):
		if f.ends_with(".map") and f.get_slice("--", 0) == area:
			names.append(f.get_basename())
	names.sort()
	for n: String in names:
		var reader := MapReader.new(n + ".map")
		var sig := _signature(_style(reader))
		counts[sig] = counts.get(sig, 0) + 1
		if not first.has(sig):
			first[sig] = n
	var best := ""
	for n: String in names:
		for sig: String in counts:
			if first[sig] == n and (best == "" or counts[sig] > counts[best]):
				best = sig
	return {"shared": best, "count": counts.get(best, 0)}


static func _signature(style: DungeonStyle) -> String:
	var parts: PackedStringArray = []
	for p in style.get_property_list():
		if p["usage"] & PROPERTY_USAGE_STORAGE and p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v = style.get(p["name"])
			if v is Array and not v.is_empty() and v[0] is Resource:
				v = v.map(func(r: Resource) -> String: return r.resource_path if r != null else "")
			parts.append("%s=%s" % [p["name"], var_to_str(v)])
	return "\n".join(parts)


# ---------------------------------------------------------------------------
# Converting a floor
# ---------------------------------------------------------------------------

func _convert(floor_name: String, area_style: Dictionary) -> void:
	var reader := MapReader.new(floor_name + ".map")
	if reader.map.getNodes().is_empty():
		push_error("map_to_scene: %s has no nodes (no .map file?)" % floor_name)
		_failed += 1
		return
	var area := floor_name.get_slice("--", 0)
	var floor_part := floor_name.get_slice("--", 1)
	var style := _style(reader)
	var style_name := area if _signature(style) == area_style["shared"] else floor_name
	var style_path := "%s/%s.tres" % [_style_dir, style_name]
	var layout := _layout(reader)
	var layout_path := "%s/%s.tres" % [_layout_dir, floor_name]
	if not _save(style, style_path) or not _save(layout, layout_path):
		return
	style = ResourceLoader.load(style_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	layout = ResourceLoader.load(layout_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if not _data_only:
		for t in style.texture_names:
			_fix_import(TEXTURES + t)
	var dir := _scene_dir + "/" + area
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + "/" + floor_part + ".tscn"
	var ok := _write_scene(func(root: DungeonScene) -> void:
		_fill(root, reader, style, layout), path)
	for w in reader.warnings:
		print("  " + w)
	_warnings += reader.warnings.size()
	if ok:
		print("%s: %d cells, %d objects, style %s" % [floor_name, layout.cells.size(),
				reader.inv_lines.size(), style_name])


## The DungeonStyle of what the reader parsed.
func _style(r: MapReader) -> DungeonStyle:
	var s := DungeonStyle.new()
	for t in r.textures:
		s.texture_names.append(t.fileName)
		var res := GameResourceLoader.resolve(Values.LabyrinthTextures + t.fileName)
		if res == "":
			r.warn("missing texture %s%s (the legacy renderer stops on it)" % [Values.LabyrinthTextures, t.fileName])
		s.textures.append(load(res) as Texture2D if res != "" else null)
	var tn: Array = MapLoader.textureNorm
	s.floor_slots = Vector2i(tn[0][0], tn[0][1])
	s.wall_slots = Vector2i(tn[1][0], tn[1][1])
	s.roof_slots = Vector2i(tn[2][0], tn[2][1])
	s.carpet_slots = Vector2i(tn[3][0], tn[3][1])
	s.pillar_slots = Vector2i(tn[4][0], tn[4][1])
	var f: Array = r.settings
	s.fog = f[MapLoader.FOG]
	s.light0 = f[MapLoader.LIGHT_0]
	s.light1 = f[MapLoader.LIGHT_1]
	s.material = f[MapLoader.MATERIAL]
	s.inv_material = f[MapLoader.INV_MATERIAL]
	s.sky = f[MapLoader.SKY]
	s.carpet_floors = f[MapLoader.USE_CARPET_FLOOR]
	s.pillar_walls = f[MapLoader.USE_PILLAR_WALLS]
	s.snow = f[MapLoader.USE_SNOW]
	s.fire = f[MapLoader.USE_FIRE]
	s.rain = f[MapLoader.USE_RAIN]
	var v: Array = r.settingValues
	if s.fog:
		var fog: Array = v[MapLoader.FOG]
		s.fog_color = Color(fog[0], fog[1], fog[2], fog[3])
		s.fog_density = fog[4]
		s.fog_start = fog[5]
		s.fog_end = fog[6]
	if s.light0:
		_set_light(s, "light0", v[MapLoader.LIGHT_0])
	if s.light1:
		_set_light(s, "light1", v[MapLoader.LIGHT_1])
	if s.material:
		_set_material(s, "material", v[MapLoader.MATERIAL], r)
	if s.inv_material:
		_set_material(s, "inv_material", v[MapLoader.INV_MATERIAL], r)
	if s.sky:
		var sky: Array = v[MapLoader.SKY]
		s.sky_top = _color(sky, 0)
		s.sky_bottom = _color(sky, 4)
		for i in range(8, sky.size()):
			if sky[i] != 0.0:
				r.warn("sky: value %d is set (%s) but nothing reads it" % [i, str(sky[i])])
	if r.enemy_color != null:
		s.has_enemy_color = true
		s.enemy_color = Color(r.enemy_color[0], r.enemy_color[1], r.enemy_color[2], r.enemy_color[3])
	return s


static func _color(a: Array, i: int) -> Color:
	return Color(a[i], a[i + 1], a[i + 2], a[i + 3])


static func _set_light(s: DungeonStyle, p: String, a: Array) -> void:
	s.set(p + "_ambient", _color(a, MapLoader.LIGHT_AMBIENT))
	s.set(p + "_diffuse", _color(a, MapLoader.LIGHT_DIFFUSE))
	s.set(p + "_specular", _color(a, MapLoader.LIGHT_SPECULAR))
	var i := MapLoader.LIGHT_POSITION
	s.set(p + "_position", Vector4(a[i], a[i + 1], a[i + 2], a[i + 3]))
	i = MapLoader.LIGHT_ATTENUATION
	s.set(p + "_attenuation", Vector3(a[i], a[i + 1], a[i + 2]))


static func _set_material(s: DungeonStyle, p: String, a: Array, r: MapReader) -> void:
	s.set(p + "_ambient", _color(a, MapLoader.MATERIAL_AMBIENT))
	s.set(p + "_diffuse", _color(a, MapLoader.MATERIAL_DIFFUSE))
	s.set(p + "_specular", _color(a, MapLoader.MATERIAL_SPECULAR))
	s.set(p + "_emission", _color(a, MapLoader.MATERIAL_EMISSION))
	s.set(p + "_shininess", a[MapLoader.MATERIAL_SHININESS])
	if a[17] != 0.0 or a[18] != 0.0:
		r.warn("%s: shininess has more than one value; the extra ones are not kept" % p)


## The DungeonLayout of the reader's map, in the legacy node order.
func _layout(r: MapReader) -> DungeonLayout:
	var l := DungeonLayout.new()
	l.size = r.map.getSize()
	var mp = r.map.getMapPos()
	if mp == null:
		r.warn("no mapPos line (the legacy menu map stops on it)")
	else:
		l.map_pos = Vector2i(mp[0], mp[1])
	var nodes: Dictionary = r.map.getNodes()
	for addr in nodes:
		var n = nodes[addr]
		var c := DungeonCell.new()
		c.address = n.getAddress()
		for d in 4:
			c.neighbours[d] = n.neighbors[d].getAddress() if n.neighbors[d] != null else -1
		for d in 4:
			c.walls[d] = n.walls[d]
		c.floor = n.floor
		c.roof = n.roof
		if n.carpetFloor != null:
			c.has_carpet = true
			c.carpet_slot = n.carpetFloor.getDirection()
			c.carpet_rotation = n.carpetFloor.getRotation()
		c.extra_links = n.nrOfNeighbors - c.neighbour_count()
		l.cells.append(c)
	return l


## Fills the floor scene: the root's values, the layout, the objects and the
## rig at the first door.
func _fill(root: DungeonScene, r: MapReader, style: DungeonStyle, layout: DungeonLayout) -> void:
	root.map_name = r.labyrinthName
	root.style = style
	var steps: Array = r.getStepsToBattle()
	root.steps_to_battle = Vector2i(steps[0], steps[0] + steps[1])
	root.battle_music = PackedStringArray(r.getBattleMusic())
	var m = r.getMission()
	if m != null:
		root.has_mission = true
		root.mission_kind = m[0]
		root.mission_name = m[1]
		root.mission_entries = PackedStringArray(m.slice(2))
	(root.get_node(^"Layout") as DungeonFloor).layout = layout
	var objects := root.get_node(^"Objects")
	var rig_set := false
	for line: Dictionary in r.inv_lines:
		var o := _object(line, r, style)
		if o == null:
			continue
		# File order in the name: two lines may name the same kind and cell.
		o.name = "%02d %s" % [objects.get_child_count(), o.name]
		objects.add_child(o)
		o.owner = root
		# The View's preview (its frames and quad) is an override inside the
		# object's scene: saved for an editable instance.
		if o.has_node(^"View"):
			root.set_editable_instance(o, true)
		if not rig_set and (o is DungeonDoor or o is DungeonHinderDoor) and o.get("mark") == 0:
			_place_rig(root, line["inv"])
			rig_set = true


## The camera at a door's start: on its cell, facing away from the door
## (Graph.doorLocation), as LabyrinthPlayer's camera would look.
func _place_rig(root: DungeonScene, door) -> void:
	var p = door.getNode().getPos()
	var angle: float = Values.TO_ANGLE[Values.getCounterAngle(door.getDirection())]
	var rig := root.get_node(^"Rig") as Node3D
	rig.position = Vector3(p.getX(), 0, p.getZ())
	rig.rotation = Vector3(0, deg_to_rad(-(angle + 90.0)), 0)


## The object scene of an "inv" line with its exports, parsed from the
## line's words as Inventory.createInventory reads them.
func _object(line: Dictionary, r: MapReader, style: DungeonStyle) -> DungeonObject:
	var w: PackedStringArray = line["words"]
	var kind := w[0]
	var scene := ""
	for k in KINDS:
		if (k[0] == "=" and kind == k[1]) or (k[0] == "^" and kind.begins_with(k[1])):
			scene = k[2]
			break
	var o: DungeonObject = (load(OBJECTS + scene + ".tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var inv = line["inv"]
	o.kind = kind
	o.cell = J.parseInt(w[1])
	o.facing = Values.getCounterAngle(J.parseInt(w[2]))
	o.database_name = inv.getDatabaseName()
	o.name = "%s %d" % [kind.validate_node_name(), o.cell]
	var token := _word(w, 3, r)
	o.image = _word(w, 4, r)
	var rest: PackedStringArray = w.slice(5)
	o.position = Vector3(inv.getNode().getPos().getX(), 0, inv.getNode().getPos().getZ())
	match scene:
		"DungeonChest":
			o.frames = J.parseInt(token)
			o.content_type = J.parseInt(_word(rest, 0, r))
			o.content_name = _word(rest, 1, r)
			o.content_info = rest.slice(2)
		"DungeonRiddle":
			o.riddle_name = _word(rest, 0, r)
			o.riddle_class = _word(rest, 1, r)
			o.hinders = rest.slice(2)
		"DungeonFloorButton", "DungeonButton":
			o.frames = J.parseInt(token)
			o.hinders = rest
		"DungeonIceButton":
			o.frames = J.parseInt(token)
			o.sound = _word(rest, 0, r)
			o.hinders = rest.slice(1)
		"DungeonAegisComboButton", "DungeonIceComboButton":
			o.frames = J.parseInt(token)
			var i := 0
			o.image_nr = J.parseInt(_word(rest, i, r))
			i += 1
			if scene == "DungeonIceComboButton":
				o.sound = _word(rest, i, r)
				i += 1
			var nr := J.parseInt(_word(rest, i, r))
			i += 1
			o.buttons = rest.slice(i, i + nr)
			i += nr
			o.open_door = rest[i] if i < rest.size() else ""
		"DungeonDoor", "DungeonIfDoor":
			o.open_roads = token
			o.next_places = PackedStringArray([o.image]) + rest
			o.image = ""
		"DungeonTriggerDoor":
			o.open_roads = token
			o.trigger = o.image
			o.next_places = rest
			o.image = ""
		"DungeonLadderDoor":
			o.open_roads = token
			o.going_up = J.parseBoolean(_word(rest, 0, r))
			o.next_places = rest.slice(1)
		"DungeonHinderDoor", "DungeonHiddenHinderDoor", "DungeonRiddleDoor":
			o.frames = J.parseInt(token)
			o.next_place = _word(rest, 0, r)
			o.village_start = J.parseInt(rest[1]) if rest.size() > 1 else -1
		"DungeonAddDoor":
			o.frames = J.parseInt(token)
			o.next_place = _word(rest, 0, r)
			o.open_status = J.parseInt(_word(rest, 1, r))
			o.village_start = J.parseInt(rest[2]) if rest.size() > 2 else -1
		"DungeonBomb", "DungeonVillager", "DungeonSimpleRiddle", "DungeonMissionChest":
			o.dialogs = _dialogs(rest)
		"DungeonBoss", "DungeonSavePoint":
			pass
	if inv is InventoryDoor or inv is HinderDoor:
		o.mark = inv.getDoorIndex()
	_preview(o, inv, r)
	return o


func _word(w: PackedStringArray, i: int, r: MapReader) -> String:
	if i < w.size():
		return w[i]
	r.warn("token %d missing, read as \"\"" % (i + 2))
	return ""


## The dialogs as the legacy constructors parse them (Parser.getArgument and
## getText; [speaker, line 1, line 2]).
static func _dialogs(rest: PackedStringArray) -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	var t := StringTokenizer.new(" ".join(rest))
	while t.hasMoreTokens():
		var s: Array = Parser.getArgument(t.nextToken())
		var speaker: String = s[0]
		s = Parser.getText(t, s[1])
		out.append(PackedStringArray([speaker, s[0], s[1] if s.size() > 1 else ""]))
	return out


## The object's View in the editor: its frames, and the quad the legacy
## object draws at its default state (Inventory.setSettings and the size of
## its first image, as initDraw computes them).
func _preview(o: DungeonObject, inv, r: MapReader) -> void:
	var view := o.get_node_or_null(^"View") as AnimatedSprite3D
	if view == null:
		return
	if inv.image == null or inv.image == "":
		return
	inv.initDraw(null)
	var paths: Array = []
	for i in inv.images.size():
		var res := GameResourceLoader.resolve(inv.images[i])
		if res == "":
			r.warn("missing image %s (the legacy object draws nothing)" % inv.images[i])
			return
		paths.append(res)
	if not _data_only:
		view.sprite_frames = _write_frames(inv.image, paths, r)
	# The state of a new game: a hinder door is locked (Graph.updateMap gives
	# it status 0), the others show their current frame.
	var frame: int = inv.currentTex
	if inv is HinderDoor:
		frame = 1
	elif inv is FloorButton:
		frame = inv.status
	frame = clampi(frame, 0, paths.size() - 1)
	var size := Vector2((load(paths[frame]) as Texture2D).get_size())
	view.frame = frame
	view.transform = o.transform.affine_inverse() * DungeonObject.view_transform(inv, size)
	view.flip_h = DungeonObject.view_flipped(inv)
	view.visible = inv.currentTex != Object2D.INVISIBLE


## The SpriteFrames of an image series ("default", one frame per image).
func _write_frames(image: String, paths: Array, r: MapReader) -> SpriteFrames:
	var key := image.get_basename() if image.get_extension() != "" else image
	var path := "%s/%s.tres" % [FRAMES_DIR, key]
	if _frames.has(key):
		if _frames[key] != paths.size():
			r.warn("%s with %d frames, elsewhere %d: the frames are those of the first" % [image, paths.size(), _frames[key]])
		return load(path)
	_frames[key] = paths.size()
	# The View shows the frame the legacy object chose; nothing plays.
	var frames := SpriteFrames.new()
	frames.set_animation_loop(&"default", false)
	for p: String in paths:
		frames.add_frame(&"default", load(p))
		_fix_import(p.trim_prefix("res://"))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	ResourceSaver.save(frames, path)
	return load(path)


## Sets detect_3d/compress_to to 0 (disabled) in an image's .import file:
## otherwise the editor re-imports a texture it sees on a 3D material as VRAM
## compressed with mipmaps, which would change the legacy drawing too.
func _fix_import(image: String) -> void:
	var res := GameResourceLoader.resolve(image)
	if res == "" or _imports.has(res):
		return
	_imports[res] = true
	var path := ProjectSettings.globalize_path(res + ".import")
	var text := FileAccess.get_file_as_string(path)
	if text.contains("detect_3d/compress_to=1"):
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text.replace("detect_3d/compress_to=1", "detect_3d/compress_to=0"))
		f.close()


# ---------------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------------

func _save(res: Resource, path: String) -> bool:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("map_to_scene: could not write %s (%s)" % [path, error_string(err)])
		_failed += 1
		return false
	return true


## Writes an inherited scene of the template: a bootstrap file names it, the
## instance gets an edit state so that pack() keeps the inheritance.
func _write_scene(fill: Callable, path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[gd_scene format=3]\n\n[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]\n\n[node name=\"%s\" instance=ExtResource(\"1_base\")]\n"
			% [TEMPLATE, path.get_file().get_basename()])
	f.close()
	var bootstrap: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	var root: DungeonScene = bootstrap.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	fill.call(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("map_to_scene: could not write %s (%s)" % [path, error_string(err)])
		_failed += 1
		return false
	_canonicalize(path)
	return true


## Drops the node unique_ids (and the node references made of them): Godot
## 4.7 picks them at random, and the node paths say the same.
func _canonicalize(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var ids := RegEx.create_from_string(" (unique_id=[0-9]+|parent_id_path=PackedInt32Array\\([0-9, ]*\\))")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(ids.sub(text, "", true))
	f.close()
