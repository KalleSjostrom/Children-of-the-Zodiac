extends SceneTree
## Converts the .vil files of maps/Village into village scenes
## (docs/MODERNIZATION_PLAN.md 6.2; the conventions are in
## docs/ARCHITECTURE.md section 9, the workflow in docs/CONVERTING_VILLAGES.md).
## Run headless from the project root; the wrapper
## tools/import/vil_to_scene.sh runs the two stages with Godot's import
## between them:
##
##   godot --headless --path . --script res://tools/import/vil_to_scene.gd -- [options] <place>...
##
## For a place (a folder maps/Village/<Place>) it writes:
##   scenes/villages/<Place>/<Place>.tscn      the base: inherits VillageScene.tscn;
##                                              the background most variants draw,
##                                              the top layer and the spawns if all
##                                              variants have the same, the obstacles
##                                              all of them have
##   scenes/villages/<Place>/<variant>.tscn    one per .vil file, inherits the base;
##                                              overrides Background when it draws
##                                              another image (Dellna2, Parasne1, a
##                                              night image of its own)
##   scenes/villages/<Place>/<image>.png       a background's 256 px tiles in one image
##                                              (in the folder of the place whose art
##                                              it is, when a variant uses another
##                                              place's art); a background without a
##                                              tile folder is used as it is
##   resources/sprite_frames/<folder>/<image>.tres            one per villager image set
##   resources/sprite_frames/<folder>/animobj/<name>.tres     one per animObj series
##
## Options:
##   --stage=art     only the stitched backgrounds (with .import files: lossless,
##                   no mipmaps) and the SpriteFrames
##   --stage=scenes  only the scenes; the backgrounds must be imported first
##                   (godot --headless --path . --import)
##   --data-only     scenes without art (no textures, SpriteFrames or previews),
##                   for dry runs
##   --out=<dir>     write the scenes to <dir>/<Place>/ (an absolute or user://
##                   path) instead of res://scenes/villages/
##   --all           every place of maps/Village
##
## The .vil files are read with the legacy tokenizer (AbstractMapLoader) and
## the legacy parsers (J.parseInt & co.), so that every value is what
## VillageLoaderMapLoader reads. Child order is file order: doors and signs
## are searched in order and the first in range wins. The scenes are saved
## with PackedScene.pack() and ResourceSaver.save(); the node unique_ids
## (random in Godot 4.7) are left out, so that converting twice writes the
## same files. tools/import/verify_villages.gd checks the result.

const TEMPLATE := "res://scenes/villages/VillageScene.tscn"
const SCENE_DIR := "res://scenes/villages"
const FRAMES_DIR := "res://resources/sprite_frames"
const VIL_DIR := "maps/Village/"
const IMAGES := "res/Village/"
const TILE := 256
## Legacy Sprite frame time (ms) of villagers and animated objects.
const FRAME_MS := 150.0
const DIRECTION_ANIMS: Array[StringName] = [&"up", &"right", &"down", &"left"]

var _door_scene: PackedScene = load("res://scenes/common/VillageDoor.tscn")
var _sign_scene: PackedScene = load("res://scenes/common/VillageSign.tscn")
var _loot_scene: PackedScene = load("res://scenes/common/VillageLoot.tscn")
var _spawn_scene: PackedScene = load("res://scenes/common/VillageSpawn.tscn")
var _actor_scene: PackedScene = load("res://scenes/common/ActorView.tscn")
var _particles_scene: PackedScene = load("res://scenes/common/particles/LegacyParticles2D.tscn")

var _art := true
var _scenes := true
var _data_only := false
var _out := SCENE_DIR
var _failed := 0


func _init() -> void:
	var places: Array[String] = []
	var all := false
	for a in OS.get_cmdline_user_args():
		if a == "--stage=art":
			_scenes = false
		elif a == "--stage=scenes":
			_art = false
		elif a == "--data-only":
			_data_only = true
			_art = false
		elif a.begins_with("--out="):
			_out = a.trim_prefix("--out=").trim_suffix("/")
		elif a == "--all":
			all = true
		else:
			places.append(a)
	if all:
		places.assign(GameResourceLoader.listDirectories(VIL_DIR))
	if places.is_empty():
		print("usage: vil_to_scene.gd -- [--stage=art|scenes] [--data-only] [--out=<dir>] [--all] <place>...")
		quit(2)
		return
	for place in places:
		_convert_place(place)
	print("CONVERTED %d places, %d failed" % [places.size(), _failed])
	quit(1 if _failed > 0 else 0)


