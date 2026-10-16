class_name BattleSystem
extends RefCounted
## Port of battleBacks.BattleSystem: an (abstract) particle system drawn as a
## battle background effect (e.g. snow).

var NR_OF_PARTICLES: int = 0
var particleTexture = ""
var particles = null
var tex = null
var hasInited: bool = false
var force = null
static var DUMMY_POS = [0.0, 0.0]


func _init() -> void:
	# Java field initializers (run before the constructor body).
	NR_OF_PARTICLES = getNumberOfParticles()
	particleTexture = ImageHandler.addPermanentlyLoadNow(
			Values.ParticleSystemsImages + getTextureName())
	force = getForce()

	var s: Array = J.array(NR_OF_PARTICLES, null)
	particles = J.array(NR_OF_PARTICLES, null)
	var temp: Array = J.array(NR_OF_PARTICLES, null)

	for i in range(NR_OF_PARTICLES):
		temp[i] = getParticle()
		s[i] = SortingElement.new(temp[i].pos.z, i)
	s.sort_custom(func(a, b): return a.compareTo(b) < 0)
	for i in range(NR_OF_PARTICLES):
		particles[i] = temp[s[i].getIndex()]


## Updates all particles of the system.
func update():
	for p in particles:
		p.update(force)


func draw(g, front):
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.beginBlend(false)
	g.setBlendFunc(Graphics.GL_ONE)

	tex.bind(g.getGL())
	g.beginQuads()
	for p in particles:
		p.drawParticle(g, 0, DUMMY_POS, false, false)
	g.end()
	g.endBlend()


func setup(gl):
	# Override to implement effect.
	pass


## Abstract.
func getNumberOfParticles():
	return 0


## Abstract.
func getTextureName():
	return ""


## Abstract.
func getParticle():
	return null


## Abstract.
func getForce():
	return null
