extends SceneTree
## Pictures for writing a remake's layout (the village-remake skill, steps 2
## and 3): a part of the village image, zoomed, with a coordinate grid
## (village pixels) and optionally the layout drawn over it, so that outlines
## and positions can be read off and checked.
##
## godot --headless --path . --script res://tools/village_remake/remake_view.gd -- <remake> <out.png> [options]
##   --rect=x,y,w,h   the part to show (village pixels; default: everything)
##   --zoom=n         nearest-neighbour zoom (default 1)
##   --grid=n         a line every n village pixels, every fifth one magenta and
##                    numbered with its coordinate (default 0: none)
##   --layout         draw the layout: object outlines (white), their overhead
##                    part (blue) and footprint (red), blocked regions (red
##                    outline), walkable regions (green outline), features
##                    (orange crosses at the feet, numbered in layout order:
##                    the numbers are printed), views (cyan rectangles)
##   --image=<path>   draw on this picture instead of the village image
##   --pieces         the overhead pieces as the build cuts them (trimmed) in
##                    full colour over the rest darkened: ground left in a
##                    piece shows bright
##   --players=x,y[,f];...  Kin with his feet at each x, y (frame f of his
##                    sheet: 1 facing up, the default, 9 facing down) under
##                    the overhead, as the game draws them: a player behind a
##                    tree, sign or roof is covered to the feet

const Lib := preload("res://tools/village_remake/remake_lib.gd")
const Draw := preload("res://tools/village_remake/remake_draw.gd")
const FEET := Vector2(Lib.PLAYER_W / 2.0, Lib.PLAYER_H - 2)
const PLAYER_SHEET := "res://res/Village/Characters/Kin/Kin_sheet.png"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: -- <remake> <out.png> [--rect=x,y,w,h] [--zoom=n] [--grid=n] [--layout] [--image=<path>] [--pieces] [--players=x,y;...]")
		quit(1)
		return
	var opts := {}
	for a in args.slice(2):
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var layout := Lib.load_layout(args[0])
	if layout.is_empty():
		quit(1)
		return
	var image: Image
	if opts.has("image"):
		image = Image.load_from_file(opts["image"])
		image.convert(Image.FORMAT_RGBA8)
	else:
		image = Lib.village_image(args[0], layout)
	if opts.has("pieces") or opts.has("players"):
		_draw_depth(image, layout, opts)
	if opts.has("layout"):
		_draw_layout(image, layout)
	var rect := Rect2i(Vector2i.ZERO, image.get_size())
	if opts.has("rect"):
		var r: PackedStringArray = opts["rect"].split(",")
		rect = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).intersection(rect)
	var zoom := int(opts.get("zoom", "1"))
	var out := image.get_region(rect)
	out.resize(rect.size.x * zoom, rect.size.y * zoom, Image.INTERPOLATE_NEAREST)
	var grid := int(opts.get("grid", "0"))
	if grid > 0:
		_draw_grid(out, rect, zoom, grid)
	out.save_png(args[1])
	print("Wrote %s: %s at x%d" % [args[1], rect, zoom])
	quit()


func _draw_grid(out: Image, rect: Rect2i, zoom: int, grid: int) -> void:
	for x in range(rect.position.x, rect.end.x):
		if x % grid == 0:
			var major := x % (grid * 5) == 0
			Draw.line(out, Vector2((x - rect.position.x) * zoom, 0), Vector2((x - rect.position.x) * zoom, out.get_height() - 1),
				Color(1, 0, 1, 0.8) if major else Color(1, 1, 0, 0.35))
			if major:
				Draw.number(out, x, Vector2i((x - rect.position.x) * zoom + 2, 2), Color(1, 0.6, 1))
	for y in range(rect.position.y, rect.end.y):
		if y % grid == 0:
			var major := y % (grid * 5) == 0
			Draw.line(out, Vector2(0, (y - rect.position.y) * zoom), Vector2(out.get_width() - 1, (y - rect.position.y) * zoom),
				Color(1, 0, 1, 0.8) if major else Color(1, 1, 0, 0.35))
			if major:
				Draw.number(out, y, Vector2i(2, (y - rect.position.y) * zoom + 2), Color(1, 0.6, 1))