func _convert_place(place: String) -> void:
	var files: Array = GameResourceLoader.listFiles(VIL_DIR + place).filter(
			func(f: String) -> bool: return f.ends_with(".vil"))
	if files.is_empty():
		push_error("vil_to_scene: no .vil files in " + VIL_DIR + place)
		_failed += 1
		return
	var variants: Array[Dictionary] = []
	for f: String in files:
		var reader := VilReader.new()
		reader.parseFile(VIL_DIR + place + "/" + f)
		var model := reader.model
		model["place"] = place
		model["file"] = f.get_basename()
		for w in reader.warnings:
			print("  %s/%s: %s" % [place, f, w])
		if not model.has("size"):
			push_error("vil_to_scene: %s/%s has no back line" % [place, f])
			_failed += 1
			return
		_resolve_art(model)
		variants.append(model)
	var shared := _shared(variants)
	if _art:
		for v in variants:
			_write_art(v)
	if _scenes:
		var dir := _out + "/" + place
		DirAccess.make_dir_recursive_absolute(dir)
		var base_path := dir + "/" + place + ".tscn"
		if not _write_scene(_build_base(place, variants, shared), TEMPLATE, base_path):
			return
		for v in variants:
			_write_scene(_build_variant(v, shared), base_path, dir + "/" + v["file"] + ".tscn")
	print("%s: %d variants (%s)" % [place, variants.size(),
			", ".join(variants.map(func(v: Dictionary) -> String: return v["file"]))])


# ---------------------------------------------------------------------------
# Reading a .vil file
# ---------------------------------------------------------------------------

