class_name CircularWave
extends RefCounted
## Port of particleSystem.equations.CircularWave (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var clockWise: bool = false
var z: float = 0.0
var useStaticZ: bool = false

## Java overloads: (period, amplifier, phi, clockWise) and
## (period, amplifier, phi, clockWise, useStaticZ, z). Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_clockWise = null, p_useStaticZ = null, p_z = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	phi = float(p_phi)
	clockWise = bool(p_clockWise)
	useStaticZ = false if p_useStaticZ == null else bool(p_useStaticZ)
	z = 0.0 if p_z == null else float(p_z)

func modifyVector(v, elapsedTime):
	time += elapsedTime
	return getVectorAfterTime(v, time)

func getVectorAfterTime(v, p_time):
	var theta: float = (omega * p_time) + phi
	var t: float = 2.0 * PI - theta if clockWise else theta
	var c: float = cos(t) * amplifier
	var s: float = sin(t) * amplifier
	v.y += s
	v.x += c
	if useStaticZ:
		v.z = z
	return v
