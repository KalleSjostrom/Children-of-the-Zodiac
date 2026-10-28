class_name ParticleSystem
extends PointBody
## Port of particleSystem.ParticleSystem: common methods for a particle
## system (fire, smoke, ...).

static var hasInited = false
## Names of the particle textures (loaded lazily by load(), see notes).
static var particleTexture = null
const ROUND = 0
const SHARP = 1
const JITTER_1 = 2
const JITTER_2 = 3
const JITTER_3 = 4
const JITTER_4 = 5
const JITTER_2_45 = 6
const JITTER_3_45 = 7
const JITTER_4_45 = 8
const JONAS_ROUND = 9
const JONAS_ROUND_2 = 10
const STONE = 11
const SMOKE = 12
const DEATH_0 = 13
const DEATH_1 = 14
const DEATH_2 = 15
const PIXEL = 16
const ROUND_WHITE = 17
const ROUND_WHITE_SHARP = 18
const ROUND_INVERTED = 19
const CLOCK = 20
const CLOCK_HOUR = 21
const CLOCK_MINUTE = 22
const POS_X_GREATER_TARGET_X = 0
const CHECK_DISTANCE = 1
const POS_Z_LESS_TARGET_Z = 2
const PARTICLES_DESTROYED = 3
const POS_Y_GREATER_TARGET_Y = 4
const POS_Z_GREATER_TARGET_Z = 5
const POS_Y_LESS_TARGET_Y = 6
const DEMOLISH_EMITTER_TYPE = 0
const INTERPOLATING_EMITTER_TYPE = 1
const DEFAULT_EMITTER_TYPE = 2
const FLARE_EMITTER_TYPE = 3
const SHATTER_EMITTER_TYPE = 4
const TEST_EMITTER_TYPE = 5
const LINE_EMITTER_TYPE = 6
const FLAME_EMITTER_TYPE = 7
const IS_DESTROYED = 0
const IS_DEAD = 1
const IS_DELAYED = 2
const WAITING = 3
## Java value is -1 (the skeleton had 1).
const BLEND_MODE_NO_BLEND = -1

const _TEXTURE_FILES = [
	"particle.png", "yellowjitter.png", "stars2.png", "stars3.png",
	"stars4.png", "stars5.png", "stars245.png", "stars345.png",
	"stars445.png", "round.png", "smallRound.png", "sten.png",
	"smoke_particle.png", "death0.png", "death1.png", "death2.png",
	"pixel.png", "roundWhite.png", "roundWhiteSharp.png",
	"roundInverted.png", "clock.png", "clockHour.png", "clockMinute.png"]

static var tex = null
## Port deviation (docs/port_notes/particles-system.md): the random numbers of
## the card and enemy effects (particles, emitters, equations, colours, and
## the cards' effect positions), apart from J's shared generator, so that a
## seeded run's other draws (critical hits, enemy logic) do not depend on how
## much the effects draw. Main seeds it in deterministic runs.
static var rand := JRandom.new()
var particlePool = []
var particles = null
var speed: float = 0.0
var particlesLeft: int = 0
var color: int = 0
var targetIndex: int = 0
var nrParticles: int = 0
var textures = null
var destroyed: bool = false
var source = null
var target = null
var gravity = null
var targetPoint = null
var isDeadLimit: int = 0
var drawable = null
var emitTimeStep: float = 0.0
var destroyFadeGravity = null
var additiveColoring: bool = false
var destroyMode: int = 0
var info = null
var enemy = null
var emitter = null
var particlesDestroyed: int = 0
var checkDestroyMode: int = 0
var destroyCameraShake: bool = false
var destroyEnemyShake: bool = false
var destroyEnemySlice: bool = false
var settings = null
var readyMode: int = 0
var readyModeDone: bool = false
var readModeDelayTime: int = 0
var blendMode: int = 0

## Reused temporary force vector for the gravity of the particles.
var _tmpForce = null

