class_name BattleParticle
extends RefCounted
## Port of battleBacks.BattleParticle: an (abstract) particle of a battle
## background particle system (BattleSystem).

var pos = null
var var_ = null
var color = null
static var rand = JRandom.new()
var originX: float = 0.0
var originZ: float = 0.0
var size = null
const WIDTH = 0
const HEIGHT = 1
const s = 2
static var WORLD_SIZE = [8.0 * s, -4.0 * s, 4.0 * s, 7.0]


func _init() -> void:
	# Java field initializers (run before the constructor body).
	pos = Vector3f.new()
	var_ = Vector3f.new()
	color = getColor()
	size = getSize()
	resurrect()
	pos.x = (rand.nextFloat() * WORLD_SIZE[0]) + WORLD_SIZE[1]
	originX = pos.x
	pos.y = getInitialHeight()
	pos.z = -((rand.nextFloat() * WORLD_SIZE[2]) + WORLD_SIZE[3])
	originZ = pos.z


func update(force):
	pos.addLocal(force.add(var_))
	if shouldResurrect():
		resurrect()
		return true
	return false


func resurrect():
	pos.set_(originX, rand.nextFloat() * 2 + 2.0, originZ)
	var_.set_(
			(rand.nextFloat() - 0.5) / 500.0,
			-rand.nextFloat() / 300.0,
			(rand.nextFloat() - 0.5) / 500.0)


func drawParticle(g, dir, fs, changed, front):
	g.setColor(1, 1, 1, color[3])
	var height: float = size[HEIGHT]
	var width: float = size[WIDTH]
	g.drawCenteredCurrent2D(pos, height, width)


## Abstract.
func getSize():
	return null


## Abstract.
func getColor():
	return null


## Abstract.
func shouldResurrect():
	return false


## Abstract.
func getInitialHeight():
	return 0.0
