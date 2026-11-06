extends DungeonLook
## The 16-bit look (docs/LOOK_PROTOTYPES_PLAN.md, section 5).
##
## * The whole game (apply_global): PixelFilter over the whole frame, the UI
##   included: the frame at 512×384 (res), its colours cut to a few levels
##   per channel with an ordered dither (5.1, the pixelating render path).
## * The prototype floors (DungeonLook.FLOORS): the walls', floors' and
##   roofs' shader with the light and the fog in steps (bands) and the
##   textures sampled nearest (nearest). With textures=<px> the textures are
##   scaled down to that width and cut to the same colour levels (5.2 a, art
##   converted by a rule); pixel art made for a texture
##   (proto/pixel/textures/<Walls|Floors|Roofs>/<name>.png, 5.2 b and c)
##   replaces it while art is on.
##
## The console changes the settings: look pixel <key>=<value> ...

const FILTER_SCRIPT := "res://proto/pixel/PixelFilter.gd"
const FILTER_NAME := "PixelFilter"
const ART_DIR := "res://proto/pixel/textures/"
const LABYRINTH_DIR := "res://res/Labyrinth/"

## The settings, for the session (configure). Keys and their defaults.
static var settings := {
	"res": 512, # the frame's width in cells; the height is 3/4 of it
	"levels": 16, # colour levels per channel (32: 15-bit colour)
	"dither": 1.0, # the ordered dither, in levels (0: none)
	"average": false, # a cell is the mean of its screen pixels (off: its centre)
	"sharp": true, # cells blend over one screen pixel at their edges: even at any window size
	"bands": 6, # steps of the floors' light and fog (0: smooth)
	"nearest": true, # the floors' textures sampled nearest
	"textures": 128, # the floors' textures scaled to this width (0: as they are)
	"art": true, # pixel art from proto/pixel/textures/ where it exists
}

static var _shaders := {} # variant code -> Shader
static var _textures := {} # key -> Texture2D


func configure(changes: Dictionary) -> String:
	for key: String in changes:
		if not settings.has(key):
			return "pixel has no setting '%s' (%s)" % [key, ", ".join(PackedStringArray(settings.keys()))]
		var value = _parse(changes[key], settings[key])
		if value == null:
			return "pixel: '%s' is not a value for %s" % [changes[key], key]
		settings[key] = value
	return ""


func describe() -> String:
	var parts := PackedStringArray()
	for key: String in settings:
		var v = settings[key]
		parts.append("%s=%s" % [key, ("on" if v else "off") if v is bool else str(v)])
	return " ".join(parts)


func apply_global(main: Node, on: bool) -> void:
	var old := main.get_node_or_null(FILTER_NAME)
	if old != null:
		main.remove_child(old)
		old.queue_free()
	if on:
		var filter: CanvasLayer = load(FILTER_SCRIPT).new()
		filter.name = FILTER_NAME
		filter.call("set_settings", settings)
		main.add_child(filter)


func floor_built(scene: DungeonScene) -> void:
	var f := scene.get_node(^"Layout") as DungeonFloor
	for mi: MeshInstance3D in [f.walls_instance(), f.sky_instance()]:
		if mi == null or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i) as ShaderMaterial
			if m != null:
				mi.mesh.surface_set_material(i, _variant(m))


## The floor material m in this look: its shader with the look's defines,
## its texture converted.
func _variant(m: ShaderMaterial) -> ShaderMaterial:
	var bands: int = settings.bands
	var v := m.duplicate() as ShaderMaterial
	v.shader = _shader(m.shader, bands > 0, settings.nearest)
	if bands > 0:
		v.set_shader_parameter("look_bands", float(bands))
	var tex := m.get_shader_parameter("tex") as Texture2D
	if tex != null:
		v.set_shader_parameter("tex", _texture(tex))
	return v


## The dungeon shader s with LOOK_BANDS and LOOK_NEAREST defined
## (dungeon_gl.gdshaderinc).
static func _shader(s: Shader, bands: bool, nearest: bool) -> Shader:
	var defines := ""
	if bands:
		defines += "#define LOOK_BANDS\n"
	if nearest:
		defines += "#define LOOK_NEAREST\n"
	if defines == "":
		return s
	var code := s.code.replace("#include", defines + "#include")
	if not _shaders.has(code):
		var variant := Shader.new()
		variant.code = code
		_shaders[code] = variant
	return _shaders[code]


## The texture tex in this look: the pixel art made for it, else scaled to
## the textures setting's width and cut to the colour levels, else itself.
static func _texture(tex: Texture2D) -> Texture2D:
	var rel := tex.resource_path.trim_prefix(LABYRINTH_DIR).get_basename()
	var art := ART_DIR + rel + ".png"
	var width: int = settings.textures
	var key := "%s|%s|%d|%d" % [rel, settings.art, width, settings.levels]
	if _textures.has(key):
		return _textures[key]
	var out := tex
	if settings.art and FileAccess.file_exists(art):
		out = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(art)))
	elif width > 0:
		out = ImageTexture.create_from_image(_by_rule(tex.get_image(), width, settings.levels))
	_textures[key] = out
	return out


## A texture converted by a rule (5.2 a): scaled to width (Lanczos), each
## channel cut to levels, the alpha to fully on or off.
static func _by_rule(img: Image, width: int, levels: int) -> Image:
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var height := maxi(1, roundi(float(width) * img.get_height() / img.get_width()))
	img.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var n := float(maxi(levels, 2) - 1)
	for y in height:
		for x in width:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(roundf(c.r * n) / n, roundf(c.g * n) / n, roundf(c.b * n) / n,
				1.0 if c.a >= 0.5 else 0.0))
	return img


## text as a value of the setting whose value is now; null if it is none.
static func _parse(text: String, now: Variant) -> Variant:
	if now is bool:
		match text.to_lower():
			"on", "true", "1", "yes", "":
				return true
			"off", "false", "0", "no":
				return false
		return null
	if now is int:
		return int(text) if text.is_valid_int() else null
	if now is float:
		return float(text) if text.is_valid_float() else null
	return text
