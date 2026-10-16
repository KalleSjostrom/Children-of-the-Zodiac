class_name ObstacleHandler
extends RefCounted
## Port of villages.utils.ObstacleHandler: keeps the obstacles of a village
## and the lines where the background should start/stop scrolling.

const TOP_LEFT = 0
const BOTTOM_RIGHT = 1
const WIDTH_HEIGHT = 2
var boundingLines = J.array2d(2, 3, 0)
var obstacles = []


## Java: ObstacleHandler(int[] backRes).
func _init(backRes = null) -> void:
	if backRes == null:
		return
	var res: Array = Values.ORIGINAL_RESOLUTION
	for i in 2:
		boundingLines[i][TOP_LEFT] = int(res[i]) / 2
		boundingLines[i][BOTTOM_RIGHT] = int(backRes[i]) - int(res[i]) / 2
		boundingLines[i][WIDTH_HEIGHT] = \
				boundingLines[i][BOTTOM_RIGHT] - boundingLines[i][TOP_LEFT]


## Adds an obstacle. The coordinates are adjusted after the size of the
## player (Java int compound assignments truncate towards zero).
func addObstacle(topLeft, bottomRight, playerHeight, playerWidth):
	topLeft[Values.Y] = int(topLeft[Values.Y] - playerHeight)
	bottomRight[Values.Y] = int(bottomRight[Values.Y] - 2.8 * playerHeight / 4.0)
	topLeft[Values.X] = int(topLeft[Values.X] - 3 * playerWidth / 4.0)
	bottomRight[Values.X] = int(bottomRight[Values.X] - 0.9 * playerWidth / 4.0)
	obstacles.append(Obstacle.new(topLeft, bottomRight))


func isInMiddle(pos, index):
	return pos > boundingLines[index][TOP_LEFT] and \
			pos < boundingLines[index][BOTTOM_RIGHT]


func getBackPos(pos, index):
	return int(boundingLines[index][TOP_LEFT] - pos)


func hasCollided(x, y, direction):
	var found := false
	var i := 0
	while i < obstacles.size() and not found:
		var o: Obstacle = obstacles[i]
		if o.checkCollision(x, y, direction):
			found = true
		i += 1
	return found
