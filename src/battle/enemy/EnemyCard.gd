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


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	super.translate(g)
	drawTex(g, currentList, 0, true)


func setImage(type, elem = null):
	match int(type):
		Slot.ATTACK:
			currentList = Slot.ATTACK
		Slot.MAGIC:
			currentList = Slot.MAGIC + int(elem)
		Slot.SUPPORT:
			currentList = Slot.SUPPORT + Card.NR_ELEMENT_MODES - 1
