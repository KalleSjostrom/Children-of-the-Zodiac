extends SceneTree
## Builds a village remake from its layout (the village-remake skill, step 4):
## res://proto/villages/<remake>/layout.json -> the place's scenes, its
## background and overhead pieces, the views of it (another place that shows
## part of it, as Alares - Celis does Alares at night), and the cutscene
## copies. VillageRemake loads them with --village=<remake>.
##
## godot --headless --path . --script res://tools/village_remake/remake_build.gd -- <remake>
## godot --headless --path . --import      (then: the new PNGs get .import files)
##
## Every scene is the default scene's text with:
## * the background, the overhead pieces and the obstacles replaced (the base
##   scene of the place and of each view; variants lose theirs);
## * each door, sign, loot, spawn, actor and particle system moved to its
##   layout "features" entry, keyed "<parent>/<node name without its number>"
##   ("Doors/Inn", "Actors/Uri"): [x, y] moves it, null drops it, a villager's
##   {"pos": [x, y], "walk": [...]} also gives its walk (left out: its .char
##   walk). A feature without an entry stops the build: nothing is left at
##   its old place by accident;
## * a night layer (a view's or the place's "night": {"windows": [[x1, y1,
##   x2, y2], ...], "glows": [...]}) in place of the default one: light
##   around each window and glow; a view's windows also get lit glass in its
##   background and its overhead pieces (a night view, like the default
##   Alares - Celis at Night.png). A window's rect is its panes (inside the
##   frame, x2 and y2 excluded).
## Writes under ROOT/<remake>/ only, and lists what it wrote.

const Lib := preload("res://tools/village_remake/remake_lib.gd")
const FEATURE_GROUPS: PackedStringArray = ["Spawns", "Doors", "Signs", "Loot", "Actors", "Ground", "Effects"]
## The default night layer's colours (res/Village/Alares - Celis/Alares -
## Celis at Night - 1.png): the blue over everything, the light of a window,
## and how far (layer pixels) a window's light fades out.
const NIGHT := Color(0.106, 0.051, 0.824, 0.431)
const WINDOW := Color(0.89, 0.953, 0.07, 0.188)
const WINDOW_FADE := 6.0
## Lit glass (the panes of the default night background): a window's glass
## pixels (dark and not warm or green: not its frame, muntins or flowers)
## become LIT, their lighter reflections up to LIT_HIGH.
const LIT := Color(0.85, 0.91, 0.27)
const LIT_HIGH := Color(0.93, 0.95, 0.55)

var _remake := ""
var _dir := ""
var _errors := PackedStringArray()
var _written := PackedStringArray()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Usage: -- <remake>")
		quit(1)
		return
	_remake = args[0]
	_dir = Lib.ROOT + _remake + "/"
	var layout := Lib.load_layout(_remake)
	if layout.is_empty():
		quit(1)
		return
	var place: String = layout["place"]
	var size := Lib.veci(layout["size"])
	var image := Lib.village_image(_remake, layout)
	var parts := Lib.all_parts(layout, image)
	var blocked := Lib.blocked_mask(layout, parts, image)
	var rects := Lib.mask_to_rects(blocked)
	var pieces := _overhead_pieces(layout, parts, image, place)
	_save_png(image, place + "/" + place + ".png")
	var entries := {"from": PackedVector2Array(), "to": PackedVector2Array()}
	for e: Dictionary in layout.get("entries", []):
		entries["from"].append(Lib.vec(e["from"]))
		entries["to"].append(Lib.vec(e["to"]))
	var main := {"place": place, "size": size, "origin": Vector2i.ZERO, "features": layout.get("features", {}),
		"night": layout.get("night", {}), "background": _dir + place + "/" + place + ".png",
		"pieces": pieces, "rects": rects, "entries": entries}
	_build_place(main)
	for view: Dictionary in layout.get("views", []):
		_build_view(view, main, image)
	_build_sequences(layout)
	if not _errors.is_empty():
		printerr("\n".join(_errors))
		printerr("Build stopped: %d problems" % _errors.size())
		quit(1)
		return
	print("Overhead pieces %d, obstacles %d (blocked feet area %d px)" % [pieces.size(), rects.size(), blocked.count()])
	print("Wrote:\n  " + "\n  ".join(_written))
	print("Run godot --headless --path . --import next, then remake_check.gd.")
	quit()


