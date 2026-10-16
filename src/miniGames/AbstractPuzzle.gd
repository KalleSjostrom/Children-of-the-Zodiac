class_name AbstractPuzzle
extends RiddleGame
## Port of miniGames.AbstractPuzzle: base class of the tile puzzles. The first
## text line of the riddle file holds the settings, e.g.
## "distance=125 n=4 folder=4x4Tenjins". The tile images are
## res/MiniGames/TileGames/<folder>/<N>x<N><nr>.png.

var distance: int = 125
var N: int = 4

var tiles = null # Tile[N][N], indexed tiles[x][y]

var ys = null
var xs = null

var cursory: int = 0
var cursorx: int = 0
var folder: String = ""


func getNNPrefix():
	return Values.MiniGamesImages + "TileGames/" + folder + "/" + str(N) + "x" + str(N)


func setArray(a, start):
	a[0] = start
	for i in range(1, a.size()):
		a[i] = a[i - 1] + distance


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.
	var t: String = texts[0]
	var st := StringTokenizer.new(t)
	while st.hasMoreTokens():
		var args: Array = Parser.getArgument(st.nextToken())
		var command: String = args[0]
		var val: String = args[1]
		if command == "n":
			N = J.parseInt(val)
		elif command == "distance":
			distance = J.parseInt(val)
		elif command == "folder":
			folder = val

	tiles = J.array2d(N, N, null)
	xs = J.array(N, 0)
	ys = J.array(N, 0)

	var x: int = getImage().getX() + 24
	var y: int = getImage().getY() + 24

	setArray(xs, x)
	setArray(ys, y)

	for i in N * N:
		tiles[i % N][i / N] = Tile.new(i % N, i / N,
			ImageHandler.addToCurrentLoadNow(
				getNNPrefix() + ("0" if i < 9 else "") + str(i + 1) + ".png"))
	scramblePuzzle()


## Abstract in Java.
func scramblePuzzle():
	pass


func isRiddleDone():
	var found := false
	var x: int = 0
	while x < N and not found:
		var y: int = 0
		while y < N and not found:
			found = not tiles[x][y].isCorrect()
			y += 1
		x += 1
	if not found:
		SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET)
		InventoryButton.updateDoorStatus(hinders, 1)
		fadingDown = true
	return not found


func drawTopLayer(g):
	super.drawTopLayer(g)
	for ts in tiles:
		for t in ts:
			t.draw(g, xs, ys)
