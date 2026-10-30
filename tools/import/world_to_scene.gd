extends SceneTree
## Converts the world maps and the airship maps of maps/Landscape into scenes
## (docs/MODERNIZATION_PLAN.md 9.1; the conventions are in
## docs/ARCHITECTURE.md section 13, how to convert a map again in its
## "Converting a map again"). Run headless from the project root; the
## wrapper tools/import/world_to_scene.sh runs the two stages with Godot's
## import between them:
##
##   godot --headless --path . --script res://tools/import/world_to_scene.gd -- [options] <file.map>...
##
## For each file it writes:
##   scenes/world_map/<file>.tscn       inherits WorldMapScene.tscn: the background,
##                                      the roads (world*.map) and the nodes in file
##                                      order, the top layer, the night layer
##   scenes/world_map/<image>.png       the background's 256 px tiles in one image
##                                      (West.png, East.png, North.png, World1.png,
##                                      World2.png)
## and, from world0.map, world1.map and world2.map:
##   resources/world_map/place_index.tres   the map of every world map node
##                                      (LandscapeLoader.PlaceMapLoader's index)
##
## Options:
##   --stage=art     only the stitched backgrounds (with .import files: lossless,
##                   no mipmaps; tools/import/tile_art.gd, as the village converter)
##   --stage=scenes  only the scenes and the index; the backgrounds must be
##                   imported first (godot --headless --path . --import)
##   --all           every .map file of maps/Landscape
##
## A world*.map file is read as LandscapeLoaderMapLoader reads it (background,
## node, road, co, oc), a land*.map file as AirLandscapeLoaderMapLoader does
## (start, node), with the legacy tokenizer (AbstractMapLoader) and parsers
## (J.parseInt), so that every value is the legacy loader's. Child order is
## file order: getNode returns the first node of a name, getRoad the first
## road of an address. The scenes are saved with PackedScene.pack() and
## ResourceSaver.save(); the node unique_ids (random in Godot 4.7) are left
## out, so that converting twice writes the same files.
## tools/import/verify_world_map.gd checks the result.

const TileArt := preload("res://tools/import/tile_art.gd")
const TEMPLATE := "res://scenes/world_map/WorldMapScene.tscn"
const SCENE_DIR := "res://scenes/world_map"
const MAP_DIR := "maps/Landscape/"
const IMAGES := "res/Landscape/"
## LandscapeLoader.PlaceMapLoader's files, in its order.
const WORLD_FILES: Array[String] = ["world0.map", "world1.map", "world2.map"]
## The size DoubleBackground's tiles cover on the world map and the airship
## (Values.ORIGINAL_RESOLUTION).
const SCREEN := Vector2i(1024, 768)
## AirLandscapeLoaderMapLoader's zones ("start <zone>") and Landscape's values.
const ZONES := {"west": 0, "east": 1, "north": 2}

var _road_scene: PackedScene = load("res://scenes/world_map/WorldMapRoad.tscn")
var _node_scene: PackedScene = load("res://scenes/world_map/WorldMapNode.tscn")
var _air_node_scene: PackedScene = load("res://scenes/world_map/AirshipNode.tscn")

var _art := true
var _scenes := true
var _failed := 0


func _init() -> void:
	var files: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a == "--stage=art":
			_scenes = false
		elif a == "--stage=scenes":
			_art = false
		elif a == "--all":
			for f in GameResourceLoader.listFiles(MAP_DIR):
				if f.ends_with(".map") and not files.has(f):
					files.append(f)
		else:
			files.append(a)
	if files.is_empty():
		print("usage: world_to_scene.gd -- [--stage=art|scenes] [--all] <file.map>...")
		quit(2)
		return
	files.sort()
	for file in files:
		_convert(file)
	if _scenes:
		_write_index()
	print("CONVERTED %d maps, %d failed" % [files.size(), _failed])
	quit(1 if _failed > 0 else 0)


