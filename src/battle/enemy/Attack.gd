class_name Attack
extends RefCounted
## Port of battle.enemy.Attack: the name of an enemy attack, sliding in at the
## bottom of the screen on top of an AttackBackground.
## Port note: the text width uses Graphics._stringWidth(name, 50) in place of
## TextManager.createRenderer(50).getBounds(name).

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
		g.drawWithShadow(name, shadowX + 3, Y_POS + 3, JColor.BLACK)
		g.drawWithShadow(name, pos, Y_POS)