## Bridge (the battle effects phase, docs/ARCHITECTURE.md section 11): a
## system drawn as particles (this class's draw and ShatterParticleSystem's;
## not the sphere, image, slow and enemy systems) runs on the GPU
## (EffectParticles3D) unless --legacy=battle_effects: its draw hands the
## node its state (gpu_state) instead of drawing quads. The legacy system
## stays in charge: it still moves, emits, is destroyed and decides when the
## battle goes on (isDestroyed, isReady, isDead), with a pool of at most
## GPU_WAIT_PARTICLES particles (reduce_for_waits; not with
## --legacy=effect_waits, which keeps the legacy pool and so the legacy
## waits, for parity runs). gpu_amount and gpu_emit_step: the legacy pool
## and time step, which the GPU draws; gpu_seed: the GPU particles' seed,
## from gpu_rand (the particles' own draws stay those of rand); gpu_age,
## gpu_stepped, gpu_elapsed: the game time since the system started, the time
## its updates stepped and the game time since its last draw; gpu_destroys,
## gpu_plains, gpu_kills: its destroy, plainDestroy and kill calls so far;
## gpu_preprocess: a warm-up for the GPU (the Flame's pre-run); gpu_shown: its
## node has its settings.
const GPU_WAIT_PARTICLES := 64
static var gpu_rand := JRandom.new(0)
var gpu := false
var gpu_amount := 0
var gpu_emit_step := 0.0
var gpu_seed := 0
var gpu_age := 0.0
var gpu_stepped := 0.0
var gpu_elapsed := 0.0
var gpu_destroys := 0
var gpu_plains := 0
var gpu_kills := 0
var gpu_preprocess := 0.0
var gpu_shown := false

## Java overloads: ParticleSystem(AnimSettings, BattleEnemy) and
## ParticleSystem(AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	ParticleSystem.load()
	setSettings(p_settings)
	enemy = p_enemy
	gpu = gpu_path() and not (self is SphereParticleSystem or self is ImageParticleSystem
			or self is SlowParticleSystem or self is EnemySystem)
	if gpu:
		gpu_amount = nrParticles
		gpu_emit_step = emitTimeStep
		gpu_seed = gpu_rand.nextInt(J.INT_MAX)
		reduce_for_waits()
	create(nrParticles, settings)


## Bridge: whether the card and enemy effects run on the GPU (not with
## --legacy=battle_effects).
static func gpu_path() -> bool:
	return not Main.is_legacy("battle_effects")


## Bridge: on the GPU path the legacy particles only decide the waits, so a
## pool of at most GPU_WAIT_PARTICLES does: the same rate per pool slot (a
## longer time step) and the same share of the pool for isDead's limit.
## Not with --legacy=effect_waits, nor for the flare (FlareEmitter takes 400
## of the pool and its destroy counts them), nor for a system that waits for
## its last particle (an isDeadLimit of 0: the last of a smaller pool dies
## sooner; Ultima's 250 waited 0.3 s less) up to 4 x GPU_WAIT_PARTICLES.
func reduce_for_waits() -> void:
	if Main.is_legacy("effect_waits") or nrParticles <= GPU_WAIT_PARTICLES:
		return
	if int(settings.getValue(AnimSettings.EMITTER_TYPE)) == FLARE_EMITTER_TYPE:
		return
	if isDeadLimit == 0 and nrParticles <= 4 * GPU_WAIT_PARTICLES:
		return
	var k: float = float(GPU_WAIT_PARTICLES) / nrParticles
	emitTimeStep /= k
	isDeadLimit = roundi(isDeadLimit * k)
	nrParticles = GPU_WAIT_PARTICLES

## Java: forces the static initializer (loads the particle textures).
static func load():
	if particleTexture == null:
		particleTexture = []
		for f in _TEXTURE_FILES:
			particleTexture.append(ImageHandler.addPermanentlyLoadNow(
					Values.ParticleSystemsImages + f))

