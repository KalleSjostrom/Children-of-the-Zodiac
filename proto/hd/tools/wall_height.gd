extends SceneTree
## A height map and a normal map for a wall texture, for an HD set
## (proto/hd/HDMaterials.gd, docs/LOOK_PROTOTYPES_PLAN.md 10.6). The height
## map made from the brightness alone (HDMaterials._height_from) does not
## have the shapes, so it is not enough for relief walls (HDWalls).
##
##   godot --headless --path . --script res://proto/hd/tools/wall_height.gd -- \
##       <texture> [recipe=stones] [set=painted] [bump=4] [<option>=<value> ...]
##
## <texture> is a legacy texture (res://res/Labyrinth/Walls/forestwall.png);
## the maps go to proto/hd/<set>/<Walls|Floors|Roofs>/<name>/height.png and
## normal.png (bump: the normal map's strength). Transparent texels (the
## forest wall's sky) are as low as can be. Distances wrap sideways, as the
## textures tile that way. After a run, the console's "look hd-painted"
## enters the floor again with the new maps.
##
## ao_depth=<units> also writes ao.png, an occlusion map: how much of the sky
## the relief around each texel hides (its horizon in 8 directions, up to
## ao_radius=32 texels away), for relief that deep on a 4-unit quad (HDLook's
## relief times the texture's relief_scale; 0, the default: no ao.png). The
## rock's grain is the normal map's: at full size it greyed all the rock with
## specks. So the map is made from the height map scaled down by ao_scale=4
## (averaged), and a rise less than ao_floor=0.2 of the height map's range
## hides nothing (the beams stand 0.6 over the rock, its grain 0.15). What it
## hides is exaggerated ao_strength=4 times: for relief this shallow the
## true occlusion darkens the rock by the beams by about 6 %. HDLook's
## occlusion setting (0.5) takes a share of it for the lights. The
## shadow maps cannot show the relief's own shadows
## (docs/LOOK_PROTOTYPES_PLAN.md 10.13); the occlusion map darkens the
## crevices instead.
##
## Recipes:
## * stones (the forest wall): the darkest texels are mortar (mortar=0.2,
##   their share of the opaque texels), and each stone rises from it in a
##   rounded profile to its full height radius=10 texels from the mortar,
##   with a little of its brightness on top.
## * timber (the mine wall and roof): wood-coloured texels (saturated, red to orange)
##   are beams in front of the rock, their faces at full height and rounded
##   off over bevel=6 texels at their edges. The rock lies at rock=0.4,
##   roughened by its paint's shading (rough=0.15); its brightest texels (the
##   white veins, veins=0.06 of them) are flattened, not ridges. With hole=
##   (a brightness; 0, the default: none), a patch of rock darker than that
##   and at least twice OPENING texels wide is an opening (a doorway's dark):
##   it sinks from the rock to as low as can be over bevel texels.

const LABYRINTH_DIR := "res://res/Labyrinth/"
## The timber recipe fills holes in the wood up to twice this wide (texels).
const CLOSE := 6.0
## An opening (the timber recipe's hole) is at least twice this wide
## (texels): the rock's own dark specks are not.
const OPENING := 16.0
## A wall's width in units (DungeonFloor.WIDTH): ao_depth in texels.
const QUAD := 4.0
const DEFAULTS := {"recipe": "stones", "set": "painted", "bump": "4",
	"mortar": "0.2", "radius": "10", "bevel": "6", "rock": "0.4", "rough": "0.15", "veins": "0.06",
	"hole": "0", "ao_depth": "0", "ao_radius": "32", "ao_scale": "4", "ao_floor": "0.2", "ao_strength": "4"}


