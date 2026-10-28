class_name CircleShape
extends EmitterShape
## Port of bodies.emitter.CircleShape.

var radiusa: float = 0.0
var radiusb: float = 0.0


func _init(settings = null) -> void:
	super(settings)
	radiusa = settings.getVector(ShapeSettings.POINTS).x
	radiusb = settings.getVector(ShapeSettings.POINTS).y


func modifyDirection(direction):
	return direction


func getEmittancePos():
	var emitPosition = Vector3f.new()
	var theta: float = BodiesParticleSystem.rand.nextDouble() * 2 * PI
	emitPosition.x = radiusa * cos(theta)
	emitPosition.y = radiusb * sin(theta)
	emitPosition.addLocal(getPosition())
	return emitPosition
