class_name WeatherParticle
extends RefCounted
## Port of weather.WeatherParticle (abstract): one rain drop / snow flake of
## a WeatherSystem, drawn as a camera facing quad in the labyrinth.
##
## Port note: the Java field var is var_ (keyword).

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


## Draws the particle (one quad, inside beginQuads/end of the system) if it is
## within the view of the player. dir is the player angle (-180..180), fs the
## player location [x, z]. Returns true if the particle is close to the player
## (it is then drawn again in front of the labyrinth walls).
func drawParticle(g, dir, fs, changed, front):
	var s: float
	var sx: float
	var sz: float
	var d: int = dir
	if changed or resurrected:
		sx = pos[0] - fs[0]
		sz = pos[2] - fs[1]
		vars[SX] = sx
		vars[SZ] = sz
		var a: Array = angles[d + 180]
		s = sx * a[0] + sz * a[1]
		vars[S] = s
		resurrected = false
	else:
		sx = vars[SX]
		sz = vars[SZ]
		s = vars[S]
	# s is like the distance from the camera to the far clipping plane or the
	# projection of the snow flake on the line-of-sight. 4 is one square.
	var farClip: float = 7.5 if front else 20.0
	var nearClip: float = 3.0 if front else 7.5
	var inside: bool = s > 3 and s < 7
	if s > nearClip and s < farClip:
		# Distance from the eye to the snowflake.
		var distSquared: float = sx * sx + sz * sz
		var sSquared: float = s * s
		if (3.7 * distSquared) < 5 * sSquared:
			var gl = g.getGL()
			gl.glColor4f(1, 1, 1, color[3])
			var height: float = size[HEIGHT]
			var width: float = size[WIDTH]
			var x1: float = pos[0] - width / 2.0
			var y1: float = pos[1] - height / 2.0
			var y2: float = y1 + height
			var z1: float = pos[2] - width / 2.0
			gl.glTexCoord2i(0, 0)
			gl.glVertex3f(x1, y1, z1)
			if (d > 45 and d < 225) or d < -135:
				gl.glTexCoord2i(0, 1)
				gl.glVertex3f(x1, y2, z1)
				if (d > -135 and d < -45) or (d > 45 and d < 135):
					var x2: float = x1 + width
					gl.glTexCoord2i(1, 1)
					gl.glVertex3f(x2, y2, z1)
					gl.glTexCoord2i(1, 0)
					gl.glVertex3f(x2, y1, z1)
				else:
					var z2: float = z1 + width
					gl.glTexCoord2i(1, 1)
					gl.glVertex3f(x1, y2, z2)
					gl.glTexCoord2i(1, 0)
					gl.glVertex3f(x1, y1, z2)
			else:
				gl.glTexCoord2i(1, 0)
				if (d > -135 and d < -45) or (d > 45 and d < 135):
					var x2: float = x1 + width
					gl.glVertex3f(x2, y1, z1)
					gl.glTexCoord2i(1, 1)
					gl.glVertex3f(x2, y2, z1)
				else:
					var z2: float = z1 + width
					gl.glVertex3f(x1, y1, z2)
					gl.glTexCoord2i(1, 1)
					gl.glVertex3f(x1, y2, z2)
				gl.glTexCoord2i(0, 1)
				gl.glVertex3f(x1, y2, z1)
	return inside


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
