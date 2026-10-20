class_name StarParticle
extends BodiesParticle
## Port of bodies.particles.StarParticle.

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)


func _init(settings = null) -> void:
	super(settings)
	rgb[0] = 0.5 + J.random() / 2.0
	rgb[1] = 0.5 + J.random() / 2.0
	rgb[2] = 0.5 + J.random() / 2.0


## Java: update(float elapsedTime) (does not move the particle).
func update(elapsedTime, body = null):
	if J.random() < 0.01:
		rgb[0] = 0.5 + J.random() / 2.0
		rgb[1] = 0.5 + J.random() / 2.0
		rgb[2] = 0.5 + J.random() / 2.0


## Java: draw(Graphics g, GameTexture t, Vector3f pPos); draws at the
## particle's own position (ignores pPos).
func draw(g, t = null, pPos = null):
	if t is GameTexture:
		super.draw(g, t, Vector3f.ZERO)
	else:
		super.draw(g, t, pPos)


## Bridge (phase 1 step B): draw's override for Body.place_quad: stars are
## drawn without the system's position (fixed on the screen).
func place_quad(t, pPos) -> Array:
	return super.place_quad(t, Vector3f.ZERO)


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifyFadeValue(fadeValue):
	return 0.0


func isAlive():
	return true
