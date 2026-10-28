class_name BodiesParticle
extends Body
## Port of bodies.particles.Particle (GDScript class BodiesParticle): a body
## that fades out over time.

var fadeValue: float = 0.0
var fade = Vector3f.new(1000, 0.001, 2000)


func _init(settings = null) -> void:
	if settings != null:
		for type in SystemLoader.settingKeys(settings):
			match int(type):
				ParticleSettings.POSITION:
					setPosition(settings.getVector(type))
				ParticleSettings.MASS:
					setMass(SystemLoader.getValueFromInterval(settings.getString(type)))
				ParticleSettings.SIZE:
					setSize(SystemLoader.getValueFromInterval(settings.getString(type)))
				ParticleSettings.COLOR:
					setColor(settings.getVector(type))
				ParticleSettings.FADE:
					fade = settings.getVector(type)
				_:
					pass
	reset()
	kill()
	if settings != null:
		parseArgs(settings.getString(ParticleSettings.SETTINGS))


## Abstract in Java.
func modifyFadeValue(fadeValue):
	return fadeValue


## Java: update(float elapsedTime) (seconds).
func update(elapsedTime, body = null):
	super.update(elapsedTime)
	fadeValue = modifyFadeValue(fadeValue)
	life -= fadeValue


func getFadeValue():
	return getRandomFade() + getFadeOffset()


func getRandomFade():
	return BodiesParticleSystem.rand.nextDouble() / fade.x


func getFadeOffset():
	return fade.y


func getFadeArg():
	return fade.z


func reset():
	super.reset()
	fadeValue = getFadeValue()


func checkCollision(b):
	pass


func moveStuck(elapsedTime):
	pass


func parseArgs(args):
	if args != null and String(args).contains("="):
		args = args.replace("[", "")
		args = args.replace("]", "")
		var argv
		if args.contains(";"):
			argv = J.split(args, ";")
		else:
			argv = [args]
		for s in argv:
			var params = J.split(s, "=")
			executeCommand(params[0], params[1])


func executeCommand(command, value):
	pass