## The overhead pieces: one PNG per object with an overhead part (its
## pixels of the background, the rest transparent), ordered by the object's
## lowest pixel so that a piece in front draws over one behind it.
## [{"id", "path", "pos": Vector2i, "rect": Rect2i}].
func _overhead_pieces(layout: Dictionary, parts: Dictionary, image: Image, place: String) -> Array:
	var pieces: Array = []
	for object: Dictionary in layout.get("objects", []):
		var over: Lib.Mask = parts[object["id"]]["overhead"]
		var bounds := Rect2i()
		var found := false
		for y in range(over.origin.y, over.origin.y + over.size.y):
			for x in range(over.origin.x, over.origin.x + over.size.x):
				if over.at(x, y):
					bounds = bounds.expand(Vector2i(x, y)) if found else Rect2i(x, y, 0, 0)
					found = true
		if not found:
			continue
		bounds.size += Vector2i.ONE
		var piece := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for y in bounds.size.y:
			for x in bounds.size.x:
				var p := bounds.position + Vector2i(x, y)
				if over.at(p.x, p.y):
					piece.set_pixel(x, y, image.get_pixelv(p))
		var file := place + "/top/" + str(object["id"]) + ".png"
		_save_png(piece, file)
		var mask: Lib.Mask = parts[object["id"]]["mask"]
		pieces.append({"id": object["id"], "path": _dir + file, "pos": bounds.position, "rect": bounds,
			"order": mask.origin.y + mask.size.y, "image": piece})
	pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["order"] < b["order"])
	return pieces


## The scenes of the place (or a view: spec as in _init) rewritten.
func _build_place(spec: Dictionary) -> void:
	var place: String = spec["place"]
	var src := Lib.SCENES + place + "/"
	var files := Array(DirAccess.get_files_at(src)).filter(func(f: String) -> bool: return f.ends_with(".tscn"))
	var night_path := ""
	if not (spec["night"] as Dictionary).is_empty():
		night_path = place + "/" + place + " night.png"
		_save_png(_night_layer(spec["size"], spec["night"].get("windows", []) + spec["night"].get("glows", []), spec["origin"]), night_path)
		night_path = _dir + night_path
	var used := {}
	for file: String in files:
		var text := FileAccess.get_file_as_string(src + file)
		var is_base: bool = file == place + ".tscn"
		var out := _rewrite(text, spec, is_base, night_path, used)
		_save_text(out, place + "/" + file)
	for key: String in spec["features"]:
		if not used.has(key):
			_errors.append("%s: features[\"%s\"] names nothing in the default scenes" % [place, key])


## A view: another place showing the part of the remake at "origin" (its
## size is the default view's), with the remake's pieces cut to it.
func _build_view(view: Dictionary, main: Dictionary, image: Image) -> void:
	var place: String = view["place"]
	var base: VillageScene = (load(Lib.SCENES + place + "/" + place + ".tscn") as PackedScene).instantiate()
	var size := base.size
	base.free()
	var origin := Lib.veci(view["origin"])
	var crop := image.get_region(Rect2i(origin, size))
	var windows: Array = (view.get("night", {}) as Dictionary).get("windows", [])
	var lit := _light_windows(crop, windows, origin)
	_save_png(crop, place + "/" + place + ".png")
	var pieces: Array = []
	for p: Dictionary in main["pieces"]:
		if (p["rect"] as Rect2i).intersects(Rect2i(origin, size)):
			var moved := p.duplicate()
			moved["pos"] = p["pos"] - origin
			if (p["rect"] as Rect2i).intersects(lit):
				# Its own copy, with the view's lit glass.
				var piece: Image = (p["image"] as Image).duplicate()
				for y in piece.get_height():
					for x in piece.get_width():
						var q: Vector2i = moved["pos"] + Vector2i(x, y)
						if piece.get_pixel(x, y).a > 0.0 and Rect2i(Vector2i.ZERO, size).has_point(q):
							piece.set_pixel(x, y, crop.get_pixelv(q))
				var file := place + "/top/" + str(p["id"]) + ".png"
				_save_png(piece, file)
				moved["path"] = _dir + file
			pieces.append(moved)
	var rects: Array[Rect2i] = []
	if _had_obstacles(place):
		for r: Rect2i in main["rects"]:
			var cut := r.intersection(Rect2i(origin, size))
			if cut.has_area():
				rects.append(Rect2i(cut.position - origin, cut.size))
	_build_place({"place": place, "size": size, "origin": origin, "features": view.get("features", {}),
		"night": view.get("night", {}), "background": _dir + place + "/" + place + ".png",
		"pieces": pieces, "rects": rects, "entries": {"from": PackedVector2Array(), "to": PackedVector2Array()}})


