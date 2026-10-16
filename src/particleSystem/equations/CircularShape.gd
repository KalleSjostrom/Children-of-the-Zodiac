class_name CircularShape
extends RefCounted
## Port of particleSystem.equations.CircularShape (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var clockWise: bool = false
var origin = null

## Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_clockWise = null, p_origin = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	phi = float(p_phi)
	clockWise = bool(p_clockWise)
	origin = p_origin

func modifyVector(v, elapsedTime):
	time += elapsedTime
	return getVectorAfterTime(v, time)

func getVectorAfterTime(v, p_time):
	var theta: float = (omega * p_time) + phi
	var t: float = 2.0 * PI - theta if clockWise else theta
	var c: float = cos(t) * amplifier
	var s: float = sin(t) * amplifier
	v.x = origin.x + c
	v.y = origin.y + s
	v.z = origin.z
	return v
