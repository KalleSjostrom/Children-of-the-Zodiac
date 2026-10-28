extends SceneTree
## Generates the GPU particle systems of the villages and cutscenes
## (docs/MODERNIZATION_PLAN.md 6.4, docs/ARCHITECTURE.md section 9) from
## maps/ParticleSystems/particleSystems.info, read by the legacy SystemLoader
## (and its settings, shapes and particle classes), so that every value is
## the one the game reads. How to run it and tune the results:
## docs/CONVERTING_PARTICLES.md. Run headless from the project root;
## tools/import/particles_to_scenes.sh runs the two stages with Godot's import
## between them:
##
##   godot --headless --path . --script res://tools/import/particles_to_scenes.gd -- [options] [<system>...]
##
## For every system (or the named ones) it writes
##   scenes/common/particles/systems/<system>.tscn         a VillageParticles2D
##       (GPUParticles2D): the particle class's shader as process material,
##       with the system's settings as uniforms; texture, blending, amount,
##       lifetime, warm-up; a Background (Sprite2D) for a background image; the
##       slave system of a master/slave emitter as a child
##   scenes/common/particles/systems/<system>_points.png   for an image shape:
##       the pixels it emits from (alpha >= 100 after scaling), one per texel
##
## Options:
##   --stage=points   only the emission point images (with .import files)
##   --stage=scenes   only the scenes; the point images must be imported first
##   --reset-tuning   intensity, size_scale and amount from the data, not kept
##                    from the existing scenes
##
## Rates. A legacy system emits one body per emitter time step while its pool
## has one, so both the time step and nrParticles limit the rate; a GPU
## system emits amount / lifetime per second. The generator steps single
## legacy particles (the real classes and commands, at 30 steps a second)
## over a grid of their random inputs to get their mean and longest lives,
## and takes the lower of the two limits; lifetime (the slot's cycle) is the
## longest life. Systems whose emitter never emits (a time step of 0) and
## that have a warm-up shape (the stars) emit all their particles at once
## from it. The tuning exports (intensity, size_scale, amount) of an existing
## scene are kept (amount by its ratio to the generated value), unless
## --reset-tuning. Generating twice writes the same files.

const SYSTEMS_DIR := "res://scenes/common/particles/systems/"
const SHADER_DIR := "res://scenes/common/particles/"
## The shader of each particle class (ParticleFactory's kinds; rainparticle
## and sandparticle have no class there, as in the original, so no scene).
const SHADERS := {
	0: "fire_particle.gdshader",
	1: "smoke_particle.gdshader",
	3: "rainbow_particle.gdshader",
	5: "snow_particle.gdshader",
	8: "star_particle.gdshader",
}
const SMOKE := 1
const SNOW := 5
const STAR := 8
const STEPS := 30.0
## The default intensity of an additive system, per particle class: the
## legacy glows were too bright (fire, rainbow and smoke: 0.6); snow flakes
## and stars do not glow and stay closer to the legacy (0.85).
const ADDITIVE_INTENSITY := {0: 0.6, 1: 0.6, 3: 0.6, 5: 0.85, 8: 0.85}
## The wind the smoke lives are estimated with: every village with a smoke
## system has a wind of magnitude 10 (Alares, Dellna, Home of Celis, Pensara,
## Zazo).
const ESTIMATE_WIND := Vector2(10.0, 0.0)
const FADE_SAMPLES := 16
const MASS_SAMPLES := 8
const MAX_SAMPLES := 4
const MAX_STEPS := 30 * 600
## The lifetime of a system whose particles never die (the stars).
const FIXED_LIFETIME := 1000000.0
## Particles are never culled: they run while off the screen, as the legacy
## systems do.
const VISIBILITY := Rect2(-4096, -4096, 12288, 12288)
const POINTS_WIDTH := 256

var _loader # SystemLoader
var _points_stage := true
var _scenes_stage := true
var _reset_tuning := false
var _failed := 0