## VillageLoaderMapLoader.executeCommand, recording what each command reads
## instead of building the village.
class VilReader extends AbstractMapLoader:
	var model := {"obstacles": [], "spawns": [], "particles": [], "doors": [], "signs": [],
		"loots": [], "buildings": [], "actors": []}
	var warnings: Array[String] = []
	var _sign = null
	var _villager_folder := ""

	## J.parseInt, with a warning for a token that is no integer (content
	## quirks: the legacy loader reads it the same way, as J.parseInt's 0).
	func _int(s: String) -> int:
		var value := J.parseInt(s)
		if not s.strip_edges().trim_prefix("+").is_valid_int():
			warnings.append("line %d: '%s' is not an integer, read as %d (as by the legacy loader)"
					% [lineCount, s, value])
		return value

	func executeCommand(command: String, tok: StringTokenizer) -> void:
		if command == "o":
			var x := _int(tok.nextToken())
			var y := _int(tok.nextToken())
			var x2 := _int(tok.nextToken())
			var y2 := _int(tok.nextToken())
			model["obstacles"].append(Rect2i(x, y, x2 - x, y2 - y))
		elif command == "inside":
			model["inside"] = true
		elif command.begins_with("start"):
			var s := command.replace("start", "")
			var number := -1 if s == "" else _int(s)
			var x := _int(tok.nextToken())
			var y := _int(tok.nextToken())
			var a := _int(tok.nextToken())
			model["spawns"].append({"number": number, "x": x, "y": y, "facing": a})
		elif command.contains("landname"):
			model["land_name"] = tok.nextToken()
		elif command.begins_with("lootL"):
			if not model["loots"].is_empty():
				model["loots"].back()["lines"].append(lastLine.replace("lootLine ", ""))
		elif command == "loot":
			model["loots"].append(_loot(tok))
		elif command == "door" or command == "holeDoor":
			model["doors"].append(_door(tok, command == "holeDoor"))
		elif command == "wind":
			var parts: Array = J.split(tok.nextToken(), ";")
			var wind: Array = []
			for i in 3:
				wind.append(J.parseFloat(parts[i]))
			wind.append(J.parseFloat(tok.nextToken()))
			model["wind"] = wind
		elif command in ["doorSignFl", "doorSignSl", "holeDoorSignFl", "holeDoorSignSl"]:
			var hole := command.begins_with("hole")
			var door = null
			for d in model["doors"]:
				if d["hole"] == hole:
					door = d
			var text := lastLine.replace(command, "")
			if door == null:
				warnings.append("%s before any door: ignored (as by the legacy loader)" % command)
			elif command.ends_with("Fl"):
				door["sign_lines"] = [text]
			elif door["sign_lines"].is_empty():
				warnings.append("%s without a first line: ignored (as by the legacy loader)" % command)
			else:
				door["sign_lines"].append(text)
		elif command == "sign":
			var x := _int(tok.nextToken())
			var y := _int(tok.nextToken())
			var w := -1
			if tok.hasMoreTokens():
				w = _int(tok.nextToken())
			var dirs: Array = []
			if tok.hasMoreTokens():
				for s in J.split(tok.nextToken(), ";"):
					dirs.append(_int(s))
			else:
				dirs.append(0)
			_sign = {"x": x, "y": y, "radius": w, "directions": dirs, "lines": [], "listed": []}
			model["signs"].append(_sign)
		elif command == "signL" or command == "signL2":
			if _sign == null:
				warnings.append("%s before any sign: ignored (as by the legacy loader)" % command)
			else:
				_sign["lines"].append(lastLine.replace(command + " ", ""))
				_sign["listed"].append(command == "signL")
		elif command == "villager":
			var name := tok.nextToken().replace("_", " ")
			var statuses: Array = []
			while tok.hasMoreTokens():
				statuses.append(_int(tok.nextToken()))
			model["actors"].append({"kind": "villager", "name": name, "statuses": statuses,
				"folder": _villager_folder})
		elif command == "particlesystem":
			var line_index: int = model.get("particle_lines", 0)
			model["particle_lines"] = line_index + 1
			while tok.hasMoreTokens():
				var name := tok.nextToken()
				var layer := DoubleBackground.UPPER_LAYER
				var active := true
				var status := -1
				if name.contains(":"):
					var temp: Array = J.split(name, ":")
					name = temp[0]
					layer = _int(temp[1])
					if temp.size() > 2:
						active = J.parseBoolean(temp[2])
					if temp.size() > 3:
						status = _int(temp[3])
				var p := {"name": name, "layer": layer, "active": active, "status": status,
					"order": model["particles"].size(), "line": line_index}
				model["particles"].append(p)
				if layer == DoubleBackground.VILLAGER_LAYER:
					model["actors"].append({"kind": "particles", "particles": p})
		elif command == "background":
			var folder := tok.nextToken().replace("_", " ")
			model["folder_name"] = folder
			if folder.contains("--"):
				var parts: Array = J.split(folder, "--")
				model["village_name"] = parts[0]
				model["background_folder"] = parts[0] + parts[1]
			else:
				model["village_name"] = folder
				model["background_folder"] = folder
			model["day"] = J.parseBoolean(tok.nextToken())
			if tok.hasMoreTokens():
				model["extra_name"] = tok.nextToken().replace("_", " ")
			_villager_folder = model["village_name"]
		elif command == "villagerFolder":
			_villager_folder = Organizer.convertKeepCase(tok.nextToken())
		elif command == "back":
			var w := _int(tok.nextToken())
			var h := _int(tok.nextToken())
			model["size"] = Vector2i(w, h)
			model["actual_size"] = Vector2i(w, h)
			model["back_extra"] = 0
			if tok.hasMoreTokens():
				var s := tok.nextToken()
				if s.contains("as="):
					var sa: Array = J.split(s.replace("as=", ""), ":")
					model["actual_size"] = Vector2i(_int(sa[0]), _int(sa[1]))
				else:
					model["back_extra"] = _int(s)
		elif command == "offset":
			var x := _int(tok.nextToken())
			var y := _int(tok.nextToken())
			model["offset"] = Vector2i(x, y)
		elif command == "music":
			model["music"] = tok.nextToken()
		elif command == "building":
			var b := VillageBuilding.new()
			b.store_name = tok.nextToken()
			b.background = tok.nextToken()
			b.keeper = tok.nextToken()
			b.keeper_name = tok.nextToken().replace("_", " ")
			b.first_line = tok.nextToken().replace("_", " ")
			b.second_line = Organizer.convertKeepCase(tok.nextToken())
			b.music = tok.nextToken().replace("_", " ")
			model["buildings"].append(b)
		elif command == "animObj":
			var name := tok.nextToken()
			var x := _int(tok.nextToken())
			var y := _int(tok.nextToken())
			var count := 4
			if tok.hasMoreTokens():
				count = _int(tok.nextToken())
			model["actors"].append({"kind": "animObj", "name": name, "x": x, "y": y, "count": count})
		else:
			warnings.append("line %d: unknown command '%s' ignored (as by the legacy loader)" % [lineCount, command])

	## StoreDoor.getDoor's reading of a door line.
	func _door(tok: StringTokenizer, hole: bool) -> Dictionary:
		var kinds: Array = J.split(tok.nextToken(), ";")
		var targets: Array = J.split(tok.nextToken(), ";")
		var x := _int(tok.nextToken())
		var y := _int(tok.nextToken())
		var w := _int(tok.nextToken())
		var directions := tok.nextToken()
		var dirs: Array = []
		var activation := -1
		if directions.contains(";"):
			for d in J.split(directions, ";"):
				if d.contains("s"):
					activation = _int(d.replace("s", ""))
				else:
					dirs.append(_int(d))
		else:
			dirs.append(_int(directions))
		var fade := StoreDoor.FADE_DOWN
		if tok.hasMoreTokens():
			fade = _int(tok.nextToken())
		var to_pos: Array = []
		if tok.hasMoreTokens():
			to_pos = [-1.0, -1.0, -1.0, -1.0]
			to_pos[0] = J.parseFloat(tok.nextToken())
			if tok.hasMoreTokens():
				to_pos[1] = J.parseFloat(tok.nextToken())
				to_pos[2] = J.parseFloat(tok.nextToken())
				var temp: float = to_pos[0]
				to_pos[0] = to_pos[1]
				to_pos[1] = temp
			if tok.hasMoreTokens():
				to_pos[3] = J.parseFloat(tok.nextToken())
		return {"hole": hole, "kinds": kinds, "targets": targets, "x": x, "y": y, "radius": w,
			"directions": dirs, "activation": activation, "fade": fade, "to_pos": to_pos,
			"sign_lines": []}

	## Loot.getLoot's reading of a loot line (all of it: the legacy loader
	## stops after the name when the loot is taken).
	func _loot(tok: StringTokenizer) -> Dictionary:
		var l := {"name": tok.nextToken(), "x": _int(tok.nextToken()),
			"y": _int(tok.nextToken()), "lines": [], "triggers": {}, "amount": 0,
			"card_level": 0, "all_cards": false, "life": 0.0}
		var dirs: Array = []
		for s in J.split(tok.nextToken(), ";"):
			dirs.append(_int(s))
		l["directions"] = dirs
		var c_name := tok.nextToken()
		if c_name.begins_with("trigger="):
			for s in J.split(c_name.replace("trigger=", ""), "--"):
				var temp: Array = J.split(s, ":")
				l["triggers"][temp[0]] = _int(temp[1])
			c_name = tok.nextToken()
		l["content_name"] = c_name
		var t := _int(tok.nextToken())
		l["type"] = t
		var spaced := c_name.replace("_", " ")
		match t:
			Loot.GOLD:
				l["amount"] = _int(spaced)
			Loot.ITEM:
				l["amount"] = 1
				if tok.hasMoreTokens():
					l["amount"] = _int(tok.nextToken())
			Loot.CARD:
				l["card_level"] = _int(tok.nextToken())
				if tok.hasMoreTokens():
					l["all_cards"] = J.parseBoolean(tok.nextToken())
			Loot.LIFE:
				l["life"] = J.parseFloat(spaced)
		return l


