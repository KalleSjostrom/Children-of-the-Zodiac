extends DungeonLook
## The HD look (docs/LOOK_PROTOTYPES_PLAN.md, section 4), in two art
## directions: hd-painted (the "painted" set) and hd-photo (the "photo" set;
## HDMaterials says what a set holds and what stands in for what it lacks).
##
## On a prototype floor (DungeonLook.FLOORS):
## * the camera moves through the floor (moves_camera), as Godot's lights, GI
##   and volumetric fog need;
## * the walls, floors and roofs get PBR materials (HDMaterials) with
##   tangents, and cast shadows; walls, floors and roofs whose texture has a
##   height map in the set are relief (HDWalls), and boxes behind the outer
##   walls close the daylight's shadow at their feet and corners (HDWalls'
##   sun blockers);
## * the player carries a flickering torch (Torch) with shadows; a floor with
##   a sky gets a sky in the Environment and a daylight from above;
## * the Environment: AgX tonemapping, glow, SSAO, SSIL, SDFGI and
##   volumetric fog; a FogVolume of drifting fog low over the floor
##   (drift_fog.gdshader) and glowing embers in the air (ember.gdshader);
##   a heat haze over the frame, off by default (heat_haze.gdshader).
## The objects' quads, the battle and the minimap stay the legacy drawing,
## at the camera (DungeonScene._eye), except a hinder door's wall: relief
## like the wall it stands in for, when its images have height maps in the
## set (show_object).
##
## The console changes the settings: look hd-painted <key>=<value> ...; the
## tuning panel (HDTuner, F2 on an HD floor) changes those of KNOBS at once
## (apply), and saves them as the floor's defaults (save_map_defaults). A
## floor entry gives every setting not changed this session the floor's
## default (map_defaults).

const HDMaterials := preload("res://proto/hd/HDMaterials.gd")
const Torch := preload("res://proto/hd/Torch.gd")
const HDWalls := preload("res://proto/hd/HDWalls.gd")
const DRIFT_FOG := preload("res://proto/hd/drift_fog.gdshader")
const EMBER := preload("res://proto/hd/ember.gdshader")
const HEAT_HAZE := preload("res://proto/hd/heat_haze.gdshader")
const HDTuner := preload("res://proto/hd/HDTuner.gd")

## The settings, for the session (configure). Keys and their defaults.
static var settings := {
	"torch": 8.0, # the torch's energy (a floor with a sky: a sixth of it)
	"flicker": 0.1, # the torch's slow swell: at most this share of its energy (Torch)
	"flicker_speed": 1.2, # how fast it swells (about turns a second)
	"flutter": 0.025, # a faster, fainter flicker over the swell
	"flutter_speed": 7.0,
	"sway": 0.01, # how far the torch sways (units)
	"sway_speed": 0.6,
	"sun": 2.0, # the daylight's energy on a floor with a sky
	"exposure": 1.0,
	"brightness": 1.1, # the legacy textures as albedo: they are painted dark, with
	"contrast": 0.85, # their shading in them (contrast < 1 lifts the darks)
	"gi": true, # SDFGI
	"ssao": true,
	"ssil": true,
	"glow": true,
	"fog": 1.0, # the volumetric fog's density, times the floor's
	"fog_anisotropy": 0.45, # its forward scattering: halos round lights, shafts (-1..1); > 0 hides fog lit only by the torch (the mine): it scatters the light away from the eyes
	"fog_length": 48.0, # how far it reaches (units)
	"fog_sky": 0.3, # how much it covers the sky (0..1)
	"torch_fog": 0.2, # the torch's light in the fog: its halo
	"sun_fog": 1.0, # the daylight's light in the fog
	"drift": 1.0, # the drifting fog's density, times its own (0: none)
	"drift_height": 1.0, # how high it reaches, times its own
	"drift_wind": 1.0, # how fast it drifts, times its own
	"drift_scale": 0.07, # its noise's frequency (smaller: larger puffs)
	"drift_cover": 0.45, # how much of it is clear air (0..1)
	"embers": 160, # how thick the embers glow in the air: how many over each 10 x 10 units of floor (0: none)
	"embers_reach": 7.0, # how far from the camera they are drawn (units, along the floor's axes); they fade out over the last 2 (ember.gdshader)
	"haze": 0.0, # the heat haze: how far it shifts the image at most (pixels of a 768-pixel frame; 0: none; heat_haze.gdshader)
	"haze_speed": 0.3, # how fast its ripples rise
	"haze_scale": 6.0, # their frequency (larger: finer)
	"haze_near": 2.0, # no haze nearer than this (units)
	"haze_far": 24.0, # all of it from this far
	"haze_ground": 0.5, # more of it near the floor (0: the same at every height; 1: none at the roof)
	"haze_blur": 0.5, # how much it blurs the distance (a mipmap level of the frame at full strength)
	"haze_tint": 0.0, # a warm grade over the frame (0..1)
	"blockers": true, # boxes behind the outer walls in the daylight's shadow (HDWalls)
	"relief": 0.05, # walls, floors and roofs with a set's height map as relief this deep (units; times a set's material.cfg relief_scale; 0: flat quads; HDWalls)
	"relief_grid": 64, # the relief's grid cells along a quad's side
	"bump": 3.0, # the strength of normal maps made from the albedo
	"roughness": 0.85,
	"occlusion": 0.5, # how much a set's ao.png darkens the lights too, not only the ambient (StandardMaterial3D.ao_light_affect; the relief's crevices, which its shadows do not reach; wall_height.gd bakes it 4 times exaggerated)
	"legacy_normals": true, # the original's normal maps where they exist
	"materials": true, # the PBR materials (off: the legacy shader, for comparing)
	"normals": true, # normal maps
	"shadows": true, # the torch's and the daylight's shadows
	"cull": "back", # the PBR materials' cull mode (back, front, none); the mesh is turned (_flipped)
}
static var _defaults := settings.duplicate()
## The settings changed this session (configure, the tuning panel): key ->
## true. They keep their values from floor to floor.
static var _changed := {}

