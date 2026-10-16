class_name RandomWave
extends RefCounted
## Port of particleSystem.equations.RandomWave (implements VectorEquation).

var omega: float = 0.0
var time: float = 0.0
var amplifier: float = 0.0
var phi: float = 0.0
var weight = null
var source = null

## Period in seconds.
func _init(period = null, p_amplifier = null, p_phi = null, p_weight = null, p_source = null) -> void:
	omega = (2.0 * PI) / float(period)
	amplifier = float(p_amplifier)
	phi = float(p_phi)
	weight = p_weight
	source = p_source

## NOTE: faithful to the Java original, which recurses forever (it is never
## called in the game; only getVectorAfterTime is used).
func modifyVector(v, elapsedTime):
	time += elapsedTime
	return modifyVector(v, elapsedTime)

func getVectorAfterTime(v, elapsedTime):
	var theta: float = (omega * time) + phi
	var val: float = cos(theta) * amplifier
	v.x = source.x + (val * J.random() * weight.x if weight.x != 0 else 0.0)
	v.y = source.y + (val * J.random() * weight.y if weight.y != 0 else 0.0)
	return v
