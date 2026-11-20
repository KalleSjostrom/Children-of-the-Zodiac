class_name Attack
extends RefCounted
## Port of battle.enemy.Attack: the name of an enemy attack, sliding in at the
## bottom of the screen on top of an AttackBackground.
## Port note: the text width uses Graphics._stringWidth(name, 50) in place of
## TextManager.createRenderer(50).getBounds(name).

## Bridge (phase 4.4's rollout, part 4): the node of a line over its shadow.
const SHADOW_TEXT := "res://scenes/ui/ShadowText.tscn"
const Y_POS = 735
const SPEED = 60
var pos: int = 0
var startPos: int = 0
var visible: bool = false
var dest: int = 0
var name = ""
var ab = null


func _init() -> void:
	ab = AttackBackground.new()
	setAttackName("Death Claw Super")


func setAttackName(name):
	self.name = name
	var w: float = Graphics._stringWidth(str(name), 50)
	var width: int = J.round(w / 2)
	startPos = -width
	pos = startPos
	dest = 512 - width


func update():
	ab.update()


func initDraw(g):
	ab.initDraw(g)


func show():
	visible = true
	ab.show()


func hide():
	pos = startPos
	visible = false
	ab.hide()


## Draws the background and, while it shows, the name sliding in (pos steps
## by SPEED per draw). Bridge (phase 4.4's rollout, part 4, step B,
## docs/ARCHITECTURE.md section 15): each drawWithShadow is a ShadowText node
## on the UI layer in the frame's 2D order (_show_with_shadow: the same state
## changes); --legacy=battle_attack_name keeps the legacy text.
func draw(g):
	ab.draw(g)
	if visible:
		g.loadIdentity()
		g.setFontSize(46)
		if pos + SPEED < dest:
			pos = pos + SPEED
		else:
			pos = dest
		var shadowX: int = dest + absi(pos - dest)
		if not Main.is_legacy("battle_attack_name"):
			_show_with_shadow(g, shadowX + 3, Y_POS + 3, JColor.BLACK)
			_show_with_shadow(g, pos, Y_POS)
			return
		g.drawWithShadow(name, shadowX + 3, Y_POS + 3, JColor.BLACK)
		g.drawWithShadow(name, pos, Y_POS)


## Bridge (phase 4.4's rollout, part 4): drawWithShadow(name, x, y, c) without
## the drawing (Graphics.place_with_shadow: the text colours and drawString's
## setColor(color) after each line), shown by the frame's next ShadowText on
## the UI layer at the size and in the font set now, in the material of the
## 2D state here (the alpha test BattleEnemy.draw sets: GREATER .1). Nothing
## is shown for an empty name (the legacy drawing draws nothing then).
func _show_with_shadow(g, x: int, y: int, c = null) -> void:
	var mat: Material = g.canvas_material()
	var colours: Array[Color] = g.place_with_shadow(c)
	var text := str(name)
	if text == "":
		return
	var view = g.show_ui(SHADOW_TEXT, Graphics.UI_LAYER)
	if view != null:
		view.show_text(text, Vector2i(x, y), MenuText.role(Graphics.getCurrentFontSize()), colours[0], colours[1],
				Graphics.font_bold(), mat)