func _init() -> void:
	var args := DEFAULTS.duplicate()
	var texture := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
		else:
			texture = a
	var tex: Texture2D = load(texture) as Texture2D if texture != "" else null
	if tex == null or not args.recipe in ["stones", "timber"]:
		push_error("wall_height: no texture '%s' or no recipe '%s'" % [texture, args.recipe])
		quit(1)
		return
	var src := tex.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var height: Image
	if args.recipe == "stones":
		height = stones(src, float(args.mortar), float(args.radius))
	else:
		height = timber(src, float(args.bevel), float(args.rock), float(args.rough), float(args.veins),
			float(args.hole))
	var normal := height.duplicate() as Image
	normal.bump_map_to_normal_map(float(args.bump))
	var dir := "res://proto/hd/%s/%s/" % [args.set, texture.trim_prefix(LABYRINTH_DIR).get_basename()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	height.save_png(dir + "height.png")
	normal.save_png(dir + "normal.png")
	var written := "height.png, normal.png"
	if float(args.ao_depth) > 0.0:
		var scale := maxf(float(args.ao_scale), 1.0)
		var small := height.duplicate() as Image
		# Trilinear: from the mipmaps, so the texels are averaged, not picked.
		small.resize(maxi(roundi(height.get_width() / scale), 1), maxi(roundi(height.get_height() / scale), 1),
			Image.INTERPOLATE_TRILINEAR)
		var texels := float(args.ao_depth) * small.get_width() / QUAD
		var ao := occlusion(small, texels, float(args.ao_radius) / scale, float(args.ao_floor),
			float(args.ao_strength))
		ao.resize(height.get_width(), height.get_height(), Image.INTERPOLATE_CUBIC)
		ao.save_png(dir + "ao.png")
		written += ", ao.png"
	print("wall_height: %s: %s%s" % [args.recipe, dir, written])
	quit()


## The stones recipe: the height map (L8, white high) of src (RGBA8).
static func stones(src: Image, mortar: float, radius: float) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var light := _blurred_light(src, 2)
	var rgba := src.get_data()
	var opaque := PackedFloat32Array()
	for i in w * h:
		if rgba[i * 4 + 3] > 127:
			opaque.append(light[i])
	opaque.sort()
	var threshold := opaque[int(opaque.size() * mortar)] if not opaque.is_empty() else 0.0
	var mean := 0.0
	for v in opaque:
		mean += v
	mean /= maxf(opaque.size(), 1.0)
	var is_mortar := PackedByteArray()
	is_mortar.resize(w * h)
	for i in w * h:
		is_mortar[i] = 1 if rgba[i * 4 + 3] <= 127 or light[i] <= threshold else 0
	var d := _distance(is_mortar, w, h)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		if rgba[i * 4 + 3] > 127:
			# A quarter circle: steep at the mortar, flat on the stone.
			var e := 1.0 - minf(d[i] / radius, 1.0)
			out[i] = 0.85 * sqrt(maxf(1.0 - e * e, 0.0)) + 0.3 * (light[i] - mean)
	return _image(out, w, h)


## The timber recipe: the height map (L8, white high) of src (RGBA8).
static func timber(src: Image, bevel: float, rock: float, rough: float, veins: float,
		hole := 0.0) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var rgba := src.get_data()
	# Wood: saturated, from red to orange, not too dark. The mask is blurred
	# and cut again, which drops specks, then closed (grown and shrunk by
	# CLOSE texels), which fills the bolts' holes.
	var wood := Image.create(w, h, false, Image.FORMAT_L8)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			var is_wood := c.a > 0.5 and c.s > 0.35 and c.v > 0.12 and (c.h < 0.12 or c.h > 0.97)
			wood.set_pixel(x, y, Color.WHITE if is_wood else Color.BLACK)
	wood.resize(maxi(w / 4, 1), maxi(h / 4, 1), Image.INTERPOLATE_BILINEAR)
	wood.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var mask := wood.get_data()
	var is_wood := PackedByteArray()
	is_wood.resize(w * h)
	for i in w * h:
		is_wood[i] = 1 if mask[i] > 127 else 0
	var to_wood := _distance(is_wood, w, h)
	var outside := PackedByteArray()
	outside.resize(w * h)
	for i in w * h:
		outside[i] = 1 if to_wood[i] > CLOSE else 0
	var to_outside := _distance(outside, w, h)
	var not_wood := PackedByteArray()
	not_wood.resize(w * h)
	for i in w * h:
		not_wood[i] = 1 if to_outside[i] <= CLOSE else 0
	var inside := _distance(not_wood, w, h)
	# The rock: its fine shading less its broad shading, the veins (its
	# brightest texels) at the broad shading.
	var fine := _blurred_light(src, 1)
	var broad := _blurred_light(src, 16)
	var rock_light := PackedFloat32Array()
	for i in w * h:
		if not_wood[i] == 1:
			rock_light.append(fine[i])
	rock_light.sort()
	var vein := rock_light[int(rock_light.size() * (1.0 - veins))] if not rock_light.is_empty() else 1.0
	# The openings: the dark rock shrunk and grown by OPENING texels (which
	# drops patches narrower than twice that), and each texel's distance from
	# the rest.
	var opening := PackedByteArray()
	opening.resize(w * h)
	var to_lit := PackedFloat32Array()
	if hole > 0.0:
		var lit := PackedByteArray()
		lit.resize(w * h)
		for i in w * h:
			lit[i] = 0 if not_wood[i] == 1 and fine[i] < hole else 1
		to_lit = _distance(lit, w, h)
		var core := PackedByteArray()
		core.resize(w * h)
		for i in w * h:
			core[i] = 1 if to_lit[i] > OPENING else 0
		var to_core := _distance(core, w, h)
		for i in w * h:
			opening[i] = 1 if to_core[i] <= OPENING and lit[i] == 0 else 0
			lit[i] = 1 - opening[i]
		to_lit = _distance(lit, w, h)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		var shade := broad[i] if fine[i] >= vein else fine[i]
		var stone := clampf(rock + rough * (shade - broad[i]) * 4.0, 0.0, rock + rough)
		if opening[i] == 1:
			stone *= 1.0 - smoothstep(0.0, 1.0, minf(to_lit[i] / bevel, 1.0))
		if rgba[i * 4 + 3] <= 127:
			stone = 0.0
		# The beams rise from the rock to full height over the bevel.
		var t := smoothstep(0.0, 1.0, minf(inside[i] / bevel, 1.0))
		out[i] = lerpf(stone, 1.0, t) if not_wood[i] == 0 else stone
	return _image(out, w, h)


## The occlusion map (L8, white open) of height (L8, white high) whose full
## range is depth texels deep: 1 less strength times the mean, over 8
## directions, of the sine of the horizon's elevation (the steepest rise
## within radius texels, wrapping sideways; a rise counts from least of the
## range up).
static func occlusion(height: Image, depth: float, radius: float, least: float,
		strength: float) -> Image:
	var w := height.get_width()
	var h := height.get_height()
	var data := height.get_data()
	var heights := PackedFloat32Array()
	heights.resize(w * h)
	for i in w * h:
		heights[i] = data[i] / 255.0 * depth
	# Each direction's steps: texel offsets x, y and 1 / the distance; the
	# steps grow with the distance.
	var steps := []
	for k in 8:
		var dir := Vector2.from_angle(TAU * k / 8.0)
		var offsets := PackedInt32Array()
		var inverse := PackedFloat32Array()
		var t := 1.0
		while t <= radius:
			var o := Vector2i((dir * t).round())
			offsets.append_array([o.x, o.y])
			inverse.append(1.0 / Vector2(o).length())
			t = maxf(t + 1.0, t * 1.25)
		steps.append([offsets, inverse])
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			var here := heights[y * w + x] + least * depth
			var hidden := 0.0
			for step: Array in steps:
				var offsets: PackedInt32Array = step[0]
				var inverse: PackedFloat32Array = step[1]
				var rise := 0.0 # the horizon's slope
				for s in inverse.size():
					var sy := clampi(y + offsets[s * 2 + 1], 0, h - 1)
					var sx := posmod(x + offsets[s * 2], w)
					rise = maxf(rise, (heights[sy * w + sx] - here) * inverse[s])
				hidden += rise / sqrt(1.0 + rise * rise)
			out[y * w + x] = 1.0 - strength * hidden / 8.0
	return _image(out, w, h)


## The brightness of src (0..1 per texel), blurred by scaling down by
## factor and up again.
static func _blurred_light(src: Image, factor: int) -> PackedFloat32Array:
	var lum := src.duplicate() as Image
	lum.convert(Image.FORMAT_L8)
	var w := lum.get_width()
	var h := lum.get_height()
	if factor > 1:
		lum.resize(maxi(w / factor, 1), maxi(h / factor, 1), Image.INTERPOLATE_BILINEAR)
		lum.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var data := lum.get_data()
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		out[i] = data[i] / 255.0
	return out


## Each texel's distance (in texels, chamfer 3-4) from the nearest source
## texel (source[i] 1), wrapping sideways.
static func _distance(source: PackedByteArray, w: int, h: int) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(w * h)
	for i in w * h:
		d[i] = 0.0 if source[i] == 1 else 1e9
	for y in h:
		for x in w:
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var left := (x - 1 + w) % w
			var right := (x + 1) % w
			var v := minf(d[i], d[y * w + left] + 3.0)
			if y > 0:
				v = minf(v, d[(y - 1) * w + x] + 3.0)
				v = minf(v, d[(y - 1) * w + left] + 4.0)
				v = minf(v, d[(y - 1) * w + right] + 4.0)
			d[i] = v
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var left := (x - 1 + w) % w
			var right := (x + 1) % w
			var v := minf(d[i], d[y * w + right] + 3.0)
			if y < h - 1:
				v = minf(v, d[(y + 1) * w + x] + 3.0)
				v = minf(v, d[(y + 1) * w + left] + 4.0)
				v = minf(v, d[(y + 1) * w + right] + 4.0)
			d[i] = v
	for i in w * h:
		d[i] /= 3.0
	return d


## heights (0..1 per texel) as an L8 image.
static func _image(heights: PackedFloat32Array, w: int, h: int) -> Image:
	var out := PackedByteArray()
	out.resize(w * h)
	for i in w * h:
		out[i] = clampi(int(heights[i] * 255.0), 0, 255)
	return Image.create_from_data(w, h, false, Image.FORMAT_L8, out)
