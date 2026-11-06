extends SceneTree
## Checks a built village remake (the village-remake skill, step 5) with the
## legacy collision (remake_lib.inflate / reachable: ObstacleHandler's
## arithmetic) from the first spawn of its first variant:
## * every spawn and return point (entries_to) is free and reachable;
## * every door, sign and loot can be reached in its range, every villager
##   talked to (range 30, Villager.checkTalkable);
## * every villager's walk ends where it starts and runs clear of obstacles
##   and inside the village;
## * where the village can be left (the edges reached);
## * every cutscene actor's path (the remake's copy of the cutscene, the
##   villagers at their remake starts, the party beside the villager whose
##   dialog runs it) runs clear of obstacles (a warning: actors pass through
##   anything, but it shows).
##
## godot --headless --path . --script res://tools/village_remake/remake_check.gd -- <remake>
##
## Prints the report and writes report/check.txt and report/check.png (the
## background; red: where the feet can't go; green dots: where they can;
## blue: the overhead pieces; doors yellow, signs cyan, loot magenta, spawns
## white, villagers orange with their walks green, cutscene paths blue; all
## at the feet, a position + (18, 54), numbered as in check.txt). Exit code
## 1 when something fails.

const Lib := preload("res://tools/village_remake/remake_lib.gd")
const Draw := preload("res://tools/village_remake/remake_draw.gd")
## A legacy position's feet, for drawing.
const FEET := Vector2(Lib.PLAYER_W / 2.0, Lib.PLAYER_H - 2)
const TALK_RANGE := 30
const LOOT_RANGE := 35

var _lines := PackedStringArray()
var _fails := 0
var _warns := 0
var _marks: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Usage: -- <remake>")
		quit(1)
		return
	var remake := args[0]
	var dir := Lib.ROOT + remake + "/"
	var layout := Lib.load_layout(remake)
	if layout.is_empty():
		quit(1)
		return
	var place: String = layout["place"]
	for a in args.slice(1):
		if a.begins_with("--probe="):
			_probe(dir + place + "/" + place + ".tscn", layout, a.trim_prefix("--probe="))
			quit()
			return
	var image := Lib.village_image(remake, layout)
	var overlay := image.duplicate() as Image
	_check_place(dir, place, overlay, true)
	overlay.save_png(dir + "report/check.png")
	for view: Dictionary in layout.get("views", []):
		var view_image := Image.load_from_file(dir + view["place"] + "/" + view["place"] + ".png")
		view_image.convert(Image.FORMAT_RGBA8)
		_marks.clear()
		_check_place(dir, view["place"], view_image, false)
		view_image.save_png(dir + "report/check %s.png" % view["place"])
	_lines.append("")
	_lines.append("%d failed, %d warnings" % [_fails, _warns])
	DirAccess.make_dir_recursive_absolute(dir + "report")
	FileAccess.open(dir + "report/check.txt", FileAccess.WRITE).store_string("\n".join(_lines) + "\n")
	print("\n".join(_lines))
	quit(1 if _fails > 0 else 0)


## --probe=x,y[;x,y...]: for each position (a sprite's top-left, as in the
## layout), the obstacles it collides with and the layout objects and
## regions under those obstacles' rectangles.
func _probe(base_path: String, layout: Dictionary, points: String) -> void:
	var base: VillageScene = (load(base_path) as PackedScene).instantiate()
	var rects: Array[Rect2i] = []
	for shape: CollisionShape2D in base.get_node("Obstacles").get_children():
		rects.append(VillageScene.obstacle_rect(shape))
	base.free()
	var inflated := Lib.inflate(rects)
	for text in points.split(";", false):
		var p := Vector2(float(text.split(",")[0]), float(text.split(",")[1]))
		var hits := PackedStringArray()
		for i in inflated.size():
			var o := inflated[i]
			if p.y >= o[1] and p.y <= o[3] and p.x >= o[0] and p.x <= o[2]:
				hits.append("o %s (%s)" % [[rects[i].position.x, rects[i].position.y, rects[i].end.x, rects[i].end.y], _owners(rects[i], layout)])
		print("%s (feet %s): %s" % [Vector2i(p), Vector2i(p + Vector2(18, 56)), "free" if hits.is_empty() else "; ".join(hits)])


## The layout objects whose outline bounds touch r, and "region" for the
## blocked regions'.
static func _owners(r: Rect2i, layout: Dictionary) -> String:
	var out := PackedStringArray()
	for o: Dictionary in layout.get("objects", []):
		var bounds := Lib.polygon_bounds(Lib.poly(o["poly"])) if o.has("poly") else Rect2i(Lib.veci([o["rect"][0], o["rect"][1]]), Lib.veci([o["rect"][2] - o["rect"][0], o["rect"][3] - o["rect"][1]]))
		if bounds.grow(4).intersects(r):
			out.append(o["id"])
	for b: Dictionary in layout.get("blocked", []):
		if b.has("poly") and Lib.polygon_bounds(Lib.poly(b["poly"])).intersects(r):
			out.append("blocked region")
	return ", ".join(out)


