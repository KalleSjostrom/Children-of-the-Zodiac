class_name HateRiddle
extends RiddleGame
## Port of miniGames.HateRiddle: the number pad riddle in the Forest of Hate.
## The player enters a four digit code (8145) on a 3x3 pad.

var hand = MenuHand.new(Values.RIGHT)
var ys = [260, 340, 420]
var xs = [435, 505, 565]
var cursory: int = 0
var cursorx: int = 0
var choosenCode: String = "____"


## Constructs a new riddle; it is set up in init(name, lab, hinders).
func _init() -> void:
	super()
	pass


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.
	hand.setVisible(true)
	hand.setXpos(xs[cursorx])
	hand.setYpos(ys[cursory])


## Checks the input for changes.
func checkInput():
	if gameActions[UP].isPressed():
		cursory += ys.size() - 1
		cursory %= ys.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[DOWN].isPressed():
		cursory += ys.size() + 1
		cursory %= ys.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[LEFT].isPressed():
		cursorx += xs.size() - 1
		cursorx %= xs.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[RIGHT].isPressed():
		cursorx += xs.size() + 1
		cursorx %= xs.size()
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	elif gameActions[TRIANGLE].isPressed():
		isRiddleDone()
	elif gameActions[CIRCLE].isPressed():
		isRiddleDone()
		fadingDown = true
	elif gameActions[CROSS].isPressed():
		if choosenCode.contains("_"):
			choosenCode = choosenCode.replace("_", "")
			choosenCode += str(cursory * 3 + cursorx + 1)
			while choosenCode.length() < 4:
				choosenCode += "_"
		if not isRiddleDone() and not choosenCode.contains("_"):
			choosenCode = "____"
			SoundPlayer.playSound(SoundMap.ERROR)

	hand.setXpos(xs[cursorx] - hand.getXOffset())
	hand.setYpos(ys[cursory] - hand.getYOffset())


func isRiddleDone():
	var done: bool = choosenCode == "8145"
	if done:
		SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET)
		InventoryButton.updateDoorStatus(hinders, 1)
		fadingDown = true
	return done


## Java: initDraw(GL2 gl) (and the inherited initDraw(Graphics)).
func initDraw(g):
	pass


## Draws the riddle on the given graphics (everything is in drawTopLayer).
func draw(g, alpha = null):
	pass


func drawTopLayer(g):
	super.drawTopLayer(g)
	g.setFontSize(36)
	Graphics.setTextColor(JColor.BLACK)
	g.startText(fade, -1)
	for j in ys.size():
		for i in xs.size():
			g.drawMultiString(str(j * 3 + i + 1), xs[i], ys[j])
	var sb: String = ""
	for c in choosenCode:
		sb += c + " "
	g.drawMultiCenteredText(sb, ys[2] + 80)
	g.finishText()
	hand.drawHand(g)
