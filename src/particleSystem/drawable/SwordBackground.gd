class_name SwordBackground
extends RefCounted
## Port of particleSystem.drawable.SwordBackground (implements SystemDrawable).

var source = null
var target = null

func _init(p_source = null, p_target = null) -> void:
	source = p_source
	target = p_target

func drawGround(g, destroyed, pos, particles, particlesLeft):
	if not destroyed:
		var tSize: float = 0.0
		var ySize: float = 0.2
		var x: float = pos.x if absf(pos.x - target.x) > ySize else target.x
		var y: float = pos.y if absf(pos.y - target.y) > ySize else target.y
		var z: float = target.z
		var alpha: float = 0.0 if particles.size() == 0 else float(particlesLeft) / float(particles.size())
		var gl = g.getGL()
		g.setColor(1.0, 1.0, 1.0, alpha)
		g.beginQuads()

		gl.glTexCoord2i(0, 0)
		gl.glVertex3f(source.x - tSize, source.y - ySize, z)
		gl.glTexCoord2i(1, 0)
		gl.glVertex3f(x + tSize, source.y - ySize, z)
		gl.glTexCoord2i(1, 1)
		gl.glVertex3f(x + tSize, y + ySize, z)
		gl.glTexCoord2i(0, 1)
		gl.glVertex3f(source.x - tSize, y + ySize, z)
		g.end()
