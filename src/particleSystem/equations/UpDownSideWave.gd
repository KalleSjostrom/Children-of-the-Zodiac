class_name UpDownSideWave
extends RefCounted
## Port of particleSystem.equations.UpDownSideWave (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var horizontal: bool = false
var info = null

## Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_info = null, p_horizontal = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	phi = float(p_phi)
	horizontal = bool(p_horizontal)
	info = p_info

func modifyVector(v, elapsedTime):
	var theta: float = (omega * time) + phi
	time += elapsedTime
	var s: float = sin(theta) * amplifier
	if horizontal:
		v.x = info.interpolate(null, time).x + s
	else:
		v.y = info.interpolate(null, time).y + s
	return v

func getVectorAfterTime(v, p_time):
	var theta: float = (omega * p_time) + phi
	var s: float = sin(theta) * amplifier
	if horizontal:
		v.x += s
	else:
		v.y += s
	return v