func setSettings(p_settings):
	settings = p_settings.clone()
	setMass(p_settings.getValue(AnimSettings.SYSTEM_MASS))
	gravity = p_settings.getVector(AnimSettings.GRAVITY)
	emitTimeStep = p_settings.getValue(AnimSettings.EMITTANCE_TIME_STEP)
	speed = p_settings.getValue(AnimSettings.SPEED)
	color = int(p_settings.getValue(AnimSettings.COLOR))
	nrParticles = int(p_settings.getValue(AnimSettings.NR_PARTICLES))
	isDeadLimit = int(p_settings.getValue(AnimSettings.IS_DEAD_LIMIT))
	destroyMode = int(p_settings.getValue(AnimSettings.DESTROY_MODE))
	additiveColoring = p_settings.getBoolean(AnimSettings.ADDITIVE_COLORING)
	blendMode = int(p_settings.getValue(AnimSettings.BLEND_MODE))
	checkDestroyMode = int(p_settings.getValue(AnimSettings.CHECK_DESTROY_MODE))
	readyMode = int(p_settings.getValue(AnimSettings.READY_MODE))
	readModeDelayTime = int(p_settings.getValue(AnimSettings.READY_MODE_DELAY_TIME))

	destroyCameraShake = p_settings.getBoolean(AnimSettings.DESTROY_CAMERA_SHAKE)
	destroyEnemyShake = p_settings.getBoolean(AnimSettings.DESTROY_ENEMY_SHAKE)
	destroyEnemySlice = p_settings.getBoolean(AnimSettings.DESTROY_ENEMY_SLICE)

	source = p_settings.getVector(AnimSettings.SOURCE)
	target = p_settings.getVector(AnimSettings.TARGET).clone()
	destroyFadeGravity = p_settings.getVector(AnimSettings.DESTROY_FADE_GRAVITY)
	targetPoint = p_settings.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT)

	var nrTexs: int = int(p_settings.getValue(AnimSettings.NR_TEXTURES))
	textures = J.array(nrTexs, 0)
	for i in range(nrTexs):
		textures[i] = int(p_settings.getValue(AnimSettings.NR_TEXTURES + (i + 1)))

## Creates the system (particles, movement vector and emitter).
func create(nrOfParticles, p_settings):
	setPosition(source.clone())

	info = calcInterpolationInfo(p_settings)
	var sourceToTarget = target.subtract(source)
	var direction = sourceToTarget.normalize()
	direction.multLocal(speed)
	setVelocity(direction)

	particles = []
	if emitTimeStep == 0:
		for i in range(nrOfParticles):
			var p = createParticle()
			p.resurrect(self, null)
			particles.append(p)
	var emitterType: int = int(p_settings.getValue(AnimSettings.EMITTER_TYPE))
	match emitterType:
		DEMOLISH_EMITTER_TYPE:
			emitter = DemolishEmitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		INTERPOLATING_EMITTER_TYPE:
			emitter = InterpolatingEmitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		DEFAULT_EMITTER_TYPE:
			emitter = Emitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		FLARE_EMITTER_TYPE:
			emitter = FlareEmitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		SHATTER_EMITTER_TYPE:
			emitter = ShatterEmitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		TEST_EMITTER_TYPE:
			emitter = Emitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		LINE_EMITTER_TYPE:
			emitter = LineEmitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		FLAME_EMITTER_TYPE:
			emitter = Flame2Emitter.new(particlePool, particles, info, emitTimeStep, nrOfParticles)
		_:
			pass

## Java: update(float elapsedTime) (seconds).
func update(elapsedTime, body = null):
	super.update(elapsedTime)
	gpu_stepped += elapsedTime
	_updateParticles(elapsedTime)

	if checkShouldDestroy(getPosition(), target, particlesDestroyed):
		if not destroyed:
			if enemy != null:
				if destroyCameraShake:
					Camera.shakeit(1000)
				if destroyEnemyShake:
					enemy.shake(1000)
				if destroyEnemySlice:
					enemy.slice()
		match destroyMode:
			ParticleValues.DESTROY_ONCE:
				if not destroyed:
					emitter.destroy(enemy)
					for p in particles:
						p.setVelocity(Vector3f.new(0.0, 0.0, 0.0))
						p.setForce(Vector3f.new(0.0, 0.0, 0.0))
					destroy()
			ParticleValues.DESTROY_MULTIPLE_TIMES:
				emitter.destroy(enemy)
				destroy()
			ParticleValues.PLAIN_DESTROY:
				plainDestroy()