func _check_place(dir: String, place: String, overlay: Image, walkable: bool) -> void:
	var files := Array(DirAccess.get_files_at(dir + place)).filter(func(f: String) -> bool:
		return f.ends_with(".tscn") and f != place + ".tscn")
	files.sort()
	var scenes: Array = []
	for file: String in files:
		scenes.append((load(dir + place + "/" + file) as PackedScene).instantiate())
	if scenes.is_empty():
		_fail("%s: no variant scenes in %s" % [place, dir + place])
		return
	var first: VillageScene = scenes[0]
	var size := first.size
	var rects: Array[Rect2i] = []
	for shape: CollisionShape2D in first.get_node("Obstacles").get_children():
		rects.append(VillageScene.obstacle_rect(shape))
	var grid := Lib.collision_grid(Lib.inflate(rects), size)
	_lines.append("== %s: %s, %d obstacles" % [place, size, rects.size()])
	_draw_overhead(first, overlay)
	_draw_blocked(grid["inflated"], overlay)
	var reach := {}
	var spawn := _spawn(first)
	if walkable and rects.size() > 0:
		if spawn == null:
			_fail("no spawn 0 in %s" % first.scene_file_path.get_file())
		else:
			# Standing villagers block the player (all statuses at once: a
			# conservative union); walking ones move on.
			var blockers: Array = []
			for a: Node in first.get_node("Actors").get_children():
				if a is ActorView and a.role == ActorView.Role.VILLAGER:
					var walk: Array = Array(a.walk) if a.walk_override else Array(Lib.read_char(a.villager_folder, a.villager_name)["walk"])
					if (Lib.walk_points(a.position, walk)["points"] as PackedVector2Array).size() == 1:
						blockers.append(a.position)
			var r := Lib.reachable(grid, size, Vector2i(spawn.position), 2, blockers)
			reach = r["positions"]
			_lines.append("Reachable from %s: %d positions" % [first.scene_file_path.get_file(), reach.size()])
			_report_exits(r["exits"], size)
			for p: Vector2i in reach:
				if p.x % 8 == 0 and p.y % 8 == 0:
					Draw.fill_rect(overlay, Rect2i(Vector2i(FEET) + p - Vector2i.ONE, Vector2i(3, 3)), Color(0.1, 1, 0.1, 0.9))
	var villager_starts := {}
	for scene: VillageScene in scenes:
		var file := scene.scene_file_path.get_file()
		_lines.append("-- %s" % file)
		for s: VillageSpawn in scene.get_node("Spawns").get_children():
			_place_check("spawn %d" % s.number, s.position, 0, reach, grid, Color.WHITE, overlay, true)
		for i in scene.entries_to.size():
			_place_check("return point %s (was %s)" % [scene.entries_to[i], scene.entries_from[i]], scene.entries_to[i], 0, reach, grid, Color.WHITE, overlay, true)
		for d: VillageDoor in scene.get_node("Doors").get_children():
			_place_check("door %s" % d.targets[0], d.position, d.radius, reach, grid, Color.YELLOW, overlay, false)
		for s: VillageSign in scene.get_node("Signs").get_children():
			_place_check("sign \"%s\"" % s.lines[0], s.position, s.radius, reach, grid, Color.CYAN, overlay, false)
		for l: VillageLoot in scene.get_node("Loot").get_children():
			_place_check("loot %s" % l.loot_name, l.position, LOOT_RANGE, reach, grid, Color.MAGENTA, overlay, false)
		for a: Node in scene.get_node("Actors").get_children():
			if a is ActorView and a.role == ActorView.Role.VILLAGER:
				var v: ActorView = a
				if not villager_starts.has(v.villager_name):
					villager_starts[v.villager_name] = v.position
				_check_villager(v, reach, grid, size, overlay)
			elif a is ActorView or a is LegacyParticles2D:
				_mark(a.position, Color.RED, overlay)
				_lines.append("  %d %s at %s" % [_marks.size(), a.name, Vector2i(a.position)])
	for scene: VillageScene in scenes:
		scene.free()
	_check_sequences(dir, place, villager_starts, grid, size, overlay, reach)


func _spawn(scene: VillageScene) -> VillageSpawn:
	for s: VillageSpawn in scene.get_node("Spawns").get_children():
		if s.number == 0 or s.number == -1:
			return s
	return null


