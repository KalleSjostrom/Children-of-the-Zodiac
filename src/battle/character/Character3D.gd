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


## Draws the character if it is not hidden (see setHideTimer()), else after a
## critical hit the red screen (_show_red_screen).
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
			_show_red_screen(g)


## Bridge (phase 4.4's closing, step B, docs/ARCHITECTURE.md section 15): the
## red screen (Java: loadIdentity, setImageColor(.7, 0, 0, .5), drawImage(imW,
## 0, 0)) without the drawing: the same state changes (the identity, which
## puts the row's later members at z 0 too, the colour, the white image's bind
## and the texture coordinate its quad leaves: Graphics.skip_image) and the
## quad drawImage draws (GameTexture.drawPart's corners, glVertex2i at z 0
## under the 3D projection: behind the near plane, so it never shows) as
## Graphics.place_quad gives it, shown by the PanelQuad in its batch's slot
## (Utils3D.show_quad).
func _show_red_screen(g) -> void:
	g.loadIdentity()
	g.setImageColor(0.7, 0, 0, 0.5)
	var t: GameTexture = g.skip_image(_getImW())
	if t == null:
		return
	var tc = t.getImageTexCoords()
	var w: int = t.getWidth()
	var h: int = t.getHeight()
	Utils3D.show_quad(g, [get_instance_id(), &"red"], g.place_quad(
			PackedVector3Array([Vector3(0, h, 0), Vector3(w, h, 0), Vector3(w, 0, 0), Vector3(0, 0, 0)]),
			PackedVector2Array([Vector2(tc.left(), tc.bottom()), Vector2(tc.right(), tc.bottom()),
				Vector2(tc.right(), tc.top()), Vector2(tc.left(), tc.top())])))


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


## Bridge (phase 4.4's rollout, part 2): the Java drawImage (the portrait,
## drawTex) without the drawing; its quad to the PanelQuad in its slot.
func _show_image(g) -> void:
	if texture[0] != null:
		Utils3D.show_quad(g, [get_instance_id(), &"image"],
				Utils3D.place_3d(g, texture[0].getTexture(), coordList[0]))