# ---------------------------------------------------------------------------
# Art (DoubleBackground's image choice)
# ---------------------------------------------------------------------------

## The images DoubleBackground loads for the variant: the background (tiles
## or one image), the night layer and the top layer (top/top.info).
func _resolve_art(v: Dictionary) -> void:
	var rl := GameResourceLoader.getResourceLoader()
	var folder: String = v.get("background_folder", "")
	var name: String = v.get("extra_name", folder)
	if name == "":
		name = folder
	var dir := IMAGES + folder + ("" if folder == "" else "/")
	var image := ""
	v["night_top"] = ""
	if not v.get("day", true):
		var jpg := dir + name + " at Night.jpg"
		image = jpg if rl.exists(jpg) or rl.exists(dir + name + " at Nightfolder") else dir + name + ".jpg"
		var top := dir + name + " at Night - 1.png"
		v["night_top"] = top if rl.exists(top) else IMAGES + "standardOvernight.png"
	else:
		var png := dir + name + ".png"
		if rl.exists(png) or (rl.exists(dir + name + "folder") and rl.exists(dir + name + "folder/x0y0.png")):
			image = png
		else:
			image = dir + name + ".jpg"
	v["image"] = image
	# DoubleBackground.cutImage: the tile folder when it has x0y0, else the image.
	var ext := ".jpg" if image.ends_with(".jpg") else ".png"
	var tiles := image.replace(ext, "folder")
	v["tiles"] = tiles if rl.exists(tiles + "/x0y0" + ext) else ""
	v["tile_ext"] = ext
	v["background_png"] = image.get_file().get_basename() + ".png"
	# What is drawn: the tiles (as resolved: a missing .png name falls back to
	# the .jpg tiles, so the day and night names often give the same image).
	v["background_key"] = (GameResourceLoader.resolve(v["tiles"] + "/x0y0" + ext) if v["tiles"] != ""
			else GameResourceLoader.resolve(image))
	v["top"] = _top_layer(folder)


## DoubleBackground.doTopLayer: [position, image] per top.info line, in order.
func _top_layer(folder: String) -> Array:
	var out: Array = []
	var path := IMAGES + folder + "/top/top.info"
	if not GameResourceLoader.fileExists(path):
		return out
	for line in GameResourceLoader.readText(path).replace("\r", "").split("\n"):
		if line == "":
			continue
		var args: Array = J.split(line, ":")
		var n: String = args[0]
		var p := Vector2i(J.parseInt(args[1]), J.parseInt(args[2]))
		if n.begins_with("i"):
			out.append([p, IMAGES + "/top/" + n.replace("i/", "")])
		else:
			out.append([p, IMAGES + folder + "/top/" + n])
	return out


