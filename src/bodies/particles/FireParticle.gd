class_name FireParticle
extends BodiesParticle
## Port of bodies.particles.FireParticle.

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)


func _init(settings = null) -> void:
	super(settings)


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifyFadeValue(fadeValue):
	if getParent() != null:
		var pPos = getEmitPosition()
		fadeValue += pow(getPosition().distanceSquared(pPos) / 300.0, 3) / getFadeArg()
	return fadeValue