## The floors' defaults in a set (HDMaterials), saved by the tuning panel: a
## file in the set's folder, a section per map (DungeonScene.map_name) with
## key=value lines, over the settings' own defaults.
const MAPS_FILE := "maps.cfg"

## The settings of the tuning panel (HDTuner), by group: [key, slider's
## min, max, step], or [key] for an on/off one. apply takes them at once.
const KNOBS := [
	["Fog", [["fog", 0.0, 5.0, 0.01], ["fog_anisotropy", -0.9, 0.9, 0.01],
		["fog_length", 4.0, 200.0, 1.0], ["fog_sky", 0.0, 1.0, 0.01],
		["torch_fog", 0.0, 4.0, 0.01], ["sun_fog", 0.0, 8.0, 0.01]]],
	["Drifting fog", [["drift", 0.0, 5.0, 0.01], ["drift_height", 0.1, 3.0, 0.01],
		["drift_wind", 0.0, 5.0, 0.01], ["drift_scale", 0.01, 0.3, 0.001],
		["drift_cover", 0.0, 1.0, 0.01]]],
	["Heat haze", [["haze", 0.0, 20.0, 0.1], ["haze_speed", 0.0, 3.0, 0.01],
		["haze_scale", 0.5, 30.0, 0.1], ["haze_near", 0.0, 20.0, 0.1],
		["haze_far", 0.5, 100.0, 0.5], ["haze_ground", 0.0, 1.0, 0.01],
		["haze_blur", 0.0, 4.0, 0.05], ["haze_tint", 0.0, 1.0, 0.01]]],
	["Light", [["torch", 0.0, 30.0, 0.1], ["sun", 0.0, 10.0, 0.05],
		["exposure", 0.1, 4.0, 0.01], ["shadows"], ["gi"], ["ssao"], ["ssil"], ["glow"]]],
	["Torch flicker", [["flicker", 0.0, 0.5, 0.005], ["flicker_speed", 0.0, 10.0, 0.05],
		["flutter", 0.0, 0.3, 0.005], ["flutter_speed", 0.0, 30.0, 0.1],
		["sway", 0.0, 0.1, 0.001], ["sway_speed", 0.0, 10.0, 0.05]]],
	["Surfaces", [["relief", 0.0, 0.3, 0.005], ["roughness", 0.0, 1.0, 0.01],
		["occlusion", 0.0, 1.0, 0.01], ["embers", 0.0, 1000.0, 1.0], ["embers_reach", 2.0, 20.0, 0.5]]],
]
## The drifting fog's wind (drift_fog.gdshader), times drift_wind.
const DRIFT_WIND := Vector3(0.35, 0.02, 0.15)
## The embers' sorting offset: after the floor's objects and weather
## (DungeonScene.SORT_STEP slots), before GLBackend's batches in the scene
## (the minimap, a battle: from 1e6).
const EMBERS_SORTING_OFFSET := 900000.0

