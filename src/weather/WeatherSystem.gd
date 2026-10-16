class_name WeatherSystem
extends RefCounted
## Port of weather.WeatherSystem (abstract): a system of weather particles
## (rain, snow) drawn in the labyrinth. The particles are kept sorted along
## x and along z so they can be drawn back to front for the view direction.

var NR_OF_PARTICLES: int = 0
var particleTexture = ""
var particlesx = null
var particlesz = null
var tex = null
var hasInited: bool = false
var force = null
var list = []


func _init() -> void:
	NR_OF_PARTICLES = getNumberOfParticles()
	particleTexture = ImageHandler.addPermanentlyLoadNow(
			Values.ParticleSystemsImages + getTextureName())
	force = getForce()
	var x: Array = J.array(NR_OF_PARTICLES, null)
	var z: Array = J.array(NR_OF_PARTICLES, null)
	particlesx = J.array(NR_OF_PARTICLES, null)
	particlesz = J.array(NR_OF_PARTICLES, null)
	var particles: Array = J.array(NR_OF_PARTICLES, null)

	for i in NR_OF_PARTICLES:
		particles[i] = getParticle()
		x[i] = SortingElement.new(particles[i].pos[0], i)
		z[i] = SortingElement.new(particles[i].pos[2], i)
	x.sort_custom(func(a, b): return a.yPos < b.yPos)
	z.sort_custom(func(a, b): return a.yPos < b.yPos)
	for i in NR_OF_PARTICLES:
		particlesx[i] = particles[x[i].getIndex()]
		particlesz[i] = particles[z[i].getIndex()]


## Updates all the particles of the system.
func update():
	for p in particlesx:
		p.update(force)


func draw(g, player, front):
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.setBlendFunc(Graphics.GL_ONE)
	setup(g)
	tex.bind(g.getGL())
	g.beginQuads()
	if not front:
		var dir: int = Values.angleToDirection2(player.getDirection())
		match dir:
			0:
				loop(g, particlesz, player)
			1:
				loopBackwards(g, particlesx, player)
			2:
				loopBackwards(g, particlesz, player)
			3:
				loop(g, particlesx, player)
	else:
		var pdir: int = player.getDirection()
		var loc = player.getLocation()
		var moving: bool = player.isMoving()
		for p in list:
			p.drawParticle(g, pdir, loc, moving, true)
	g.end()

	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)


func loop(g, particles, player):
	list.clear()
	var pdir: int = player.getDirection()
	var loc = player.getLocation()
	var moving: bool = player.isMoving()
	for p in particles:
		if p.drawParticle(g, pdir, loc, moving, false):
			list.append(p)


func loopBackwards(g, particles, player):
	list.clear()
	var pdir: int = player.getDirection()
	var loc = player.getLocation()
	var moving: bool = player.isMoving()
	var i: int = NR_OF_PARTICLES - 1
	while i >= 0:
		if particles[i].drawParticle(g, pdir, loc, moving, false):
			list.append(particles[i])
		i -= 1


func setup(g):
	pass # Override to implement effect.


## (abstract)
func getNumberOfParticles():
	return 0


## (abstract)
func getTextureName():
	return ""


## (abstract)
func getParticle():
	return null


## (abstract)
func getForce():
	return null