## --players and --pieces: the players drawn, then the overhead over them;
## with --pieces everything else darkened to a quarter.
func _draw_depth(image: Image, layout: Dictionary, opts: Dictionary) -> void:
	var village := image.duplicate() as Image
	var over := Lib.Mask.new(Vector2i.ZERO, image.get_size())
	var parts := Lib.all_parts(layout, village)
	for id in parts:
		over.merge(parts[id]["overhead"], 1)
	if opts.has("players"):
		var sheet := (load(PLAYER_SHEET) as Texture2D).get_image()
		sheet.convert(Image.FORMAT_RGBA8)
		for spec: String in (opts["players"] as String).split(";", false):
			var v := spec.split(",")
			var frame := int(v[2]) if v.size() > 2 else 1
			image.blend_rect(sheet, CharacterSheet.region(frame), Vector2i(int(v[0]), int(v[1])) - Vector2i(roundi(FEET.x), roundi(FEET.y)))
	for y in image.get_height():
		for x in image.get_width():
			if over.at(x, y):
				image.set_pixel(x, y, village.get_pixel(x, y))
			elif opts.has("pieces"):
				var c := image.get_pixel(x, y)
				image.set_pixel(x, y, Color(c.r * 0.25, c.g * 0.25, c.b * 0.25))


func _draw_layout(image: Image, layout: Dictionary) -> void:
	var size := Lib.veci(layout["size"])
	var parts := Lib.all_parts(layout, image)
	for id in parts:
		var p: Dictionary = parts[id]
		var mask: Lib.Mask = p["mask"]
		for y in range(mask.origin.y, mask.origin.y + mask.size.y):
			for x in range(mask.origin.x, mask.origin.x + mask.size.x):
				if p["overhead"].at(x, y):
					Draw.blend(image, x, y, Color(0.2, 0.4, 1, 0.35))
				elif p["footprint"].at(x, y):
					Draw.blend(image, x, y, Color(1, 0.1, 0.1, 0.35))
	for object: Dictionary in layout.get("objects", []):
		if object.has("poly"):
			Draw.polyline(image, Lib.poly(object["poly"]), Color(1, 1, 1, 0.9), true)
	for region: Dictionary in layout.get("blocked", []):
		_outline(image, Lib.region_mask(region, size, image), Color(1, 0.2, 0.2, 0.9))
	for region: Dictionary in layout.get("walkable", []):
		_outline(image, Lib.region_mask(region, size, image), Color(0.2, 1, 0.2, 0.9))
	var n := 0
	for key: String in layout.get("features", {}):
		var f: Variant = layout["features"][key]
		if f == null:
			continue
		n += 1
		var pos := Lib.vec(f["pos"] if f is Dictionary else f)
		Draw.marker(image, pos + FEET, n, Color.ORANGE)
		print("%3d %s at %s" % [n, key, Vector2i(pos)])
		if f is Dictionary and f.has("walk"):
			var pts: PackedVector2Array = Lib.walk_points(pos, f["walk"])["points"]
			for i in pts.size():
				pts[i] += FEET
			Draw.polyline(image, pts, Color(0.3, 1, 0.3), false, 2)
	for view: Dictionary in layout.get("views", []):
		Draw.rect_outline(image, Rect2(Lib.vec(view["origin"]), Vector2(1024, 768)), Color.CYAN, 2)


## The cells of mask that have an unset neighbour.
static func _outline(image: Image, mask: Lib.Mask, color: Color) -> void:
	for y in range(mask.origin.y, mask.origin.y + mask.size.y):
		for x in range(mask.origin.x, mask.origin.x + mask.size.x):
			if mask.at(x, y) and (not mask.at(x - 1, y) or not mask.at(x + 1, y) or not mask.at(x, y - 1) or not mask.at(x, y + 1)):
				Draw.blend(image, x, y, color)
