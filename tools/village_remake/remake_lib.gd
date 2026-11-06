extends RefCounted
## Shared code of the village-remake tools (tools/village_remake/, the
## village-remake skill: .claude/skills/village-remake/SKILL.md): the layout
## file, the rules that turn its outlines into collision rectangles and
## overhead pieces, the legacy collision the check simulates, and the paths
## of cutscene actors.
##
## Coordinates are village pixels of the remake (origin at the background's
## top-left, y down), as in the scenes. A legacy position is a sprite's
## top-left corner; its feet are at y + PLAYER_H.
##
## The rules (docs in the skill, "Collision and overhead"): an "o" rectangle
## blocks the player's position inflated by its size
## (ObstacleHandler.addObstacle): the feet can't be in [y1, y2 + 16.8], the
## sprite's centre not in [x1 - 9, x2 + 9.9]. So for each column x of an
## object, with top(x) and base(x) its highest and lowest pixel:
## * footprint (feet blocked): from min(top(x) + PLAYER_H, base(x) - PLAYER_H),
##   but not above top(x), down to base(x). A player behind it (feet above
##   the footprint) is then covered by what is above the cut below;
## * overhead (drawn over the sprites): its pixels with y < base(x) - PLAYER_H.
##   A player in front (feet below base(x) + 16) never reaches them. A tree
##   gives "cut" instead (where its trunk starts): its whole canopy is
##   overhead, as in the original villages, so a player behind the canopy
##   (feet above the trunk's footprint) is covered to the feet;
## * the overhead less the ground at its edges (trim_ground): an outline
##   drawn a little outside the art leaves no road or grass over a sprite.

const ROOT := "res://proto/villages/"
const SCENES := "res://scenes/villages/"
const SEQUENCES := "res://maps/Story/Sequences/"
const CHARS := "res://maps/Village/"
## The legacy sprite size (Sprite.STANDARD_WIDTH / HEIGHT, Player.getWidth /
## getHeight) the obstacles are inflated by.
const PLAYER_W := 36
const PLAYER_H := 56
## The grid the collision rectangles are built on (village pixels).
const CELL := 4
## Cutscene directions (Values.UP .. LEFT) as steps.
const STEPS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


## A grid of bytes (0 or 1) at origin, size cells wide and high (village
## pixels); everything outside it is 0.
class Mask:
	extends RefCounted
	var origin := Vector2i.ZERO
	var size := Vector2i.ZERO
	var data := PackedByteArray()

	func _init(p_origin: Vector2i, p_size: Vector2i) -> void:
		origin = p_origin
		size = Vector2i(maxi(p_size.x, 0), maxi(p_size.y, 0))
		data.resize(size.x * size.y)

	func rect() -> Rect2i:
		return Rect2i(origin, size)

	func at(x: int, y: int) -> bool:
		var lx := x - origin.x
		var ly := y - origin.y
		return lx >= 0 and ly >= 0 and lx < size.x and ly < size.y and data[ly * size.x + lx] != 0

	func put(x: int, y: int, value: int) -> void:
		var lx := x - origin.x
		var ly := y - origin.y
		if lx >= 0 and ly >= 0 and lx < size.x and ly < size.y:
			data[ly * size.x + lx] = value

	## Sets (value 1) or clears (0) every cell where other is set.
	func merge(other: Mask, value: int) -> void:
		var r := rect().intersection(other.rect())
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if other.at(x, y):
					put(x, y, value)

	func count() -> int:
		return data.count(1)