## A spawn (range 0: it must be free and reachable itself) or a door, sign
## or loot (some reachable position within range: dist < range, as their
## isInRange).
func _place_check(what: String, pos: Vector2, range: int, reach: Dictionary, grid: Dictionary,
		color: Color, overlay: Image, is_spot: bool) -> void:
	var n := _mark(pos, color, overlay)
	if range > 0:
		Draw.circle(overlay, pos + FEET, range, color)
	if reach.is_empty():
		var free := not Lib.grid_collides(grid, pos.x, pos.y)
		_lines.append("  %d %s at %s%s" % [n, what, Vector2i(pos), "" if free else ": inside an obstacle"])
		return
	if is_spot:
		if Lib.grid_collides(grid, pos.x, pos.y):
			_fail("%d %s at %s is inside an obstacle" % [n, what, Vector2i(pos)])
		elif not _near(reach, pos, 3.0):
			_fail("%d %s at %s can't be reached from spawn 0" % [n, what, Vector2i(pos)])
		else:
			_lines.append("  %d ok   %s at %s" % [n, what, Vector2i(pos)])
		return
	var best := _closest(reach, pos)
	if best < range:
		_lines.append("  %d ok   %s at %s (reached %.0f px away, range %d)" % [n, what, Vector2i(pos), best, range])
	else:
		_fail("%d %s at %s: the closest reachable position is %.0f px away, range %d" % [n, what, Vector2i(pos), best, range])


func _check_villager(v: ActorView, reach: Dictionary, grid: Dictionary, size: Vector2i, overlay: Image) -> void:
	var walk: Array = Array(v.walk) if v.walk_override else Array(Lib.read_char(v.villager_folder, v.villager_name)["walk"])
	var w := Lib.walk_points(v.position, walk)
	var pts: PackedVector2Array = w["points"]
	var feet := PackedVector2Array()
	for p in pts:
		feet.append(p + FEET)
	Draw.polyline(overlay, feet, Color(0.3, 1, 0.3, 1), false, 2)
	var n := _mark(v.position, Color.ORANGE, overlay)
	var what := "villager %s at %s%s" % [v.villager_name, Vector2i(v.position), "" if v.walk_override else " (not moved: walk_override off)"]
	var problems := PackedStringArray()
	if not w["closed"]:
		problems.append("its walk does not end where it starts")
	var hit := _first_hit(pts, grid, size)
	if hit != Vector2.INF:
		problems.append("its walk runs into an obstacle or off the village at %s" % Vector2i(hit))
	if not reach.is_empty():
		var best := INF
		for p in pts:
			best = minf(best, _closest(reach, p))
		if best >= TALK_RANGE:
			problems.append("it can't be talked to (closest reachable position %.0f px away)" % best)
	if problems.is_empty():
		_lines.append("  %d ok   %s, %s" % [n, what, "standing" if pts.size() == 1 else "walking %d legs" % (pts.size() - 1)])
	else:
		_fail("%d %s: %s" % [n, what, "; ".join(problems)])


## The first point of the polyline (every 2 px) that collides or leaves the
## village, else Vector2.INF.
static func _first_hit(pts: PackedVector2Array, grid: Dictionary, size: Vector2i) -> Vector2:
	for i in pts.size():
		var a := pts[i]
		var b := pts[mini(i + 1, pts.size() - 1)]
		if is_nan(a.x) or is_nan(b.x):
			continue
		var n := maxi(int(a.distance_to(b) / 2.0), 1)
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			if Lib.grid_collides(grid, p.x, p.y) or p.x < 0 or p.y < 0 or p.x > size.x - Lib.PLAYER_W or p.y > size.y - Lib.PLAYER_H:
				return p
	return Vector2.INF


## The party's start in a cutscene that the villager at v starts by being
## talked to: the reachable position in talking range nearest to just below
## v (Kin), Celis one step further away (Lib.party_starts without reach).
static func _talking_party(reach: Dictionary, v: Vector2) -> Dictionary:
	if reach.is_empty():
		return Lib.party_starts(v)
	var best := Vector2.INF
	for dy in range(-TALK_RANGE, TALK_RANGE + 1, 2):
		for dx in range(-TALK_RANGE, TALK_RANGE + 1, 2):
			var p := Vector2i(roundi(v.x / 2.0) * 2 + dx, roundi(v.y / 2.0) * 2 + dy)
			if reach.has(p) and Vector2(p).distance_to(v) < TALK_RANGE \
					and (best == Vector2.INF or Vector2(p).distance_to(v + Vector2(0, 28)) < best.distance_to(v + Vector2(0, 28))):
				best = Vector2(p)
	if best == Vector2.INF:
		return Lib.party_starts(v)
	var away := (best - v).normalized() if best != v else Vector2.DOWN
	return {"Kin": best, "Celis": best + away * 30.0}


