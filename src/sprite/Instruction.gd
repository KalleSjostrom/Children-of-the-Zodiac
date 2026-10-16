class_name Instruction
extends RefCounted
## Port of sprite.Instruction.
## Constructors: Instruction(int dir) (dialog instruction) and
## Instruction(String dir, bool standStill, int dist, int speed).
## The static modifyTime(float, int) is modifyTimeStatic.

const SLOWEST = 0
const SLOW = 1
const FAST = 2
const FASTEST = 3
static var SPEED = [.03, .05, .07, .1, .12]
static var TIME_MODIFICATOR = [.4, .6, .8, 1.0, 1.2, 1.4]
var tempDist: float = 0.0
var speed: float = .05
var distance: int = 0
var inDir: int = 0
var inExtraDir: int = 0
var speedIndex: int = 0
var moving: bool = false
var dialog: bool = false

func _init(dir = null, standStill = null, dist = null, speed = null) -> void:
	if standStill == null:
		inDir = int(dir)
		dialog = true
		moving = false
		return
	var d: String = str(dir)
	if d.length() > 1:
		inDir = J.parseInt(J.substring(d, 0, 1))
		inExtraDir = J.parseInt(J.substring(d, 1))
	else:
		inDir = J.parseInt(d)
		inExtraDir = -1
	moving = not standStill
	distance = int(dist)
	speedIndex = absi(int(speed))
	self.speed = (-1 if speed < 0 else 1) * SPEED[speedIndex]
	reset()

func modifyTime(elapsedTime):
	return modifyTimeStatic(elapsedTime, speedIndex)

static func modifyTimeStatic(elapsedTime, speed):
	return J.round(TIME_MODIFICATOR[speed] * float(elapsedTime))

func reset():
	tempDist = distance

func getDirection():
	return inDir

func getExtraDirection():
	return inExtraDir

func getSpeed():
	return speed

func isMoving():
	return moving

func isDialog():
	return dialog

func decrementDistance():
	tempDist -= absf(speed) * Values.LOGIC_INTERVAL

func getDistanceLeft():
	return tempDist

func getDistance():
	return distance

func resetDistance():
	tempDist = 0
