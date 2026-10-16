class_name BodiesSnowParticle
extends BodiesParticle
## Port of bodies.particles.SnowParticle (GDScript class BodiesSnowParticle).

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)
var height: int = 0


func _init(settings = null) -> void:
	super(settings)


func executeCommand(command, value):
	if command == "height":
		height = J.parseInt(value)


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifyFadeValue(fadeValue):
	return 0.0


func isAlive():
	return getPosition().y > -height
