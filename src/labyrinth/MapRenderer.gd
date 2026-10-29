class_name MapRenderer
extends Hideable
## Port of labyrinth.MapRenderer: the small rotating mini map in the corner.
##
## Port note: the static GLU/quadric become the active Graphics at call time.

## Bridge (phase 3 step B): the show_node keys of the minimap's batches
## (PART_KEY, PART_KEY - 1 …; the battle effects' keys are instance ids).
const PART_KEY := -1000
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

## Bridge (phase 3, dev only: --minimap-node): draw(g, alpha, angle, origin,
## lastOrigin) drawn by nodes. The legacy drawing runs (the same GL state
## changes, the same geometry), its 3D primitives are kept instead of drawn
## (Graphics.begin_capture_3d), and each batch is a MinimapPart node in the
## frame's 3D chunk, in the batch's slot (Graphics.show_node). The floor's
## frames are drawn to the bit, but a battle's frames after them differ by
## 1/255 (docs/MODERNIZATION_PLAN.md 8.3), so by default the 3D bridge draws
## the minimap.
func show_map(g, alpha, angle, origin, lastOrigin):
	g.begin_capture_3d()
	draw(g, alpha, angle, origin, lastOrigin)
	var batches: Array = g.end_capture_3d()
	for i in batches.size():
		var part = g.show_node(PART_KEY - i, func() -> GeometryInstance3D: return MinimapPart.new())
		if part != null:
			var b: Dictionary = batches[i]
			part.show_batch(b.mat, b.v, b.uv, b.c, b.n)

func drawBackground(g, size):
	glu = g
	if quad == null:
		quad = g.gluNewQuadric()
	g.setTextureEnabled(false)
	g.setColor(0, 0, 0, 0.5)
	g.gluDisk(quad, 0, size, 50, 1)
	g.setTextureEnabled(true)
