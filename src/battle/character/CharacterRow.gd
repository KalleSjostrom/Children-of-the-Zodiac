class_name CharacterRow
extends CreatureRow
## Port of battle.character.CharacterRow: the party characters in a row
## (hidden on the y axis).
## Port note: Java's getPos() (float[]) is getRowPos() (see CreatureRow).

const NO_TARGET = -1
const ON_ALL = -2
const RANDOM = -3
var target: int = NO_TARGET
var characters = Load.getCharactersAsCreatures()
var supportMode: bool = false


func _init() -> void:
	super(1)
	setAxis(Y)
	setLimit(true)
	setMovementSpeed(true)
	instantHide()


func getCreatureList():
	return characters


func getSide():
	return BattleProgressBar.LEFT


func getPos(p_axis: int):
	return super(p_axis)


func getRowPos():
	return BattleValues.CHARACTER_POSITION


func translateCreature(g):
	g.translate(BattleValues.DISTANCE_BETWEEN_CHARACTERS_X, 0, 0)


## Sets the index of the character the enemy is hitting.
func setTarget(newTarget, supportMode = null):
	target = newTarget
	self.supportMode = bool(supportMode) if supportMode != null else false


## Draws the characters; the targeted one(s) are moved up into view.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.loadIdentity()
	g.translate(0, getYtrans(), -2)
	if not boss:
		drawBack(g)
	g.setColor(1)
	translate(g)
	if target == ON_ALL:
		g.translate(0, -trans[Y], 0)
	for i in creatures3D.size():
		if i == target:
			g.translate(0, -trans[Y], 0)
		creatures3D[i].setSupport(supportMode and i == target)
		creatures3D[i].draw(g)
		if i == target:
			g.translate(0, trans[Y], 0)
		translateCreature(g)
		g.setColor(1, 1, 1)
	if target == ON_ALL:
		g.translate(0, trans[Y], 0)


## Shows the row and, when it has stopped moving, targets all characters.
func testShowCharacters():
	show()
	Scheduler.waitUntil(func(): return not shouldTranslate_, func(): target = ON_ALL)


func testHideCharacters():
	target = -1
	hide()


func drawBack(g):
	var x: float = 1.08
	g.drawGradient(
			Vector3f.ZERO, BACK_ALPHA_TOP, BACK_ALPHA_BOTTOM,
			x, -x, -0.07, 0.3, false, true)


func get_(i):
	return creatures3D[i]
