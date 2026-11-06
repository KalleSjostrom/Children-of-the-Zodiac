class_name WeatherParticle
extends RefCounted
## Port of weather.WeatherParticle (abstract): one rain drop / snow flake of
## a WeatherSystem, drawn as a camera facing quad in the labyrinth.
##
## Port note: the Java field var is var_ (keyword).
##
## drawParticle is removed with the legacy weather drawing (plan 7.9): the
## GPU particles (WeatherParticles3D) run these laws and draw.

var pos: Array = [0.0, 0.0, 0.0]
var var_: Array = [0.0, 0.0, 0.0]
var color = null
static var rand := JRandom.new()
var vars: Array = [0.0, 0.0, 0.0]
var originX: float = 0.0
var originZ: float = 0.0
static var angles = null
var size = null
var resurrected: bool = false
const WIDTH = 0
const HEIGHT = 1
const S = 0
const SX = 1
const SZ = 2


static func _static_init() -> void:
	angles = J.array2d(361, 2, 0.0)
	for i in range(0, 361):
		var theta: float = deg_to_rad(i - 180)
		angles[i][0] = cos(theta)
		angles[i][1] = sin(theta)


func _init() -> void:
	color = getColor()
	size = getSize()
	resurrect()
	var wSize: Array = getWorldSize()
	originX = (rand.nextFloat() * wSize[0]) + wSize[1]
	pos[0] = originX
	pos[1] = getInitialHeight()
	originZ = -((rand.nextFloat() * wSize[2]) + wSize[3])
	pos[2] = originZ


func getWorldSize():
	# return [11 * 4, 2 * 4, 13 * 4, 0]
	return [13 * 4, 0, 13 * 4, 0]


func update(force):
	pos[0] += force[0] + var_[0]
	pos[1] += force[1] + var_[1]
	pos[2] += force[2] + var_[2]
	if shouldResurrect():
		resurrect()
		return true
	return false


func resurrect():
	pos[0] = originX
	pos[1] = rand.nextFloat() * 2 + 2.0 # from 2 to 4
	pos[2] = originZ

	var_[0] = (rand.nextFloat() - 0.5) / 500.0
	var_[1] = -rand.nextFloat() / 300.0
	var_[2] = (rand.nextFloat() - 0.5) / 500.0
	resurrected = true


## (abstract)
func getSize():
	return null


## (abstract)
func getColor():
	return null


## (abstract)
func shouldResurrect():
	return false


## (abstract)
func getInitialHeight():
	return 0.0
