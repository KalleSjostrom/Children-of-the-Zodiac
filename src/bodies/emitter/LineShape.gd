class_name LineShape
extends EmitterShape
## Port of bodies.emitter.LineShape.

var point = null
var minAngleTan: float = 0.0
var maxAngleTan: float = 0.0
var interval: float = 0.0


func _init(settings = null) -> void:
	super(settings)
	point = settings.getVector(ShapeSettings.POINTS)
	var angle: float = settings.getValue(ShapeSettings.ANGLE)
	minAngleTan = tan(deg_to_rad(-angle))
	maxAngleTan = tan(deg_to_rad(angle))
	interval = maxAngleTan - minAngleTan


func modifyDirection(direction):
	var temp: float = J.random() * interval + minAngleTan
	direction.x += temp
	return direction


func getEmittancePos():
	var deltaX: float
	var deltaY: float
	var pos = getPosition()
	deltaX = point.x
	deltaY = point.y
	var emitPosition = Vector3f.new(
		J.random() * deltaX + pos.x,
		J.random() * deltaY + pos.y, 0.0)
	return emitPosition