## The particle part of update (shared with FlameParticleSystem.create):
## emits, applies gravity, updates the particles, moves dead ones to the
## pool (keeps the order, compacts the shared particles Array in place).
func _updateParticles(elapsedTime) -> void:
	particlesLeft = 0
	particlesDestroyed = 0
	emitter.update(self, elapsedTime)
	var grav = getGravity()
	if grav != null and _tmpForce == null:
		_tmpForce = Vector3f.new()
	var n: int = particles.size()
	var w: int = 0
	for r in range(n):
		var p = particles[r]
		if grav != null:
			_tmpForce.x = grav.x * (rand.nextDouble() - 0.5)
			_tmpForce.y = grav.y
			_tmpForce.z = grav.z
			p.addForce(_tmpForce)
		# else: Java p.addForce(null) is a no-op (Vector3f.addLocal(null)).
		p.update(elapsedTime, self)
		var alive: bool = p.isAlive()
		if alive:
			particles[w] = p
			w += 1
		else:
			particlePool.append(p)
		particlesLeft += 1 if alive else 0
		if not destroyed:
			particlesDestroyed += 1 if p.isDestroyed() else 0
	if w != n:
		particles.resize(w)

func plainDestroy(particleSystem = null):
	gpu_plains += 1
	emitter.destroy(enemy)
	destroyed = true
	gravity = destroyFadeGravity
	for p in particles:
		p.plainDestroy(self)

func checkShouldDestroy(pos, p_target, p_particlesDestroyed):
	var shouldDestroy: bool = false
	match checkDestroyMode:
		POS_Z_LESS_TARGET_Z:
			shouldDestroy = pos.z < p_target.z
		POS_Z_GREATER_TARGET_Z:
			shouldDestroy = pos.z > p_target.z
		POS_X_GREATER_TARGET_X:
			shouldDestroy = pos.x > p_target.x
		POS_Y_GREATER_TARGET_Y:
			shouldDestroy = pos.y > p_target.y
		POS_Y_LESS_TARGET_Y:
			shouldDestroy = pos.y < p_target.y
		PARTICLES_DESTROYED:
			shouldDestroy = p_particlesDestroyed == 400
		CHECK_DISTANCE:
			var dist: float = getPosition().distanceSquared(p_target)
			shouldDestroy = dist < 0.2
		_:
			pass
	return shouldDestroy

func createPos(onAll, onEnemy):
	# Unimplemented. Override to implement effect.
	pass

## Java: createParticle() (ShatterParticleSystem adds createParticle(c, settings)).
func createParticle(c = null, p_settings = null):
	return Particle.new(getColor(), settings, self)

## Loads the textures if needed.
func loadGLTextures():
	ParticleSystem.load()
	tex = J.array(particleTexture.size())
	for i in range(particleTexture.size()):
		tex[i] = ImageHandler.getTexture(particleTexture[i]).getTexture()

func isDestroyed():
	return destroyed

func getGravity():
	return gravity

func isDead():
	if readyModeDone:
		return particlesLeft <= isDeadLimit if destroyed else false
	if readyMode != WAITING:
		return particlesLeft <= isDeadLimit if destroyed else false
	return false

func isReady():
	var ret: bool = false
	match readyMode:
		IS_DESTROYED:
			ret = isDestroyed()
		IS_DEAD:
			ret = isDead()
		IS_DELAYED:
			readyMode = WAITING
			readyModeDone = false
			Scheduler.after(readModeDelayTime, func(): readyModeDone = true)
		WAITING:
			ret = readyModeDone
	return ret

## Destroys the system (can result in an explosion depending on the system).
func destroy(body = null):
	gpu_destroys += 1
	if targetPoint != null:
		gravity = targetPoint
	else:
		gravity = destroyFadeGravity
	destroyed = true
	for p in particles:
		p.destroy(self)

## Abruptly kills the system (no explosion, it just disappears).
func kill():
	gpu_kills += 1
	destroyed = true
	for p in particles:
		p.kill()

