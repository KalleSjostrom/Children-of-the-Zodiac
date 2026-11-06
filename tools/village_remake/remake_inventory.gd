extends SceneTree
## Lists what a village place has that a remake must keep (the
## village-remake skill, step 1): per variant scene its doors, signs, loot,
## spawns, villagers (start and walk from their .char files), animated
## objects and particle systems; the obstacle groups of its .vil file (the
## comments name buildings; saved in obstacle_groups.json when the .vil files
## were deleted); the cutscenes that take place in it, with their
## actors' paths; the doors of other places that return into it (to_pos);
## the places named "<Place> - ...".
##
## godot --headless --path . --script res://tools/village_remake/remake_inventory.gd -- <Place> <out dir>
##
## Writes <out dir>/inventory.txt (numbered), inventory.json and
## inventory.png (the place's background at half size, every item marked
## with its number). Changes nothing else.

const Lib := preload("res://tools/village_remake/remake_lib.gd")
const Draw := preload("res://tools/village_remake/remake_draw.gd")
const VIEW_SCALE := 0.5
## The obstacle groups of each place's "<Place> - 0.vil" (its "o" lines under
## their comment headings: name, rect [x1, y1, x2, y2], count), saved from
## the .vil files before they were deleted.
const OBSTACLE_GROUPS := "res://tools/village_remake/obstacle_groups.json"

var _items: Array = []
var _lines := PackedStringArray()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: -- <Place> <out dir>")
		quit(1)
		return
	var place := args[0]
	var out_dir := args[1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var dir := Lib.SCENES + place + "/"
	if not DirAccess.dir_exists_absolute(dir):
		printerr("No place %s" % dir)
		quit(1)
		return
	var base: VillageScene = (load(dir + place + ".tscn") as PackedScene).instantiate()
	_lines.append("Place %s: size %s, folder %s, village_name %s" % [place, base.size, base.folder_name, base.village_name])
	_lines.append("Overhead pieces in the base scene: %d" % base.get_node("Overhead").get_child_count())
	var variants := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool:
		return f.ends_with(".tscn") and f != place + ".tscn")
	variants.sort()
	var json := {"place": place, "size": [base.size.x, base.size.y], "variants": {}, "features": {}}
	for file: String in variants:
		var scene: VillageScene = (load(dir + file) as PackedScene).instantiate()
		json["variants"][file] = _variant(scene, json["features"])
		scene.free()
	base.free()
	json["obstacle_groups"] = _obstacle_groups(place)
	json["sequences"] = _sequences(place, json["features"])
	json["returns"] = _returns(place)
	json["related"] = Array(DirAccess.get_directories_at(Lib.SCENES)).filter(func(d: String) -> bool:
		return d.begins_with(place + " - "))
	_lines.append("")
	_lines.append("Related places: %s" % ", ".join(json["related"]))
	FileAccess.open(out_dir.path_join("inventory.txt"), FileAccess.WRITE).store_string("\n".join(_lines) + "\n")
	FileAccess.open(out_dir.path_join("inventory.json"), FileAccess.WRITE).store_string(JSON.stringify(json, "\t"))
	_draw_map(dir + place + ".tscn", json, out_dir.path_join("inventory.png"))
	print("Wrote inventory.txt, inventory.json, inventory.png to %s (%d items)" % [out_dir, _items.size()])
	quit()


## Adds a numbered item; returns its number.
func _item(kind: String, pos: Vector2, text: String) -> int:
	_items.append({"kind": kind, "pos": pos})
	_lines.append("%3d  %s" % [_items.size(), text])
	return _items.size()


## The features of a variant (keys "<group>/<node name without its number>")
## into features (shared by the variants: the first one's data, plus the
## variants it is in); returns the variant's root data.
func _variant(scene: VillageScene, features: Dictionary) -> Dictionary:
	var file := scene.scene_file_path.get_file()
	_lines.append("")
	_lines.append("== %s: day %s, wind %s %s, buildings: %s" % [file, scene.day, scene.has_wind, scene.wind_force,
		", ".join(scene.buildings.map(func(b: VillageBuilding) -> String: return b.store_name))])
	for group in ["Spawns", "Doors", "Signs", "Loot", "Actors", "Ground", "Effects"]:
		for node: Node in scene.get_node(group).get_children():
			var key := "%s/%s" % [group, _bare(node.name)]
			if features.has(key):
				features[key]["variants"].append(file)
				_lines.append("     %s (as above)" % key)
				continue
			var f := _feature(group, node, scene)
			f["variants"] = [file]
			f["number"] = _item(group, Lib.vec(f["pos"]), "%s at %s  %s" % [key, Vector2i(Lib.vec(f["pos"])), f.get("text", "")])
			features[key] = f
	return {"day": scene.day, "has_wind": scene.has_wind, "buildings": scene.buildings.map(func(b: VillageBuilding) -> String: return b.store_name)}


