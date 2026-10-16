class_name LabyrinthPlayer
extends RefCounted
## Port of labyrinth.LabyrinthPlayer: manages the movement in the labyrinth.
## It has methods for turning and moving to a given position. It also updates
## the view so that the screen shows where the player is looking (first
## person view).
##
## Port note: Java's get() is get_().

const LEFT_TURN = -1
const RIGHT_TURN = 1
const TURN_SPEED = 0.002
const MOVE_SPEED = 0.002

var pos = null
var position = null
var camera = null
var moving: bool = false
var turning: bool = false
var turnProgress: float = 0.0
var moveProgress: float = 0.0
var srcAngle: float = 0.0
var destAngle: float = 0.0
var angle: float = 0.0
var turnDir: int = 0
var dir: int = 0
var from: float = 0.0
var to: float = 0.0
var node = null
var labyrinth = null
var limit: float = 24.5


## Creates a new labyrinth player which manages the position of the player
## and the camera view. p_pos is the starting LabyrinthPosition.
func _init(p_pos = null) -> void:
	pos = [0.0, 0.0, 0.0]
	position = p_pos
	turnProgress = 0
	camera = Camera.new()
	camera.updatePosition(position)


## Initiates the movement to the given node. The player must then be updated
## with update() to move all the way.
func moveTo(n, lab) -> void:
	var p = n.getPos()
	labyrinth = lab
	node = n
	moving = true
	moveProgress = 0.0
	var fromX: float = position.getX()
	var fromZ: float = position.getZ()
	var toX: float = p.getX()
	var toZ: float = p.getZ()
	var xDif: float = absf(fromX - toX)
	if xDif > 1:
		from = fromX
		to = toX
		dir = LabyrinthPosition.X
	else:
		from = fromZ
		to = toZ
		dir = LabyrinthPosition.Z


## Initiates the turning sequence to the given angle (degrees) in the
## direction turnDir (LEFT_TURN or RIGHT_TURN).
func turnYTo(p_angle, p_turnDir) -> void:
	turning = true
	turnProgress = 0
	srcAngle = position.getAngle()
	angle = p_angle
	destAngle = angle
	turnDir = p_turnDir

	if srcAngle < 0 and J.round(destAngle) == 180:
		destAngle *= -1
	elif destAngle < 0 and J.round(srcAngle) == 180:
		srcAngle *= -1


static func slerp(a, b, t) -> float:
	var tf: float = t
	tf = 3 * tf * tf - 2 * tf * tf * tf
	return a + (b - a) * tf


## Updates the player on its way to the position given in moveTo().
func move(elapsedTime) -> void:
	moveProgress += MOVE_SPEED * elapsedTime
	if moveProgress < 1.0:
		var p: float = slerp(from, to, moveProgress)
		position.setValue(dir, p)
		camera.updatePosition(position)
	else:
		from = to
		position.setValue(dir, to)
		camera.updatePosition(position)
		moving = false
		node.visit()
		node.arrive(labyrinth)


## Updates the player on its way to the angle given in turnYTo().
func turn(elapsedTime) -> void:
	turnProgress += TURN_SPEED * elapsedTime
	if turnProgress < 1.0:
		var a: float = slerp(srcAngle, destAngle, turnProgress)
		position.setAngle(a)
		camera.updatePosition(position)
	else:
		position.setAngle(angle)
		camera.updatePosition(position)
		turning = false


## Java: get().
func get_() -> float:
	return absf(from - to) / LabyrinthNode.DISTANCE


## Checks if the player is currently moving (or turning).
func isMoving() -> bool:
	return moving or turning


func isMovingForward() -> bool:
	return moving


## Checks if the player is turning.
func isTurning() -> bool:
	return turning


## Updates the player (elapsedTime in milliseconds).
func update(elapsedTime) -> void:
	if turning:
		turn(elapsedTime)
	else:
		move(elapsedTime)


## Turns the view of the given graphics to the players view.
func lookAt(g) -> void:
	camera.lookAt(g)


## Gets the direction (angle) that the player is looking in.
func getDirection() -> int:
	return int(position.getAngle())


func getLocation():
	return position.getLocation()