func _had_obstacles(place: String) -> bool:
	for file in DirAccess.get_files_at(Lib.SCENES + place):
		if file.ends_with(".tscn") and FileAccess.get_file_as_string(Lib.SCENES + place + "/" + file).contains("parent=\"Obstacles\""):
			return true
	return false


## A default scene's text rewritten for the remake (see the top). used
## collects the feature keys met.
func _rewrite(text: String, spec: Dictionary, is_base: bool, night_path: String, used: Dictionary) -> String:
	var blocks := _blocks(text)
	var head: String = blocks[0]
	var ext: Array = []
	var sub: Array = []
	var nodes: Array = []
	var indices := {}
	for i in range(1, blocks.size()):
		var b: String = blocks[i]
		if b.begins_with("[ext_resource"):
			if b.contains("id=\"1_base\"") and not is_base:
				b = RegEx.create_from_string("path=\"[^\"]*\"").sub(b, "path=\"%s%s/%s.tscn\"" % [_dir, spec["place"], spec["place"]])
			ext.append(b)
			continue
		if b.begins_with("[sub_resource"):
			sub.append(b)
			continue
		var name := _attr(b, "name")
		var parent := _attr(b, "parent")
		if parent == "Obstacles" or parent == "Overhead" or (parent == "." and name == "Background"):
			continue
		if parent == "":
			nodes.append(_root_block(b, spec) if is_base else b)
			continue
		if parent == "." and name == "Night" and night_path != "":
			b = RegEx.create_from_string("(?m)^texture = .*$").sub(b, "texture = ExtResource(\"rn_night\")")
			if not b.contains("texture ="):
				b = b.rstrip("\n") + "\ntexture = ExtResource(\"rn_night\")\n"
			ext.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"rn_night\"]\n" % night_path)
			nodes.append(b)
			continue
		if FEATURE_GROUPS.has(parent):
			var key := "%s/%s" % [parent, _bare(name)]
			used[key] = true
			if not (spec["features"] as Dictionary).has(key):
				_errors.append("%s: no features[\"%s\"] (at %s in the default scene)" % [spec["place"], key, _position(b)])
				continue
			var f: Variant = spec["features"][key]
			if f == null:
				continue
			var index: int = indices.get(parent, 0)
			indices[parent] = index + 1
			b = RegEx.create_from_string("index=\"\\d+\"").sub(b, "index=\"%d\"" % index)
			nodes.append(_move_feature(b, f, spec["place"]))
			continue
		nodes.append(b)
	if is_base:
		_add_base_nodes(spec, ext, sub, nodes)
	var all_nodes := "\n".join(nodes)
	ext = ext.filter(func(e: String) -> bool: return all_nodes.contains("ExtResource(\"%s\")" % _attr(e, "id")) or _attr(e, "id") == "1_base")
	sub = sub.filter(func(s: String) -> bool: return all_nodes.contains("SubResource(\"%s\")" % _attr(s, "id")))
	var parts := [head, "".join(ext)]
	if not sub.is_empty():
		parts.append("\n".join(sub))
	parts.append("\n".join(nodes))
	return "\n".join(parts).strip_edges() + "\n"


## The root node of a base scene: its size the remake's, and the entries.
func _root_block(b: String, spec: Dictionary) -> String:
	var size: Vector2i = spec["size"]
	for key in ["size", "actual_size"]:
		var line := "%s = %s" % [key, var_to_str(size)]
		var re := RegEx.create_from_string("(?m)^" + key + " = .*$")
		b = re.sub(b, line) if re.search(b) != null else b.rstrip("\n") + "\n" + line + "\n"
	if not (spec["entries"]["from"] as PackedVector2Array).is_empty():
		b = b.rstrip("\n") + "\nentries_from = %s\nentries_to = %s\n" % [var_to_str(spec["entries"]["from"]), var_to_str(spec["entries"]["to"])]
	return b