func _init() -> void:
	var names: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a == "--stage=points":
			_scenes_stage = false
		elif a == "--stage=scenes":
			_points_stage = false
		elif a == "--reset-tuning":
			_reset_tuning = true
		elif a.begins_with("--"):
			push_error("particles_to_scenes: unknown option " + a)
			quit(2)
			return
		else:
			names.append(a)
	_loader = SystemLoader.getLoader()
	if names.is_empty():
		for n: String in _loader.systemSettings:
			names.append(n)
	DirAccess.make_dir_recursive_absolute(SYSTEMS_DIR)
	var generated := 0
	for system_name in names:
		if not _loader.systemSettings.has(system_name):
			push_error("particles_to_scenes: no system " + system_name)
			_failed += 1
			continue
		var d := _describe(system_name, null)
		if d.is_empty():
			continue
		if _points_stage:
			_write_points(d)
		if _scenes_stage:
			_write_scene(d)
		generated += 1
	print("GENERATED %d systems, %d failed" % [generated, _failed])
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# Reading the legacy settings
# ---------------------------------------------------------------------------

## The system as the legacy loader builds it (SystemLoader.buildSystem; a
## slave with its master's emitter settings, as getSystem builds it), and the
## GPU values made from it. Empty for a particle kind without a class.
func _describe(system_name: String, master_emitter) -> Dictionary:
	var s = _loader.systemSettings[system_name]
	var p = _loader.particleSettings.get(_string(s, SystemSettings.PARTICLE_NAME))
	var kind := int(_value(p, ParticleSettings.KIND))
	if not SHADERS.has(kind):
		print("  %s: particle kind %d has no class (as in ParticleFactory): no scene" % [system_name, kind])
		return {}
	var e = master_emitter
	if e == null:
		e = _loader.emitterSettings.get(_string(s, SystemSettings.EMITTER_NAME))
	var shape_settings = _loader.shapeSettings.get(_string(e, EmitterSettings.SHAPE_NAME))
	var d := {"name": system_name, "kind": kind, "system": s, "particle": p, "emitter": e,
		"shape_settings": shape_settings}
	d["texture"] = GameResourceLoader.resolve(Values.ParticleSystemsImages + str(_string(s, SystemSettings.TEXTURE)))
	d["additive"] = int(_value(s, SystemSettings.ADDITIVE)) == Settings.TRUE
	d["particles"] = int(_value(s, SystemSettings.NR_PARTICLES))
	d["warm_up"] = int(_value(s, SystemSettings.WARM_UP_LENGTH))
	var warm_shape_name = _string(s, SystemSettings.WARM_UP_SHAPE_NAME)
	d["warm_shape"] = {} if warm_shape_name == null else _shape(_loader.shapeSettings.get(warm_shape_name))
	var background = _string(s, SystemSettings.BACKGROUND)
	if background != null:
		var args: Array = J.split(background, ";")
		d["background"] = [GameResourceLoader.resolve(Values.ParticleSystemsImages + str(args[0])),
				Vector2(J.parseInt(args[1]), J.parseInt(args[2]))]
	var force = _vector(e, EmitterSettings.FORCE)
	d["force"] = Vector2.ZERO if force == null else Vector2(force.x, force.y)
	d["time_step"] = _mean(_interval(_string(e, EmitterSettings.EMITTANCE_TIME_STEP)))
	d["master"] = master_emitter == null and int(_value(e, EmitterSettings.KIND)) == EmitterFactory.MASTER_SLAVE \
			and _string(e, EmitterSettings.SLAVE_NAME) != null
	d["shape"] = _shape(shape_settings)
	d["mass"] = _interval(_string(p, ParticleSettings.MASS))
	d["size"] = _interval(_string(p, ParticleSettings.SIZE))
	var color = _vector(p, ParticleSettings.COLOR)
	d["color"] = Color(0, 0, 0) if color == null else Color(color.x, color.y, color.z)
	var fade = _vector(p, ParticleSettings.FADE)
	d["fade"] = Vector3(1000, 0.001, 2000) if fade == null else Vector3(fade.x, fade.y, fade.z)
	var args := _settings_args(_string(p, ParticleSettings.SETTINGS))
	d["max"] = _interval(args.get("max", "0"))
	d["height"] = J.parseInt(args.get("height", "0"))
	d["fixed"] = kind == STAR or (not d["warm_shape"].is_empty() and float(d["time_step"]) <= 0.0)
	if d["master"]:
		d["slave"] = _describe(_string(e, EmitterSettings.SLAVE_NAME), e)
	if _scenes_stage and master_emitter == null:
		_rates(d)
	return d


