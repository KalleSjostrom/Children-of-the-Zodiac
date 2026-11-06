class_name WeatherSystem
extends RefCounted
## Port of weather.WeatherSystem (abstract): a system of weather particles
## (rain, snow) drawn in the labyrinth. The particles are kept sorted along
## x and along z so they can be drawn back to front for the view direction.
##
## Bridge (the dungeon particles phase, docs/ARCHITECTURE.md section 10): the
## particles run on the GPU (WeatherParticles3D, drawn by the floor's
## DungeonWeather): the system builds no particles, and update and
## place_particles hand the nodes the state. The legacy simulation and
## drawing (the sorted particles, draw, loop, loopBackwards and the quads of
## --legacy=dungeon_particles) are removed (plan 7.9); WeatherParticle and its
## subclasses keep the laws the GPU particles run.

var NR_OF_PARTICLES: int = 0
var particleTexture = ""
var tex = null
var hasInited: bool = false
var force = null
## gpu_seed: the GPU particles' seed, drawn from the weather's generator;
## gpu_updates: the legacy updates since the back pass was placed;
## gpu_running: the particles run in this frame.
var gpu_seed := 0
var gpu_updates := 0
var gpu_running := false


func _init() -> void:
	NR_OF_PARTICLES = getNumberOfParticles()
	particleTexture = ImageHandler.addPermanentlyLoadNow(
			Values.ParticleSystemsImages + getTextureName())
	force = getForce()
	gpu_seed = WeatherParticle.rand.nextInt(J.INT_MAX)


## Counts the update for the GPU particles (the legacy one moved all the
## particles of the system).
func update():
	gpu_updates += 1


## Bridge (phase 2 step B and the dungeon particles phase): the legacy
## draw(g, player, front) without the drawing, the state a WeatherParticles3D
## pass takes (DungeonWeather.show_gpu): "gpu", "scene" (Rain or Snow),
## "seed", "running" (updated since the last frame; both passes take the
## back pass's value, so they run in step), "shown" (not --hide-particles),
## "location" (x, z) and "facing" (the player's integer angle) for the view
## test, and the GL "state" (alpha test, fog). The same GL state changes as
## the drawing, with the colour and texture coordinate its last quad leaves
## (a pass draws some of its 10 000 particles in every frame).
func place_particles(g, player, front) -> Dictionary:
	if not hasInited:
		tex = ImageHandler.getTexture(particleTexture).getTexture()
		hasInited = true
	g.setBlendFunc(Graphics.GL_ONE)
	setup(g)
	tex.bind(g.getGL())
	var st: Dictionary = g.render_state_3d()
	if not front:
		gpu_running = gpu_updates > 0
		gpu_updates = 0
	var d: int = player.getDirection()
	var color: Array = RainParticle.color_ if self is RainSystem else WeatherSnowParticle.color_
	g.glColor4f(1, 1, 1, color[3])
	if (d > 45 and d < 225) or d < -135:
		g.glTexCoord2f(1, 0)
	else:
		g.glTexCoord2f(0, 1)
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.setAlphaFunc(0.1)
	var loc = player.getLocation()
	return {"gpu": true, "scene": "Rain" if self is RainSystem else "Snow", "seed": gpu_seed,
		"running": gpu_running, "shown": not Main.hide_particles, "location": Vector2(loc[0], loc[1]),
		"facing": d, "state": st}


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
