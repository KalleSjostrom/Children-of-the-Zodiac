class_name RainbowParticle
extends BodiesParticle
## Port of bodies.particles.RainbowParticle.

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)


func _init(settings = null) -> void:
	super(settings)


func reset():
	super.reset()
	rgb[0] = J.random()
	rgb[1] = J.random()
	rgb[2] = J.random()


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifyFadeValue(fadeValue):
	if getParent() != null:
		var pPos = getEmitPosition()
		fadeValue += pow(getPosition().distanceSquared(pPos) / 1000.0, 3) / getFadeArg()
	return fadeValue