## An EmitterShape's settings as uniforms (legacy coordinates, y up).
func _shape(ss) -> Dictionary:
	var kind := int(_value(ss, ShapeSettings.KIND))
	var pos = _vector(ss, ShapeSettings.POSITION)
	var d := {"kind": kind, "position": Vector2(pos.x, pos.y), "a": Vector2.ZERO, "b": Vector2.ZERO,
		"spread": Vector2.ZERO, "points": PackedVector2Array()}
	match kind:
		EmitterFactory.LINE:
			var point = _vector(ss, ShapeSettings.POINTS)
			d["a"] = Vector2(point.x, point.y)
			var angle: float = _value(ss, ShapeSettings.ANGLE)
			d["spread"] = Vector2(tan(deg_to_rad(-angle)), tan(deg_to_rad(angle)))
		EmitterFactory.BOX:
			var v0 = _vector(ss, ShapeSettings.POINTS)
			var v1 = _vector(ss, ShapeSettings.POINTS + 1)
			d["a"] = Vector2(v0.x, v0.y)
			d["b"] = Vector2(v1.x, v1.y)
		EmitterFactory.CIRCLE:
			var radii = _vector(ss, ShapeSettings.POINTS)
			d["a"] = Vector2(radii.x, radii.y)
		EmitterFactory.IMAGE:
			# The legacy shape scales the image and reads its alpha raster.
			var shape := ImageShape.new(ss)
			var points := PackedVector2Array()
			for h in shape.height:
				var row: Array = shape.pixels[h]
				for w in shape.width:
					if int(row[w]) >= 100:
						points.append(Vector2(shape.width - w if shape.flipX else w,
								shape.height - h if shape.flipY else h))
			d["points"] = points
	return d


## A Settings value without adding the key: Settings.get_ (as Java's get)
## creates an empty setting for a missing key, which the particle and system
## constructors would then read (a null fade).
static func _setting(settings, key: int):
	return settings.settings.get(key)


static func _string(settings, key: int):
	var s = _setting(settings, key)
	return null if s == null else s.string


static func _value(settings, key: int) -> float:
	var s = _setting(settings, key)
	return 0.0 if s == null else float(s.value)


static func _vector(settings, key: int):
	var s = _setting(settings, key)
	return null if s == null else s.vector


## SystemLoader.getValueFromInterval's range: "a-b" draws between min and max.
static func _interval(s) -> Vector2:
	if s == null:
		return Vector2.ZERO
	var text := String(s)
	if text.contains("-"):
		var parts: Array = J.split(text, "-")
		var a: float = J.parseFloat(parts[0])
		var b: float = J.parseFloat(parts[1])
		return Vector2(minf(a, b), maxf(a, b))
	var v: float = J.parseFloat(text)
	return Vector2(v, v)


static func _mean(interval: Vector2) -> float:
	return (interval.x + interval.y) / 2.0


## Particle.parseArgs's "[name=value;...]".
static func _settings_args(s) -> Dictionary:
	var out := {}
	if s == null or not String(s).contains("="):
		return out
	for part in String(s).replace("[", "").replace("]", "").split(";"):
		var kv := part.split("=")
		if kv.size() == 2:
			out[kv[0]] = kv[1]
	return out


# ---------------------------------------------------------------------------
# Rates and lives
# ---------------------------------------------------------------------------