## The layout of the remake (ROOT/<remake>/layout.json), or {} after printing
## what is wrong with it.
static func load_layout(remake: String) -> Dictionary:
	var path := ROOT + remake + "/layout.json"
	if not FileAccess.file_exists(path):
		printerr("No layout: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		printerr("%s is not a JSON object" % path)
		return {}
	var layout: Dictionary = parsed
	for key in ["place", "source", "size"]:
		if not layout.has(key):
			printerr("%s: no \"%s\"" % [path, key])
			return {}
	return layout


## The remake's background: the layout's source picture, cut to "crop" ([x1,
## y1, x2, y2] in source pixels; the whole picture if left out) and scaled by
## "scale" (nearest neighbour when it is a whole number), as RGBA8. Its size
## must be the layout's "size".
static func village_image(remake: String, layout: Dictionary) -> Image:
	var image := Image.load_from_file(ROOT + remake + "/" + str(layout["source"]))
	image.convert(Image.FORMAT_RGBA8)
	if layout.has("crop"):
		var c: Array = layout["crop"]
		image = image.get_region(Rect2i(int(c[0]), int(c[1]), int(c[2]) - int(c[0]), int(c[3]) - int(c[1])))
	var scale := float(layout.get("scale", 1.0))
	if scale != 1.0:
		var whole := is_equal_approx(scale, roundf(scale))
		image.resize(roundi(image.get_width() * scale), roundi(image.get_height() * scale),
				Image.INTERPOLATE_NEAREST if whole else Image.INTERPOLATE_BILINEAR)
	if image.get_size() != veci(layout["size"]):
		printerr("The village image is %s, the layout's size %s" % [image.get_size(), layout["size"]])
	return image


static func vec(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func veci(a: Variant) -> Vector2i:
	return Vector2i(roundi(float(a[0])), roundi(float(a[1])))


static func poly(points: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(vec(p))
	return out


## Fills the polygon (even-odd, pixel centres) into mask with value.
static func fill_polygon(mask: Mask, points: PackedVector2Array, value := 1) -> void:
	if points.size() < 3:
		return
	var ymin := INF
	var ymax := -INF
	for p in points:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var n := points.size()
	for y in range(maxi(floori(ymin), mask.origin.y), mini(ceili(ymax) + 1, mask.origin.y + mask.size.y)):
		var cy := y + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := points[i]
			var b := points[(i + 1) % n]
			if (a.y <= cy) != (b.y <= cy):
				xs.append(a.x + (cy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			for x in range(maxi(ceili(xs[k] - 0.5), mask.origin.x), mini(floori(xs[k + 1] - 0.5), mask.origin.x + mask.size.x - 1) + 1):
				mask.put(x, y, value)


static func polygon_bounds(points: PackedVector2Array) -> Rect2i:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2i(Vector2i(floori(lo.x), floori(lo.y)), Vector2i(ceili(hi.x) - floori(lo.x) + 1, ceili(hi.y) - floori(lo.y) + 1))


## The mask of a layout region: {"poly": [[x, y], ...]}, {"rect": [x1, y1,
## x2, y2]}, {"flood": [x, y], "tolerance": t, "within": [x1, y1, x2, y2]}
## (the pixels of background connected to the seed whose colour differs from
## the seed's by at most t/255 per channel) or {"like": [x, y], "tolerance":
## t, "within": [...]} (every such pixel within, connected or not: grass
## showing through a sign's gaps).
static func region_mask(region: Dictionary, size: Vector2i, background: Image) -> Mask:
	if region.has("poly"):
		var points := poly(region["poly"])
		var m := Mask.new(polygon_bounds(points).position, polygon_bounds(points).size)
		fill_polygon(m, points)
		return m
	if region.has("rect"):
		var r: Array = region["rect"]
		var m := Mask.new(Vector2i(int(r[0]), int(r[1])), Vector2i(int(r[2]) - int(r[0]), int(r[3]) - int(r[1])))
		m.data.fill(1)
		return m
	if region.has("flood"):
		var within := Rect2i(Vector2i.ZERO, size)
		if region.has("within"):
			var w: Array = region["within"]
			within = Rect2i(Vector2i(int(w[0]), int(w[1])), Vector2i(int(w[2]) - int(w[0]), int(w[3]) - int(w[1])))
		return flood(background, veci(region["flood"]), float(region.get("tolerance", 40)) / 255.0, within)
	if region.has("like"):
		var w: Array = region.get("within", [0, 0, size.x, size.y])
		var within := Rect2i(Vector2i(int(w[0]), int(w[1])), Vector2i(int(w[2]) - int(w[0]), int(w[3]) - int(w[1])))
		within = within.intersection(Rect2i(Vector2i.ZERO, size))
		var c0 := background.get_pixelv(veci(region["like"]))
		var t := float(region.get("tolerance", 40)) / 255.0
		var m := Mask.new(within.position, within.size)
		for y in range(within.position.y, within.end.y):
			for x in range(within.position.x, within.end.x):
				var c := background.get_pixel(x, y)
				if absf(c.r - c0.r) <= t and absf(c.g - c0.g) <= t and absf(c.b - c0.b) <= t:
					m.put(x, y, 1)
		return m
	printerr("Unknown region: %s" % region)
	return Mask.new(Vector2i.ZERO, Vector2i.ZERO)


## The pixels of image within bounds connected (4-way) to seed whose colour
## is within tolerance of the seed's in every channel.
static func flood(image: Image, seed: Vector2i, tolerance: float, bounds: Rect2i) -> Mask:
	var m := Mask.new(bounds.position, bounds.size)
	if not bounds.has_point(seed):
		return m
	var c0 := image.get_pixelv(seed)
	var stack: Array[Vector2i] = [seed]
	m.put(seed.x, seed.y, 1)
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in STEPS:
			var q: Vector2i = p + d
			if not bounds.has_point(q) or m.at(q.x, q.y):
				continue
			var c := image.get_pixelv(q)
			if absf(c.r - c0.r) <= tolerance and absf(c.g - c0.g) <= tolerance and absf(c.b - c0.b) <= tolerance:
				m.put(q.x, q.y, 1)
				stack.append(q)
	return m


## The parts of a layout object: "mask" (its pixels), "overhead" (empty when
## its "overhead" is false) and "footprint" (feet blocked), by the rules at
## the top. Options: "solid": true blocks the whole outline; "footprint":
## [[x1, y1, x2, y2], ...] blocks those instead; "base": [[x, y], ...] is the
## ground line when it is not the outline's lowest pixel in each column;
## "cut": y, the overhead is the outline above y (a tree's canopy) instead of
## above base(x) - PLAYER_H. all_parts trims the ground off the overhead.
static func object_parts(object: Dictionary, size: Vector2i, background: Image) -> Dictionary:
	var mask := region_mask(object, size, background)
	var overhead := Mask.new(mask.origin, mask.size)
	var footprint := Mask.new(mask.origin, mask.size)
	var base_line := poly(object["base"]) if object.has("base") else PackedVector2Array()
	var fixed_cut: int = int(object["cut"]) if object.has("cut") else -1
	for x in range(mask.origin.x, mask.origin.x + mask.size.x):
		var top := -1
		var base := -1
		for y in range(mask.origin.y, mask.origin.y + mask.size.y):
			if mask.at(x, y):
				if top == -1:
					top = y
				base = y
		if top == -1:
			continue
		if not base_line.is_empty():
			base = roundi(_line_y(base_line, x + 0.5))
		var foot_top := maxi(top, mini(top + PLAYER_H, base - PLAYER_H))
		var cut := fixed_cut if fixed_cut >= 0 else base - PLAYER_H
		for y in range(mask.origin.y, mask.origin.y + mask.size.y):
			if mask.at(x, y) and y < cut and object.get("overhead", true):
				overhead.put(x, y, 1)
		if object.get("solid", false):
			for y in range(top, base + 1):
				if mask.at(x, y):
					footprint.put(x, y, 1)
		elif not object.has("footprint"):
			for y in range(foot_top, base + 1):
				footprint.put(x, y, 1)
	if object.has("footprint"):
		for r in object["footprint"]:
			var m := region_mask({"rect": r}, size, background)
			footprint = _grow(footprint, m.rect())
			footprint.merge(m, 1)
	return {"mask": mask, "overhead": overhead, "footprint": footprint}


## The y of the polyline at x (clamped to its ends).
static func _line_y(line: PackedVector2Array, x: float) -> float:
	if x <= line[0].x:
		return line[0].y
	for i in range(1, line.size()):
		if x <= line[i].x:
			var a := line[i - 1]
			var b := line[i]
			return a.y + (x - a.x) / maxf(b.x - a.x, 0.001) * (b.y - a.y)
	return line[line.size() - 1].y


## mask grown to cover r too.
static func _grow(mask: Mask, r: Rect2i) -> Mask:
	var bigger := Mask.new(mask.rect().merge(r).position, mask.rect().merge(r).size)
	bigger.merge(mask, 1)
	return bigger


## Every object's parts (object_parts), by id, in layout order, each
## overhead less the ground at its edges (trim_ground; "trim": false on an
## object keeps its whole outline) and less the layout's "ground" regions
## (ground inside an outline that the trim can't reach).
static func all_parts(layout: Dictionary, background: Image) -> Dictionary:
	var size := veci(layout["size"])
	var out := {}
	var objects := Mask.new(Vector2i.ZERO, size)
	for object: Dictionary in layout.get("objects", []):
		out[object["id"]] = object_parts(object, size, background)
		objects.merge(out[object["id"]]["mask"], 1)
	for object: Dictionary in layout.get("objects", []):
		var p: Dictionary = out[object["id"]]
		if object.get("trim", true) and (p["overhead"] as Mask).count() > 0:
			(p["overhead"] as Mask).merge(trim_ground(p["mask"], background, objects), 0)
	for region: Dictionary in layout.get("ground", []):
		var m := region_mask(region, size, background)
		for id in out:
			(out[id]["overhead"] as Mask).merge(m, 0)
	return out


## trim_ground: the ground colours are those of a ring TRIM_RING px wide
## around the outline (other objects' outlines left out), kept in buckets of
## 1/TRIM_BUCKETS per channel; a colour is ground-like when its bucket or a
## neighbouring one is a ground colour's and it is light (luma at least
## TRIM_LIGHT: road and grass; a shadow on the grass is as dark as a
## canopy's edge, so it stays, and the trim can't get into a canopy through
## it). From the outline's edge inwards, at most TRIM_DEPTH px deep, a pixel
## is ground when it is ground-like, differs from the ground pixel it is
## reached from by at most TRIM_STEP per channel (the art's dark outline
## stops it) and at least TRIM_OPEN of its 8 neighbours are ground-like or
## outside every outline (a 1 px gap in the outline does not let it into a
## canopy whose highlights are the grass's colour). Each flood starts at an
## edge pixel next to a ground pixel outside the outline (its origin, within
## TRIM_ORIGIN per channel) and keeps within TRIM_ORIGIN of that origin's
## colour: one that starts on the road stays on road colours (the ring of a
## big object holds many colours: a stall's pink wares, near its roof's).
## The origin must match the pixel TRIM_OUTSIDE px further out too, so an
## outline drawn a little inside the art does not start a flood from the
## art outside it (it can't fix one drawn well inside: draw them outside).
## A last step without the TRIM_OPEN rule takes the ground along the art's
## outline.
const TRIM_RING := 4
const TRIM_DEPTH := 40
const TRIM_BUCKETS := 16
const TRIM_STEP := 0.12
const TRIM_LIGHT := 0.6
const TRIM_OPEN := 6
const TRIM_ORIGIN := 0.14
const TRIM_OUTSIDE := 4
const NEIGHBOURS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]


## The pixels of mask that are ground (road, grass, shadow) at its edges:
## where an outline drawn by hand runs outside the art. objects: every
## object's outline (their pixels are not ground).
static func trim_ground(mask: Mask, background: Image, objects: Mask) -> Mask:
	var bounds := Rect2i(Vector2i.ZERO, background.get_size())
	var area := mask.rect().grow(TRIM_RING).intersection(bounds)
	var visited := Mask.new(area.position, area.size)
	var edge: Array[Vector2i] = []
	for y in range(mask.origin.y, mask.origin.y + mask.size.y):
		for x in range(mask.origin.x, mask.origin.x + mask.size.x):
			if not mask.at(x, y):
				continue
			visited.put(x, y, 1)
			for d in STEPS:
				if not mask.at(x + d.x, y + d.y) and bounds.has_point(Vector2i(x + d.x, y + d.y)):
					edge.append(Vector2i(x, y))
					break
	var palette := {}
	var layer := edge
	for i in TRIM_RING:
		var next: Array[Vector2i] = []
		for p in layer:
			for d in STEPS:
				var q: Vector2i = p + d
				if not area.has_point(q) or visited.at(q.x, q.y):
					continue
				visited.put(q.x, q.y, 1)
				next.append(q)
				if not objects.at(q.x, q.y):
					palette[_bucket(background.get_pixelv(q))] = true
		layer = next
	# The ground colours with their neighbouring buckets, so that a colour is
	# near one with a single lookup.
	var n := TRIM_BUCKETS
	var near := {}
	for key: int in palette:
		var r := key / (n * n)
		var g := (key / n) % n
		var b := key % n
		for dr in range(maxi(r - 1, 0), mini(r + 2, n)):
			for dg in range(maxi(g - 1, 0), mini(g + 2, n)):
				for db in range(maxi(b - 1, 0), mini(b + 2, n)):
					near[(dr * n + dg) * n + db] = true
	var t := TrimArea.new(area)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := background.get_pixel(x, y)
			var i := t.index(x, y)
			if 0.299 * c.r + 0.587 * c.g + 0.114 * c.b >= TRIM_LIGHT and near.has(_bucket(c)):
				t.like[i] = 1
			if t.like[i] == 1 or not objects.at(x, y):
				t.free[i] = 1
	var ground := Mask.new(mask.origin, mask.size)
	layer = []
	for p in edge:
		if t.like[t.index(p.x, p.y)] == 0 or not t.is_open(p):
			continue
		var c := background.get_pixelv(p)
		for d in STEPS:
			# The ground outside: o next to the edge, as o2 further out (an
			# outline drawn across the art has art outside it, cut off by the
			# art's own edge within a few px).
			var o: Vector2i = p + d
			var o2: Vector2i = p + d * TRIM_OUTSIDE
			if not bounds.has_point(o2) or objects.at(o.x, o.y) or objects.at(o2.x, o2.y):
				continue
			var oc := background.get_pixelv(o)
			var oc2 := background.get_pixelv(o2)
			if (absf(c.r - oc.r) <= TRIM_ORIGIN and absf(c.g - oc.g) <= TRIM_ORIGIN and absf(c.b - oc.b) <= TRIM_ORIGIN
					and absf(oc2.r - oc.r) <= TRIM_ORIGIN and absf(oc2.g - oc.g) <= TRIM_ORIGIN and absf(oc2.b - oc.b) <= TRIM_ORIGIN):
				ground.put(p.x, p.y, 1)
				t.origin[t.index(p.x, p.y)] = oc
				layer.append(p)
				break
	for i in TRIM_DEPTH:
		layer = _trim_step(layer, ground, mask, background, t, true)
		if layer.is_empty():
			break
	# The ground along the art's outline (it fails the TRIM_OPEN rule): one
	# step from all the ground found, without the rule.
	layer = []
	for y in range(mask.origin.y, mask.origin.y + mask.size.y):
		for x in range(mask.origin.x, mask.origin.x + mask.size.x):
			if ground.at(x, y):
				layer.append(Vector2i(x, y))
	_trim_step(layer, ground, mask, background, t, false)
	return ground


## trim_ground's facts about the pixels of its area (the outline and its
## ring): like (a ground-like colour), free (ground-like or outside every
## outline), worked out when asked open (TRIM_OPEN neighbours free), and
## for a ground pixel the colour of its flood's origin.
class TrimArea:
	extends RefCounted
	var area := Rect2i()
	var like := PackedByteArray()
	var free := PackedByteArray()
	var open := PackedByteArray() # 0: not worked out yet, 1: no, 2: yes
	var origin := PackedColorArray()

	func _init(p_area: Rect2i) -> void:
		area = p_area
		like.resize(area.size.x * area.size.y)
		free.resize(area.size.x * area.size.y)
		open.resize(area.size.x * area.size.y)
		origin.resize(area.size.x * area.size.y)

	func index(x: int, y: int) -> int:
		return (y - area.position.y) * area.size.x + x - area.position.x

	## Whether at least TRIM_OPEN of p's 8 neighbours are free (outside the
	## area counts as free: the picture's edge or beyond the ring).
	func is_open(p: Vector2i) -> bool:
		var i := index(p.x, p.y)
		if open[i] == 0:
			var count := 0
			for d in NEIGHBOURS:
				var q: Vector2i = p + d
				if not area.has_point(q) or free[index(q.x, q.y)] == 1:
					count += 1
			open[i] = 2 if count >= TRIM_OPEN else 1
		return open[i] == 2


## One step of trim_ground's flood from layer: the new ground pixels (also
## set in ground). open_rule: TRIM_OPEN applies.
static func _trim_step(layer: Array[Vector2i], ground: Mask, mask: Mask, background: Image, t: TrimArea,
		open_rule: bool) -> Array[Vector2i]:
	var next: Array[Vector2i] = []
	for p in layer:
		var c := background.get_pixelv(p)
		var oc := t.origin[t.index(p.x, p.y)]
		for d in STEPS:
			var q: Vector2i = p + d
			if not mask.at(q.x, q.y) or ground.at(q.x, q.y) or t.like[t.index(q.x, q.y)] == 0:
				continue
			var cq := background.get_pixelv(q)
			if (absf(cq.r - c.r) <= TRIM_STEP and absf(cq.g - c.g) <= TRIM_STEP and absf(cq.b - c.b) <= TRIM_STEP
					and absf(cq.r - oc.r) <= TRIM_ORIGIN and absf(cq.g - oc.g) <= TRIM_ORIGIN and absf(cq.b - oc.b) <= TRIM_ORIGIN
					and (not open_rule or t.is_open(q))):
				ground.put(q.x, q.y, 1)
				t.origin[t.index(q.x, q.y)] = oc
				next.append(q)
	return next


static func _bucket(c: Color) -> int:
	var n := TRIM_BUCKETS
	return (clampi(int(c.r * n), 0, n - 1) * n + clampi(int(c.g * n), 0, n - 1)) * n + clampi(int(c.b * n), 0, n - 1)


## Where the feet can't be: the objects' footprints and the "blocked"
## regions, less the "walkable" ones.
static func blocked_mask(layout: Dictionary, parts: Dictionary, background: Image) -> Mask:
	var size := veci(layout["size"])
	var blocked := Mask.new(Vector2i.ZERO, size)
	for id in parts:
		blocked.merge(parts[id]["footprint"], 1)
	for region: Dictionary in layout.get("blocked", []):
		blocked.merge(region_mask(region, size, background), 1)
	for region: Dictionary in layout.get("walkable", []):
		blocked.merge(region_mask(region, size, background), 0)
	return blocked


## The blocked mask as "o" rectangles [x1, y1, x2, y2] on the CELL grid (a
## cell is blocked when any of its pixels is), greedily merged: each
## rectangle grows right from its top-left cell, then down.
static func mask_to_rects(mask: Mask) -> Array[Rect2i]:
	var cols := ceili(float(mask.size.x) / CELL)
	var rows := ceili(float(mask.size.y) / CELL)
	var cells := PackedByteArray()
	cells.resize(cols * rows)
	for cy in rows:
		for cx in cols:
			var hit := false
			for y in range(cy * CELL, mini((cy + 1) * CELL, mask.size.y)):
				for x in range(cx * CELL, mini((cx + 1) * CELL, mask.size.x)):
					if mask.data[y * mask.size.x + x] != 0:
						hit = true
						break
				if hit:
					break
			cells[cy * cols + cx] = 1 if hit else 0
	var out: Array[Rect2i] = []
	for cy in rows:
		for cx in cols:
			if cells[cy * cols + cx] != 1:
				continue
			var w := 1
			while cx + w < cols and cells[cy * cols + cx + w] == 1:
				w += 1
			var h := 1
			var grow := true
			while grow and cy + h < rows:
				for i in w:
					if cells[(cy + h) * cols + cx + i] != 1:
						grow = false
						break
				if grow:
					h += 1
			for j in h:
				for i in w:
					cells[(cy + j) * cols + cx + i] = 2
			out.append(Rect2i(mask.origin + Vector2i(cx, cy) * CELL, Vector2i(w, h) * CELL))
	return out


## The legacy obstacle test (ObstacleHandler.addObstacle + Obstacle.
## checkCollision, the same arithmetic): rects are the "o" rectangles; the
## result is [x1, y1, x2, y2] per rectangle, the positions that collide.
static func inflate(rects: Array[Rect2i]) -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for r in rects:
		out.append(PackedInt32Array([int(r.position.x - 3 * PLAYER_W / 4.0), int(r.position.y - PLAYER_H),
			int(r.end.x - 0.9 * PLAYER_W / 4.0), int(r.end.y - 2.8 * PLAYER_H / 4.0)]))
	return out


static func collides(inflated: Array[PackedInt32Array], x: float, y: float) -> bool:
	for o in inflated:
		if y >= o[1] and y <= o[3] and x >= o[0] and x <= o[2]:
			return true
	return false


## collides() for every whole position from -margin to size + margin, as a
## lookup: {"origin", "w", "cells": PackedByteArray}. Positions off the grid
## fall back to collides().
static func collision_grid(inflated: Array[PackedInt32Array], size: Vector2i, margin := 64) -> Dictionary:
	var origin := Vector2i(-margin, -margin)
	var w := size.x + 2 * margin
	var h := size.y + 2 * margin
	var cells := PackedByteArray()
	cells.resize(w * h)
	for o in inflated:
		for y in range(maxi(o[1], origin.y), mini(o[3], origin.y + h - 1) + 1):
			var row := (y - origin.y) * w
			for x in range(maxi(o[0], origin.x), mini(o[2], origin.x + w - 1) + 1):
				cells[row + x - origin.x] = 1
	return {"origin": origin, "w": w, "h": h, "cells": cells, "inflated": inflated}


static func grid_collides(grid: Dictionary, x: float, y: float) -> bool:
	if x != floorf(x) or y != floorf(y):
		return collides(grid["inflated"], x, y)
	var origin: Vector2i = grid["origin"]
	var w: int = grid["w"]
	var gx := int(x) - origin.x
	var gy := int(y) - origin.y
	if gx < 0 or gy < 0 or gx >= w or gy >= int(grid["h"]):
		return collides(grid["inflated"], x, y)
	return (grid["cells"] as PackedByteArray)[gy * w + gx] != 0


## The player positions (every step pixels, top-left corners) reachable on
## foot from start: a Dictionary Vector2i -> true, and under "exits" the
## positions past an edge (the village is left there: Village.update).
## blockers: villagers' positions; the player can't come within
## VILLAGER_BLOCK of one (Player.checkCollision).
static func reachable(grid: Dictionary, size: Vector2i, start: Vector2i, step := 2, blockers: Array = []) -> Dictionary:
	var limit := Vector2i(size.x - PLAYER_W, size.y - PLAYER_H)
	var seen := {start: true}
	var exits: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in STEPS:
			var q: Vector2i = p + d * step
			if seen.has(q) or grid_collides(grid, q.x, q.y) or _blocked_by(blockers, p, q):
				continue
			seen[q] = true
			if q.x < 0 or q.y < 0 or q.x > limit.x or q.y > limit.y:
				exits.append(q)
				continue
			queue.append(q)
	return {"positions": seen, "exits": exits}


## Player.checkCollision: within this distance of a villager the player
## can't move closer to it (a step from farther away still can end inside).
const VILLAGER_BLOCK := 30.0


static func _blocked_by(blockers: Array, from: Vector2i, to: Vector2i) -> bool:
	for b: Vector2 in blockers:
		var d := b.distance_to(Vector2(from))
		if d < VILLAGER_BLOCK and b.distance_to(Vector2(to)) < d:
			return true
	return false


## The walk of a villager (.char "in" lines without "in"): its corner
## points from start, and whether it ends where it starts.
static func walk_points(start: Vector2, walk: Array) -> Dictionary:
	var points := PackedVector2Array([start])
	var p := start
	for line: String in walk:
		var w := line.split(" ", false)
		if w.size() < 3 or w[2] == "true":
			continue
		p += Vector2(STEPS[int(w[0])]) * float(w[1])
		points.append(p)
	return {"points": points, "closed": p.is_equal_approx(start)}


## The start and the "in" lines of a .char file (outside forstatus blocks:
## the remakes don't support those).
static func read_char(folder: String, name: String) -> Dictionary:
	var path := CHARS + folder + "/villagers/" + name + ".char"
	var out := {"start": null, "walk": PackedStringArray(), "image": ""}
	if not FileAccess.file_exists(path):
		return out
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		var w := raw.strip_edges().split(" ", false)
		w = PackedStringArray(Array(w).map(func(s: String) -> String: return s.strip_edges()).filter(func(s: String) -> bool: return s != ""))
		if w.is_empty():
			continue
		match w[0]:
			"start":
				out["start"] = [int(w[1]), int(w[2])]
			"in":
				out["walk"].append(" ".join(w.slice(1)))
			"image":
				out["image"] = w[1]
	return out


# ---------------------------------------------------------------------------
# Cutscenes
# ---------------------------------------------------------------------------

## The cutscenes that take place in place (their info line's name, the
## village they load), as "<chapter>/<name>" (without ".seq").
static func sequences_in(place: String) -> PackedStringArray:
	var out := PackedStringArray()
	for chapter in DirAccess.get_directories_at(SEQUENCES):
		for file in DirAccess.get_files_at(SEQUENCES + chapter):
			if file.ends_with(".seq") and sequence_place(FileAccess.get_file_as_string(SEQUENCES + chapter + "/" + file)) == place:
				out.append(chapter + "/" + file.get_basename())
	return out


static func sequence_place(text: String) -> String:
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("info "):
			var m := RegEx.create_from_string("name=\"([^\"]*)\"").search(line)
			return m.get_string(1) if m != null else ""
	return ""


## The party members as cutscene actors: the timeline gives them the last
## indices (VillageStoryTimeLine: villagers, then extras, then the party).
const PARTY: PackedStringArray = ["Kin", "Celis", "Zalzi", "Borealis"]


## Whether an actor's pos (actor and pos lines) reads "y;x": the party's
## and villagers' are copied index by index into [y, x] arrays
## (VillageStoryTimeLine.setParty, Actor.initStartLocation); extras' and
## particle systems' go through Sprite.setPos, which takes "x;y". movepos is
## always "x;y".
static func pos_is_yx(actor_name: String) -> bool:
	return not (actor_name.contains("Extras") or actor_name.contains("System"))


## The position of an actor or pos line's pos= value, as x, y.
static func _actor_pos(line: String) -> Variant:
	var p: Variant = _pos(line, "pos")
	if p == null:
		return null
	return Vector2(p.y, p.x) if pos_is_yx(_quoted(line, "name")) else p


## The actors of a cutscene and how they move, in file order:
## {"actors": [{"name", "index", "pos": Vector2 or null}], "moves": [{"line",
## "actor" (index), "kind", "to": Vector2 (absolute: show, to), "by":
## Vector2 (relative: dist, queue, tor)}], "screen": [lines with screen
## positions]}. Variables come from the file's and main.var's var lines. A
## show at -1;-1 shows the actor where it is (no move).
static func parse_sequence(text: String) -> Dictionary:
	var vars := {}
	for raw in FileAccess.get_file_as_string(SEQUENCES + "main.var").split("\n"):
		_read_var(raw.strip_edges(), vars)
	var actors: Array = []
	var moves: Array = []
	var screen: Array = []
	var lines := text.split("\n")
	for n in lines.size():
		var line := lines[n].strip_edges()
		if line.begins_with("#"):
			continue
		if line.begins_with("var "):
			_read_var(line, vars)
		elif line.begins_with("actor "):
			var name := _quoted(line, "name")
			actors.append({"name": name, "index": -1, "pos": _actor_pos(line), "line": n})
		elif line.begins_with("pos "):
			for a: Dictionary in actors:
				if a["name"] == _quoted(line, "name") and _actor_pos(line) != null:
					a["pos"] = _actor_pos(line)
		elif line.begins_with("ins ") and line.contains("index="):
			var kind := _arg(line, "kind")
			var index_text := _arg(line, "index")
			var index: int = int(vars.get(index_text, index_text))
			var move := {"line": n, "actor": index, "kind": kind}
			match kind:
				"show", "to":
					var p: Variant = _pos(line, "movepos")
					if p != null and p != Vector2(-1, -1):
						move["to"] = p
						moves.append(move)
				"dist", "queue":
					var d := int(_arg(line, "direction", "0"))
					move["by"] = Vector2(STEPS[d]) * float(_arg(line, "distance", "0"))
					moves.append(move)
				"tor":
					var p: Variant = _pos(line, "movepos")
					if p != null:
						move["by"] = p
						moves.append(move)
				"screen_to", "screen_pos":
					screen.append(n)
	var from_village := RegEx.create_from_string("(?m)^\\s*set\\s+fromvillage").search(text) != null
	var next := 0
	for group in ["villager", "extra", "party"]:
		for a: Dictionary in actors:
			var name: String = a["name"]
			var is_party := PARTY.has(name)
			var is_extra := not is_party and name.contains("Extras")
			if group == ("party" if is_party else "extra" if is_extra else "villager"):
				a["index"] = next
				next += 1
	return {"actors": actors, "moves": moves, "screen": screen, "from_village": from_village}


## The villagers whose dialogs start the cutscene name ("<chapter>/<name>";
## a .char line "run <name with _>") in the place's folder.
static func runners(folder: String, name: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := CHARS + folder + "/villagers/"
	var run := "run " + name.get_file().replace(" ", "_")
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".char"):
			for raw in FileAccess.get_file_as_string(dir + file).split("\n"):
				if raw.strip_edges().begins_with(run + " ") or raw.strip_edges() == run:
					out.append(file.get_basename())
					break
	return out


## Where the party starts in a cutscene that a villager's dialog runs: the
## timeline keeps the party where the player stands (VillageStoryTimeLine.
## setParty: their pos lines count only with "set fromvillage"); taken as
## just below the villager, facing it.
static func party_starts(villager_pos: Vector2) -> Dictionary:
	return {"Kin": villager_pos + Vector2(0, 40), "Celis": villager_pos + Vector2(0, 70)}


static func _read_var(line: String, vars: Dictionary) -> void:
	if line.begins_with("var "):
		var kv := line.substr(4).split("=")
		if kv.size() == 2:
			vars[kv[0].strip_edges()] = int(kv[1])


static func _arg(line: String, key: String, default := "") -> String:
	var m := RegEx.create_from_string("(?:^|\\s)" + key + "=([^\\s]+)").search(line)
	return m.get_string(1) if m != null else default


static func _quoted(line: String, key: String) -> String:
	var m := RegEx.create_from_string(key + "=\"([^\"]*)\"").search(line)
	return m.get_string(1) if m != null else ""


static func _pos(line: String, key: String) -> Variant:
	var v := _arg(line, key)
	if v == "":
		return null
	var parts := v.split(";")
	return Vector2(float(parts[0]), float(parts[1]))


## The path of each actor of a parsed cutscene: index -> PackedVector2Array
## (its corners, from its start: its pos, else starts[name], else its first
## show; for a party member starts[name] first, unless the cutscene says
## "set fromvillage", and then its pos: it walks there before the cutscene's
## moves, Actor.initStartLocation), for the actors whose start is known.
static func sequence_paths(parsed: Dictionary, starts: Dictionary) -> Dictionary:
	var current := {}
	var paths := {}
	for a: Dictionary in parsed["actors"]:
		var start: Variant = a["pos"] if a["pos"] != null else starts.get(a["name"])
		var walk_to: Variant = null
		if PARTY.has(a["name"]) and not parsed["from_village"] and starts.has(a["name"]):
			walk_to = a["pos"]
			start = starts[a["name"]]
		if start != null:
			current[a["index"]] = start
			paths[a["index"]] = PackedVector2Array([start])
			if walk_to != null:
				current[a["index"]] = walk_to
				paths[a["index"]].append(walk_to)
	for m: Dictionary in parsed["moves"]:
		var i: int = m["actor"]
		if m.has("to"):
			if m["kind"] == "show" or not current.has(i):
				paths[i] = paths.get(i, PackedVector2Array())
				# A show teleports: a new piece of path starts (NAN marks the break).
				if not paths[i].is_empty():
					paths[i].append(Vector2(NAN, NAN))
			current[i] = m["to"]
			paths[i].append(m["to"])
		elif current.has(i):
			current[i] = current[i] + m["by"]
			paths[i].append(current[i])
	return paths


## The cutscene text with its village positions moved: every actor pos and
## every show / to movepos by offset, except a villager's home (homes: its
## old .char start -> its new one: a walk back home goes to the new home),
## and the actors named in positions (name -> [x, y]) to those instead (a
## villager actor without a pos gets one). Relative moves stay. Positions are
## x, y here; each line keeps its own order (pos_is_yx). Returns the text.
static func move_sequence(text: String, offset: Vector2, positions: Dictionary, homes := {}) -> String:
	var lines := text.split("\n")
	var pos_re := RegEx.create_from_string("(\\s(?:pos|movepos)=)(-?[0-9.]+);(-?[0-9.]+)")
	for n in lines.size():
		var line := lines[n]
		var stripped := line.strip_edges()
		var kind := _arg(stripped, "kind")
		var is_actor := stripped.begins_with("actor ") or stripped.begins_with("pos ")
		if not is_actor and not (stripped.begins_with("ins ") and (kind == "show" or kind == "to")):
			continue
		var m := pos_re.search(line)
		if m != null and float(m.get_string(2)) == -1.0 and float(m.get_string(3)) == -1.0:
			continue
		# Actor and pos lines of the party and villagers read "y;x" (pos_is_yx).
		var yx := is_actor and pos_is_yx(_quoted(stripped, "name"))
		if m == null:
			if is_actor and positions.has(_quoted(stripped, "name")):
				var at := vec(positions[_quoted(stripped, "name")])
				lines[n] = line.rstrip(" \t\r") + " pos=" + _pos_text(at, yx) + ("\r" if line.ends_with("\r") else "")
			continue
		var a := float(m.get_string(2))
		var b := float(m.get_string(3))
		var old := Vector2(b, a) if yx else Vector2(a, b)
		var p: Vector2 = homes[old] if homes.has(old) else old + offset
		if is_actor and positions.has(_quoted(stripped, "name")):
			p = vec(positions[_quoted(stripped, "name")])
		lines[n] = line.substr(0, m.get_start()) + m.get_string(1) + _pos_text(p, yx) + line.substr(m.get_end())
	return "\n".join(lines)


static func _pos_text(p: Vector2, yx: bool) -> String:
	return "%d;%d" % ([roundi(p.y), roundi(p.x)] if yx else [roundi(p.x), roundi(p.y)])
