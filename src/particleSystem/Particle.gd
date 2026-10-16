class_name Particle
extends PointBody
## Port of particleSystem.Particle: common methods for a particle.

var life: float = 0.0
var fade: float = 0.0
var rgb = null
var fadeDistMult: float = 0.0
var fadeDistPower: float = 0.0
var fadeRandomAdd: float = 0.0
var fadeRandomMult: float = 0.0
var destroyForceVectorAmplifier: float = 0.0
var destroyFadeRandomAdd: float = 0.0
var destroyFadeRandomMult: float = 0.0
var velocityRandMult: float = 0.0
var velocityRandAdd: float = 0.0
var lifeMultiplier: float = 0.0
var systemDead: bool = false
var setVelocityOnParticles: bool = false
var source = null
var positionNoise = null
var counter: int = 0
var size: float = 0.0
var targetPointGravityMult: float = 0.0
var color = null
var collisionVector = null
var targetPoint = null
var targetPointGravityKillOnArrive: bool = false

## Java: Particle(float[] color, AnimSettings settings, PointBody body).
func _init(p_color = null, p_settings = null, body = null) -> void:
	setSettings(p_settings)
	rgb = p_color
	life = 1.0
	fade = getFade()

func setSettings(settings):
	setMass(settings.getValue(AnimSettings.PARTICLE_MASS)
			+ J.random() * settings.getValue(AnimSettings.MASS_RANDOM_MULT))
	size = settings.getValue(AnimSettings.SIZE) \
			+ J.random() * settings.getValue(AnimSettings.SIZE_RANDOM_MULT)

	lifeMultiplier = settings.getValue(AnimSettings.LIFE_MULTIPLIER)
	positionNoise = settings.getVector(AnimSettings.POSITION_NOISE)
	velocityRandAdd = settings.getValue(AnimSettings.VELOCITY_RANDOM_ADD)
	velocityRandMult = settings.getValue(AnimSettings.VELOCITY_RANDOM_MULT)
	setVelocityOnParticles = settings.getBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES)
	fadeDistPower = settings.getValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER)
	fadeDistMult = settings.getValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER)
	source = settings.getVector(AnimSettings.SOURCE)

	fadeRandomMult = settings.getValue(AnimSettings.FADE_RANDOM_MULT)
	fadeRandomAdd = settings.getValue(AnimSettings.FADE_RANDOM_ADD)

	destroyForceVectorAmplifier = settings.getValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER)
	destroyFadeRandomMult = settings.getValue(AnimSettings.DESTROY_FADE_RANDOM_MULT)
	destroyFadeRandomAdd = settings.getValue(AnimSettings.DESTROY_FADE_RANDOM_ADD)
	targetPoint = settings.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT)
	targetPointGravityMult = settings.getValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT)
	targetPointGravityKillOnArrive = settings.getBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE)

	collisionVector = settings.getVector(AnimSettings.COLLISION_VECTOR)

func applyRand(pos, rand):
	pos.x += (J.random() - 0.5) * rand.x
	pos.y += (J.random() - 0.5) * rand.y
	pos.z += (J.random() - 0.5) * rand.z
	return pos

func getFade():
	return J.random() * fadeRandomMult + fadeRandomAdd

## Draws the particle (inside a beginQuads/end block of the system).
func drawParticle(g, additiveColoring):
	var pos = getPosition()
	if color != null:
		g.setColor(color.x, color.y, color.z, life * lifeMultiplier)
	else:
		g.setColor(rgb[0], rgb[1], rgb[2], life * lifeMultiplier)
	g.drawCenteredCurrent2D(pos, size)

func setLifeMultiplier(lm):
	lifeMultiplier = lm

## Moves the particle and decreases its life. elapsedTime in seconds.
func update(elapsedTime, body = null):
	var p = getPosition()
	var temp = null
	if targetPoint != null:
		temp = Vector3f.new(
				targetPoint.x - p.x,
				targetPoint.y - p.y, targetPoint.z - p.z)

		var grav = temp.multLocal(targetPointGravityMult)
		setForce(grav)
	super.update(elapsedTime)
	life -= increaseFade(getPosition().distanceSquared(body.getPosition()))
	p = getPosition()
	if targetPoint != null:
		var temp2 = Vector3f.new(
				targetPoint.x,
				targetPoint.y, 0.0)
		temp = Vector3f.new(
				p.x,
				p.y, 0.0)
		if targetPointGravityKillOnArrive:
			var ls: float = temp2.lengthSquared()
			var pls: float = temp.lengthSquared()
			if pls > ls:
				life = 0.0
		elif p.y < 0:
			p = ParticleSystem.getRandomSphereVector(0.05)
			p.z -= 2
			setPosition(p)
			targetPoint = null
			setForce(Vector3f.new())
			setVelocity(Vector3f.new())
			life = 1.0

	if collisionVector != null:
		var v = getVelocity()
		if p.x <= collisionVector.x and v.x < 0:
			v.x *= -0.8
		elif p.x >= collisionVector.y and v.x > 0:
			v.x *= -0.8
		if p.y <= collisionVector.z and v.y < 0:
			v.y *= -0.8

func increaseFade(dist):
	if not systemDead:
		fade += pow(dist, fadeDistPower) * fadeDistMult
	return fade

## Java overloads: resurrect(body, pos) and resurrect(body, pos, int startLife).
func resurrect(body, pos, startLife = null):
	life = 1.0 if startLife == null else float(startLife)
	fade = getFade()
	var p
	if pos == null:
		p = body.getPosition().clone()
		setPosition(applyRand(p, positionNoise))
	else:
		setPosition(pos)
	if body != null:
		setForce(body.getForce().clone())
	setVelocity(Vector3f.new(0.0, 0.0, 0.0))
	if setVelocityOnParticles:
		var velRand: float = J.random() * velocityRandMult + velocityRandAdd
		setVelocity(body.getVelocity().clone().multLocal(velRand))

func isAlive():
	return life > 0

## Kills the particle forever (the system is dead, no resurrection).
func kill():
	systemDead = true

## Called when the particle system is destroyed (explosion-like sparks).
func destroy(body = null):
	var f = ParticleSystem.getRandomSphereVector(1.0)
	f.multLocal((J.random() + 0.1) * destroyForceVectorAmplifier)
	setForce(f)
	fade = J.random() * destroyFadeRandomMult + destroyFadeRandomAdd
	systemDead = true

func plainDestroy(particleSystem = null):
	fade = J.random() * destroyFadeRandomMult + destroyFadeRandomAdd

func isDestroyed():
	var dist: float = getPosition().distanceSquared(source)
	var destroyed: bool = dist < 0.01 and not systemDead
	if destroyed:
		counter += 1
		setForce(Vector3f.new(0.0, 0.0, 0.0))
		setVelocity(Vector3f.new(0.0, 0.0, 0.0))
	# TODO (original): Counter only for flare.
	return counter > 8 and not systemDead

func addLife(f):
	life += f

func getLife():
	return life

func setLife(l):
	life = l

## Java: setColor(Vector3f c, float a).
func setColor(c, a = null):
	color = c
	life = a