## Fills in "life_mean", "life_max", "rate", "lifetime", "amount",
## "preprocess" and, for a master, the slave's rate (the master's deaths
## while the slave pool has a body) and slots.
func _rates(d: Dictionary) -> void:
	var particles: int = d["particles"]
	if d["fixed"]:
		d["life_mean"] = FIXED_LIFETIME
		d["life_max"] = FIXED_LIFETIME
		d["rate"] = 0.0
		d["lifetime"] = FIXED_LIFETIME
		d["amount"] = particles
		d["preprocess"] = 0.0
		return
	var initial := Vector2.ZERO
	if d.has("master_velocity"):
		initial = d["master_velocity"]
	var lives := _lives(d, initial)
	d["life_mean"] = lives.x
	d["life_max"] = lives.y
	# A master/slave emitter is updated by both of its systems every step.
	var updates := 2.0 if d["master"] else 1.0
	var step_rate: float = updates / float(d["time_step"]) if float(d["time_step"]) > 0.0 else 0.0
	var pool_rate: float = particles / lives.x
	d["rate"] = minf(step_rate, pool_rate)
	d["lifetime"] = snappedf(lives.y * 1.05 + 1.0 / STEPS, 0.001)
	d["amount"] = maxi(1, ceili(float(d["rate"]) * float(d["lifetime"])))
	d["preprocess"] = float(d["warm_up"]) / STEPS
	if d["master"]:
		var slave: Dictionary = d["slave"]
		var mass: float = _mean(d["mass"])
		slave["master_velocity"] = Vector2(0.0, d["force"].length() / (STEPS * mass)) * 0.5
		_rates(slave)
		var fed: float = minf(float(d["rate"]), slave["particles"] / float(slave["life_mean"]))
		slave["rate"] = fed
		slave["amount"] = maxi(1, ceili(fed * float(slave["lifetime"])))
		slave["master_mass"] = mass
		slave["master_fade"] = d["fade"]


## The mean and longest life (s) of the system's particles: single legacy
## particles stepped by the legacy commands at 30 steps a second, over a grid
## of their random inputs (the fade, a log-uniform mass and smoke max as the
## shaders draw them); the longest at the slowest fade, the largest mass and
## max.
func _lives(d: Dictionary, initial: Vector2) -> Vector2:
	var kind: int = d["kind"]
	var fades: Array[float] = []
	if kind == SNOW:
		fades.append(0.0)
	else:
		for i in FADE_SAMPLES:
			fades.append((i + 0.5) / FADE_SAMPLES)
	var masses := _log_samples(d["mass"], MASS_SAMPLES)
	var tops: Array[float] = [0.0]
	if kind == SMOKE:
		tops = _log_samples(d["max"], MAX_SAMPLES)
	var total := 0.0
	var count := 0
	var sample := 0
	for q in fades:
		for m in masses:
			for top in tops:
				sample += 1
				total += _life(d, q, m, top, initial, sample)
				count += 1
	var longest := _life(d, 0.0, d["mass"].y, d["max"].y, initial, 0)
	return Vector2(total / count, longest)


static func _log_samples(interval: Vector2, n: int) -> Array[float]:
	var out: Array[float] = []
	if interval.y <= interval.x or interval.x <= 0.0:
		out.append(interval.x)
		return out
	for i in n:
		out.append(interval.x * pow(interval.y / interval.x, (i + 0.5) / n))
	return out


## One legacy particle's life (s): built by ParticleFactory, emitted by the
## system's emitter (EmitterFactory) from its shape, its fade set to the
## quantile q of the legacy random fade, then stepped as
## BodiesParticleSystem.step does (gravity, wind for smoke, update).
func _life(d: Dictionary, q: float, mass: float, top: float, initial: Vector2, sample: int) -> float:
	BodiesParticleSystem.rand.setSeed(sample + 1)
	var emitter = EmitterFactory.createEmitter(d["emitter"], d["shape_settings"]) \
			if not d.has("emitter_object") else d["emitter_object"]
	d["emitter_object"] = emitter
	var kind: int = d["kind"]
	var b = ParticleFactory.createParticle(kind, d["particle"])
	# FireParticle and SmokeParticle fade with the distance only when they
	# have a parent system.
	b.setParent(emitter)
	b.setMass(mass)
	if kind == SMOKE:
		b.max = top
	emitter.emit(b, emitter.getShape().getEmittancePos(), Vector3f.new(initial.x, initial.y, 0.0))
	var fade: Vector3 = d["fade"]
	if kind == SMOKE:
		b.fadeValue = q / 200.0 + 0.001
	elif kind != SNOW:
		b.fadeValue = q / fade.x + fade.y
	var gravity := GravityCommand.new()
	var wind := Vector3f.new(ESTIMATE_WIND.x, ESTIMATE_WIND.y, 0.0)
	var dt := 1.0 / STEPS
	for n in MAX_STEPS:
		gravity.executeSingle(b, dt)
		if kind == SMOKE and b.isAlive():
			b.addForce(wind.mult(b.getMass()))
		if b.isAlive():
			b.update(dt)
		if b.isDead():
			return (n + 1) / STEPS
	return MAX_STEPS / STEPS