## The floor's map (DungeonScene.map_name) and its defaults: the settings'
## own with the map's section of the set's MAPS_FILE over them (set_up).
var map_name := ""
var map_defaults := {}

# The floor's parts that changes are applied to (set_up, floor_built).
var _env: Environment
var _torch: OmniLight3D
var _sun: DirectionalLight3D
var _outdoor := false
var _fog_density := 0.0 # the floor's fog density (settings.fog multiplies it)
var _embers: GPUParticles3D
var _drift: FogVolume
var _drift_base := {} # its own density and height
var _haze: MeshInstance3D
var _relief: Node3D
var _relief_scales := {} # relief textures -> their sets' relief_scale
var _walls := [] # HDWalls.quads of the floor that are walls
var _doors := {} # the hinder doors in relief (their nodes) -> their relief instances, one per image
var _centres := [] # its cells' centres
var _blockers: MeshInstance3D
var _materials: Array[StandardMaterial3D] = [] # the floor's PBR materials


func configure(changes: Dictionary) -> String:
	for key: String in changes:
		if not settings.has(key):
			return "%s has no setting '%s' (%s)" % [look_name, key, ", ".join(PackedStringArray(settings.keys()))]
		var value = _parse(changes[key], settings[key])
		if value == null:
			return "%s: '%s' is not a value for %s" % [look_name, changes[key], key]
		settings[key] = value
		_changed[key] = true
	return ""


func describe() -> String:
	var parts := PackedStringArray()
	for key: String in settings:
		var v = settings[key]
		parts.append("%s=%s" % [key, ("on" if v else "off") if v is bool else str(v)])
	return " ".join(parts)


func moves_camera() -> bool:
	return true


func set_up(scene: DungeonScene) -> void:
	# A set's files are read again at every floor entry, so that a map
	# written meanwhile (proto/hd/tools) shows after the console's "look".
	HDMaterials.forget()
	map_name = scene.map_name
	map_defaults = _map_defaults(_look_set(), map_name)
	for key: String in settings:
		if not _changed.has(key):
			settings[key] = map_defaults[key]
	var style := scene.style
	_outdoor = style.sky
	_env = _environment(style)
	(scene.get_node(^"Environment") as WorldEnvironment).environment = _env
	var camera := scene.get_node(^"Rig/Camera") as Camera3D
	camera.near = 0.05
	camera.far = 300.0
	_torch = Torch.new()
	# The sun blockers (HDWalls) are for the daylight only.
	_torch.shadow_caster_mask = 0xFFFFF ^ HDWalls.BLOCKER_LAYER
	camera.add_child(_torch)
	if _outdoor:
		_sun = DirectionalLight3D.new()
		_sun.name = "Daylight"
		_sun.light_color = Color(0.82, 0.87, 0.95)
		_sun.directional_shadow_max_distance = 40.0
		_sun.light_angular_distance = 2.0
		_sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
		scene.add_child(_sun)
	_embers = _make_embers()
	scene.add_child(_embers)
	_haze = _make_haze()
	camera.add_child(_haze)
	for key: String in ["torch", "torch_fog", "flicker", "flicker_speed", "flutter",
			"flutter_speed", "sway", "sway_speed", "sun", "sun_fog", "shadows", "embers", "haze"]:
		apply(key)
	scene.add_child(HDTuner.new(self, KNOBS, settings, _defaults))


