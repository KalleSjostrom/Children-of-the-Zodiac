class_name AttackBackground
extends Hideable
## Port of battle.enemy.AttackBackground: the background behind the name of
## an enemy attack. It slides up from the bottom of the screen.


func _init() -> void:
	super(1)
	setAxis(Y_AXIS)
	setLimit(-0.4, 0, true)
	setMovementSpeed(false)
	setPos(-0.6, -0.73)
	instantHide()


func initDraw(g: Graphics):
	var tex: String = Values.BattleImages + "attackBack.png"
	loadTexture(tex, 0)
	setSize(0, BattleValues.CARD_SCALE)
	createCoords(1)
	drawTex(g, 0, 0, true)


## Java: createCoords(int size).
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	var size: int = int(saveW) if saveW != null else 1
	createCoordList(size)
	createCoordFor(0, width, 0, X)
	createCoordFor(-height / 2, height / 2, 0, Y)
	createCoordFor(0, 0, 0, Z)


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	super.translate(g)
	drawTex(g, 0, 0, true)