static func _bare(node_name: String) -> String:
	var space := node_name.find(" ")
	return node_name.substr(space + 1) if space > 0 and node_name.left(space).is_valid_int() else node_name


func _feature(group: String, node: Node, scene: VillageScene) -> Dictionary:
	var p: Vector2 = node.position
	var f := {"pos": [p.x, p.y]}
	if node is VillageDoor:
		var d: VillageDoor = node
		f["text"] = "door %s -> %s radius %d facing %s%s" % [d.kinds, d.targets, d.radius, d.directions,
			("  sign: " + " / ".join(d.sign_lines)) if not d.sign_lines.is_empty() else ""]
	elif node is VillageSign:
		var s: VillageSign = node
		f["text"] = "sign radius %d facing %s: %s" % [s.radius, s.directions, " / ".join(s.lines)]
	elif node is VillageLoot:
		var l: VillageLoot = node
		f["text"] = "loot %s facing %s: %s" % [l.loot_name, l.directions, " / ".join(l.lines)]
	elif node is VillageSpawn:
		var s: VillageSpawn = node
		f["text"] = "spawn %d facing %d" % [s.number, s.facing]
	elif node is ActorView and node.role == ActorView.Role.VILLAGER:
		var a: ActorView = node
		var c := Lib.read_char(a.villager_folder, a.villager_name)
		if c["start"] != null:
			f["pos"] = c["start"]
		var walk: PackedStringArray = c["walk"]
		var moves := Array(walk).filter(func(w: String) -> bool: return w.split(" ", false)[2] != "true")
		f["villager"] = a.villager_name
		f["walk"] = walk
		f["standing"] = moves.is_empty()
		f["statuses"] = Array(a.statuses)
		f["text"] = "villager %s (%s)%s, %s: %s" % [a.villager_name, c["image"],
			" statuses %s" % a.statuses if not a.statuses.is_empty() else "",
			"standing" if moves.is_empty() else "walking", " | ".join(walk)]
	elif node is ActorView:
		var a: ActorView = node
		f["text"] = "animated object %s (%d images)" % [a.object_name, a.image_count]
	elif node is LegacyParticles2D:
		var s: LegacyParticles2D = node
		f["text"] = "particle system %s, layer %d" % [s.system_name, s.layer]
	return f


## The "o" lines of the place's first .vil file under their comment headings:
## [{"name", "rect": [x1, y1, x2, y2] (the bounds), "count"}]. The .vil files
## are deleted (plan 13, decision 5): their groups were saved in
## OBSTACLE_GROUPS (the scenes' obstacles have no headings).
func _obstacle_groups(place: String) -> Array:
	var groups: Array = []
	if not FileAccess.file_exists(OBSTACLE_GROUPS):
		return groups
	var saved = JSON.parse_string(FileAccess.get_file_as_string(OBSTACLE_GROUPS))
	if not (saved is Dictionary) or not saved.has(place):
		return groups
	for s: Dictionary in saved[place]:
		var a: Array = s["rect"]
		groups.append({"name": String(s["name"]), "count": int(s["count"]),
				"rect": [int(a[0]), int(a[1]), int(a[2]), int(a[3])]})
	_lines.append("")
	_lines.append("== Obstacle groups (.vil comments)")
	for g: Dictionary in groups:
		var r: Array = g["rect"]
		g["number"] = _item("obstacles", Vector2(r[0], r[1]), "obstacles \"%s\": %d rects within %s" % [g["name"], g["count"], g["rect"]])
	return groups


## The cutscenes in place, their actors and traced paths (villagers without
## a pos start at their .char start).
func _sequences(place: String, features: Dictionary) -> Dictionary:
	var starts := {}
	for key: String in features:
		var f: Dictionary = features[key]
		if f.has("villager"):
			starts[f["villager"]] = Lib.vec(f["pos"])
	var out := {}
	_lines.append("")
	_lines.append("== Cutscenes in %s" % place)
	for name in Lib.sequences_in(place):
		var text := FileAccess.get_file_as_string(Lib.SEQUENCES + name + ".seq")
		var parsed := Lib.parse_sequence(text)
		var seq_starts := starts.duplicate()
		var runners := Lib.runners(place, name)
		if not runners.is_empty() and starts.has(runners[0]):
			seq_starts.merge(Lib.party_starts(starts[runners[0]]), true)
		var paths := Lib.sequence_paths(parsed, seq_starts)
		var actors: Array = []
		for a: Dictionary in parsed["actors"]:
			var path: PackedVector2Array = paths.get(a["index"], PackedVector2Array())
			actors.append({"name": a["name"], "pos": [a["pos"].x, a["pos"].y] if a["pos"] != null else null,
				"path": Array(path).filter(func(p: Vector2) -> bool: return not is_nan(p.x)).map(func(p: Vector2) -> Array: return [p.x, p.y])})
		var first := Vector2.ZERO
		for a: Dictionary in actors:
			if not a["path"].is_empty():
				first = Lib.vec(a["path"][0])
				break
		var n := _item("sequence", first, "cutscene %s (status %s%s): %s%s" % [name, Lib._arg(text, "status", "-").trim_prefix("\"").trim_suffix("\""),
			", run by %s: the party starts beside them" % ", ".join(runners) if not runners.is_empty() else "",
			", ".join(actors.map(func(a: Dictionary) -> String:
				return "%s%s" % [a["name"].get_file(), "@%s" % Vector2i(Lib.vec(a["pos"])) if a["pos"] != null else ""])),
			"  (screen_to/screen_pos lines: %s)" % parsed["screen"] if not parsed["screen"].is_empty() else ""])
		out[name] = {"number": n, "actors": actors, "runners": Array(runners), "from_village": parsed["from_village"]}
	return out