func floor_built(scene: DungeonScene) -> void:
	var f := scene.get_node(^"Layout") as DungeonFloor
	var look_set := _look_set()
	var walls := [] # HDWalls.quads of every PBR surface that are walls
	var relief_quads := [] # the quads drawn as relief (walls, floors, roofs)
	var doors := _relief_doors(scene, f.layout, look_set)
	# The places of the walls that hinder doors in relief stand in for.
	var covered := {}
	for d: Dictionary in doors:
		covered[HDWalls.place_key(d)] = true
	var mi := f.walls_instance()
	if mi != null and mi.mesh != null:
		var old := mi.mesh
		var mesh := ArrayMesh.new()
		for i in old.get_surface_count():
			var m := old.surface_get_material(i) as ShaderMaterial
			var tex: Texture2D = m.get_shader_parameter("tex") if m != null else null
			var st := SurfaceTool.new()
			if tex == null or not settings.materials:
				st.create_from(old, i)
				st.set_material(m)
				st.commit(mesh)
				continue
			var arrays := old.surface_get_arrays(i)
			var quads := HDWalls.quads(arrays, tex)
			# A hinder door in relief stands in for the wall it is on.
			var left_out := quads.filter(func(q: Dictionary) -> bool: return covered.has(HDWalls.place_key(q)))
			if not left_out.is_empty():
				quads = quads.filter(func(q: Dictionary) -> bool: return not covered.has(HDWalls.place_key(q)))
			walls.append_array(quads.filter(func(q: Dictionary) -> bool: return q.wall))
			# Relief needs a real height map (a set's): the one made from the
			# brightness does not have the stones' shapes.
			if settings.relief > 0.0 and not quads.is_empty() and HDMaterials.has_height_map(tex, look_set):
				relief_quads.append_array(quads)
				_relief_scales[tex] = HDMaterials.relief_scale(tex, look_set)
				left_out.append_array(quads)
			if not left_out.is_empty():
				arrays = _without(arrays, left_out)
				if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
					continue
			st.create_from_arrays(_flipped(arrays))
			st.generate_tangents()
			st.set_material(_material(tex, look_set))
			st.commit(mesh)
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	# The hinder doors last: a quad per image, one wall each.
	for d: Dictionary in doors:
		_relief_scales[d.tex] = HDMaterials.relief_scale(d.tex, look_set)
		if d.frame == 0:
			walls.append(d)
	relief_quads.append_array(doors)
	_walls = walls
	for c in f.layout.cells:
		_centres.append(c.center())
	if not relief_quads.is_empty():
		_relief = HDWalls.relief(relief_quads, walls, _material.bind(look_set),
			func(tex: Texture2D) -> Image: return HDMaterials.height(tex, look_set, settings),
			_sunk(), settings.relief_grid, not scene.style.sky)
		scene.add_child(_relief)
		var instances := _relief.get_children()
		var first := relief_quads.size() - doors.size()
		for k in doors.size():
			var d: Dictionary = doors[k]
			var mi_door := instances[first + k] as MeshInstance3D
			(_doors.get_or_add(d.door, []) as Array).append(mi_door)
			# Until the door is drawn (show_object): the image its View shows.
			mi_door.visible = d.frame == (d.door.get_node(^"View") as AnimatedSprite3D).frame
	_make_blockers(scene)
	# The Environment's sky replaces the legacy gradient quad.
	if f.sky_instance() != null:
		f.sky_instance().visible = false
	_drift = _make_drift_fog(f.layout, scene.style)
	scene.add_child(_drift)
	apply("drift")