# ---------------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------------

func _points_path(d: Dictionary) -> String:
	return SYSTEMS_DIR + str(d["name"]) + "_points.png"


## The emission points of an image shape as an RGBA8 image (one point per
## texel: R = x & 255, G = y & 255, B = (x >> 8) | ((y >> 8) << 4), A = 255),
## imported lossless, without mipmaps or filtering fixes.
func _write_points(d: Dictionary) -> void:
	if d.has("slave"):
		_write_points(d["slave"])
	var points: PackedVector2Array = d["shape"]["points"]
	if points.is_empty():
		return
	var height := ceili(float(points.size()) / POINTS_WIDTH)
	var image := Image.create_empty(POINTS_WIDTH, height, false, Image.FORMAT_RGBA8)
	for i in points.size():
		var x := int(points[i].x)
		var y := int(points[i].y)
		image.set_pixel(i % POINTS_WIDTH, i / POINTS_WIDTH,
				Color8(x & 255, y & 255, (x >> 8) | ((y >> 8) << 4), 255))
	var path := _points_path(d)
	image.save_png(path)
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


func _write_scene(d: Dictionary) -> void:
	var path := SYSTEMS_DIR + str(d["name"]) + ".tscn"
	var old: VillageParticles2D = null
	if not _reset_tuning and ResourceLoader.exists(path):
		var existing := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if existing != null:
			old = existing.instantiate() as VillageParticles2D
	var root := _build(d, old)
	if old != null:
		old.free()
	_own(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("particles_to_scenes: could not write %s (%s)" % [path, error_string(err)])
		_failed += 1
		return
	_canonicalize(path)
	print("  %s: %s, %d particles, rate %.1f/s, life %.2f s (longest %.2f s)" % [d["name"],
		SHADERS[d["kind"]].get_basename(), d["amount"], d["rate"], d["life_mean"], d["life_max"]])


## The node of a system (and its slave), with the tuning of the old scene.
func _build(d: Dictionary, old: VillageParticles2D) -> VillageParticles2D:
	var node := VillageParticles2D.new()
	node.name = d["name"]
	node.system_name = d["name"]
	node.texture = load(d["texture"])
	node.lifetime = d["lifetime"]
	node.preprocess = d["preprocess"]
	node.one_shot = d["fixed"]
	node.explosiveness = 1.0 if d["fixed"] else 0.0
	node.fixed_fps = 0
	node.interpolate = false
	node.local_coords = true
	node.draw_order = GPUParticles2D.DRAW_ORDER_INDEX
	node.visibility_rect = VISIBILITY
	node.time_step = d["time_step"]
	node.warm_up_steady = not d["fixed"] and not d["warm_shape"].is_empty()
	# The snow's law is linear: its long warm-up can take coarse steps.
	node.warm_up_fps = 2 if node.warm_up_steady and d["kind"] == SNOW else 0
	node.default_amount = d["amount"]
	if d["additive"]:
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		blend.resource_scene_unique_id = "additive"
		node.material = blend
	node.process_material = _process_material(d)
	var intensity: float = ADDITIVE_INTENSITY[d["kind"]] if d["additive"] else 1.0
	var size_scale := 1.0
	var amount: int = d["amount"]
	if old != null:
		intensity = old.intensity
		size_scale = old.size_scale
		if old.default_amount > 0 and old.amount != old.default_amount:
			amount = maxi(1, roundi(float(amount) * old.amount / old.default_amount))
	node.amount = amount
	node.intensity = intensity
	node.size_scale = size_scale
	if d.has("background"):
		var image := Sprite2D.new()
		image.name = "Background"
		image.texture = load(d["background"][0])
		image.centered = false
		image.position = d["background"][1]
		image.show_behind_parent = true
		node.add_child(image)
	if d.has("slave"):
		var slave_old: VillageParticles2D = null
		if old != null:
			slave_old = old.get_node_or_null(NodePath(str(d["slave"]["name"]))) as VillageParticles2D
		var slave := _build(d["slave"], slave_old)
		node.add_child(slave)
	return node


func _process_material(d: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_DIR + str(SHADERS[d["kind"]]))
	m.resource_local_to_scene = true
	m.resource_scene_unique_id = "process"
	# Every uniform is written, so that the scene shows the whole system.
	var shape: Dictionary = d["warm_shape"] if d["fixed"] and not d["warm_shape"].is_empty() else d["shape"]
	var set_parameter := func(parameter: StringName, value: Variant, _default: Variant) -> void:
		m.set_shader_parameter(parameter, value)
	set_parameter.call(&"shape_kind", shape["kind"], 0)
	var position: Vector2 = shape["position"]
	set_parameter.call(&"emitter_origin", Vector2(position.x, -position.y), Vector2.ZERO)
	set_parameter.call(&"shape_a", shape["a"], Vector2.ZERO)
	set_parameter.call(&"shape_b", shape["b"], Vector2.ZERO)
	set_parameter.call(&"spread_min", shape["spread"].x, 0.0)
	set_parameter.call(&"spread_max", shape["spread"].y, 0.0)
	var points: PackedVector2Array = shape["points"]
	if not points.is_empty():
		m.set_shader_parameter(&"emission_points", load(_points_path(d)))
	m.set_shader_parameter(&"emission_point_count", points.size())
	set_parameter.call(&"force", d["force"], Vector2.ZERO)
	set_parameter.call(&"mass_min", d["mass"].x, 0.01)
	set_parameter.call(&"mass_max", d["mass"].y, 0.01)
	set_parameter.call(&"size_min", d["size"].x, 1.0)
	set_parameter.call(&"size_max", d["size"].y, 1.0)
	var color: Color = d["color"]
	set_parameter.call(&"color", Vector3(color.r, color.g, color.b), Vector3.ONE)
	match int(d["kind"]):
		0, 3:
			set_parameter.call(&"fade", d["fade"], Vector3(1000, 0.001, 2000))
		SMOKE:
			set_parameter.call(&"max_min", d["max"].x, 0.0)
			set_parameter.call(&"max_max", d["max"].y, 0.0)
			m.set_shader_parameter(&"wind", Vector2.ZERO)
			m.set_shader_parameter(&"from_master", d.has("master_mass"))
			m.set_shader_parameter(&"master_mass", d.get("master_mass", 0.01))
			m.set_shader_parameter(&"master_fade", d.get("master_fade", Vector3(1000, 0.001, 2000)))
			m.set_shader_parameter(&"master_fade_distance", 300.0)
		SNOW:
			set_parameter.call(&"height", float(d["height"]), 0.0)
	return m


func _own(root: Node, node: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_own(root, child)


## Makes the saved text the same on every run: no uid in the header, no node
## unique_ids (random in Godot 4.7), and resource ids numbered in file order
## (ext_resource "1", "2", ...; sub_resource "<type>_<n>").
func _canonicalize(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var ids := RegEx.create_from_string(" (unique_id=[0-9]+|parent_id_path=PackedInt32Array\\([0-9, ]*\\))")
	text = ids.sub(text, "", true)
	text = RegEx.create_from_string("^\\[gd_scene ([^\\]]*?) uid=\"[^\"]*\"").sub(text, "[gd_scene $1")
	var ext := RegEx.create_from_string("\\[ext_resource [^\\]]*? id=\"([^\"]+)\"\\]")
	var n := 0
	for found in ext.search_all(text):
		n += 1
		var old_id := found.get_string(1)
		var new_id := str(n)
		text = text.replace("id=\"%s\"]" % old_id, "id=\"%s\"]" % new_id)
		text = text.replace("ExtResource(\"%s\")" % old_id, "ExtResource(\"%s\")" % new_id)
	var sub := RegEx.create_from_string("\\[sub_resource type=\"([A-Za-z0-9_]+)\" id=\"([^\"]+)\"\\]")
	var counts := {}
	for found in sub.search_all(text):
		var type := found.get_string(1)
		counts[type] = counts.get(type, 0) + 1
		var old_id := found.get_string(2)
		var new_id := "%s_%d" % [type, counts[type]]
		text = text.replace("id=\"%s\"]" % old_id, "id=\"%s\"]" % new_id)
		text = text.replace("SubResource(\"%s\")" % old_id, "SubResource(\"%s\")" % new_id)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