func _write_art(v: Dictionary) -> void:
	if v["tiles"] != "":
		_stitch(v)
	for a: Dictionary in v["actors"]:
		if a["kind"] == "villager":
			for image_set in _char_images(a["folder"], a["name"]):
				_write_frames(image_set)
		elif a["kind"] == "animObj":
			_write_frames(_anim_obj_images(v["folder_name"], a["name"], a["count"]))


## The stitched background of v: in the folder of the place whose art it is
## when that is another place (No Place at Night uses Zazo - Teo's night
## background), so a background is stitched once; else in v's place folder.
func _background_path(v: Dictionary) -> String:
	var folder: String = v.get("background_folder", "")
	var place: String = v["place"]
	if folder != "" and folder != place and DirAccess.dir_exists_absolute("res://" + VIL_DIR + folder):
		place = folder
	return SCENE_DIR + "/" + place + "/" + v["background_png"]


## Stitches the tiles DoubleBackground.generateNames draws (x<i>y<j> for
## i < ceil(actual width / 256), j < ceil(actual height / 256)) into one
## image, pixel for pixel as imported.
func _stitch(v: Dictionary) -> void:
	var path := _background_path(v)
	var columns := ceili(v["actual_size"].x / float(TILE))
	var rows := ceili(v["actual_size"].y / float(TILE))
	var images := {}
	var image_size := Vector2i.ZERO
	var format := -1
	for i in columns:
		for j in rows:
			var tile := GameResourceLoader.resolve("%s/x%dy%d%s" % [v["tiles"], i, j, v["tile_ext"]])
			if tile == "":
				print("  %s: tile x%dy%d missing" % [v["file"], i, j])
				continue
			var img := (load(tile) as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			if format == -1:
				format = img.get_format()
			images[Vector2i(i, j)] = img
			image_size = image_size.max(Vector2i(i, j) * TILE + img.get_size())
	if images.is_empty():
		return
	var out := Image.create_empty(image_size.x, image_size.y, false, format)
	for k: Vector2i in images:
		var img: Image = images[k]
		if img.get_format() != format:
			img.convert(format)
		out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), k * TILE)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	out.save_png(path)
	# Same import as the tiles: lossless, no mipmaps; the alpha border was
	# already fixed when the tiles were imported. An .import file that already
	# has these settings is kept, with its uid.
	var params: Array[String] = ["compress/mode=0", "compress/high_quality=false",
		"mipmaps/generate=false", "mipmaps/limit=-1", "process/fix_alpha_border=false",
		"process/premult_alpha=false", "process/size_limit=0", "detect_3d/compress_to=0"]
	var current := FileAccess.get_file_as_string(path + ".import")
	if params.all(func(line: String) -> bool: return current.contains(line + "\n")):
		return
	var f := FileAccess.open(path + ".import", FileAccess.WRITE)
	f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\n"
		+ "\n".join(params) + "\n")
	f.close()


## The image sets of a villager's .char file ("image <name> [count [h w]]"
## lines, Villager.loadImages): [resource path, [legacy image paths]] each.
func _char_images(folder: String, name: String) -> Array:
	var out: Array = []
	var text := GameResourceLoader.readText(VIL_DIR + folder + "/villagers/" + name + ".char")
	for line in text.replace("\r", "").split("\n"):
		var tok := StringTokenizer.new(line.strip_edges())
		if not tok.hasMoreTokens() or tok.nextToken().to_lower() != "image":
			continue
		var image := tok.nextToken().replace("_", " ")
		var count := 16
		if tok.hasMoreTokens():
			count = J.parseInt(tok.nextToken())
		var base: String
		var res_dir: String
		if image.begins_with("char/"):
			image = image.replace("char/", "")
			base = IMAGES + "Characters/" + image + "/" + image
			res_dir = "Characters"
		else:
			base = IMAGES + folder + "/villagers/" + image + "/" + image
			res_dir = folder
		var paths: Array = []
		for i in count:
			paths.append(base + str(i + 1) + ".png")
		var set := [FRAMES_DIR + "/" + res_dir + "/" + image + ".tres", paths, true]
		if count > 0 and not out.any(func(s: Array) -> bool: return s[0] == set[0]):
			out.append(set)
	return out


## AnimatedObjects' image series: [resource path, [legacy image paths], false].
func _anim_obj_images(folder: String, name: String, count: int) -> Array:
	var paths: Array = []
	for i in count:
		paths.append(IMAGES + folder + "/animobj/" + name + "/" + name + str(i + 1) + ".png")
	return [FRAMES_DIR + "/" + folder + "/animobj/" + name + ".tres", paths, false]