func _convert(file: String) -> void:
	var reader := LandscapeReader.new(file.begins_with("land"))
	reader.parseFile(MAP_DIR + file)
	var m := reader.model
	m["file"] = file
	for w in reader.warnings:
		print("  %s: %s" % [file, w])
	if reader.failed:
		push_error("world_to_scene: %s: not converted (see the warnings)" % file)
		_failed += 1
		return
	if m["airship"]:
		# AirLandscapeLoader.loadImages: World/World<airship status>, and the map
		# is land<airship status>.map.
		var status := file.get_basename().trim_prefix("land")
		m["background"] = "World" + status
		_resolve_art(m, "World/World" + status, "World", false)
	else:
		if m["background"] == "":
			push_error("world_to_scene: %s has no background line" % file)
			_failed += 1
			return
		# LandscapeLoader.loadImages(name): <name>/<name>, the top layer of <name>.
		_resolve_art(m, m["background"] + "/" + m["background"], m["background"], true)
	if _art and m["tiles"] != "":
		TileArt.stitch(m["tiles"], m["tile_ext"], SCREEN, _background_path(m), file)
	if _scenes:
		var path := SCENE_DIR + "/" + file.get_basename() + ".tscn"
		if not _write_scene(_fill.bind(m), path):
			return
	print("%s: background %s, %d nodes, %d roads, %d top layer pieces%s" % [file, m["background"],
			m["nodes"].size(), m["roads"].size(), m["top"].size(),
			", night layer " + str(m["night_top"]).get_file() if m["night_top"] != "" else ""])


# ---------------------------------------------------------------------------
# Reading a .map file
# ---------------------------------------------------------------------------

## LandscapeLoaderMapLoader.executeCommand (a world map) or
## AirLandscapeLoaderMapLoader.executeCommand (an airship map), recording
## what each command reads instead of building the map; and PlaceMapLoader's
## name of each node line (its last token).
class LandscapeReader extends AbstractMapLoader:
	var model := {"background": "", "nodes": [], "roads": [], "index_names": []}
	var warnings: Array[String] = []
	## A file the scene cannot hold as the legacy loader reads it.
	var failed := false
	var _airship := false
	var _zone := 0
	var _road = null
	var _names := {}

	func _init(airship: bool) -> void:
		_airship = airship
		model["airship"] = airship

	func _warn(text: String, fatal := false) -> void:
		warnings.append("line %d: %s%s" % [lineCount, text, " (not converted)" if fatal else ""])
		failed = failed or fatal

	func _int(t: StringTokenizer) -> int:
		var s := t.nextToken()
		var value := J.parseInt(s)
		if not s.strip_edges().trim_prefix("+").is_valid_int():
			_warn("'%s' is not an integer, read as %d (as by the legacy loader)" % [s, value])
		return value

	func executeCommand(command: String, tok: StringTokenizer) -> void:
		if command == "node":
			_node(tok)
		elif _airship:
			if command == "start":
				var zone := tok.nextToken()
				if ZONES.has(zone):
					_zone = ZONES[zone]
				else:
					_warn("unknown zone '%s': the previous one stays (as in the legacy loader)" % zone)
			elif command != "end":
				_warn("'%s' ignored (as by the legacy loader)" % command)
		elif command == "background":
			if model["background"] != "" or not model["nodes"].is_empty():
				_warn("a background line after the first or after a node", true)
			model["background"] = tok.nextToken()
		elif command == "road":
			var road := {"address": _int(tok)}
			road["source"] = tok.nextToken().replace("_", " ")
			road["direction_to_destination"] = _int(tok)
			road["destination"] = tok.nextToken().replace("_", " ")
			road["direction_to_source"] = _int(tok)
			road["points"] = []
			road["has_oc"] = false
			for end in ["source", "destination"]:
				if not _names.has(String(road[end]).to_lower()):
					_warn("road %d: no node '%s' before it" % [road["address"], road[end]], true)
			for r: Dictionary in model["roads"]:
				if r["address"] == road["address"]:
					_warn("road %d: a second road of this address (getRoad finds the first)" % road["address"])
			model["roads"].append(road)
			_road = road
		elif command == "co" or command == "oc":
			if _road == null:
				_warn("'%s' before any road" % command, true)
			elif _road["has_oc"]:
				_warn("'%s' after the road's oc line" % command, true)
			elif command == "co":
				var x := _int(tok)
				var y := _int(tok)
				_road["points"].append(Vector2i(x, y))
			else:
				_road["has_oc"] = true
		elif command != "end":
			_warn("'%s' ignored (as by the legacy loader)" % command)

	## LandscapeLoaderMapLoader / AirLandscapeLoaderMapLoader: x, y, type and
	## name; PlaceMapLoader takes the line's last token as the name.
	func _node(tok: StringTokenizer) -> void:
		if not _airship and not model["roads"].is_empty():
			_warn("a node after the roads", true)
		var line := StringTokenizer.new(lastLine)
		line.nextToken()
		var last := ""
		while line.hasMoreTokens():
			last = line.nextToken()
		model["index_names"].append(last)
		var node := {"x": _int(tok), "y": _int(tok)}
		node["kind"] = tok.nextToken()
		node["name"] = tok.nextToken().replace("_", " ")
		node["zone"] = _zone
		if last.replace("_", " ") != node["name"]:
			_warn("node '%s': PlaceMapLoader names it '%s'" % [node["name"], last])
		var key := String(node["name"]).to_lower()
		if _names.has(key):
			_warn("a second node '%s' (getNode finds the first)" % node["name"])
		_names[key] = true
		model["nodes"].append(node)


