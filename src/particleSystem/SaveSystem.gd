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
## Bridge (the dungeon particles phase, docs/ARCHITECTURE.md section 10): the
## particles run on the GPU (SaveParticles3D, the save point's "Particles"
## node) unless the legacy drawing is kept (WeatherSystem.gpu_path); then
## the system builds no particles (nor their 400-step warm-up), and update
## and place_particles hand the node the state (place_gpu). gpu_seed: drawn
## from the save points' generator; gpu_center: the centre (pos is shared
## by every save point); gpu_updates: the updates since the last placing.
var gpu := false
var gpu_seed := 0
var gpu_center := Vector2.ZERO
var gpu_updates := 0

func _init(x = null, z = null) -> void:
	if particleTexture == "":
		particleTexture = ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "particle.png")
	pos = [float(x), float(z)]
	gpu = WeatherSystem.gpu_path()
	if gpu:
		gpu_seed = SaveParticle.rand.nextInt(J.INT_MAX)
		gpu_center = Vector2(pos[0], pos[1])
		return
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
	if gpu:
		gpu_updates += 1
		return
	for p in particlesx:
		p.update()

func loop(g, particles, dir):
	for p in particles:
		p.drawParticle(g, dir)

func loopBackwards(g, particles, dir):
	for i in range(NR_OF_PARTICLES - 1, -1, -1):
		particles[i].drawParticle(g, dir)

## Bridge (phase 2 step B, docs/ARCHITECTURE.md section 10): draw(g, dir)
## without the drawing: the same GL state changes, and the quads it would
## draw, in eye space (the modelview applied, as GLBackend does): "vertices"
## (4 per quad), "uvs", "colors" and the render state "state".
func place_particles(g, dir) -> Dictionary:
	if gpu:
		return place_gpu(g, dir)
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.setBlendFunc(Graphics.GL_ONE)
	g.setAlphaTestEnabled(true)
	g.setAlphaFunc(0)
	tex.bind(g.getGL())
	var out := {"vertices": PackedVector3Array(), "uvs": PackedVector2Array(),
		"colors": PackedColorArray(), "state": g.render_state_3d()}
	if dir > -135 and dir < -45: # 0
		for p in particlesz:
			p.place_quad(g, 0, out)
	elif dir > -45 and dir < 45: # 1
		for i in range(NR_OF_PARTICLES - 1, -1, -1):
			particlesx[i].place_quad(g, 1, out)
	elif dir > 45 and dir < 135:
		for i in range(NR_OF_PARTICLES - 1, -1, -1):
			particlesz[i].place_quad(g, 2, out)
	elif dir > 135 or dir < -135: # 3
		for p in particlesx:
			p.place_quad(g, 3, out)
	var uvs: PackedVector2Array = out.uvs
	if not uvs.is_empty():
		g.glTexCoord2f(uvs[uvs.size() - 1].x, uvs[uvs.size() - 1].y)
	out.vertices = g.getModelView() * out.vertices
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
	# Main.hide_particles (dev): no quads, the same GL state.
	if Main.hide_particles:
		out.vertices = PackedVector3Array()
		out.uvs = PackedVector2Array()
		out.colors = PackedColorArray()
	return out


## Bridge (the dungeon particles phase): place_particles on the GPU path, the
## state the save point's SaveParticles3D takes (DungeonSavePoint): "gpu",
## "seed", "center" (x, z), "running" (updated since the last placing),
## "shown" (the facing is in a quadrant that draws and not
## --hide-particles), "facing" (the player's integer angle) and the GL
## "state" (alpha test, fog). The same GL state changes as the drawing, and
## the texture coordinate its last quad leaves; the colour stays (the last
## particle's colour is not known here; lit objects ignore it and the
## weather sets its own).
func place_gpu(g, dir) -> Dictionary:
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.setBlendFunc(Graphics.GL_ONE)
	g.setAlphaTestEnabled(true)
	g.setAlphaFunc(0)
	tex.bind(g.getGL())
	var st: Dictionary = g.render_state_3d()
	var drawn := true
	if (dir > -135 and dir < -45) or (dir > -45 and dir < 45): # 0, 1
		g.glTexCoord2f(0, 1)
	elif (dir > 45 and dir < 135) or dir > 135 or dir < -135: # 2, 3
		g.glTexCoord2f(1, 0)
	else:
		drawn = false
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
	var running := gpu_updates > 0
	gpu_updates = 0
	return {"gpu": true, "seed": gpu_seed, "center": gpu_center, "running": running,
		"shown": drawn and not Main.hide_particles, "facing": dir, "state": st}


func draw(g, dir):
	# Main.hide_particles (dev): the same GL state, nothing drawn. On the GPU
	# path the floor's scene draws the particles (DungeonSavePoint).
	if Main.hide_particles or gpu:
		place_particles(g, dir)
		return
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