## One SpriteFrames per image set: a villager's four directions (Sprite: 4
## images per direction, ia[i + direction * 4]), or an animated object's first
## four images; 150 ms per image.
func _write_frames(image_set: Array) -> void:
	var paths: Array = image_set[1]
	var frames := SpriteFrames.new()
	var per_anim := mini(paths.size(), 4)
	var anims: Array[StringName] = [&"default"]
	if image_set[2]:
		anims = DIRECTION_ANIMS
	if image_set[2]:
		frames.remove_animation(&"default")
	for d in anims.size():
		var anim := anims[d]
		if not frames.has_animation(anim):
			frames.add_animation(anim)
		frames.set_animation_speed(anim, 1000.0 / FRAME_MS)
		frames.set_animation_loop(anim, true)
		for i in per_anim:
			var index := i + d * per_anim
			if index >= paths.size():
				break
			var res := GameResourceLoader.resolve(paths[index])
			if res == "":
				print("  missing image " + paths[index])
				continue
			frames.add_frame(anim, load(res))
	DirAccess.make_dir_recursive_absolute(image_set[0].get_base_dir())
	ResourceSaver.save(frames, image_set[0])


# ---------------------------------------------------------------------------
# Base / variant split (decision 1: one inherited scene per .vil file)
# ---------------------------------------------------------------------------

## What the variants have in common: the root values, the background (the
## one most variants draw, ties to the first in file order; a variant with
## another one overrides the base's Background node), the top layer (if all
## have the same), the obstacles (as a multiset: the legacy obstacle order
## does not matter, collision tests all of them) and the spawns (if all
## variants list the same).
func _shared(variants: Array[Dictionary]) -> Dictionary:
	var first: Dictionary = variants[0]
	var shared := {"root": {}, "obstacles": [], "spawns": [], "background": first, "top": true}
	for key in _root_values(first):
		var value = _root_values(first)[key]
		if variants.all(func(v: Dictionary) -> bool: return _root_values(v)[key] == value):
			shared["root"][key] = value
	var best := 0
	for v in variants:
		var count := variants.filter(func(w: Dictionary) -> bool: return _same_background(v, w)).size()
		if count > best:
			best = count
			shared["background"] = v
	shared["top"] = variants.all(func(v: Dictionary) -> bool: return v["top"] == first["top"])
	var common: Array = first["obstacles"].duplicate()
	for v in variants.slice(1):
		var rest: Array = v["obstacles"].duplicate()
		var kept: Array = []
		for r in common:
			var i := rest.find(r)
			if i >= 0:
				rest.remove_at(i)
				kept.append(r)
		common = kept
	shared["obstacles"] = common
	if variants.all(func(v: Dictionary) -> bool: return v["spawns"] == first["spawns"]):
		shared["spawns"] = first["spawns"]
	return shared


## The variant's VillageScene root properties.
func _root_values(v: Dictionary) -> Dictionary:
	var wind: Array = v.get("wind", [0.0, 0.0, 0.0, 0.0])
	return {
		"place_name": v["place"], "folder_name": v.get("folder_name", ""),
		"village_name": v.get("village_name", ""), "background_folder": v.get("background_folder", ""),
		"day": v.get("day", true), "extra_name": v.get("extra_name", ""), "size": v["size"],
		"actual_size": v["actual_size"], "back_extra": v["back_extra"],
		"has_tile_offset": v.has("offset"), "tile_offset": v.get("offset", Vector2i.ZERO),
		"inside": v.get("inside", false), "music": v.get("music", ""),
		"land_name": v.get("land_name", ""), "has_wind": v.has("wind"),
		"wind_force": PackedFloat64Array(wind.slice(0, 3)), "wind_turbulence": wind[3],
		"night_screen_fixed": v["night_top"].contains("standard"),
	}


## Whether variants a and b draw the same background image at the same shift.
static func _same_background(a: Dictionary, b: Dictionary) -> bool:
	return a["background_key"] == b["background_key"] and a.get("offset") == b.get("offset")


func _build_base(place: String, variants: Array[Dictionary], shared: Dictionary) -> Callable:
	return func(root: VillageScene) -> void:
		for key in shared["root"]:
			root.set(key, shared["root"][key])
		_add_background(root, shared["background"])
		if shared["top"]:
			_add_top(root, variants[0])
		var shapes := root.get_node("Obstacles")
		for i in shared["obstacles"].size():
			_add_obstacle(root, shapes, "O%03d" % i, shared["obstacles"][i])
		for i in shared["spawns"].size():
			_add_spawn(root, i, shared["spawns"][i])