## Java: draw(Graphics g).
func draw(g, t = null, pPos = null):
	if not hasInited:
		loadGLTextures()
		hasInited = true

	if blendMode != BLEND_MODE_NO_BLEND:
		g.beginBlend(true)
		g.setBlendFunc(Graphics.GL_ONE if additiveColoring else Graphics.GL_ONE_MINUS_SRC_ALPHA)

	var gl = g.getGL()
	tex[textures[0]].bind(gl)
	if drawable != null:
		drawable.drawGround(
				g, destroyed, getPosition(), particles, particlesLeft)
	if gpu:
		show_gpu(g)

	var piece: int = particles.size() / textures.size()
	for i in range(textures.size()):
		tex[textures[i]].bind(gl)
		g.beginQuads()
		for j in range(i * piece, (i + 1) * piece):
			# Main.hide_particles (dev) and the GPU path: no quads, the same GL
			# state (as far as the GPU path's smaller pool gives it).
			if Main.hide_particles or gpu:
				particles[j].place_particle(g)
			else:
				particles[j].drawParticle(g, additiveColoring)
		g.end()
	if blendMode != BLEND_MODE_NO_BLEND:
		g.endBlend()


## Bridge (the battle effects phase): where draw draws the particles, the
## GPU system takes their place: its node in the frame's 3D chunk
## (Graphics.show_node) gets the state; not with --hide-particles.
func show_gpu(g) -> void:
	if Main.hide_particles:
		return
	var node := g.show_node(get_instance_id(), EffectParticles3D.make) as EffectParticles3D
	if node != null:
		node.show_state(gpu_state(g))


## Bridge: the state EffectParticles3D.show_state takes (see there), in Godot
## types; the settings the first time (gpu_settings).
func gpu_state(g) -> Dictionary:
	var ahead: float = clampf(gpu_age - gpu_stepped, 0.0, 0.1)
	var p = getPosition()
	var v = getVelocity()
	var grav = getGravity()
	var textures_2d: Array = []
	for i in textures:
		textures_2d.append(tex[i].texture)
	var state := {"elapsed": gpu_elapsed,
		"body_position": Vector3(p.x, p.y, p.z) + Vector3(v.x, v.y, v.z) * ahead,
		"body_velocity": Vector3(v.x, v.y, v.z),
		"emitting": not emitter.isDestroyed(),
		"gravity": Vector3(grav.x, grav.y, grav.z) if grav != null else null,
		"destroy_events": gpu_destroys, "plain_events": gpu_plains, "kill_events": gpu_kills,
		"flare_pull": emitter is FlareEmitter and emitter.time_ > emitter.limit_,
		"path_time": emitter.getTimeCounter() if emitter is InterpolatingEmitter else gpu_age,
		"render": g.render_state_3d(), "textures": textures_2d}
	gpu_elapsed = 0.0
	if not gpu_shown:
		gpu_shown = true
		state.merge(gpu_settings())
	return state


