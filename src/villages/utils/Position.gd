class_name Position
extends RefCounted
## Port of villages.utils.Position: the position and direction of a party
## member (or the player). Used to make the party members walk in a line
## behind each other.

var x: float = 0.0
var y: float = 0.0
var direction: int = 0


## Java: Position(float x, float y, int dir).
func _init(p_x = null, p_y = null, dir = null) -> void:
	if p_x != null:
		x = float(p_x)
	if p_y != null:
		y = float(p_y)
	if dir != null:
		direction = int(dir)


## Gets the position as a float array ([y, x], see Values.X / Values.Y).
func getPosAsFloatArray():
	var p := [y, x]
	return p


func getDirection():
	return direction


func getY():
	return y


func getX():
	return x
