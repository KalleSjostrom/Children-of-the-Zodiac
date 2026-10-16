class_name Obstacle
extends RefCounted
## Port of villages.utils.Obstacle: a rectangular obstacle in a village.

var topLeft = null
var bottomRight = null


## Java: Obstacle(int[] tl, int[] br).
func _init(tl = null, br = null) -> void:
	topLeft = tl
	bottomRight = br


## Checks if the given position is inside this obstacle.
func checkCollision(x, y, dir):
	return y >= topLeft[Values.Y] and y <= bottomRight[Values.Y] and \
			x >= topLeft[Values.X] and x <= bottomRight[Values.X]
