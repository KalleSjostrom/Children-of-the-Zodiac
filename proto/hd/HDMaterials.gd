extends RefCounted
## The HD look's materials (docs/LOOK_PROTOTYPES_PLAN.md 4.1): a
## StandardMaterial3D for each legacy texture of a floor, in an art
## direction's set ("painted" or "photo").
##
## A set's maps for a texture are files in
## proto/hd/<set>/<Walls|Floors|Roofs>/<name>/: albedo.png, normal.png
## (OpenGL convention, as Godot's), height.png (white high), roughness.png,
## ao.png (white open; it darkens the lights by the occlusion setting too);
## material.cfg may set [material] uv_scale=<n>, roughness=<0-1>,
## relief_scale=<n> (relief in this texture sinks n times deeper, HDWalls).
## What a set does not have comes from the legacy texture: its albedo, the
## original's normal map (res/Labyrinth/.../<name>normal.png) where one exists
## and legacy_normals is on, else a normal and a height map made from the
## albedo's brightness (dark crevices low, bright stone high).

const SET_DIR := "res://proto/hd/"
const LABYRINTH_DIR := "res://res/Labyrinth/"

static var _cache := {}
static var _heights := {}


## The material for tex (a legacy floor texture) in look_set, with the HD
## look's settings s (bump, roughness, occlusion, legacy_normals).
static func material(tex: Texture2D, look_set: String, s: Dictionary) -> StandardMaterial3D:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	var key := "%s|%s|%s" % [rel, look_set, var_to_str(s)]
	if _cache.has(key):
		return _cache[key]
	var dir := SET_DIR + look_set + "/" + rel + "/"
	var cfg := ConfigFile.new()
	var has_cfg := cfg.load(dir + "material.cfg") == OK
	var albedo := _albedo(tex, look_set, s)
	var m := StandardMaterial3D.new()
	m.resource_name = rel
	# The legacy quads wind counter clockwise, as GL: their faces are
	# Godot's back faces (DungeonMaterials culls the same way).
	m.cull_mode = {"front": BaseMaterial3D.CULL_FRONT, "back": BaseMaterial3D.CULL_BACK}.get(s.cull, BaseMaterial3D.CULL_DISABLED)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Every quad shows its texture once, so clamp it: repeated, the forest
	# wall's transparent top rows bled into its bottom edge (a see-through
	# line along the floor) and its opaque bottom rows into its top edge.
	m.texture_repeat = false
	m.albedo_texture = _texture(albedo)
	if albedo.detect_alpha() != Image.ALPHA_NONE:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	var normal := _image(dir + "normal.png")
	if normal == null and s.legacy_normals:
		normal = _image(LABYRINTH_DIR + rel + "normal.png")
	if normal == null:
		normal = height(tex, look_set, s).duplicate()
		normal.bump_map_to_normal_map(s.bump)
	m.normal_enabled = s.normals
	m.normal_texture = _texture(normal)
	var rough := _image(dir + "roughness.png")
	if rough != null:
		m.roughness_texture = _texture(rough)
		m.roughness = 1.0
	else:
		m.roughness = float(cfg.get_value("material", "roughness", s.roughness)) if has_cfg else s.roughness
	var ao := _image(dir + "ao.png")
	if ao != null:
		m.ao_enabled = true
		m.ao_texture = _texture(ao)
		# The shadow maps cannot show the relief's own shadows: the
		# occlusion map darkens the lights in its crevices too.
		m.ao_light_affect = s.occlusion
	if has_cfg:
		var scale := float(cfg.get_value("material", "uv_scale", 1.0))
		m.uv1_scale = Vector3(scale, scale, 1.0)
		m.texture_repeat = scale != 1.0
	_cache[key] = m
	return m


## Forgets the materials and maps made so far.
static func forget() -> void:
	_cache.clear()
	_heights.clear()


