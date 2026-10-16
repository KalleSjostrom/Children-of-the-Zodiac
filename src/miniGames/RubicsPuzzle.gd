class_name RubicsPuzzle
extends AbstractPuzzle
## Port of miniGames.RubicsPuzzle: whole rows/columns of tiles are shifted
## (cross toggles between moving rows and columns).

var horizontal: bool = true

var marker = null
var markeroffset: int = -2


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.
	marker = [
		ImageHandler.addToCurrentLoadNow(getNNPrefix() + "horizontal.png"),
		ImageHandler.addToCurrentLoadNow(getNNPrefix() + "vertical.png"),
	]


func scramblePuzzle():
	var rand := JRandom.new()
	for i in 100:
		match rand.nextInt(N):
			0:
				moveLineDown(rand.nextInt(N))
			1:
				moveLineUp(rand.nextInt(N))
			2:
				moveLineRight(rand.nextInt(N))
			3:
				moveLineLeft(rand.nextInt(N))


func checkInput():
	var somethingPressed := true
	if gameActions[UP].isPressed():
		if not horizontal:
			moveLineUp(cursorx)
		else:
			cursory += ys.size() - 1
			cursory %= ys.size()
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[DOWN].isPressed():
		if not horizontal:
			moveLineDown(cursorx)
		else:
			cursory += ys.size() + 1
			cursory %= ys.size()
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[LEFT].isPressed():
		if horizontal:
			moveLineLeft(cursory)
		else:
			cursorx += xs.size() - 1
			cursorx %= xs.size()
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[RIGHT].isPressed():
		if horizontal:
			moveLineRight(cursory)
		else:
			cursorx += xs.size() + 1
			cursorx %= xs.size()
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[TRIANGLE].isPressed():
		pass
	elif gameActions[CIRCLE].isPressed():
		fadingDown = true
	elif gameActions[CROSS].isPressed():
		horizontal = not horizontal
	else:
		somethingPressed = false
	if somethingPressed:
		isRiddleDone()


func moveLineLeft(x):
	for i in N - 1:
		moveLineRight(x)


func moveLineRight(y):
	var next = tiles[0][y]
	for i in N:
		var current = next
		var x: int = (i + 1) % N
		next = tiles[x][y]
		tiles[x][y] = current
		current.setCurrent(x, y)


func moveLineUp(x):
	for i in N - 1:
		moveLineDown(x)


func moveLineDown(x):
	var next = tiles[x][0]
	for i in N:
		var current = next
		var y: int = (i + 1) % N
		next = tiles[x][y]
		tiles[x][y] = current
		current.setCurrent(x, y)


func drawTopLayer(g):
	super.drawTopLayer(g)
	if horizontal:
		g.drawImage(marker[0], xs[0] + markeroffset, ys[cursory] + markeroffset)
	else:
		g.drawImage(marker[1], xs[cursorx] + markeroffset, ys[0] + markeroffset)