func _build_variant(v: Dictionary, shared: Dictionary) -> Callable:
	return func(root: VillageScene) -> void:
		root.name = v["file"]
		var values := _root_values(v)
		for key in values:
			root.set(key, values[key])
		if not _same_background(v, shared["background"]):
			_add_background(root, v)
		if not shared["top"]:
			_add_top(root, v)
		if v["night_top"] != "" and not _data_only:
			var night: Sprite2D = root.get_node("Night")
			night.texture = _texture(v["night_top"])
			night.visible = night.texture != null
		var extra: Array = v["obstacles"].duplicate()
		for r in shared["obstacles"]:
			extra.remove_at(extra.find(r))
		for i in extra.size():
			_add_obstacle(root, root.get_node("Obstacles"), "V%03d" % i, extra[i])
		if shared["spawns"].is_empty():
			for i in v["spawns"].size():
				_add_spawn(root, i, v["spawns"][i])
		var buildings: Array[VillageBuilding] = []
		buildings.assign(v["buildings"])
		root.buildings = buildings
		for i in v["doors"].size():
			_add_door(root, i, v["doors"][i])
		for i in v["signs"].size():
			_add_sign(root, i, v["signs"][i])
		for i in v["loots"].size():
			_add_loot(root, i, v["loots"][i])
		var index := 0
		for p: Dictionary in v["particles"]:
			if p["layer"] != DoubleBackground.VILLAGER_LAYER:
				var parent := "Ground" if p["layer"] == DoubleBackground.BOTTOM_LAYER else "Effects"
				_add_particles(root, root.get_node(parent), p)
		for a: Dictionary in v["actors"]:
			if a["kind"] == "particles":
				_add_particles(root, root.get_node("Actors"), a["particles"])
			else:
				_add_actor(root, index, a, v)
			index += 1


## The background DoubleBackground draws for v: its stitched tiles, or the
## image itself when it has no tile folder (DoubleBackground.cutImage2 cuts
## it in memory), at the offset line's shift; no texture when the image is
## missing (the legacy code draws nothing either).
func _add_background(root: VillageScene, v: Dictionary) -> void:
	if _data_only:
		return
	var background: Sprite2D = root.get_node("Background")
	background.position = Vector2(v.get("offset", Vector2i.ZERO))
	if v["tiles"] != "":
		background.texture = load(_background_path(v))
	else:
		background.texture = _texture(v["image"])


## The roofs and treetops of top/top.info, one Sprite2D each, in file order.
func _add_top(root: VillageScene, v: Dictionary) -> void:
	if _data_only:
		return
	var overhead := root.get_node("Overhead")
	for i in v["top"].size():
		var piece := Sprite2D.new()
		piece.name = "%02d %s" % [i, String(v["top"][i][1]).get_file().get_basename()]
		piece.centered = false
		piece.use_parent_material = true
		piece.position = Vector2(v["top"][i][0])
		piece.texture = _texture(v["top"][i][1])
		_own(root, overhead, piece)


func _add_obstacle(root: Node, parent: Node, name: String, r: Rect2i) -> void:
	var shape := CollisionShape2D.new()
	shape.name = name
	var rect := RectangleShape2D.new()
	rect.size = Vector2(r.size)
	shape.shape = rect
	shape.position = Vector2(r.position) + Vector2(r.size) / 2.0
	_own(root, parent, shape)


func _add_spawn(root: Node, i: int, s: Dictionary) -> void:
	var spawn: VillageSpawn = _spawn_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	spawn.name = "%02d start%s" % [i, "" if s["number"] == -1 else str(s["number"])]
	spawn.number = s["number"]
	spawn.facing = s["facing"]
	spawn.position = Vector2(s["x"], s["y"])
	_own(root, root.get_node("Spawns"), spawn)


func _add_door(root: Node, i: int, d: Dictionary) -> void:
	var door: VillageDoor = _door_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	door.name = _node_name("%02d %s" % [i, d["targets"][0]])
	door.hole = d["hole"]
	door.kinds = PackedStringArray(d["kinds"])
	door.targets = PackedStringArray(d["targets"])
	door.position = Vector2(d["x"], d["y"])
	door.radius = d["radius"]
	door.directions = PackedInt32Array(d["directions"])
	door.activation_status = d["activation"]
	door.fade = d["fade"]
	door.to_pos = PackedFloat64Array(d["to_pos"])
	door.sign_lines = PackedStringArray(d["sign_lines"])
	_own(root, root.get_node("Doors"), door)


