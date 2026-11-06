class_name SaveSystem
extends RefCounted
## Port of particleSystem.SaveSystem: the particle effect of a save point.
##
## Bridge (the dungeon particles phase, docs/ARCHITECTURE.md section 10): the
## particles run on the GPU (SaveParticles3D, the save point's "Particles"
## node): the system builds no particles (nor their 400-step warm-up), and
## update and place_particles hand the node the state. The legacy simulation
## and drawing (the sorted particles, draw, loop, loopBackwards and the quads
## of --legacy=dungeon_particles) are removed (plan 7.9); SaveParticle keeps
## the laws the GPU particles run.

static var COLOR = [1.0, 1.0, 1.0]
const NR_OF_PARTICLES = 2000
var hasInited: bool = false
var tex = null
## Java: static final, initialized by the static initializer; loaded lazily
## here (first constructor call).
static var particleTexture = ""
static var pos = null
## gpu_seed: drawn from the save points' generator; gpu_center: the centre
## (pos is shared by every save point); gpu_updates: the updates since the
## last placing.
var gpu_seed := 0
var gpu_center := Vector2.ZERO
var gpu_updates := 0

func _init(x = null, z = null) -> void:
	if particleTexture == "":
		particleTexture = ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "particle.png")
	pos = [float(x), float(z)]
	gpu_seed = SaveParticle.rand.nextInt(J.INT_MAX)
	gpu_center = Vector2(pos[0], pos[1])

## Counts the update for the GPU particles (the legacy one moved all the
## particles).
func update():
	gpu_updates += 1


## Bridge (phase 2 step B and the dungeon particles phase): the legacy
## draw(g, dir) without the drawing, the state the save point's
## SaveParticles3D takes (DungeonSavePoint): "gpu",
## "seed", "center" (x, z), "running" (updated since the last placing),
## "shown" (the facing is in a quadrant that draws and not
## --hide-particles), "facing" (the player's integer angle) and the GL
## "state" (alpha test, fog). The same GL state changes as the drawing, and
## the texture coordinate its last quad leaves; the colour stays (the last
## particle's colour is not known here; lit objects ignore it and the
## weather sets its own).
func place_particles(g, dir) -> Dictionary:
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
