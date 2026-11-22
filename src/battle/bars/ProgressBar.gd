class_name BattleProgressBar
extends Object2D
## Port of battle.bars.ProgressBar: the bar displaying the progress (idle
## time) of a creature in battle.

const LEFT = 0.01
const RIGHT = -0.415
var percent: float = 1.0
var size_: float = 1 / 800.0
var color = null
const LOW = 0.3137
const HIGH = 0.9529
static var BLUE = [LOW, LOW, HIGH]
static var GREEN = [LOW, HIGH, LOW]
static var RED = [HIGH, LOW, LOW]
var side: float = 0.0


## Java overloads:
##   ProgressBar(float side)          -> new progress bar on the given side.
##   ProgressBar(int size, Object o)  -> bar with neither side nor color.
## Dispatch: a float first argument is the side; an int is the texture count.
func _init(size = null, o = null) -> void:
	super(size if size is int else 3)
	if not (size is int):
		side = float(size) if size != null else 0.0
		color = BLUE


## Creates the coordinates for the progress bar. (Java: createCoords();
## a single int argument goes to Object2D.createCoords(int).)
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	if saveW != null:
		super.createCoords(saveW)
		return
	createCoordList(1)
	var x: float = side + 0.215
	var y: float = -0.05 if side == RIGHT else 0.0
	var z: float = 0.0
	createCoordFor(x, x + width, 0, X)
	createCoordFor(y, y + height - height / 4, 0, Y)
	createCoordFor(z, z, 0, Z)


## Initiates the drawings of the progress bar.
func initDraw(g: Graphics):
	loadTexture(Values.BattleBarImages, "emptyBar.png", 0)
	loadTexture(Values.BattleBarImages, "white.png", 1)
	loadTexture(Values.BattleBarImages, "overlay.png", 2)
	setSize(0, size_)
	createCoords()


## Bridge (phase 4.4's rollout, part 2, step B, docs/ARCHITECTURE.md section
## 15): the Java draw(Graphics g, float alpha, int mode) (mode: BattleValues.HASTE,
## SLOW or anything else for default; removed: closing phase 4.4, plan 9.4)
## without the drawing: the same state changes (the
## binds, the colours, the last texture coordinates) and the bar's three
## quads (the empty bar, the fill and the overlay to the percent), each to
## the PanelQuad of key [owner, part] in its batch's slot.
func show_bar(g, alpha: float, mode: int, owner: int) -> void:
	if texture[0] != null:
		Utils3D.show_quad(g, [owner, &"bar"],
				Utils3D.place_3d(g, texture[0].getTexture(), coordList[0]))
	match mode:
		BattleValues.HASTE:
			g.setColor(GREEN[0], GREEN[1], GREEN[2], alpha)
		BattleValues.SLOW:
			g.setColor(RED[0], RED[1], RED[2], alpha)
		_:
			g.setColor(color[0], color[1], color[2], alpha)
	Utils3D.show_quad(g, [owner, &"bar_fill"],
			Utils3D.place_3d_part(g, texture[1].getTexture(), coordList[0], percent, width))
	g.setColor(1, 1, 1, alpha)
	Utils3D.show_quad(g, [owner, &"bar_overlay"],
			Utils3D.place_3d_part(g, texture[2].getTexture(), coordList[0], percent, width))


## Updates the progress bar with the given progress (0 to 100).
func update(progress = null):
	if progress == null:
		return
	percent = float(progress) / 100
