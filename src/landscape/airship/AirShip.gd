class_name AirShip
extends LandPlayer
## Port of landscape.airship.AirShip: the airship flying over the world map.

var velocity: float = 0.0
const MAX_VELOCITY = 0.2
const VELOCITY_INCREASE_STEP = 0.02
const VELOCITY_DECREASE_STEP = -0.03
var distance: float = 0.0
var increase: float = 0.0
var dirs = J.array(4, false)


func init(g = null):
	loadImages(Values.LandscapeImages, "Airship")


func go(dir):
	increase = VELOCITY_INCREASE_STEP
	dirs[dir] = true
	if not moving or direction != dir:
		direction = dir
		move(dir)


func goforward(dir):
	var dist: float = Values.DIRECTIONS[dir] * Values.LOGIC_INTERVAL * velocity
	pos[dir % 2] += dist
	distance += absf(dist)
	if distance >= 30:
		Load.getPartyItems().takeStep()
		distance = 0.0


## Java: update(float elapsedTime).
func update(f, player = null, reset = null):
	if (increase > 0 and velocity < MAX_VELOCITY) or (increase < 0 and velocity > 0):
		velocity += increase
	if velocity >= MAX_VELOCITY:
		velocity = MAX_VELOCITY
		increase = 0.0
	elif velocity <= 0:
		velocity = 0.0
		increase = 0.0
	for i in range(4):
		if dirs[i]:
			goforward(i)
		dirs[i] = false
	super.update(f, player, reset)
	checkLeftUp()
	checkRightDown()


func checkLeftUp():
	for i in range(2):
		if pos[i] < 0:
			pos[i] += (Values.ORIGINAL_RESOLUTION[i] + 55)


func checkRightDown():
	for i in range(2):
		if pos[i] > Values.ORIGINAL_RESOLUTION[i] + 55:
			pos[i] -= (Values.ORIGINAL_RESOLUTION[i] + 55)


func getDirection():
	return direction


## Java: standStill() slows the airship down; standStill(int dir[, ...]) is
## the Sprite version.
func standStill(dir = null, anim = null, ia = null):
	if dir == null:
		increase = VELOCITY_DECREASE_STEP
		dirs[direction] = true
	else:
		super.standStill(dir, anim, ia)