func _check_sequences(dir: String, place: String, starts: Dictionary, grid: Dictionary, size: Vector2i, overlay: Image, reach: Dictionary) -> void:
	for name in Lib.sequences_in(place):
		var copy := dir + "sequences/" + name + ".seq"
		var is_copy := FileAccess.file_exists(copy)
		var text := FileAccess.get_file_as_string(copy if is_copy else Lib.SEQUENCES + name + ".seq")
		var parsed := Lib.parse_sequence(text)
		var seq_starts := starts.duplicate()
		var runners := Lib.runners(place, name)
		if not runners.is_empty() and starts.has(runners[0]):
			seq_starts.merge(_talking_party(reach, starts[runners[0]]), true)
		var paths := Lib.sequence_paths(parsed, seq_starts)
		var problems := PackedStringArray()
		for a: Dictionary in parsed["actors"]:
			if not paths.has(a["index"]):
				continue
			var pts: PackedVector2Array = paths[a["index"]]
			var feet := PackedVector2Array()
			for p in pts:
				feet.append(p + FEET)
			Draw.polyline(overlay, feet, Color(0.4, 0.6, 1, 1), false, 2)
			var hit := _first_hit(pts, grid, size)
			if hit != Vector2.INF and hit.x >= 0 and hit.y >= 0 and hit.x <= size.x - Lib.PLAYER_W and hit.y <= size.y - Lib.PLAYER_H:
				problems.append("%s runs into an obstacle at %s" % [a["name"].get_file(), Vector2i(hit)])
		var first := Vector2.ZERO
		for i in paths:
			if not paths[i].is_empty():
				first = paths[i][0]
				break
		var n := _mark(first, Color(0.4, 0.6, 1), overlay)
		var what := "cutscene %s (%s)" % [name, "remake copy" if is_copy else "NOT COPIED: default positions"]
		if not is_copy:
			_warn("%d %s" % [n, what])
		if problems.is_empty():
			_lines.append("  %d ok   %s" % [n, what])
		else:
			_warn("%d %s: %s" % [n, what, "; ".join(problems)])


func _report_exits(exits: Array, size: Vector2i) -> void:
	var edges := {}
	for p: Vector2i in exits:
		var edge := "left" if p.x < 0 else "right" if p.x > size.x - Lib.PLAYER_W else "top" if p.y < 0 else "bottom"
		var along := p.y if edge == "left" or edge == "right" else p.x
		if not edges.has(edge):
			edges[edge] = [along, along]
		edges[edge][0] = mini(edges[edge][0], along)
		edges[edge][1] = maxi(edges[edge][1], along)
	if edges.is_empty():
		_fail("the village can't be left on foot (no edge is reachable)")
	for edge: String in edges:
		_lines.append("Exit: %s edge, positions %d..%d along it" % [edge, edges[edge][0], edges[edge][1]])


func _draw_blocked(inflated: Array, overlay: Image) -> void:
	for o: PackedInt32Array in inflated:
		Draw.fill_rect(overlay, Rect2i(Vector2i(o[0], o[1]) + Vector2i(FEET), Vector2i(o[2] - o[0] + 1, o[3] - o[1] + 1)), Color(1, 0, 0, 0.25))


func _draw_overhead(scene: VillageScene, overlay: Image) -> void:
	for s: Sprite2D in scene.get_node("Overhead").get_children():
		var img := s.texture.get_image()
		img.decompress()
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.9:
					Draw.blend(overlay, int(s.position.x) + x, int(s.position.y) + y, Color(0.2, 0.4, 1, 0.3))


func _mark(pos: Vector2, color: Color, overlay: Image) -> int:
	_marks.append(pos)
	Draw.marker(overlay, pos + FEET, _marks.size(), color)
	return _marks.size()


static func _closest(reach: Dictionary, pos: Vector2) -> float:
	var best := INF
	var c := Vector2i(roundi(pos.x / 2.0) * 2, roundi(pos.y / 2.0) * 2)
	for dy in range(-80, 81, 2):
		for dx in range(-80, 81, 2):
			if reach.has(c + Vector2i(dx, dy)):
				best = minf(best, pos.distance_to(Vector2(c + Vector2i(dx, dy))))
	return best


static func _near(reach: Dictionary, pos: Vector2, within: float) -> bool:
	return _closest(reach, pos) <= within


func _fail(text: String) -> void:
	_fails += 1
	_lines.append("  FAIL %s" % text)


func _warn(text: String) -> void:
	_warns += 1
	_lines.append("  WARN %s" % text)