## Applies the setting key to the floor at once (the tuning panel, HDTuner).
## False for one that takes effect only when the floor is entered again
## (most of those not in KNOBS, and the relief on a floor entered without
## it).
func apply(key: String) -> bool:
	var s := settings
	match key:
		"fog":
			_env.volumetric_fog_density = _fog_density * s.fog
		"fog_anisotropy":
			_env.volumetric_fog_anisotropy = s.fog_anisotropy
		"fog_length":
			_env.volumetric_fog_length = s.fog_length
		"fog_sky":
			_env.volumetric_fog_sky_affect = s.fog_sky
		"exposure":
			_env.tonemap_exposure = s.exposure
		"gi":
			_env.sdfgi_enabled = s.gi
		"ssao":
			_env.ssao_enabled = s.ssao
		"ssil":
			_env.ssil_enabled = s.ssil
		"glow":
			_env.glow_enabled = s.glow
		"torch":
			_torch.base_energy = s.torch / 6.0 if _outdoor else s.torch
		"torch_fog":
			_torch.light_volumetric_fog_energy = s.torch_fog
		"flicker", "flicker_speed", "flutter", "flutter_speed", "sway", "sway_speed":
			_torch.set(key, s[key])
		"sun":
			if _sun != null:
				_sun.light_energy = s.sun
		"sun_fog":
			if _sun != null:
				_sun.light_volumetric_fog_energy = s.sun_fog
		"shadows":
			_torch.shadow_enabled = s.shadows
			if _sun != null:
				_sun.shadow_enabled = s.shadows
		"drift", "drift_height", "drift_wind", "drift_scale", "drift_cover":
			if _drift == null:
				return false
			var m := _drift.material as ShaderMaterial
			m.set_shader_parameter("density", _drift_base.density * s.drift)
			m.set_shader_parameter("height", _drift_base.height * s.drift_height)
			m.set_shader_parameter("wind", DRIFT_WIND * s.drift_wind)
			m.set_shader_parameter("noise_scale", s.drift_scale)
			m.set_shader_parameter("cover", s.drift_cover)
			_drift.visible = s.drift > 0.0
		"haze", "haze_speed", "haze_scale", "haze_near", "haze_far", "haze_ground", "haze_blur", "haze_tint":
			var m := _haze.material_override as ShaderMaterial
			m.set_shader_parameter("strength", s.haze)
			m.set_shader_parameter("speed", s.haze_speed)
			m.set_shader_parameter("scale", s.haze_scale)
			m.set_shader_parameter("near", s.haze_near)
			m.set_shader_parameter("far", s.haze_far)
			m.set_shader_parameter("ground", s.haze_ground)
			m.set_shader_parameter("blur", s.haze_blur)
			m.set_shader_parameter("tint", s.haze_tint)
			# Hidden, it costs nothing (no copy of the frame).
			_haze.visible = s.haze > 0.0
		"embers", "embers_reach":
			# Emitted in a box as wide as the shader's reach, so that it draws
			# them evenly (ember.gdshader); as many as make embers per 100
			# square units.
			var reach: float = s.embers_reach
			(_embers.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(reach, 2.0, reach)
			((_embers.draw_pass_1 as QuadMesh).material as ShaderMaterial).set_shader_parameter("reach", reach)
			_embers.visibility_aabb = AABB(Vector3(-reach - 1.0, -4.0, -reach - 1.0),
				Vector3(2.0 * reach + 2.0, 8.0, 2.0 * reach + 2.0))
			var amount := maxi(roundi(s.embers * 4.0 * reach * reach / 100.0), 1)
			if _embers.amount != amount:
				_embers.amount = amount
			_embers.emitting = s.embers > 0
			_embers.visible = s.embers > 0
		"relief":
			if _relief == null:
				return false
			HDWalls.resink(_relief, _sunk())
			_make_blockers(_relief.get_parent())
		"roughness":
			for m in _materials:
				if m.roughness_texture == null:
					m.roughness = s.roughness
		"occlusion":
			for m in _materials:
				m.ao_light_affect = s.occlusion
		_:
			return false
	return true


## Sets the setting key to value (in its type) and applies it (as apply).
## Unless it is the floor's default, it stays for the session.
func change(key: String, value: Variant) -> bool:
	settings[key] = value
	if value == map_defaults[key]:
		_changed.erase(key)
	else:
		_changed[key] = true
	return apply(key)


## Sets the setting key back to the floor's default and applies it (as
## apply).
func revert(key: String) -> bool:
	return change(key, map_defaults[key])


## Why the setting key does nothing on the floor as it is now, or "" (the
## tuning panel greys such a row out).
func inactive(key: String) -> String:
	var s := settings
	match key:
		"sun", "sun_fog":
			if _sun == null:
				return "This floor has no daylight (it has no sky)"
		"drift_height", "drift_wind", "drift_scale", "drift_cover":
			if s.drift <= 0.0:
				return "The drifting fog is off (drift 0)"
		"embers_reach":
			if s.embers <= 0:
				return "The embers are off (embers 0)"
		"flicker_speed", "flutter_speed", "sway_speed":
			var amount: String = key.trim_suffix("_speed")
			if s[amount] <= 0.0:
				return "The torch has no %s (%s 0)" % [amount, amount]
		"relief", "roughness", "occlusion":
			if not s.materials:
				return "The PBR materials are off (materials=off, console)"
		"haze_speed", "haze_scale", "haze_near", "haze_far", "haze_ground", "haze_blur", "haze_tint":
			if s.haze <= 0.0:
				return "The heat haze is off (haze 0)"
	return ""


## Saves the settings of KNOBS as the floor's defaults, in its set's
## MAPS_FILE (other floors' sections and other keys stay; one at the
## setting's own default is left out, so it follows that); returns "" or
## what went wrong.
func save_map_defaults() -> String:
	var path := maps_file()
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path):
		var err := cfg.load(path)
		if err != OK:
			return "%s could not be read: %s" % [path, error_string(err)]
	for group: Array in KNOBS:
		for knob: Array in group[1]:
			var key: String = knob[0]
			# null erases the key (and an empty section).
			cfg.set_value(map_name, key, null if settings[key] == _defaults[key] else settings[key])
	var err := OK
	if cfg.get_sections().is_empty():
		if FileAccess.file_exists(path):
			err = DirAccess.remove_absolute(path)
	else:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		err = cfg.save(path)
	if err != OK:
		return "%s could not be written: %s" % [path, error_string(err)]
	for group: Array in KNOBS:
		for knob: Array in group[1]:
			map_defaults[knob[0]] = settings[knob[0]]
			_changed.erase(knob[0])
	return ""


