class_name Puzzle
extends AbstractPuzzle
## Port of miniGames.Puzzle: the classic sliding tile puzzle (one free slot).

var marker = ""

var freex: int = 0
var freey: int = 0

var markeroffset: int = -2


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.

	freex = N - 1
	freey = N - 1

	tiles[N - 1][N - 1].setImage(null)

	marker = ImageHandler.addToCurrentLoadNow(getNNPrefix() + "single.png")


func scramblePuzzle():
	var testx: int = N - 2
	var testy: int = N - 1
	var rand := JRandom.new()
	for i in 500:
		swapTiles(testx, testy, freex, freey)
		match rand.nextInt(N):
			0:
				testx += 1
			1:
				testx -= 1
			2:
				testy += 1
			3:
				testy -= 1
		if testx < 0:
			testx = 1
		if testx == N:
			testx = N - 2
		if testy < 0:
			testy = 1
		if testy == N:
			testy = N - 2


func checkInput():
	if gameActions[UP].isPressed():
		cursory += ys.size() - 1
		cursory %= ys.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[DOWN].isPressed():
		cursory += ys.size() + 1
		cursory %= ys.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[LEFT].isPressed():
		cursorx += xs.size() - 1
		cursorx %= xs.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[RIGHT].isPressed():
		cursorx += xs.size() + 1
		cursorx %= xs.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[TRIANGLE].isPressed():
		pass
	elif gameActions[CIRCLE].isPressed():
		fadingDown = true
	elif gameActions[CROSS].isPressed():
		crossPressed()


func crossPressed():
	if absi(cursorx - freex) == 1 and cursory == freey:
		swapTiles(cursorx, cursory, freex, freey)
	elif absi(cursory - freey) == 1 and cursorx == freex:
		swapTiles(cursorx, cursory, freex, freey)
	isRiddleDone()


func swapTiles(ax, ay, bx, by):
	var t = tiles[ax][ay]
	tiles[ax][ay] = tiles[bx][by]
	tiles[bx][by] = t
	tiles[ax][ay].setCurrent(ax, ay)
	tiles[bx][by].setCurrent(bx, by)
	freex = ax
	freey = ay


func drawTopLayer(g):
	super.drawTopLayer(g)
	g.drawImage(marker, xs[cursorx] + markeroffset, ys[cursory] + markeroffset)