## The background, the overhead pieces and the obstacles of a base scene.
func _add_base_nodes(spec: Dictionary, ext: Array, sub: Array, nodes: Array) -> void:
	ext.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"rn_bg\"]\n" % spec["background"])
	nodes.append("[node name=\"Background\" parent=\".\" index=\"1\"]\ntexture = ExtResource(\"rn_bg\")\n")
	var i := 0
	for p: Dictionary in spec["pieces"]:
		ext.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"rn_top%d\"]\n" % [p["path"], i])
		nodes.append("[node name=\"%02d %s\" type=\"Sprite2D\" parent=\"Overhead\" index=\"%d\"]\nuse_parent_material = true\nposition = %s\ntexture = ExtResource(\"rn_top%d\")\ncentered = false\n"
			% [i, p["id"], i, var_to_str(Vector2(p["pos"])), i])
		i += 1
	i = 0
	for r: Rect2i in spec["rects"]:
		sub.append("[sub_resource type=\"RectangleShape2D\" id=\"rn_o%d\"]\nsize = %s\n" % [i, var_to_str(Vector2(r.size))])
		nodes.append("[node name=\"V%03d\" type=\"CollisionShape2D\" parent=\"Obstacles\" index=\"%d\"]\nposition = %s\nshape = SubResource(\"rn_o%d\")\n"
			% [i, i, var_to_str(Vector2(r.position) + Vector2(r.size) / 2.0), i])
		i += 1


## A feature node block moved as its layout entry f says.
func _move_feature(b: String, f: Variant, place: String) -> String:
	var pos: Vector2 = Lib.vec(f["pos"] if f is Dictionary else f)
	b = RegEx.create_from_string("(?m)^position = .*\\n").sub(b, "")
	var lines := b.rstrip("\n").split("\n")
	lines.insert(1, "position = %s" % var_to_str(pos))
	var out := "\n".join(lines) + "\n"
	if out.contains("villager_name = "):
		var walk: PackedStringArray
		if f is Dictionary and f.has("walk"):
			walk = PackedStringArray(f["walk"])
		else:
			var folder := _value(out, "villager_folder")
			walk = Lib.read_char(folder, _value(out, "villager_name"))["walk"]
		var check := Lib.walk_points(pos, Array(walk))
		if not check["closed"]:
			_errors.append("%s: the walk of %s does not end where it starts" % [place, _value(out, "villager_name")])
		out += "walk_override = true\nwalk = %s\n" % var_to_str(walk)
	return out


## The cutscene copies: layout "sequences": {"<chapter>/<name>": {"offset":
## [dx, dy], "pos": {"<actor>": [x, y]}, "replace": [["<text>", "<text>"],
## ...]}} (replace: edits of the moved text, for a move the offset can't
## fix); every cutscene of the place and of its views needs an entry
## ("keep": unchanged, not copied).
func _build_sequences(layout: Dictionary) -> void:
	var places := [layout["place"]]
	for view: Dictionary in layout.get("views", []):
		places.append(view["place"])
	var entries: Dictionary = layout.get("sequences", {})
	var homes := {}
	for key: String in layout.get("features", {}):
		var f: Variant = layout["features"][key]
		if key.begins_with("Actors/") and f is Dictionary:
			var start: Variant = Lib.read_char(layout["place"], key.trim_prefix("Actors/"))["start"]
			if start != null:
				homes[Lib.vec(start)] = Lib.vec(f["pos"])
	for place: String in places:
		for name in Lib.sequences_in(place):
			if not entries.has(name):
				_errors.append("No sequences[\"%s\"] (a cutscene in %s)" % [name, place])
	for name: String in entries:
		var entry: Variant = entries[name]
		if entry is String and entry == "keep":
			continue
		var src := Lib.SEQUENCES + name + ".seq"
		if not FileAccess.file_exists(src):
			_errors.append("sequences[\"%s\"]: no %s" % [name, src])
			continue
		var in_place: bool = Lib.sequence_place(FileAccess.get_file_as_string(src)) == layout["place"]
		var text := Lib.move_sequence(FileAccess.get_file_as_string(src), Lib.vec(entry.get("offset", [0, 0])),
				entry.get("pos", {}), homes if in_place else {})
		for pair: Array in entry.get("replace", []):
			if not text.contains(pair[0]):
				_errors.append("sequences[\"%s\"]: replace: no \"%s\" in the moved text" % [name, pair[0]])
			text = text.replace(pair[0], pair[1])
		_save_text(text, "sequences/" + name + ".seq")