## The height map of tex in look_set (white high): the set's height.png, or
## one made from the albedo. The relief (HDWalls) and the normal map made
## where there is none use it.
static func height(tex: Texture2D, look_set: String, s: Dictionary) -> Image:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	var key := "%s|%s|%s|%s" % [rel, look_set, s.brightness, s.contrast]
	if not _heights.has(key):
		var h := _image(SET_DIR + look_set + "/" + rel + "/height.png")
		_heights[key] = h if h != null else _height_from(_albedo(tex, look_set, s))
	return _heights[key]


## True when look_set has a height map of its own for tex (height.png).
static func has_height_map(tex: Texture2D, look_set: String) -> bool:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	return FileAccess.file_exists(SET_DIR + look_set + "/" + rel + "/height.png")


## How much deeper relief in tex sinks in look_set than the HD look's relief
## setting says: its material.cfg's relief_scale, else 1.
static func relief_scale(tex: Texture2D, look_set: String) -> float:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	var cfg := ConfigFile.new()
	if cfg.load(SET_DIR + look_set + "/" + rel + "/material.cfg") != OK:
		return 1.0
	return float(cfg.get_value("material", "relief_scale", 1.0))


## The albedo of tex in look_set: the set's albedo.png, or the legacy
## texture, which is painted for the legacy light with its shading in it:
## lifted (brightness, contrast) to serve as an albedo.
static func _albedo(tex: Texture2D, look_set: String, s: Dictionary) -> Image:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	var albedo := _image(SET_DIR + look_set + "/" + rel + "/albedo.png")
	if albedo == null:
		albedo = _decompressed(tex.get_image())
		albedo.adjust_bcs(s.brightness, s.contrast, 1.0)
	return albedo


## The image of a file of a set (not imported: proto/ is not exported), or
## null.
static func _image(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return _decompressed(img) if img != null else null


static func _decompressed(img: Image) -> Image:
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	return img


## A height map from the albedo's brightness, slightly blurred (scaled down
## and up), so the bumps follow the stones rather than the paint's grain.
## Transparent texels (white above the forest wall's grass) take the opaque
## ones' mean brightness, so they do not make the highest ridge.
static func _height_from(albedo: Image) -> Image:
	var h := albedo.duplicate() as Image
	if albedo.detect_alpha() != Image.ALPHA_NONE:
		h.convert(Image.FORMAT_RGBA8)
		var base := Image.create(h.get_width(), h.get_height(), false, Image.FORMAT_RGBA8)
		base.fill(_mean_opaque(h))
		base.blend_rect(h, Rect2i(Vector2i.ZERO, h.get_size()), Vector2i.ZERO)
		h = base
	h.convert(Image.FORMAT_L8)
	var w := h.get_width()
	var ht := h.get_height()
	h.resize(maxi(w >> 1, 1), maxi(ht >> 1, 1), Image.INTERPOLATE_CUBIC)
	h.resize(w, ht, Image.INTERPOLATE_CUBIC)
	return h


## The mean colour of img's opaque texels (sampled on a 32×32 grid), opaque.
static func _mean_opaque(img: Image) -> Color:
	var small := img.duplicate() as Image
	small.resize(32, 32, Image.INTERPOLATE_NEAREST)
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in 32:
		for x in 32:
			var c := small.get_pixel(x, y)
			if c.a > 0.9:
				sum += c
				n += 1
	return Color(sum.r / n, sum.g / n, sum.b / n, 1.0) if n > 0 else Color(0.5, 0.5, 0.5, 1.0)


## A mipmapped texture of img (the legacy textures are imported without
## mipmaps, which shimmer on walls far away).
static func _texture(img: Image) -> ImageTexture:
	var copy := img.duplicate() as Image
	if copy.get_format() == Image.FORMAT_L8:
		copy.convert(Image.FORMAT_RGBA8)
	copy.generate_mipmaps()
	return ImageTexture.create_from_image(copy)
