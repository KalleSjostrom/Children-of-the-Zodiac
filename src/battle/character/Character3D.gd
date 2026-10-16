class_name Character3D
extends Creature3D
## Port of battle.character.Character3D: a party character in the 3D battle.
## It shows information about HP and progress.

var character = null
## Java: static final BufferedImage imW (created lazily, see _getImW()).
static var imW = null


func _init(side = null, c = null) -> void:
	super(side, c)
	setImage(c.getImage())
	character = c
	if character.get2DDeck() == null:
		var deck := GLDeck.new()
		deck.setDeck(character.getDeck(), Character.HAND_SIZE)
		var glWeapon := GLWeapon.new(character)
		deck.setWeaponDeck(glWeapon)
		deck.shuffleAndDeal()
		character.set2DDeck(deck)


static func _getImW() -> Image:
	if imW == null:
		imW = GraphicHelp.getImage(1, 1, JColor.WHITE)
	return imW


## Sets the given image as the texture drawn next to the creature.
func setImage(type, elem = null):
	super.loadTexture(type, 0)
	setSize(0, BattleValues.CREATURE_SCALE)


## Initiates the graphics of the character's deck if needed.
func initCreature(g):
	var deck = character.get2DDeck()
	if deck.getNeedUpdate():
		deck.initDraw(g)
		deck.setNeedUpdate(false)


## Draws the character if it is not hidden (see setHideTimer()).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if isVisible():
		g.push()
		if creature.hasTurn():
			g.translate(-0.03, -0.02, 0)
			g.scale(SCALE)
		super.draw(g)
		g.pop()
	else:
		if criticalHit:
			g.loadIdentity()
			g.setImageColor(0.7, 0, 0, 0.5)
			g.drawImage(_getImW(), 0, 0)


## Draws the name and life of the character on the info image.
func drawInfo(g):
	var c: Color = JColor.WHITE if character.isAlive() else JColor.RED

	GraphicHelp.drawStringWithBlackFrame(g, getName(), 5, 50, 40, c, 3, Values.BOLD)
	GraphicHelp.drawStringWithBlackFrame(g, "Elem:", 5, 100, 26, c, 3, Values.BOLD)

	var hp: float = creature.getAttribute(Creature.HP)
	var max_: float = creature.getAttribute(Creature.MAX_HP)
	if hp / max_ < 0.2:
		c = JColor.RED
	var s: String = character.getLife()
	var life: String = "Dead" if hp == 0 else s
	GraphicHelp.drawStringWithBlackFrame(g, life, 5, 139, 30, c, 3, Values.BOLD)


func drawImage(g):
	drawTex(g, 0, 0)