# ---------------------------------------------------------------------------
# Art
# ---------------------------------------------------------------------------

## DoubleBackground.setLandscapeImages([image, top], night): the image is
## doit's (a .png when there is one, else the .jpg), drawn as its tile folder
## (cutImage: <image>folder/x0y0 exists) or as the image itself; the top
## layer is top/top.info of the top folder; on a world map the night layer is
## doit's nightTop ("<image> at Night - 1.png", else standardOvernight.png).
func _resolve_art(m: Dictionary, image_name: String, top_folder: String, world: bool) -> void:
	var rl := GameResourceLoader.getResourceLoader()
	var png := IMAGES + image_name + ".png"
	var image := png
	if not (rl.exists(png) or (rl.exists(IMAGES + image_name + "folder")
			and rl.exists(IMAGES + image_name + "folder/x0y0.png"))):
		image = IMAGES + image_name + ".jpg"
	var ext := ".jpg" if image.ends_with(".jpg") else ".png"
	var tiles := image.replace(ext, "folder")
	m["image"] = image
	m["tiles"] = tiles if rl.exists(tiles + "/x0y0" + ext) else ""
	m["tile_ext"] = ext
	m["top"] = TileArt.top_layer(IMAGES, top_folder)
	m["night_top"] = ""
	if world:
		if rl.exists(IMAGES + image_name + " at Night.jpg") or rl.exists(IMAGES + image_name + " at Nightfolder"):
			print("  %s: a night background (%s at Night) is not supported: the scene has the day one"
					% [m["file"], image_name])
		var top := IMAGES + image_name + " at Night - 1.png"
		m["night_top"] = top if rl.exists(top) else IMAGES + "standardOvernight.png"


func _background_path(m: Dictionary) -> String:
	return SCENE_DIR + "/" + String(m["image"]).get_file().get_basename() + ".png"


# ---------------------------------------------------------------------------
# The scene
# ---------------------------------------------------------------------------