func _add_sign(root: Node, i: int, s: Dictionary) -> void:
	var sign: VillageSign = _sign_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var first: String = s["lines"][0] if not s["lines"].is_empty() else "sign"
	sign.name = _node_name("%02d %s" % [i, first.left(24)])
	sign.position = Vector2(s["x"], s["y"])
	sign.radius = s["radius"]
	sign.directions = PackedInt32Array(s["directions"])
	sign.lines = PackedStringArray(s["lines"])
	var listed: Array[bool] = []
	listed.assign(s["listed"])
	sign.listed = listed
	_own(root, root.get_node("Signs"), sign)


func _add_loot(root: Node, i: int, l: Dictionary) -> void:
	var loot: VillageLoot = _loot_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	loot.name = _node_name("%02d %s" % [i, l["name"]])
	loot.loot_name = l["name"]
	loot.position = Vector2(l["x"], l["y"])
	loot.directions = PackedInt32Array(l["directions"])
	loot.triggers = l["triggers"]
	loot.content_name = l["content_name"]
	loot.content_type = l["type"]
	loot.amount = l["amount"]
	loot.card_level = l["card_level"]
	loot.all_cards = l["all_cards"]
	loot.life = l["life"]
	loot.lines = PackedStringArray(l["lines"])
	_own(root, root.get_node("Loot"), loot)


func _add_particles(root: Node, parent: Node, p: Dictionary) -> void:
	var node: LegacyParticles2D = _particles_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	node.name = _node_name("%02d %s" % [p["order"], p["name"]])
	node.system_name = p["name"]
	node.layer = p["layer"]
	node.start_active = p["active"]
	node.activation_status = p["status"]
	node.build_order = p["order"]
	node.line = p["line"]
	if not _data_only:
		var system: Array = SystemLoader.getLoader().buildSystem(p["name"])
		if not system.is_empty() and system[0] != null:
			var e = system[0].getEmitter().getPosition()
			node.position = Vector2(e.x, -e.y)
	_own(root, parent, node)


func _add_actor(root: Node, index: int, a: Dictionary, v: Dictionary) -> void:
	var view: ActorView = _actor_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if a["kind"] == "villager":
		view.name = _node_name("%02d %s" % [index, a["name"]])
		view.role = ActorView.Role.VILLAGER
		view.villager_name = a["name"]
		view.statuses = PackedInt32Array(a["statuses"])
		view.villager_folder = a["folder"]
		if not _data_only:
			_villager_preview(view, a)
	else:
		view.name = _node_name("%02d %s" % [index, a["name"]])
		view.role = ActorView.Role.ANIMATED_OBJECT
		view.object_name = a["name"]
		view.image_count = a["count"]
		view.position = Vector2(a["x"], a["y"])
		if not _data_only:
			var frames := _anim_obj_images(v["folder_name"], a["name"], a["count"])[0] as String
			if ResourceLoader.exists(frames):
				view.sprite_frames = load(frames)
	_own(root, root.get_node("Actors"), view)


## Shows the villager in the editor where its .char file starts it, facing
## its first instruction, with its first image set.
func _villager_preview(view: ActorView, a: Dictionary) -> void:
	var sets := _char_images(a["folder"], a["name"])
	if not sets.is_empty() and ResourceLoader.exists(sets[0][0]):
		view.sprite_frames = load(sets[0][0])
		view.animation = &"down"
	var text: String = GameResourceLoader.readText(VIL_DIR + a["folder"] + "/villagers/" + a["name"] + ".char")
	var placed := false
	for line in text.replace("\r", "").split("\n"):
		var p := line.strip_edges().split(" ", false)
		if p.size() >= 3 and p[0] == "start" and not placed:
			view.position = Vector2(J.parseInt(p[1]), J.parseInt(p[2]))
			placed = true
		elif p.size() >= 2 and p[0] == "in" and view.sprite_frames != null:
			var d := clampi(J.parseInt(p[1]), 0, 3)
			if view.sprite_frames.has_animation(DIRECTION_ANIMS[d]):
				view.animation = DIRECTION_ANIMS[d]
			break


# ---------------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------------

## Writes a scene that inherits base_path: a bootstrap file names the base,
## an edit-state instance of it keeps the inheritance through pack(), and
## fill adds the nodes. The saved file is then made deterministic.
func _write_scene(fill: Callable, base_path: String, path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[gd_scene format=3]\n\n[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]\n\n[node name=\"%s\" instance=ExtResource(\"1_base\")]\n"
			% [base_path, path.get_file().get_basename()])
	f.close()
	var bootstrap: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	var root: VillageScene = bootstrap.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	fill.call(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("vil_to_scene: could not write %s (%s)" % [path, error_string(err)])
		_failed += 1
		return false
	_canonicalize(path)
	return true


## Drops the node unique_ids (and the base node references made of them):
## Godot 4.7 picks them at random, and the node paths say the same.
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
