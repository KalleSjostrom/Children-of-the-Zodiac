class_name SmokeParticle
extends BodiesParticle
## Port of bodies.particles.SmokeParticle.

static var force_ = Vector3f.new(0, GravityCommand.DEFAULT_GRAVITY, 0)
var turned: bool = false
var max: float = 0.0


func _init(settings = null) -> void:
	super(settings)


func executeCommand(command, value):
	if command == "max":
		self.max = SystemLoader.getValueFromInterval(value)


func getDefaultForce():
	return force_.clone().multLocal(getMass())


func modifySize(size):
	life = minf(life, 1)
	if not turned:
		return (1 + life) * size
	return (1.5 * (self.max - life) + (1 + self.max)) * size


func getFadeValue():
	return BodiesParticleSystem.rand.nextDouble() / 200.0 + 0.001


## Java: update(float elapsedTime) (seconds).
func update(elapsedTime, body = null):
	super.update(elapsedTime)
	life += fadeValue
	life += -fadeValue if turned else 2 * fadeValue
	if life >= self.max:
		turned = true


func reset():
	super.reset()
	life = 0.001
	turned = false


func modifyFadeValue(fadeValue):
	if getParent() != null:
		var pPos = getEmitPosition()
		fadeValue += (getPosition().distance(pPos) / 10000.0) * fadeValue
	return fadeValue