## The floor's set's MAPS_FILE.
func maps_file() -> String:
	return HDMaterials.SET_DIR + _look_set() + "/" + MAPS_FILE


## The floor's art direction: its set of HDMaterials.
func _look_set() -> String:
	return "photo" if look_name == &"hd-photo" else "painted"


## The relief textures of the floor -> how deep their walls sink.
func _sunk() -> Dictionary:
	var out := {}
	for tex: Texture2D in _relief_scales:
		out[tex] = settings.relief * _relief_scales[tex]
	return out


## The sun blockers (HDWalls) of the floor, made again (they keep behind the
## relief, whose depth may have changed).
func _make_blockers(scene: Node) -> void:
	if _blockers != null:
		_blockers.queue_free()
		_blockers = null
	if _sun != null and settings.shadows and settings.blockers:
		_blockers = HDWalls.sun_blockers(_walls, _centres, _sunk())
		if _blockers != null:
			scene.add_child(_blockers)


## The hinder doors of the floor (scene, its layout) to draw as relief: those
## whose images (their View's frames) all have a height map in look_set, while
## relief is on. The legacy drawing draws one as a wall quad showing an image
## (HinderDoor.place_view): a quad per image (HDWalls.wall_quad), with door
## (its node) and frame (the image's index).
func _relief_doors(scene: DungeonScene, layout: DungeonLayout, look_set: String) -> Array:
	var out := []
	if not settings.materials or settings.relief <= 0.0:
		return out
	var centres := {}
	for c in layout.cells:
		centres[c.address] = c.center()
	for o in scene.get_node(^"Objects").get_children():
		var view := o.get_node_or_null(^"View") as AnimatedSprite3D
		if not o is DungeonHinderDoor or view == null or view.sprite_frames == null or not centres.has(o.cell):
			continue
		var images := []
		for k in view.sprite_frames.get_frame_count(&"default"):
			var tex := view.sprite_frames.get_frame_texture(&"default", k)
			if tex == null or not HDMaterials.has_height_map(tex, look_set):
				images.clear()
				break
			var q := HDWalls.wall_quad(centres[o.cell], o.facing, tex)
			q.door = o
			q.frame = k
			images.append(q)
		out.append_array(images)
	return out


## A surface's arrays (triangles, not indexed) with each triangle wound the
## other way: the legacy quads wind counter clockwise, as GL's front faces,
## which are Godot's back faces; turned, they are lit, shadowed and culled
## as Godot's front faces.
static func _flipped(arrays: Array) -> Array:
	for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_COLOR]:
		var a = arrays[k]
		if a == null:
			continue
		for t in range(0, a.size() - 2, 3):
			var second = a[t + 1]
			a[t + 1] = a[t + 2]
			a[t + 2] = second
		arrays[k] = a
	return arrays


