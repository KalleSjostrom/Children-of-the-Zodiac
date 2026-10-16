class_name Actor
extends RefCounted
## Port of villages.villageStory.Actor: a sprite controlled by a village story.
## Constructors: Actor(Sprite sprite) and Actor(String path, int images).
## move(distance, direction, duration) and
## move(distance, direction, faceDirection, duration) are merged.
## setPos(float[]) / setPos(int[]) are merged (Sprite.setPos dispatches).
## The field animate is animate_.

var actor = null
var instructions = []
var target = [0, 0, 0]
var step = [0.0, 0.0]
var speed: float = 1.0
var acc = [0.0, 0.0]
var waiting: bool = false
var inControll: bool = false
var animate_: bool = false
const X_AXIS = 3
const Y_AXIS = 0

func _init(path = null, images = null) -> void:
	if path is String:
		actor = DefaultSprite.new(path)
		path = path.replace("Extras", "")
		actor.loadImagesFromPath(Values.VillageImages + path, images)
	else:
		actor = path

func setControll(controll):
	inControll = controll
	if actor is Villager:
		var v = actor
		v.setPause(controll)

func update(elapsedTime):
	if not inControll and (actor is Villager):
		actor.updateVillager(J.round(elapsedTime * speed))
	else:
		var pos = actor.getPos()
		var preDistance: float = calcDist(pos, target)
		for i in range(2):
			step[i] += acc[i]
			pos[i] += step[i]
		var postDistance: float = calcDist(pos, target)
		if preDistance < postDistance:
			pos[0] = float(target[0])
			pos[1] = float(target[1])
			acc[0] = 0.0
			acc[1] = 0.0
			if instructions.size() > 0:
				var start = popInstruction()
				move(start[0], start[1], start[2])
			elif actor.isMoving():
				if not animate_:
					actor.standStillActor(target[2])
				else:
					actor.setMoving(false)
				animate_ = false
		actor.setPos(pos)
		actor.update(J.round(elapsedTime * speed))

func popInstruction():
	var ins = J.removeAt(instructions, 0)
	waiting = instructions.size() == 0
	return ins

func calcDist(pos, target2):
	return pow(pos[0] - target2[0], 2) + pow(pos[1] - target2[1], 2)

func stop(direction):
	actor.standStillActor(direction)
	target[2] = direction

func getSprite():
	return actor

func moveToRel(x, y, duration):
	var direction = moveToRelative(x, y)
	setStepBasedOnDistance(direction, duration)

func moveToRelative(x, y):
	var direction := J.array(2, 0)
	direction[Values.X] = Values.LEFT if x < 0 else Values.RIGHT
	direction[Values.Y] = Values.UP if y < 0 else Values.DOWN
	var faceDirection: int = direction[Values.X if absi(x) > absi(y) else Values.Y]
	actor.moveActor(faceDirection)
	var pos = actor.getPos()
	target[Values.X] = int(pos[Values.X]) + x
	target[Values.Y] = int(pos[Values.Y]) + y
	target[2] = faceDirection
	return direction

func moveToWithSpeed(x, y, speed):
	var pos = actor.getPos()
	var direction = moveToRelative(J.round(x - pos[Values.X]), J.round(y - pos[Values.Y]))
	setStepBasedOnSpeed(direction, speed)

func moveTo(x, y, duration):
	var pos = actor.getPos()
	moveToRel(J.round(x - pos[Values.X]), J.round(y - pos[Values.Y]), duration)

## Java overloads move(distance, direction, duration) and
## move(distance, direction, faceDirection, duration).
func move(distance, direction, faceDirection, duration = null):
	if duration == null:
		duration = faceDirection
		faceDirection = direction
	if float(duration) == 0:
		target[2] = faceDirection
		stop(faceDirection)
		return
	actor.moveActor(faceDirection)
	target[2] = faceDirection
	var pos = actor.getPos()
	var index: int = direction % 2
	target[index] = int(pos[index]) + (distance * Values.DIRECTIONS[direction])
	index = absi(index - 1)
	target[index] = int(pos[index])
	setStepBasedOnDistance([direction, direction], duration)

func queueMove(distance, direction, duration):
	instructions.append([distance, direction, int(duration)])

func setStepBasedOnDistance(direction, duration):
	var pos = actor.getPos()
	var d: float = float(duration) / Values.LOGIC_INTERVAL
	for i in range(2):
		step[i] = absf(target[i] - pos[i]) / d
		step[i] *= Values.DIRECTIONS[direction[i]]