## Bridge: the GPU system's settings (its first state): "seed", "amount",
## "preprocess", "settings" (effect_particle.gdshader's uniforms) and, for
## the image emitters, "points".
func gpu_settings() -> Dictionary:
	var s = settings
	var kinds := {DEFAULT_EMITTER_TYPE: 0, TEST_EMITTER_TYPE: 0, INTERPOLATING_EMITTER_TYPE: 1,
		LINE_EMITTER_TYPE: 2, FLARE_EMITTER_TYPE: 3, FLAME_EMITTER_TYPE: 4, SHATTER_EMITTER_TYPE: 5,
		DEMOLISH_EMITTER_TYPE: 6}
	var c: Array = getColor()
	var u := {
		"emitter_kind": kinds.get(int(s.getValue(AnimSettings.EMITTER_TYPE)), 0),
		"emit_step": gpu_emit_step, "pool_size": float(gpu_amount),
		"particle_mass": s.getValue(AnimSettings.PARTICLE_MASS),
		"mass_random": s.getValue(AnimSettings.MASS_RANDOM_MULT),
		"size": s.getValue(AnimSettings.SIZE), "size_random": s.getValue(AnimSettings.SIZE_RANDOM_MULT),
		"life_multiplier": s.getValue(AnimSettings.LIFE_MULTIPLIER),
		"position_noise": _vec(s.getVector(AnimSettings.POSITION_NOISE)),
		"set_velocity": s.getBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES),
		"velocity_random_mult": s.getValue(AnimSettings.VELOCITY_RANDOM_MULT),
		"velocity_random_add": s.getValue(AnimSettings.VELOCITY_RANDOM_ADD),
		"fade_random_mult": s.getValue(AnimSettings.FADE_RANDOM_MULT),
		"fade_random_add": s.getValue(AnimSettings.FADE_RANDOM_ADD),
		"fade_distance_power": s.getValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER),
		"fade_distance_mult": s.getValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER),
		"destroy_force": s.getValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER),
		"destroy_fade_mult": s.getValue(AnimSettings.DESTROY_FADE_RANDOM_MULT),
		"destroy_fade_add": s.getValue(AnimSettings.DESTROY_FADE_RANDOM_ADD),
		"destroy_stops": destroyMode == ParticleValues.DESTROY_ONCE,
		"has_target_point": s.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT) != null,
		"target_point": _vec(s.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT)),
		"target_point_mult": s.getValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT),
		"kill_on_arrive": s.getBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE),
		"has_collision": s.getVector(AnimSettings.COLLISION_VECTOR) != null,
		"collision": _vec(s.getVector(AnimSettings.COLLISION_VECTOR)),
		"color": Vector3(c[0], c[1], c[2]), "random_color": color == ParticleValues.COLOR_RANDOM,
		"texture_count": textures.size(),
		"source": _vec(info.source), "source_to_target": _vec(info.sourceToTarget),
		"total_time": info.totalTime}
	u.merge(_equation_uniforms(info.vectorEquation))
	var out := {"seed": gpu_seed, "amount": gpu_amount, "preprocess": gpu_preprocess, "settings": u}
	if emitter is Flame2Emitter or emitter is ShatterEmitter:
		out["points"] = _gpu_points()
	return out


## The vector equation's uniforms (effect_particle.gdshader's equation_*).
static func _equation_uniforms(e) -> Dictionary:
	var u := {"equation_kind": 0}
	if e == null:
		return u
	var b := Vector4.ZERO
	var w := 0.0
	if e is CircularWave:
		u.equation_kind = 1
		b.w = 1.0 if e.useStaticZ else 0.0
		u.equation_z = e.z
		w = 1.0 if e.clockWise else 0.0
	elif e is UpDownSideWave:
		u.equation_kind = 2
		w = 1.0 if e.horizontal else 0.0
	elif e is WhirlWind:
		u.equation_kind = 3
		b = Vector4(e.source.x, e.source.y, e.source.z, e.totalTime)
		w = 1.0 if e.clockWise else 0.0
	elif e is Line:
		u.equation_kind = 4
		b = Vector4(e.source.x, e.source.y, e.source.z, e.length)
		u.equation_a = Vector4.ZERO
		u.equation_b = b
		return u
	elif e is DemolishEquation:
		u.equation_kind = 5
		b = Vector4(e.source.x, e.source.y, e.source.z, 0.0)
		w = 1.0 if e.clockWise else 0.0
	elif e is CircularShape:
		u.equation_kind = 6
		b = Vector4(e.origin.x, e.origin.y, e.origin.z, 0.0)
		w = 1.0 if e.clockWise else 0.0
	else:
		return u
	u.equation_a = Vector4(e.omega, e.amplifier, e.phi, w)
	u.equation_b = b
	return u


