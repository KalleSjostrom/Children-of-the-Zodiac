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
## Bridge (phase 4.4's rollout, part 2): the panels' node (show_panel_quad)
## and the one shown last with its quad and batch mark (a merge).
const PANEL_QUAD := preload("res://scenes/battle/PanelQuad.tscn")
static var _last_panel_quad := {}
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


## Bridge (phase 4.4's rollout, part 2, step B, docs/ARCHITECTURE.md section
## 15): the PanelQuad of key (an array: the panel's legacy object's instance
## id and the part) in this frame's 3D chunk, in the slot of the batch the
## quad would have been (Graphics.show_node: kept from frame to frame, freed
## in a frame it is not shown), showing quad (Graphics.place_quad's). A quad
## of the same material right after the last one shown, with nothing drawn
## in the chunk in between, would have merged into its batch (the enemy
## row's gradient after the character row's when no character is drawn): it
## joins that node instead (Graphics.batch_mark).
static func show_panel_quad(g, key: Array, quad: Dictionary) -> void:
	var mark: Array = g.batch_mark()
	if not mark.is_empty() and _last_panel_quad.get("mark") == mark \
			and _last_panel_quad.quad.mat == quad.mat:
		var merged: Dictionary = _last_panel_quad.quad.duplicate()
		merged.v = merged.v + quad.v
		merged.uv = merged.uv + quad.uv
		merged.c = merged.c + quad.c
		merged.n = merged.n + quad.n
		_last_panel_quad.node.show_quads(merged.mat, merged.v, merged.uv, merged.c, merged.n)
		_last_panel_quad.quad = merged
		return
	var node: PanelQuad = g.show_node(key, func() -> GeometryInstance3D: return PANEL_QUAD.instantiate()) as PanelQuad
	if node != null:
		node.show_quads(quad.mat, quad.v, quad.uv, quad.c, quad.n)
		_last_panel_quad = {"mark": g.batch_mark(), "node": node, "quad": quad}


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