## Lights the glass of each window (village pixels, x2 and y2 excluded) in
## image, whose top-left is origin in village pixels (LIT). Returns the
## windows' bounds in village pixels (empty without windows).
func _light_windows(image: Image, windows: Array, origin: Vector2i) -> Rect2i:
	var bounds := Rect2i()
	for w: Array in windows:
		var r := Rect2i(int(w[0]), int(w[1]), int(w[2]) - int(w[0]), int(w[3]) - int(w[1]))
		bounds = r if bounds.size == Vector2i.ZERO else bounds.merge(r)
		var lit := 0
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var p := Vector2i(x, y) - origin
				if not Rect2i(Vector2i.ZERO, image.get_size()).has_point(p):
					continue
				var c := image.get_pixelv(p)
				var l := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
				var warm := c.r > maxf(c.g, c.b) + 0.03
				var green := c.g > c.b + 0.04 and c.g > c.r + 0.04
				if l < 0.3 and not warm and not green:
					image.set_pixelv(p, LIT.lerp(LIT_HIGH, clampf((l - 0.08) / 0.2, 0.0, 1.0)))
					lit += 1
		if lit < r.get_area() / 5:
			_errors.append("night window %s: only %d of its %d pixels look like glass (is it on the panes?)" % [w, lit, r.get_area()])
	return bounds


## A night layer (drawn at scale 2 over a place of size): NIGHT everywhere,
## WINDOW light over each window rectangle (village pixels; origin: the
## view's top-left in them), fading out over WINDOW_FADE layer pixels.
func _night_layer(size: Vector2i, windows: Array, origin: Vector2i) -> Image:
	var layer := Image.create(ceili(size.x / 2.0), ceili(size.y / 2.0), false, Image.FORMAT_RGBA8)
	layer.fill(NIGHT)
	for w: Array in windows:
		var r := Rect2(Vector2(float(w[0]) - origin.x, float(w[1]) - origin.y) / 2.0,
			Vector2(float(w[2]) - float(w[0]), float(w[3]) - float(w[1])) / 2.0)
		var grown := Rect2i(r.grow(WINDOW_FADE)).intersection(Rect2i(Vector2i.ZERO, layer.get_size()))
		for y in range(grown.position.y, grown.end.y):
			for x in range(grown.position.x, grown.end.x):
				var c := Vector2(x + 0.5, y + 0.5)
				var d := Vector2(maxf(maxf(r.position.x - c.x, c.x - r.end.x), 0.0), maxf(maxf(r.position.y - c.y, c.y - r.end.y), 0.0)).length()
				var t := clampf(1.0 - d / WINDOW_FADE, 0.0, 1.0)
				var old := layer.get_pixel(x, y)
				var lit := NIGHT.lerp(WINDOW, t)
				if lit.a < old.a:
					layer.set_pixel(x, y, lit)
	return layer


# --- scene text ---

static func _blocks(text: String) -> Array:
	var out: Array = []
	var current := ""
	for line in text.split("\n"):
		if line.begins_with("[") and current != "":
			out.append(current.strip_edges(false, true) + "\n")
			current = ""
		if line.strip_edges() == "" and current == "":
			continue
		current += line + "\n"
	if current.strip_edges() != "":
		out.append(current.strip_edges(false, true) + "\n")
	return out


static func _attr(block: String, key: String) -> String:
	var m := RegEx.create_from_string("^\\[[^\\]]*\\s" + key + "=\"([^\"]*)\"").search(block)
	return m.get_string(1) if m != null else ""


static func _bare(node_name: String) -> String:
	var unescaped := node_name.replace("\\'", "'").replace("\\\"", "\"")
	var space := unescaped.find(" ")
	return unescaped.substr(space + 1) if space > 0 and unescaped.left(space).is_valid_int() else unescaped


static func _value(block: String, key: String) -> String:
	var m := RegEx.create_from_string("(?m)^" + key + " = \"(.*)\"$").search(block)
	return m.get_string(1) if m != null else ""


static func _position(block: String) -> String:
	var m := RegEx.create_from_string("(?m)^position = (.*)$").search(block)
	return m.get_string(1) if m != null else "?"


# --- files ---

func _save_png(image: Image, relative: String) -> void:
	DirAccess.make_dir_recursive_absolute((_dir + relative).get_base_dir())
	image.save_png(_dir + relative)
	_written.append(relative)


func _save_text(text: String, relative: String) -> void:
	DirAccess.make_dir_recursive_absolute((_dir + relative).get_base_dir())
	FileAccess.open(_dir + relative, FileAccess.WRITE).store_string(text)
	_written.append(relative)
