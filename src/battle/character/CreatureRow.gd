class_name CreatureRow
extends Hideable
## Port of battle.character.CreatureRow: a row of creatures presented in 3D.
## It draws some number of Creature3D and can hide (Hideable).
##
## Port note: Java's abstract float[] getPos() (no argument) clashes with
## Hideable.getPos(int axis); it is getRowPos() here. getPos(axis) keeps the
## Hideable behavior.

const BACK_ALPHA_TOP = 0.8
const BACK_ALPHA_BOTTOM = 0.3
var creatures3D: Array = []
var boss: bool = false


func _init(nrOfTextures = null) -> void:
	super(int(nrOfTextures) if nrOfTextures != null else 0)
	creatures3D = []


## Creates 3D wrappers for all creatures that getCreatureList() returns.
func init(boss):
	self.boss = boss
	var characters: Array = getCreatureList()
	setPos(getRowPos())
	for i in characters.size():
		var c = characters[i]
		var creature = null
		if c is Character:
			creature = Character3D.new(getSide(), c)
		else:
			creature = Enemy3D.new(getSide(), c)
		creatures3D.append(creature)


func initDraw(g: Graphics):
	for i in creatures3D.size():
		creatures3D[i].initDraw(g)


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	translate(g)
	drawBack(g)
	for i in creatures3D.size():
		creatures3D[i].draw(g)
		translateCreature(g)
		g.setColor(1)


func updateTexture(g):
	for i in creatures3D.size():
		creatures3D[i].updateTexture(g)


## Removes every 3D creature that is not alive.
func check3DCreatures():
	var i: int = 0
	while i < creatures3D.size():
		if not creatures3D[i].isAlive():
			J.removeAt(creatures3D, i)
			i -= 1
		i += 1


func get_(i):
	return creatures3D[i]


func size():
	return creatures3D.size()


## Abstract.
func drawBack(g):
	pass


## Abstract: the list of creatures to display.
func getCreatureList():
	return []


## Abstract: BattleProgressBar.LEFT or RIGHT.
func getSide():
	return 0.0


## Hideable.getPos(int axis).
func getPos(p_axis: int):
	return pos[p_axis]


## Java: abstract float[] getPos() - the position of the row.
func getRowPos():
	return [0.0, 0.0]


## Abstract: translates between the drawing of two creatures.
func translateCreature(g):
	pass
