class_name MapRenderer
extends Hideable
## Port of labyrinth.MapRenderer: the small rotating mini map in the corner.
##
## Port note: the static GLU/quadric become the active Graphics at call time.

static var MAP_POSITION = [-0.59, 0.365]
static var glu = null
static var quad = null
var map = null

func _init(map = null) -> void:
	super(0)
	self.map = map
	setLimit(false)
	setMovementSpeed(false)

func initDraw(g: Graphics):
	setPos(MAP_POSITION)
	setZdepth(-1.6)

## Java overloads draw(Graphics g) (empty) and
## draw(Graphics g, float alpha, int angle, int origin, int lastOrigin).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if alpha == null:
		return
	var a: int = angle
	super.translate(g)
	drawBackground(g, 0.25)

	g.setColor(1)
	g.scale(0.5)
	g.push()
	g.translate(-0.45, 0.45, 0)
	drawBackground(g, 0.1)

	g.setColor(1)
	var n: GameTexture = ImageHandler.getTexture(LabyrinthMap.directions[0])
	a += 450
	g.rotate(a, 0, 0, 1)
	Utils3D.draw3DwithHW(g, n.getTexture(), 0, 0, 0, 0.00035)
	g.pop()

	g.push()
	a += 360
	g.rotate(a, 0, 0, 1)

	map.draw2(g, alpha, origin, lastOrigin, a)

	g.pop()
	var t: GameTexture = ImageHandler.getTexture(LabyrinthMap.arrows[0])
	g.setImageColor(1, 0.85, 0, 1)
	Utils3D.draw3D(g, t.getTexture(), 0, 0, 0, 0.09)

func drawBackground(g, size):
	glu = g
	if quad == null:
		quad = g.gluNewQuadric()
	g.setTextureEnabled(false)
	g.setColor(0, 0, 0, 0.5)
	g.gluDisk(quad, 0, size, 50, 1)
	g.setTextureEnabled(true)
