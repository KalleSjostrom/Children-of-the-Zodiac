class_name GLHand
extends Object2D
## Port of battle.GLHand: the cursor (hand) that tells which creature to
## attack in battle.

## The array of coordinates for the hand.
static var pos = null
## The index in pos where to draw the hand.
var currentPos: int = 0
var size_: int = 0
var alive = null
var showing: bool = true
var done: bool = false
var party = null
var enemies = null


## Java overloads GLHand(party, enemies) and GLHand().
func _init(p_party = null, p_enemies = null) -> void:
	super(1)
	if p_party == null:
		return
	size_ = p_party.size() + p_enemies.size()
	self.party = p_party
	self.enemies = p_enemies
	currentPos = p_party.size()
	pos = J.array2d(size_, 2, 0.0)
	alive = J.array(size_, true)
	calcCharPos(p_party.size())
	calcEnemyPos(p_party.size())


## Updates the hand positions (used when an enemy dies and the list changes).
func update(progress = null):
	size_ = party.size() + enemies.size()
	if currentPos >= size_:
		currentPos = size_ - 1
	pos = J.array2d(size_, 2, 0.0)
	calcCharPos(party.size())
	calcEnemyPos(party.size())


## Calculates the positions of the characters in the battle.
func calcCharPos(partySize):
	var p = BattleValues.getCharPosForHand(0)

	pos[0][0] = p[0]
	pos[0][1] = p[1]

	for i in range(1, partySize):
		pos[i] = Values.copyArray(pos[i - 1])
		pos[i][0] += BattleValues.DISTANCE_BETWEEN_CHARACTERS_X


## Calculates the positions of the enemies (partySize is the character party size).
func calcEnemyPos(partySize):
	if partySize < pos.size():
		pos[partySize] = Values.copyArray(BattleValues.ENEMY_ROW_POSITION)
		pos[partySize][0] -= 0.32
		pos[partySize][1] += 0.015
		for i in range(partySize + 1, size_):
			pos[i] = Values.copyArray(pos[i - 1])
			pos[i][1] += BattleValues.DISTANCE_BETWEEN_ENEMIES
	else:
		done = true


## Creates the coordinates for the hand texture.
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	createCoordList(1)
	createCoordFor(0, 0 + width, 0, X)
	createCoordFor(0, 0 + height, 0, Y)
	createCoordFor(0, 0, 0, Z)


## Loads the texture and sets the size.
func initDraw(g: Graphics):
	texture[0] = ImageHandler.getTexture(Values.MenuImages + "hand1.png")

	setSize(0, BattleValues.HAND_SCALE)
	createCoords()


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if showing and not done:
		g.loadIdentity()
		g.translate(pos[currentPos][0], pos[currentPos][1], -2)
		if not isEnemySelected():
			g.rotate(-90, 0, 0, 1)
		drawTex(g, 0, 0)


## Moves the hand to the next creature (wrapping within the selected team).
func next(i = null):
	if isEnemySelected():
		var s: int = enemies.size()
		currentPos += 1
		var temp: int = (currentPos - party.size()) % s
		currentPos = temp + party.size()
	else:
		var s: int = party.size()
		currentPos += 1
		currentPos = currentPos % s
	if not alive[currentPos]:
		next()


## Moves the hand to the previous creature (wrapping within the selected team).
func previous():
	var s: int = party.size()
	s += enemies.size() if isEnemySelected() else 0
	var low: int = party.size() if isEnemySelected() else 0
	currentPos -= 1
	if currentPos < low:
		currentPos = s - 1
	if not alive[currentPos]:
		previous()


## Gets the index of the marked creature in the list it originated from.
func getIndex():
	return currentPos - party.size() if isEnemySelected() else currentPos


## Sets the current position of the hand to the first enemy.
func reset():
	currentPos = party.size()


func isEnemySelected():
	return currentPos >= party.size()


## Gets the team which the marked creature belongs to.
func getSelTeam():
	return enemies if isEnemySelected() else party


func hide(time = null):
	showing = false


func show():
	showing = true


## Java: setPos(boolean playerParty, int index).
func setPos(x, y = null):
	var playerParty: bool = x
	var index: int = y
	currentPos = index if playerParty else party.size()
