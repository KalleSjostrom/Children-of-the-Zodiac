class_name BattleScrollBar
extends BattleProgressBar
## Port of battle.bars.ScrollBar: the scroll bar used in the deck menu.

var loaded: bool = false
var botHeight: float = 0.0


func _init() -> void:
	super(4, null)


## Initiates the drawings of the scroll bar.
func initDraw(g: Graphics):
	loadTexture(Values.BattleBarImages, "emptyBarLong.png", 0)
	loadTexture(Values.BattleBarImages, "whiteLong.png", 1)
	loadTexture(Values.BattleBarImages, "top.png", 2)
	loadTexture(Values.BattleBarImages, "bottom.png", 3)
	createCoords()


## Creates the coordinate list used by the scroll bar.
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	if saveW != null:
		super.createCoords(saveW)
		return
	createCoordList(4)

	var x: float = -0.12
	var y: float = -0.76
	var z: float = -2.0

	setSize(0, size_)

	createCoordFor(x, x + width, 0, X)
	createCoordFor(y, y + height, 0, Y)
	createCoordFor(z, z, 0, Z)

	x = -0.081
	y = 0.193
	z = -2.0

	setSize(2, size_)

	createCoordFor(x, x + width, 2, X)
	createCoordFor(y, y + height, 2, Y)
	createCoordFor(z, z, 2, Z)

	x = -0.081
	y = -0.73
	z = -2.0

	setSize(3, size_)

	createCoordFor(x, x + width, 3, X)
	createCoordFor(y, y + height, 3, Y)
	createCoordFor(z, z, 3, Z)
	botHeight = height

	x = -0.12
	y = -0.73
	z = -2.0

	setSize(1, size_)

	createCoordFor(x, x + width, 1, X)
	createCoordFor(y, y + height, 1, Y)
	createCoordFor(z, z, 1, Z)


## progress: the percentage of the deck shown (0 to 1).
func update(progress = null):
	if progress == null:
		return
	percent = float(progress)


## Java overloads: draw(Graphics g, float offset) (the scroll bar),
## draw(Graphics g) (empty, inherited) and draw(Graphics g, float alpha, int mode)
## (inherited from ProgressBar).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if alpha == null:
		return
	if angle != null:
		super.draw(g, alpha, angle)
		return
	var offset: float = float(alpha)
	if not loaded:
		initDraw(g)
		loaded = true
	drawTex(g, 0, 0)
	if percent < 1:
		g.translate(0, -offset * height, 0)
		Utils3D.draw3DPartY(g, texture[1].getTexture(), coordList[1], percent, height)

		coordList[3][1][0] = (-height * percent) + 0.194
		coordList[3][1][1] = (-(height * percent + botHeight)) + 0.194

		Utils3D.draw3D(g, texture[2].getTexture(), coordList[2])
		Utils3D.draw3D(g, texture[2].getTexture(), coordList[3])
