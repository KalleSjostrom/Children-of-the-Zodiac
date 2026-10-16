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

## Java overloads: ParticleSystem(AnimSettings, BattleEnemy) and
## ParticleSystem(AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	ParticleSystem.load()
	setSettings(p_settings)
	enemy = p_enemy
	create(nrParticles, settings)

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
			_tmpForce.x = grav.x * (J.random() - 0.5)
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
	if targetPoint != null:
		gravity = targetPoint
	else:
		gravity = destroyFadeGravity
	destroyed = true
	for p in particles:
		p.destroy(self)

## Abruptly kills the system (no explosion, it just disappears).
func kill():
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

	var piece: int = particles.size() / textures.size()
	for i in range(textures.size()):
		tex[textures[i]].bind(gl)
		g.beginQuads()
		for j in range(i * piece, (i + 1) * piece):
			particles[j].drawParticle(g, additiveColoring)
		g.end()
	if blendMode != BLEND_MODE_NO_BLEND:
		g.endBlend()

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
			J.random() - 0.5,
			J.random() - 0.5,
			J.random() - 0.5).multLocal(scalar)

static func getRandomCircleVector(scalar):
	var theta: float = J.random() * 2 * PI
	var v = Vector3f.new(
			cos(theta),
			sin(theta),
			0.0)
	v.multLocal(scalar * J.random())
	return v

static func getRandomSphereVector(scalar):
	var theta: float = J.random() * 2 * PI
	var v = Vector3f.new(
			cos(theta),
			sin(theta),
			sin(theta))
	v.multLocal(scalar * J.random())
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
