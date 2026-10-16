class_name SaveSystem
extends RefCounted
## Port of particleSystem.SaveSystem: the particle effect of a save point.

static var COLOR = [1.0, 1.0, 1.0]
const NR_OF_PARTICLES = 2000
var hasInited: bool = false
var tex = null
## Java: static final, initialized by the static initializer; loaded lazily
## here (first constructor call).
static var particleTexture = ""
static var pos = null
var particlesx = null
var particlesz = null

func _init(x = null, z = null) -> void:
	if particleTexture == "":
		particleTexture = ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "particle.png")
	pos = [float(x), float(z)]
	var Xlist: Array = J.array(NR_OF_PARTICLES)
	var Zlist: Array = J.array(NR_OF_PARTICLES)
	particlesx = J.array(NR_OF_PARTICLES)
	particlesz = J.array(NR_OF_PARTICLES)
	var particles: Array = J.array(NR_OF_PARTICLES)

	for i in range(NR_OF_PARTICLES):
		particles[i] = SaveParticle.new()
		Xlist[i] = SortingElement.new(particles[i].getPos(0), i)
		Zlist[i] = SortingElement.new(particles[i].getPos(2), i)
	# Java Arrays.sort (stable); ties keep the original order.
	var cmp := func(a, b): return a.getYpos() < b.getYpos() \
			or (a.getYpos() == b.getYpos() and a.getIndex() < b.getIndex())
	Xlist.sort_custom(cmp)
	Zlist.sort_custom(cmp)
	for i in range(NR_OF_PARTICLES):
		particlesx[i] = particles[Xlist[i].getIndex()]
		particlesz[i] = particles[Zlist[i].getIndex()]

func update():
	for p in particlesx:
		p.update()

func loop(g, particles, dir):
	for p in particles:
		p.drawParticle(g, dir)

func loopBackwards(g, particles, dir):
	for i in range(NR_OF_PARTICLES - 1, -1, -1):
		particles[i].drawParticle(g, dir)

func draw(g, dir):
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true

	g.setBlendFunc(Graphics.GL_ONE)
	g.setAlphaTestEnabled(true)
	g.setAlphaFunc(0)
	tex.bind(g.getGL())
	g.beginQuads()
	if dir > -135 and dir < -45: # 0
		loop(g, particlesz, 0)
	elif dir > -45 and dir < 45: # 1
		loopBackwards(g, particlesx, 1)
	elif dir > 45 and dir < 135:
		loopBackwards(g, particlesz, 2)
	elif dir > 135 or dir < -135: # 3
		loop(g, particlesx, 3)
	g.end()
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
