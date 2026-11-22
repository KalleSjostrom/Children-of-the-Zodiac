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

## Bridge (phase 4.4's rollout, part 5, step B, docs/ARCHITECTURE.md section
## 15): drawParticle (Java: translate, gluSphere, translateBack; removed:
## closing phase 4.4, plan 9.4) without the drawing: the same matrix calls, and the
## sphere's triangles kept instead of drawn (Graphics.begin_capture_3d: the
## same glNormal3f and glVertex3f calls, in the material of the render state
## SphereParticleSystem.start set) and shown by the PanelQuad of key in the
## slot of their batch, merged with the spheres before it as the batch would
## have merged them (Utils3D.show_triangles).
func show_particle(g, key: Array) -> void:
	var pos = getPosition()
	if pos.z >= -6: # TODO (original): Change to enemy depth.
		g.translate(pos)
		g.begin_capture_3d()
		g.gluSphere(quad, size, 50, 50)
		for batch in g.end_capture_3d():
			Utils3D.show_triangles(g, key, batch)
		g.translateBack(pos)