func setStepBasedOnSpeed(direction, speed):
	var pos = actor.getPos()
	var x: float = absf(target[Values.X] - pos[Values.X])
	var y: float = absf(target[Values.Y] - pos[Values.Y])
	var theta: float
	if x == 0:
		theta = PI / 2
		theta *= (1 if y < 0 else -1)
	else:
		theta = atan(y / x)
	var speedComp := [0.0, 0.0]
	speedComp[Values.X] = speed * cos(theta)
	speedComp[Values.Y] = speed * sin(theta)
	for i in range(2):
		step[i] = float(speedComp[i])
		step[i] *= Values.DIRECTIONS[direction[i]]

func deaccelerateActor():
	var pos = actor.getPos()
	for i in range(2):
		var p: float = pos[i]
		var t: float = target[i]
		if p != t:
			var s: float = absf(p - t)
			acc[i] = (step[i] * step[i]) / (2 * s)
			acc[i] *= 1 if step[i] < 0 else -1

func lookTo(x, y):
	var pos = actor.getPos()
	var xdir: int = Values.LEFT if x < pos[Values.X] else Values.RIGHT
	var ydir: int = Values.UP if y < pos[Values.Y] else Values.DOWN
	var direction: int = xdir if absf(x - pos[Values.X]) > absf(y - pos[Values.Y]) else ydir
	actor.standStillActor(direction)
	target[0] = int(pos[0])
	target[1] = int(pos[1])
	target[2] = direction

func getPos():
	return actor.getPos()

func setPos(newPos):
	actor.setPos(newPos)

func isMoving():
	return actor.isMoving()

func addAnimation(name, pos):
	actor.addAnimation(name, pos)

func animate(pos):
	animate_ = true
	actor.animate(pos)

func isWaiting():
	return waiting

func getName():
	return actor.getName()

func setEmotion(show, emotion, shake):
	actor.setEmotion(show, emotion, shake)

func draw(g, bx, by):
	var pos = actor.getPos()
	var x: int = J.round(pos[Values.X] + bx)
	var y: int = J.round(pos[Values.Y] + by)
	actor.drawAtPosition(g, x, y)

func initStartLocation(pos, members):
	if pos == null:
		waiting = true
	else:
		var startPos := [0.0, 0.0]
		startPos[0] = float(pos[0])
		startPos[1] = float(pos[1])
		createStartInstructions(startPos, pos[2], members)

func createStopInstructions(pos):
	createStartInstructions(pos, 0, [])

func createStartInstructions(positions, startDir, villagers):
	var pos = actor.getPos()
	var xDif: int = J.round(positions[Values.X] - pos[Values.X])
	var yDif: int = J.round(positions[Values.Y] - pos[Values.Y])

	if villagers.size() > 0:
		var villager = villagers[0].actor.getRectangle()
		if pos[Values.Y] < villager.y:
			var player = actor.getRectangle()
			player.height = yDif
			if player.intersects(villager):
				var point1: int = villager.x - villager.width
				var point2: int = villager.x + villager.width
				var p1: int = absi(player.x - point1)
				var p2: int = absi(player.x - point2)
				var point: int = point1 if p1 < p2 else point2
				createInstruction(X_AXIS, point - player.x)
				xDif = J.round(positions[Values.X] - point)

	createInstruction(Y_AXIS, yDif)
	createInstruction(X_AXIS, xDif)

	if xDif == 0 and yDif == 0:
		actor.standStillActor(startDir)
	else:
		instructions.append([0, startDir, 0])
		actor.moveActor()
	if instructions.size() > 0:
		var start = popInstruction()
		move(start[0], start[1], start[2])
	else:
		waiting = true

func createInstruction(start, dif):
	var dir: int
	if dif < 0:
		dir = start
	elif dif > 0:
		dir = absi(start - 2)
	else:
		return
	dif = absi(dif)
	instructions.append([dif, dir, dif * 20])

func _to_string():
	return str(actor.getName())

func resetVillager():
	var v = actor
	v.reset()

func updateDialog(value):
	var v = actor
	v.updateDialog(value)

func drawEmotion(g):
	actor.drawEmotions(g)

func setDirection(dir):
	actor.setDirection(dir)

func setMoving(moving):
	actor.setMoving(moving)
