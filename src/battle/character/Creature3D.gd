class_name Creature3D
extends Object2D
## Port of battle.character.Creature3D: a creature presented in 3D in battle.
## It draws information about the creature (life, progress, element, boosts)
## and maybe an image of the creature.
##
## Port notes: the info texture is an Image drawn with ImageGraphics
## (Java Graphics2D on a BufferedImage) and uploaded as a GameTexture.
## createCoords() with an int argument is Object2D.createCoords(int).

const SCALE = 1.1
const NOT_IN_TURN_ALPHA = 0.75
const WIDTH = 100 * 3
const HEIGHT = 55 * 3
var creature = null
var progressBar = null
var tex = null
var data = null
var textImage = null
var textWidth: float = 0.0
var textHeight: float = 0.0
var side: float = 0.0
var alpha: float = 0.7
var mustUpdateText: bool = true
var criticalHit: bool = false
var support: bool = false
const DISTANCE_BETWEEN_ICONS = 0.1


## Creates a new creature on the given side (BattleProgressBar.LEFT/RIGHT).
func _init(side = null, c = null) -> void:
	super(1)
	self.side = float(side)
	progressBar = BattleProgressBar.new(self.side)
	creature = c


## Creates the coordinates for the creature.
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	if saveW != null:
		super.createCoords(saveW)
		return
	createCoordList(4)
	var x: float = 0.0
	createCoordFor(0, width, 0, X)
	createCoordFor(0, height, 0, Y)
	createCoordFor(0, 0, 0, Z)

	x += (0.22 if side == BattleProgressBar.LEFT else -0.75)
	var y: float = (0.37 if side == BattleProgressBar.LEFT else 0.11)
	createCoordFor(x, x + textWidth, 1, X)
	createCoordFor(y, y + textHeight, 1, Y)
	createCoordFor(0, 0, 1, Z)

	x = -0.12
	y = -0.09
	createCoordFor(x, x + 0.1, 2, X)
	createCoordFor(y, y + 0.1, 2, Y)
	createCoordFor(0, 0, 2, Z)

	x = 0.52 if side == BattleProgressBar.LEFT else -0.14
	y = 0.140 if side == BattleProgressBar.LEFT else 0.035
	createCoordFor(x, x + 0.1, 3, X)
	createCoordFor(y, y + 0.1, 3, Y)
	createCoordFor(0, 0, 3, Z)


## Initiates the drawing in 3D space.
func initDraw(g: Graphics):
	createTexture(g)
	createCoords()
	progressBar.initDraw(g)
	initCreature(g)


func setSupport(support):
	self.support = support


## Draws the creature image, the progress bar, the info texture, the
## element and the boosts.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if creature.isActive() and creature.isAlive():
		self.alpha = 0.7
	else:
		if not support:
			g.setColor(NOT_IN_TURN_ALPHA)
			self.alpha = 0.2
		else:
			self.alpha = 0.7
	drawImage(g)
	progressBar.update(creature.getProgress())
	progressBar.draw(g, self.alpha, creature.getSpeedMode())

	if mustUpdateText:
		updateTexture(g)
		mustUpdateText = false
	g.push()
	g.translate(0.13, -0.15, 0)
	g.scale(0.45)
	Utils3D.draw3D(g, tex, coordList[1])
	g.pop()
	drawElements(g)
	drawBoosts(g)


## Hides the creature for hideTime ms; criticalHit draws the red screen.
func setHideTimer(hideTime, criticalHit):
	hideFor(hideTime)
	self.criticalHit = criticalHit


## Draws the element icon of the creature. (As in the original, the element
## texture is bound but the tex coords of the info texture are used.)
func drawElements(g):
	var element: int = creature.getElement()
	if element != AbstractCard.NO_ELEMENT:
		var t = ImageHandler.getTexture(
				Values.MenuImages + "Elements/" + str(element) + ".png").getTexture()
		t.bind(g.getGL())
		g.push()
		g.scale(0.65)
		g.beginQuads()
		Utils3D.draw3D(g, tex.getImageTexCoords(), coordList[3])
		g.end()
		g.pop()


## Draws the boost icons under the creature.
func drawBoosts(g):
	g.push()
	if creature is Enemy:
		g.scale(0.9)
		g.translate(-0.22, -0.05, 0)
	var boosts: Array = creature.getBoosts()
	for i in boosts.size():
		if boosts[i] != 0:
			var nr: int = (i + 1) * (1 if boosts[i] == 1 else 11)
			var t = ImageHandler.getTexture(Values.Cards + str(nr) + ".png").getTexture()
			g.translate(DISTANCE_BETWEEN_ICONS, 0, 0)
			Utils3D.draw3D(g, t, coordList[2])
	g.pop()


func getName():
	return creature.getName()


func getCreature():
	return creature


## Creates the texture where the information is drawn.
func createTexture(g):
	textImage = GraphicHelp.createImage(WIDTH, HEIGHT)
	textWidth = textImage.get_width() / 300.0
	textHeight = textImage.get_height() / 300.0

	data = textImage
	tex = GameTexture.fromImage("Creature3D_" + str(get_instance_id()), textImage)
	tex.updateImage(g.getGL(), textImage)


## Clears the information texture and redraws it with drawInfo().
func updateTexture(g):
	textImage.fill(Color(0, 0, 0, 0))
	var g2d := ImageGraphics.new(textImage)
	drawInfo(g2d)
	g2d.dispose()
	tex.updateImage(g.getGL(), textImage)


func getAlpha():
	return 1.0 if creature.isActive() else NOT_IN_TURN_ALPHA


func isAlive():
	return creature.isAlive()


## Abstract: initiates creature specific graphics.
func initCreature(g):
	pass


## Abstract: draws the information about the creature (g is ImageGraphics).
func drawInfo(g):
	pass


## Abstract: draws the creature image.
func drawImage(g):
	pass
