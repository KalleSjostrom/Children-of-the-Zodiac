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


## Bridge (phase 2 step B, docs/ARCHITECTURE.md section 10): draw(g, player,
## front) without the drawing, for a floor its scene draws (DungeonWeather):
## the same GL state changes, the same particle state (the front list of the
## back pass, each particle's cached view values), and the quads it would
## draw, in eye space (the modelview applied, as GLBackend does): "vertices"
## (4 per quad), "uvs", "colors" and the render state "state".
func place_particles(g, player, front) -> Dictionary:
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.setBlendFunc(Graphics.GL_ONE)
	setup(g)
	tex.bind(g.getGL())
	var out := {"vertices": PackedVector3Array(), "uvs": PackedVector2Array(),
		"colors": PackedColorArray(), "state": g.render_state_3d(), "alpha": -1.0}
	var pdir: int = player.getDirection()
	var loc = player.getLocation()
	var moving: bool = player.isMoving()
	if not front:
		list.clear()
		var dir: int = Values.angleToDirection2(player.getDirection())
		var ps: Array = particlesz if dir == 0 or dir == 2 else particlesx
		if dir == 1 or dir == 2:
			var i: int = NR_OF_PARTICLES - 1
			while i >= 0:
				if ps[i].place_quad(pdir, loc, moving, false, out):
					list.append(ps[i])
				i -= 1
		elif dir == 0 or dir == 3:
			for p in ps:
				if p.place_quad(pdir, loc, moving, false, out):
					list.append(p)
	else:
		for p in list:
			p.place_quad(pdir, loc, moving, true, out)
	if out.alpha >= 0.0:
		var uvs: PackedVector2Array = out.uvs
		g.glColor4f(1, 1, 1, out.alpha)
		g.glTexCoord2f(uvs[uvs.size() - 1].x, uvs[uvs.size() - 1].y)
	out.vertices = g.getModelView() * out.vertices
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
	return out


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
