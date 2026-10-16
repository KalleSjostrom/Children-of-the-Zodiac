class_name Horizontal
extends RefCounted
## Port of labyrinth.Horizontal: stores the location of a node in the
## labyrinth. A node is one step, and the location is used to draw either the
## floor or the ceiling (carpet floors with straight, hook, T-cross, cross and
## end textures).

const STRAIGHT = 0
const HOOK = 1
const TCROSS = 2
const CROSS = 3
const END = 4

var coord = null
var direction: int = 0
var rotation: int = 0


## Creates a new storage object and set the location to the given values.
func _init(x = null, z = null) -> void:
	coord = [float(x), float(z)]


## Draws a square at the stored location at the given height (with the last
## bound texture) if the given direction matches the set direction. The
## normal is not set here.
func draw(g, height, width, p_direction) -> void:
	var x: float = coord[0] - 2
	var z: float = coord[1] + 2
	var h: float = height
	var w: float = width
	var gl = g.getGL()
	if self.direction == p_direction:
		if rotation == Values.UP:
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, h, z)
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + w, h, z)
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + w, h, z - w)
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, h, z - w)
		elif rotation == Values.RIGHT:
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, h, z)
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x + w, h, z)
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + w, h, z - w)
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, h, z - w)
		elif rotation == Values.DOWN:
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, h, z)
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x + w, h, z)
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x + w, h, z - w)
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, h, z - w)
		elif rotation == Values.LEFT:
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, h, z)
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + w, h, z)
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x + w, h, z - w)
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, h, z - w)


## Sets the straight texture (sum of the neighbors directions: 2 or 4).
func setStraight(sum, offset) -> void:
	direction = STRAIGHT + int(offset)
	rotation = int(sum) / 4


## Sets the hook texture (sum of the neighbors directions: 1, 3, 5 or 7).
func setHook(sum, offset) -> void:
	direction = HOOK + int(offset)
	rotation = int(sum) / 2


## Sets the T-Cross texture.
func setTCross(sum, offset) -> void:
	direction = TCROSS + int(offset)
	var s: int = int(sum)
	s += 4 if s == 3 else 0
	rotation = s - 4


## Sets the Cross texture which goes in all directions (rotation UP).
func setCross(offset) -> void:
	direction = CROSS + int(offset)
	rotation = Values.UP


## Sets the End texture which marks a dead end.
func setEnd(sum, offset) -> void:
	direction = END + int(offset)
	rotation = int(sum)


## Gets the direction of the horizontal texture.
func getDirection() -> int:
	return direction


## Gets the rotation of the horizontal texture (Values.UP, RIGHT, DOWN, LEFT).
func getRotation() -> int:
	return rotation