## The doors of other places that bring the player back into place at a
## to_pos ([y, x, direction, start]), from the scene files' text.
func _returns(place: String) -> Array:
	var out: Array = []
	var block_re := RegEx.create_from_string("\\[node name=\"([^\"]*)\" parent=\"Doors\"[^\\]]*\\]([^\\[]*)")
	_lines.append("")
	_lines.append("== Doors of other places that return into %s" % place)
	for d in DirAccess.get_directories_at(Lib.SCENES):
		if d == place:
			continue
		for file in DirAccess.get_files_at(Lib.SCENES + d):
			if not file.ends_with(".tscn"):
				continue
			var text := FileAccess.get_file_as_string(Lib.SCENES + d + "/" + file)
			for m in block_re.search_all(text):
				var body := m.get_string(2)
				var targets := RegEx.create_from_string("targets = PackedStringArray\\(([^)]*)\\)").search(body)
				var to_pos := RegEx.create_from_string("to_pos = PackedFloat64Array\\(([^)]+)\\)").search(body)
				if targets == null or to_pos == null or not targets.get_string(1).replace("_", " ").contains("\"%s\"" % place):
					continue
				var v := to_pos.get_string(1).split(",")
				var at := Vector2(float(v[1]), float(v[0]))
				var n := _item("return", at, "return from %s/%s door %s to x %d y %d facing %s" % [d, file, m.get_string(1), at.x, at.y, v[2].strip_edges()])
				out.append({"number": n, "from": "%s/%s" % [d, file], "door": m.get_string(1), "pos": [at.x, at.y]})
	return out


## The place's background at VIEW_SCALE with every item's number, the
## villagers' walks and the cutscene paths.
func _draw_map(base_path: String, json: Dictionary, out: String) -> void:
	var base: VillageScene = (load(base_path) as PackedScene).instantiate()
	var texture: Texture2D = base.get_node("Background").texture
	var image := texture.get_image()
	base.free()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(int(image.get_width() * VIEW_SCALE), int(image.get_height() * VIEW_SCALE), Image.INTERPOLATE_BILINEAR)
	var colors := {"Doors": Color.YELLOW, "Signs": Color.CYAN, "Loot": Color.MAGENTA, "Spawns": Color.WHITE,
		"Actors": Color.ORANGE, "Ground": Color.RED, "Effects": Color.RED, "obstacles": Color(1, 0.3, 0.3),
		"sequence": Color(0.4, 0.6, 1), "return": Color.WHITE}
	for g: Dictionary in json["obstacle_groups"]:
		var r: Array = g["rect"]
		Draw.rect_outline(image, Rect2(Vector2(r[0], r[1]) * VIEW_SCALE, Vector2(r[2] - r[0], r[3] - r[1]) * VIEW_SCALE), Color(1, 0.3, 0.3, 0.8))
	for name: String in json["sequences"]:
		for a: Dictionary in json["sequences"][name]["actors"]:
			var pts := PackedVector2Array()
			for p in a["path"]:
				pts.append(Lib.vec(p) * VIEW_SCALE)
			Draw.polyline(image, pts, Color(0.4, 0.6, 1, 0.9), false, 2)
	for key: String in json["features"]:
		var f: Dictionary = json["features"][key]
		if f.has("walk") and not f["standing"]:
			var pts: PackedVector2Array = Lib.walk_points(Lib.vec(f["pos"]), f["walk"])["points"]
			for i in pts.size():
				pts[i] *= VIEW_SCALE
			Draw.polyline(image, pts, Color(0.3, 1, 0.3, 0.9), false, 2)
	for i in _items.size():
		var it: Dictionary = _items[i]
		Draw.marker(image, it["pos"] * VIEW_SCALE, i + 1, colors.get(it["kind"], Color.WHITE))
	image.save_png(out)
