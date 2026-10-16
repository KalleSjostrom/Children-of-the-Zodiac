class_name WhirlWind
extends RefCounted
## Port of particleSystem.equations.WhirlWind (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var source = null
var clockWise: bool = false
var totalTime: float = 0.0

## Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_source = null, p_clockWise = null, p_totalTime = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	source = p_source
	phi = float(p_phi)
	clockWise = bool(p_clockWise)
	totalTime = float(p_totalTime)

func modifyVector(v, elapsedTime):
	time += elapsedTime
	return getVectorAfterTime(v, time)

func getVectorAfterTime(v, p_time):
	var percent: float = pow(p_time / totalTime, 2.0) * 8.0 + 0.5 + 2.0 * p_time
	var theta: float = (omega * p_time) + phi
	var t: float = 2.0 * PI - theta if clockWise else theta
	var c: float = cos(t) * amplifier * percent
	var s: float = sin(t) * amplifier * percent
	v.z = source.z + s
	v.x = source.x + c
	v.y = v.y + (J.random() - 0.5) * 0.3
	return v
