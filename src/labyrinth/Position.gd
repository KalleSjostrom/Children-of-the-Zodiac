class_name LabyrinthPosition
extends RefCounted
## Port of labyrinth.Position: stores a player position. It has both a
## location and also an angle or direction.
##
## Java constructors: Position(int x, int z) (a grid position, converted to a
## location) and Position(float x, float z, double a) (a location + angle).

const X = 0
const Z = 1

var location = null
var position = null
var angle: float = 0.0


func _init(x = null, z = null, a = null) -> void:
	if a == null:
		# Position(int x, int z)
		var ix: int = int(x)
		var iz: int = int(z)
		position = [ix, iz]
		ix = ix * LabyrinthNode.DISTANCE + LabyrinthNode.DISTANCE / 2
		iz = iz * LabyrinthNode.DISTANCE - LabyrinthNode.DISTANCE / 2
		location = [float(ix), float(iz)]
	else:
		# Position(float x, float z, double a)
		location = [float(x), float(z)]
		angle = float(a)


## Gets the x coordinate for this position.
func getX() -> float:
	return location[X]


## Gets the z coordinate for this position.
func getZ() -> float:
	return location[Z]


func getLocation():
	return location


func getSimpleX() -> int:
	return position[X]


func getSimpleY() -> int:
	return position[Z]


## Gets the angle for this position.
func getAngle() -> float:
	return angle


## Gets the x or z coordinate depending on the given axis (X or Z).
func getValue(axis) -> float:
	return getX() if axis == X else getZ()


## Sets the x or z coordinate depending on the given axis (X or Z).
func setValue(axis, value) -> void:
	location[axis] = float(value)


## Sets the angle of the position.
func setAngle(a) -> void:
	angle = float(a)
