class_name Player
extends RefCounted
## Port of villages.utils.Player: the players in the village. All the party
## members are managed from this class (animation update and movement).

const SIZE = 50
const DISTANCE_BETWEEN_MEMBERS = 10
const VELOCITY = 0.2
## Speed factor while the sprint button (circle) is held.
const SPRINT = 1.5
## Step factor for each axis of a diagonal move, so that it is as fast as a
## straight one. Java used Math.sin(45) (radians, 0.85), which made diagonal
## moves about 20% faster than straight ones.
const DIAGONAL = 0.70710678
var posArray = []
var partyMembers = []
var direction: int = 0
var currentPartyMember: int = 0
var pos = null
var distance: float = 0.0
var moving: bool = false
var sprinting: bool = false

func _init(sPos = null, dir = null) -> void:
	fillPartyMembers(sPos, dir)
	standStill()
	for i in range(SIZE):
		posArray.append(Position.new(sPos[Values.X], sPos[Values.Y], dir))
	posArray.clear()
	for i in range(SIZE + 2):
		posArray.append(Position.new(sPos[Values.X], sPos[Values.Y], dir))


func fillPartyMembers(sPos, dir):
	var characters := []
	var loadChars = Load.getCharacters()
	for i in range(loadChars.size()):
		var c = loadChars[i]
		if c.isAlive():
			characters.append(c)
	var x: int = Values.X
	var y: int = Values.Y
	for i in range(characters.size()):
		var pm := PartyMember.new(characters[i].getName())
		pm.setCurrentPos(Position.new(sPos[x], sPos[y], dir))
		partyMembers.append(pm)
	pos = sPos


## Checks if the player has collided with the given villager.
func checkCollision(v, direction):
	var x: int = Values.X
	var y: int = Values.Y
	var villagerPos = v.getPos()
	var yy: float = villagerPos[y]
	# Java: int division (STANDARD_WIDTH - v.getWidth()) / 2.
	var xx: float = villagerPos[x] - int((Sprite.STANDARD_WIDTH - v.getWidth()) / 2)
	if pos[y] > villagerPos[y]:
		yy = villagerPos[y] - (Sprite.STANDARD_HEIGHT - v.getHeight())
	var dist: int = int(Vector2(xx, yy).distance_to(Vector2(pos[x], pos[y])))

	if dist < 30:
		var newDist: int
		var check: int = J.round(pos[direction % 2] + Values.DIRECTIONS[direction] * Values.LOGIC_INTERVAL)
		if direction % 2 == x:
			newDist = int(Vector2(check, pos[y]).distance_to(Vector2(xx, yy)))
		else:
			newDist = int(Vector2(pos[x], check).distance_to(Vector2(xx, yy)))
		return newDist < dist
	return false


func update(elapsedTime):
	if sprinting:
		elapsedTime *= SPRINT
	for i in range(partyMembers.size()):
		partyMembers[i].update(Instruction.modifyTimeStatic(elapsedTime, Instruction.FASTEST))
		partyMembers[i].updatePos(getNextPos(i))


func getNextPos(member):
	return posArray[SIZE - (member * DISTANCE_BETWEEN_MEMBERS)]


## Moves the player in the given direction. speed scales the step (the
## DIAGONAL and SPRINT factors).
func go(dir, speed, oh):
	move(dir)
	if canGo(dir, speed, oh):
		var dist: float = Values.DIRECTIONS[dir] * Values.LOGIC_INTERVAL * VELOCITY * speed
		pos[dir % 2] += dist
		distance += abs(dist)
		if distance >= 30:
			Load.getPartyItems().takeStep()
			distance = 0.0


## True if a step in the given direction does not run into an obstacle.
func canGo(dir, speed, oh):
	var dist: float = Values.DIRECTIONS[dir] * Values.LOGIC_INTERVAL * VELOCITY * speed
	var x: float = pos[Values.X]
	var y: float = pos[Values.Y]
	if dir == Values.UP or dir == Values.DOWN:
		y += dist * 1.5
	else:
		x += dist * 2.5
	return not oh.hasCollided(x, y, dir)


func createPos(x, y, dir):
	return Position.new(x, y, dir)


## Adds all the party members positions to the given Dictionary
## (Java HashMap<String, float[]>).
func addPartyMembersPosition(pos):
	for i in range(partyMembers.size()):
		var pm = partyMembers[i]
		pos[pm.getName()] = pm.getPosAsFloatArray()


func move(dir):
	moving = true
	direction = dir
	for i in range(partyMembers.size()):
		var pm = partyMembers[i]
		pm.move()


func standStill():
	moving = false
	for i in range(partyMembers.size()):
		var pm = partyMembers[i]
		pm.standStill()


func isMoving():
	return moving


func getHeight():
	return partyMembers[0].getHeight()


func getWidth():
	return partyMembers[0].getWidth()


func getDirection():
	return direction


func getPos():
	return pos


func getName():
	return partyMembers[currentPartyMember].getName()


## Sets every position in the posArray to the current position, so that all
## the party members are put in exactly the same position.
func setDirectionForAll(dir):
	var pm = partyMembers[currentPartyMember]
	posArray.clear()
	for i in range(SIZE + 1):
		var p = pm.getPosition()
		posArray.append(Position.new(p.getX(), p.getY(), dir))
	move(dir)


## Updates the list of party members (if members were resurrected or died).
func setPartyMembers():
	var characters := []
	var loadChars = Load.getCharacters()
	for i in range(loadChars.size()):
		var c = loadChars[i]
		if c.isAlive():
			characters.append(c)
	if characters.size() != partyMembers.size():
		partyMembers.clear()
		for i in range(characters.size()):
			var pm := PartyMember.new(characters[i].getName())
			pm.setCurrentPos(posArray[SIZE - 1])
			partyMembers.append(pm)
		standStill()


func setAllToPos():
	for i in range(partyMembers.size()):
		partyMembers[i].updatePos(getNextPos(i))


func getPartyMembers():
	return partyMembers


## Adds the current direction and position of the player to the array of
## positions (used to move the others behind the current party member).
func setPartyMembersPositions():
	J.removeAt(posArray, 0)
	posArray.insert(SIZE, createPos(int(pos[1]), int(pos[0]), direction))


## Sets the position of the party members. The array of positions is
## cleared and filled with the given position.
func setPos(p):
	pos = p
	posArray.clear()
	direction = int(p[2] if (p.size() > 2 and p[2] != -1) else 0)
	for i in range(SIZE + 2):
		posArray.append(Position.new(p[Values.X], p[Values.Y], direction))


func getVelocity():
	return VELOCITY
