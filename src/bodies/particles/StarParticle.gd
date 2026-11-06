class_name StarParticle
extends BodiesParticle
## Port of bodies.particles.StarParticle.

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)


func _init(settings = null) -> void:
	super(settings)
	rgb[0] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0
	rgb[1] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0
	rgb[2] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0


## Java: update(float elapsedTime) (does not move the particle).
func update(elapsedTime, body = null):
	if BodiesParticleSystem.rand.nextDouble() < 0.01:
		rgb[0] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0
		rgb[1] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0
		rgb[2] = 0.5 + BodiesParticleSystem.rand.nextDouble() / 2.0


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifyFadeValue(fadeValue):
	return 0.0


func isAlive():
	return true
