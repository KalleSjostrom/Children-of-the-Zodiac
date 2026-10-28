class_name BoxShape
extends EmitterShape
## Port of bodies.emitter.BoxShape.

var vectors = [null, null]
var zeroHundred: int = 0
var hundred200: int = 0


func _init(settings = null) -> void:
	super(settings)
	vectors[0] = settings.getVector(ShapeSettings.POINTS)
	vectors[1] = settings.getVector(ShapeSettings.POINTS + 1)


func modifyDirection(direction):
	return direction


func getEmittancePos():
	var index: int = 0 if BodiesParticleSystem.rand.nextDouble() < 0.5 else 1
	var temp = interpolate(vectors[index])
	index = absi(index - 1)
	var emitPosition = interpolate(vectors[index]).add(temp).add(getPosition())
	if emitPosition.x < 300:
		zeroHundred += 1
	else:
		hundred200 += 1
	return emitPosition


func interpolate(v):
	var l: float = v.length()
	var newL: float = BodiesParticleSystem.rand.nextDouble() * l
	return v.normalize().multLocal(newL)