func _fill(root: WorldMapScene, m: Dictionary) -> void:
	root.map_file = m["file"]
	root.background_name = m["background"]
	root.airship = m["airship"]
	var background: Sprite2D = root.get_node("Background")
	background.texture = load(_background_path(m)) if m["tiles"] != "" else _texture(m["image"])
	for i in m["roads"].size():
		var r: Dictionary = m["roads"][i]
		var road: WorldMapRoad = _road_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		road.name = _node_name("%02d road %d %s - %s" % [i, r["address"], r["source"], r["destination"]])
		road.address = r["address"]
		road.source = r["source"]
		road.direction_to_destination = r["direction_to_destination"]
		road.destination = r["destination"]
		road.direction_to_source = r["direction_to_source"]
		road.has_oc = r["has_oc"]
		var curve := Curve2D.new()
		for p: Vector2i in r["points"]:
			curve.add_point(Vector2(p))
		road.curve = curve
		_own(root, root.get_node("Roads"), road)
	for i in m["nodes"].size():
		var n: Dictionary = m["nodes"][i]
		var node: Marker2D = (_air_node_scene if m["airship"] else _node_scene).instantiate(
				PackedScene.GEN_EDIT_STATE_INSTANCE)
		node.name = _node_name("%02d %s" % [i, n["name"]])
		node.position = Vector2(n["x"], n["y"])
		node.kind = n["kind"]
		node.node_name = n["name"]
		if m["airship"]:
			node.zone = n["zone"]
		_own(root, root.get_node("Nodes"), node)
	var overhead := root.get_node("Overhead")
	for i in m["top"].size():
		var piece := Sprite2D.new()
		piece.name = "%02d %s" % [i, String(m["top"][i][1]).get_file().get_basename()]
		piece.centered = false
		piece.use_parent_material = true
		piece.position = Vector2(m["top"][i][0])
		piece.texture = _texture(m["top"][i][1])
		_own(root, overhead, piece)
	if m["night_top"] != "":
		var night: Sprite2D = root.get_node("Night")
		night.texture = _texture(m["night_top"])


## PlaceMapLoader's index: world0.map, world1.map, then world2.map, each node
## line's last token (Organizer.convert) -> its file; a later file wins.
func _write_index() -> void:
	var index := WorldMapIndex.new()
	for file in WORLD_FILES:
		var reader := LandscapeReader.new(false)
		reader.parseFile(MAP_DIR + file)
		for name: String in reader.model["index_names"]:
			var key := Organizer.convert(name)
			if index.maps.has(key) and index.maps[key] != file:
				print("  index: '%s' of %s is also on %s (the later file wins, as in PlaceMapLoader)"
						% [key, index.maps[key], file])
			index.maps[key] = file
	DirAccess.make_dir_recursive_absolute(WorldMapIndex.PATH.get_base_dir())
	var err := ResourceSaver.save(index, WorldMapIndex.PATH)
	if err != OK:
		push_error("world_to_scene: could not write %s (%s)" % [WorldMapIndex.PATH, error_string(err)])
		_failed += 1
		return
	print("index: %d nodes (%s)" % [index.maps.size(), WorldMapIndex.PATH])


## Writes an inherited scene of the template: a bootstrap file names it, the
## instance gets an edit state so that pack() keeps the inheritance.
func _write_scene(fill: Callable, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[gd_scene format=3]\n\n[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]\n\n[node name=\"%s\" instance=ExtResource(\"1_base\")]\n"
			% [TEMPLATE, path.get_file().get_basename()])
	f.close()
	var bootstrap: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	var root: WorldMapScene = bootstrap.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	fill.call(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("world_to_scene: could not write %s (%s)" % [path, error_string(err)])
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


func _texture(legacy_path: String) -> Texture2D:
	var res := GameResourceLoader.resolve(legacy_path)
	if res == "":
		print("  missing image " + legacy_path)
		return null
	return load(res)


func _own(root: Node, parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = root


static func _node_name(s: String) -> String:
	return s.validate_node_name().strip_edges()