## The image emitters' points (Flame2Emitter, ShatterEmitter): the image
## they read, scaled as they scale it, its pixels with alpha >= 0.5 (rows
## counted from the bottom) placed as they place them, at the source's z; for
## the shatter also the pixels' colours (alpha = the particle's life), in a
## random order (a slot takes each pixel once).
func _gpu_points() -> Dictionary:
	var name: String = Values.BattleImages + "stroke3.png" if emitter is Flame2Emitter \
			else enemy.getCurrentImageName()
	var image: Image = ImageHandler.getImage(name)
	var width: int = J.round(image.get_width() * 0.25)
	var height: int = J.round(image.get_height() * 0.25)
	image = GraphicHelp.scaleImage(image, width, height)
	var enemy_info = enemy.getInfo()
	var scale: float = enemy_info.get_(EnemyInfo.SCALE) * 800
	var lift: float = enemy_info.get_(EnemyInfo.HEIGHT)
	if emitter is Flame2Emitter:
		lift += enemy.getTempHeight()
	var x_offset: float = enemy_info.get_(EnemyInfo.X_OFFSET)
	var z: float = info.getSource().z
	var positions := PackedVector3Array()
	var colors := PackedColorArray()
	for row in height:
		for x in width:
			var c: Color = image.get_pixel(x, row)
			if c.a8 / 255.0 < 0.5:
				continue
			var y: int = height - 1 - row
			positions.append(Vector3((x - 0.5 * width) / 200.0 * scale + x_offset, y / 200.0 * scale + lift, z))
			colors.append(Color(c.r8 / 255.0, c.g8 / 255.0, c.b8 / 255.0, c.a8 / 255.0))
	if emitter is ShatterEmitter:
		var order := range(positions.size())
		var shuffle := RandomNumberGenerator.new()
		shuffle.seed = gpu_seed
		for i in range(order.size() - 1, 0, -1):
			var j := shuffle.randi_range(0, i)
			var t = order[i]
			order[i] = order[j]
			order[j] = t
		var p2 := PackedVector3Array()
		var c2 := PackedColorArray()
		for i in order:
			p2.append(positions[i])
			c2.append(colors[i])
		return {"positions": p2, "colors": c2}
	return {"positions": positions}


static func _vec(v) -> Vector3:
	return Vector3(v.x, v.y, v.z) if v != null else Vector3.ZERO

func start(g):
	pass

func end(g):
	pass

## Gets the color of the system (float[]).
func getColor():
	return ParticleValues.getColor(color)

func bindTexture(g, i):
	tex[textures[i]].bind(g.getGL())

static func getRandomVector(scalar):
	return Vector3f.new(
			rand.nextDouble() - 0.5,
			rand.nextDouble() - 0.5,
			rand.nextDouble() - 0.5).multLocal(scalar)

static func getRandomCircleVector(scalar):
	var theta: float = rand.nextDouble() * 2 * PI
	var v = Vector3f.new(
			cos(theta),
			sin(theta),
			0.0)
	v.multLocal(scalar * rand.nextDouble())
	return v

static func getRandomSphereVector(scalar):
	var theta: float = rand.nextDouble() * 2 * PI
	var v = Vector3f.new(
			cos(theta),
			sin(theta),
			sin(theta))
	v.multLocal(scalar * rand.nextDouble())
	return v

static func calcSourceToTarget(p_settings):
	var src = p_settings.getVector(AnimSettings.SOURCE)
	var sourceToTarget = p_settings.getVector(AnimSettings.TARGET).subtract(src)
	return sourceToTarget

static func calcTotalTime(p_settings):
	var sourceToTarget = calcSourceToTarget(p_settings)
	var l: float = sourceToTarget.length()
	var totalTime: float = l / p_settings.getValue(AnimSettings.SPEED)
	return totalTime

static func calcInterpolationInfo(p_settings):
	var src = p_settings.getVector(AnimSettings.SOURCE)
	var sourceToTarget = calcSourceToTarget(p_settings)
	var totalTime: float = calcTotalTime(p_settings)
	var ve = p_settings.getVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION)
	return InterpolationInfo.new(ve, src, sourceToTarget, totalTime)

func getTextureName(currentImage):
	return particleTexture[textures[currentImage]]

func getEnemy():
	return enemy


class InterpolationInfo extends RefCounted:
	var source = null
	var sourceToTarget = null
	var totalTime: float = 0.0
	var vectorEquation = null

	func _init(e = null, p_source = null, p_sourceToTarget = null, p_totalTime = null) -> void:
		vectorEquation = e
		source = p_source
		sourceToTarget = p_sourceToTarget
		totalTime = float(p_totalTime)

	func interpolate(pos, time):
		if vectorEquation != null: # Non linear
			return vectorEquation.getVectorAfterTime(source.add(sourceToTarget.mult(time / totalTime)), time)
		else: # Use straight line
			return source.add(sourceToTarget.mult(time / totalTime))

	func useVectorEquationFromSource():
		return vectorEquation.getVectorAfterTime(null, 0.0)

	func getSource():
		return source
