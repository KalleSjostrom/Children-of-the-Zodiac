class_name SphereParticle
extends Particle
## Port of particleSystem.SphereParticle: a particle drawn as a lit sphere.

## Java: static GLU / GLUquadric. The Graphics object is the GLU here and
## the quadric is unused by the emulation (gluNewQuadric returns null).
static var glu = null
static var quad = null
var alive: bool = true

func _init(p_color = null, p_settings = null, body = null) -> void:
	super(p_color, p_settings, body)

func isAlive():
	return alive

func kill():
	super.kill()
	alive = false

func drawParticle(g, additiveColoring):
	var pos = getPosition()
	if pos.z >= -6: # TODO (original): Change to enemy depth.
		g.translate(pos)
		g.gluSphere(quad, size, 50, 50)
		g.translateBack(pos)