## A surface's arrays (as DungeonFloor builds them, 6 vertices a quad)
## without the quads of quads (HDWalls.quads).
static func _without(arrays: Array, quads: Array) -> Array:
	var dropped := {}
	for q: Dictionary in quads:
		dropped[q.index] = true
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var count := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 6
	for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_COLOR]:
		var a = arrays[k]
		if a == null:
			continue
		var kept = a.slice(0, 0)
		for q in count:
			if not dropped.has(q):
				kept.append_array(a.slice(q * 6, q * 6 + 6))
		out[k] = kept
	return out


## The PBR material of tex (HDMaterials), kept for the changes apply makes.
func _material(tex: Texture2D, look_set: String) -> Material:
	var m := HDMaterials.material(tex, look_set, settings)
	if not _materials.has(m):
		_materials.append(m)
	return m


func view_shown(scene: DungeonScene, camera: Transform3D) -> void:
	if _embers != null:
		_embers.position = camera.origin
	# The legacy 3D drawing at the camera (the minimap, a battle's enemies
	# and cards) casts no shadows from the torch.
	for c in scene.legacy_root().get_children():
		var g := c as GeometryInstance3D
		if g != null and g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A hinder door in relief (_doors) shows the instance of the image its
## legacy draw shows (view.frame: open or locked), instead of its quad.
func show_object(_scene: DungeonScene, object: DungeonObject, view: Dictionary) -> bool:
	var images: Array = _doors.get(object, [])
	if images.is_empty():
		return false
	var shown: int = view.get("frame", 0) if view.get("visible", false) else -1
	for k in images.size():
		(images[k] as Node3D).visible = k == shown
	return true


func _environment(style: DungeonStyle) -> Environment:
	var env := Environment.new()
	if style.sky:
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = style.sky_top
		sky_material.sky_horizon_color = style.sky_bottom
		sky_material.ground_horizon_color = style.sky_bottom.darkened(0.3)
		sky_material.ground_bottom_color = Color(0.05, 0.06, 0.05)
		sky_material.sky_energy_multiplier = 1.0
		var sky := Sky.new()
		sky.sky_material = sky_material
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.5
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.0, 0.0, 0.0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.32, 0.3, 0.36)
		env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = settings.exposure
	env.glow_enabled = settings.glow
	env.glow_intensity = 0.5
	env.glow_bloom = 0.04
	env.ssao_enabled = settings.ssao
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssil_enabled = settings.ssil
	env.sdfgi_enabled = settings.gi
	env.sdfgi_use_occlusion = true
	env.volumetric_fog_enabled = true
	# The floor's fog (exponential, as GL_EXP) or a faint haze, for the torch's halo.
	_fog_density = style.fog_density if style.fog else 0.012
	env.volumetric_fog_density = _fog_density * settings.fog
	env.volumetric_fog_albedo = Color(style.fog_color.r, style.fog_color.g, style.fog_color.b) if style.fog else Color(0.7, 0.7, 0.72)
	env.volumetric_fog_anisotropy = settings.fog_anisotropy
	env.volumetric_fog_length = settings.fog_length
	env.volumetric_fog_sky_affect = settings.fog_sky
	return env


## The drifting fog: a FogVolume over the whole floor (its cells' bounds); the
## settings are applied after (apply).
func _make_drift_fog(layout: DungeonLayout, style: DungeonStyle) -> FogVolume:
	var bounds := AABB()
	var first := true
	for c in layout.cells:
		var p: Vector3 = c.center()
		var cell := AABB(p - Vector3(2.0, 2.0, 2.0), Vector3(4.0, 4.0, 4.0))
		bounds = cell if first else bounds.merge(cell)
		first = false
	var noise := NoiseTexture3D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.06
	fn.fractal_octaves = 3
	noise.noise = fn
	noise.width = 64
	noise.height = 64
	noise.depth = 64
	noise.seamless = true
	var m := ShaderMaterial.new()
	m.shader = DRIFT_FOG
	m.set_shader_parameter("noise", noise)
	m.set_shader_parameter("albedo", Color(0.85, 0.86, 0.9) if style.sky else Color(0.75, 0.72, 0.68))
	_drift_base = {"density": 0.05 if style.sky else 0.02, "height": 1.6 if style.sky else 2.6}
	var v := FogVolume.new()
	v.name = "DriftFog"
	v.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	v.size = bounds.size
	v.position = bounds.get_center()
	v.material = m
	return v


