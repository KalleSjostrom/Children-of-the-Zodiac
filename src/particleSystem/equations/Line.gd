class_name Line
extends RefCounted
## Port of particleSystem.equations.Line (implements VectorEquation).

var source = null
var length: float = 0.0
static var counterRight: int = 0
static var counterLeft: int = 0

func _init(p_source = null, p_length = null) -> void:
	source = p_source
	length = float(p_length)

func modifyVector(v, elapsedTime):
	return getVectorAfterTime(v, 0.0)

func getVectorAfterTime(v, time):
	v = source.clone()
	var test: float = ParticleSystem.rand.nextDouble() * length
	if test < length / 2.0:
		counterLeft += 1
	else:
		counterRight += 1
	v.x += test
	return v
