class_name EnemyCard
extends Hideable
## Port of battle.enemy.EnemyCard: the card shown when an enemy attacks
## (attack, magic of an element, or support).


func _init() -> void:
	super(7)
	setLimit(false)
	setMovementSpeed(false)
	instantHide()


func initDraw(g: Graphics):
	setPos(BattleValues.ENEMY_POSITION)
	var att: String = Values.Cards + "monsterattack.png"
	var mneutral: String = Values.Cards + "monsterneutral.png"
	var mfire: String = Values.Cards + "monsterfire.png"
	var mice: String = Values.Cards + "monsterice.png"
	var mwind: String = Values.Cards + "monsterwind.png"
	var mearth: String = Values.Cards + "monsterearth.png"
	var sup: String = Values.Cards + "Cure.png"
	loadTexture(att, 0)
	loadTexture(mneutral, 1)
	loadTexture(mfire, 2)
	loadTexture(mice, 3)
	loadTexture(mwind, 4)
	loadTexture(mearth, 5)
	loadTexture(sup, 6)

	setSize(0, BattleValues.CARD_SCALE * 1.5)

	createCoords(1)
	# Three stray quads at the modelview of the moment, as the original.
	# Bridge (phase 4.4's rollout, part 4): PanelQuads in their batches' slots
	# (Object2D.show_tex); --legacy=battle_enemy_quads keeps the legacy quads.
	if not Main.is_legacy("battle_enemy_quads"):
		for i in 3:
			show_tex(g, [get_instance_id(), &"init", i], i, 0, true)
		return
	drawTex(g, 0, 0, true)
	drawTex(g, 1, 0, true)
	drawTex(g, 2, 0, true)


## Java: createCoords(int size).
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	var size: int = int(saveW) if saveW != null else 1
	createCoordList(size)
	createCoordFor(0, width, 0, X)
	createCoordFor(-height / 2, height / 2, 0, Y)
	createCoordFor(0, 0, 0, Z)


## Draws the card of the enemy's attack at its slide (every frame: off the
## screen while it is hidden). Bridge (phase 4.4's rollout, part 4, step B,
## docs/ARCHITECTURE.md section 15): a PanelQuad in its batch's slot
## (Object2D.show_tex); --legacy=battle_enemy_quads keeps the legacy quad.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	super.translate(g)
	if not Main.is_legacy("battle_enemy_quads"):
		show_tex(g, [get_instance_id(), &"card"], currentList, 0, true)
		return
	drawTex(g, currentList, 0, true)


func setImage(type, elem = null):
	match int(type):
		Slot.ATTACK:
			currentList = Slot.ATTACK
		Slot.MAGIC:
			currentList = Slot.MAGIC + int(elem)
		Slot.SUPPORT:
			currentList = Slot.SUPPORT + Card.NR_ELEMENT_MODES - 1