## The heat haze: a quad on the camera that the shader (heat_haze.gdshader)
## spreads over the screen, drawn first of the transparent objects (the
## lowest render priority); the settings are applied after (apply).
func _make_haze() -> MeshInstance3D:
	var noise := NoiseTexture3D.new()
	var fn := FastNoiseLite.new()
	# About four ripples across the texture, which repeats.
	fn.frequency = 0.0625
	fn.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.noise = fn
	noise.width = 64
	noise.height = 64
	noise.depth = 64
	noise.seamless = true
	var m := ShaderMaterial.new()
	m.shader = HEAT_HAZE
	m.render_priority = Material.RENDER_PRIORITY_MIN
	m.set_shader_parameter("noise", noise)
	m.set_shader_parameter("floor_y", DungeonFloor.FLOOR_HEIGHT)
	m.set_shader_parameter("roof_y", DungeonFloor.ROOF_HEIGHT)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var mi := MeshInstance3D.new()
	mi.name = "HeatHaze"
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# The shader places it; never culled.
	mi.extra_cull_margin = 16384.0
	mi.ignore_occlusion_culling = true
	return mi


## Embers in the air around the camera (emitted around it, in the floor's
## space, so they stay as the camera moves; the shader draws those out of
## reach back in reach, so they are as thick everywhere): round glows
## (ember.gdshader) between yellow and red, rising slowly on a turbulent
## draught, cooling as they die. Their count and reach (the emission box,
## the visibility AABB) are applied after (apply).
func _make_embers() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Embers"
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# They write no depth: drawn before an object's quad (a door), they were
	# blended over even where they were in front of it. Drawn after the
	# objects, a door's depth hides those behind it.
	p.sorting_offset = EMBERS_SORTING_OFFSET
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 60.0
	pm.gravity = Vector3(0.0, 0.04, 0.0)
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.5
	pm.turbulence_noise_scale = 3.0
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	# Each ember's colour, between yellow and red...
	var hue := Gradient.new()
	hue.set_color(0, Color(1.0, 0.68, 0.2))
	hue.set_color(1, Color(1.0, 0.2, 0.04))
	var hue_tex := GradientTexture1D.new()
	hue_tex.gradient = hue
	pm.color_initial_ramp = hue_tex
	# ... times its life: it flares up, glows, and cools to a dim red.
	var life := Gradient.new()
	life.set_color(0, Color(1, 1, 1, 0))
	life.set_color(1, Color(0.6, 0.3, 0.25, 0))
	life.add_point(0.12, Color(1, 1, 1, 1))
	life.add_point(0.6, Color(0.9, 0.7, 0.6, 1))
	var life_tex := GradientTexture1D.new()
	life_tex.gradient = life
	pm.color_ramp = life_tex
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	var m := ShaderMaterial.new()
	m.shader = EMBER
	quad.material = m
	p.draw_pass_1 = quad
	return p


## The defaults of the floor map in look_set: the settings' own, with the
## map's section of the set's MAPS_FILE over them.
static func _map_defaults(look_set: String, map: String) -> Dictionary:
	var out := _defaults.duplicate()
	var path := HDMaterials.SET_DIR + look_set + "/" + MAPS_FILE
	if not FileAccess.file_exists(path):
		return out
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	assert(err == OK, "%s could not be read: %s" % [path, error_string(err)])
	if err != OK or not cfg.has_section(map):
		return out
	for key in cfg.get_section_keys(map):
		var value: Variant = _typed(cfg.get_value(map, key), out.get(key))
		assert(value != null, "%s [%s]: %s is no setting, or not a value of it" % [path, map, key])
		if value != null:
			out[key] = value
	return out


## value (read from a file) in the type of the setting whose default is
## like (an int or a float for a number); null if it is no value of it.
static func _typed(value: Variant, like: Variant) -> Variant:
	if (like is float or like is int) and (value is float or value is int):
		return float(value) if like is float else roundi(value)
	return value if like != null and typeof(value) == typeof(like) else null


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
