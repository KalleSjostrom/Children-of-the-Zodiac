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


## Loads the texture and draws it once (a stray quad at the modelview of the
## moment, as the original). Bridge (phase 4.4's rollout, part 4): a PanelQuad
## in its batch's slot (Object2D.show_tex); --legacy=battle_enemy_quads keeps
## the legacy quad.
func initDraw(g: Graphics):
	var tex: String = Values.BattleImages + "attackBack.png"
	loadTexture(tex, 0)
	setSize(0, BattleValues.CARD_SCALE)
	createCoords(1)
	if not Main.is_legacy("battle_enemy_quads"):
		show_tex(g, [get_instance_id(), &"init"], 0, 0, true)
		return
	drawTex(g, 0, 0, true)


## Java: createCoords(int size).
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	var size: int = int(saveW) if saveW != null else 1
	createCoordList(size)
	createCoordFor(0, width, 0, X)
	createCoordFor(-height / 2, height / 2, 0, Y)
	createCoordFor(0, 0, 0, Z)


## Draws the background at its slide (every frame: off the screen while it is
## hidden). Bridge (phase 4.4's rollout, part 4, step B, docs/ARCHITECTURE.md
## section 15): a PanelQuad in its batch's slot (Object2D.show_tex);
## --legacy=battle_enemy_quads keeps the legacy quad.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	super.translate(g)
	if not Main.is_legacy("battle_enemy_quads"):
		show_tex(g, [get_instance_id(), &"back"], 0, 0, true)
		return
	drawTex(g, 0, 0, true)
