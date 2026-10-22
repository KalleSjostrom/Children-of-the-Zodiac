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
##
## WeatherParticle.drawParticle's arithmetic for all particles of a pass at
## once (_place_pass; phase 2 rollout, for the frame rate): what is the same
## for every particle is worked out once per pass (the view angle's cosine
## and sine, the clip distances, the corners' order and texture coordinates,
## the size and the colour: the particles of a system share their class's),
## the vertices go into one local array, and the texture coordinates and
## colours are filled in at the end. Every vertex, colour and cached value
## is the one drawParticle computes.
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
	var v: PackedVector3Array
	if not front:
		list.clear()
		var dir: int = Values.angleToDirection2(player.getDirection())
		var ps: Array = particlesz if dir == 0 or dir == 2 else particlesx
		v = _place_pass(ps, dir == 1 or dir == 2, pdir, loc, moving, false)
	else:
		v = _place_pass(list, false, pdir, loc, moving, true)
	if not v.is_empty():
		# drawParticle's corner order: texture coordinates 0,0 0,1 1,1 1,0 when
		# the player looks along one axis, 0,0 1,0 1,1 0,1 along the other.
		var d: int = pdir
		var quad_uv := PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]) 				if (d > 45 and d < 225) or d < -135 				else PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		var uvs := quad_uv
		while uvs.size() < v.size():
			uvs.append_array(uvs)
		uvs.resize(v.size())
		var alpha: float = particlesx[0].color[3]
		var colors := PackedColorArray()
		colors.resize(v.size())
		colors.fill(Color(1, 1, 1, alpha))
		out.uvs = uvs
		out.colors = colors
		out.alpha = alpha
		g.glColor4f(1, 1, 1, alpha)
		g.glTexCoord2f(quad_uv[3].x, quad_uv[3].y)
	out.vertices = g.getModelView() * v
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
	return out


## Bridge (phase 2 step B): WeatherParticle.drawParticle without the drawing,
## for each particle of ps in order (backwards when asked): the same view
## test and cached values (vars, resurrected); the back pass collects the
## particles close to the player into list (drawn again in the front pass).
## Returns the vertices of the quads it would draw (4 each, in the
## particles' space).
func _place_pass(ps: Array, backwards: bool, d: int, fs, changed: bool, front: bool) -> PackedVector3Array:
	var v := PackedVector3Array()
	var n: int = ps.size()
	if n == 0:
		return v
	var a: Array = WeatherParticle.angles[d + 180]
	var ca: float = a[0]
	var sa: float = a[1]
	var fx: float = fs[0]
	var fz: float = fs[1]
	var far_clip: float = 7.5 if front else 20.0
	var near_clip: float = 3.0 if front else 7.5
	var upper: bool = (d > 45 and d < 225) or d < -135
	var across: bool = (d > -135 and d < -45) or (d > 45 and d < 135)
	var size: Array = ps[0].size
	var width: float = size[WeatherParticle.WIDTH]
	var height: float = size[WeatherParticle.HEIGHT]
	var half_w: float = width / 2.0
	var half_h: float = height / 2.0
	var i: int = n - 1 if backwards else 0
	var step: int = -1 if backwards else 1
	for k in n:
		var p: WeatherParticle = ps[i]
		i += step
		var vars: Array = p.vars
		var s: float
		var sx: float
		var sz: float
		if changed or p.resurrected:
			var pos: Array = p.pos
			sx = pos[0] - fx
			sz = pos[2] - fz
			vars[WeatherParticle.SX] = sx
			vars[WeatherParticle.SZ] = sz
			s = sx * ca + sz * sa
			vars[WeatherParticle.S] = s
			p.resurrected = false
		else:
			sx = vars[WeatherParticle.SX]
			sz = vars[WeatherParticle.SZ]
			s = vars[WeatherParticle.S]
		if not front and s > 3 and s < 7:
			list.append(p)
		if s > near_clip and s < far_clip and (3.7 * (sx * sx + sz * sz)) < 5 * (s * s):
			var pos: Array = p.pos
			var x1: float = pos[0] - half_w
			var y1: float = pos[1] - half_h
			var y2: float = y1 + height
			var z1: float = pos[2] - half_w
			v.append(Vector3(x1, y1, z1))
			if upper:
				v.append(Vector3(x1, y2, z1))
				if across:
					var x2: float = x1 + width
					v.append(Vector3(x2, y2, z1))
					v.append(Vector3(x2, y1, z1))
				else:
					var z2: float = z1 + width
					v.append(Vector3(x1, y2, z2))
					v.append(Vector3(x1, y1, z2))
			else:
				if across:
					var x2: float = x1 + width
					v.append(Vector3(x2, y1, z1))
					v.append(Vector3(x2, y2, z1))
				else:
					var z2: float = z1 + width
					v.append(Vector3(x1, y1, z2))
					v.append(Vector3(x1, y2, z2))
				v.append(Vector3(x1, y2, z1))
	return v


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
