class_name DemolishEquation
extends RefCounted
## Port of particleSystem.equations.DemolishEquation (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var source = null
var clockWise: bool = false

## Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_source = null, p_clockWise = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	source = p_source
	phi = float(p_phi)
	clockWise = bool(p_clockWise)

func modifyVector(v, elapsedTime):
	time += elapsedTime
	return getVectorAfterTime(v, time)

func getVectorAfterTime(v, p_time):
	var theta: float = (omega * p_time) + phi
	var t: float = 2.0 * PI - theta if clockWise else theta
	var c: float = cos(t) * amplifier
	var s: float = sin(t) * amplifier
	v.y = source.y + s
	v.x = source.x + c
	return v
