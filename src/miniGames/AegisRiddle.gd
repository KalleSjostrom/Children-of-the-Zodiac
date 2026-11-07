class_name AegisRiddle
extends RiddleGame
## Port of miniGames.AegisRiddle: shows the texts of the riddle file on
## SPLIT pages (the inscription in the Temple of Aegis).

const SPLIT = 2
var pageNr: int = 0


## Constructs a new riddle; it is set up in init(name, lab, hinders).
func _init() -> void:
	super()
	pass


func checkInput():
	if pageNr < SPLIT:
		if not isRiddleFading():
			if gameActions[CROSS].isPressed():
				pageNr += 1
				if pageNr == SPLIT:
					fadingDown = true


## Bridge (phase 4.2 step B): the page's lines are a MenuText node
## (AbstractPage.show_lines, centred as drawMultiCenteredText);
## --legacy=riddle draws them.
func drawTopLayer(g):
	super.drawTopLayer(g)
	if pageNr < SPLIT:
		g.startText(1, 0, 28)
		var half: int = texts.size() / 2
		var start: int = pageNr * half
		var end: int = start + half
		if Main.is_legacy("riddle"):
			for i in range(start, end):
				g.drawMultiCenteredText(texts[i], 250 + (i - start) * 50)
		else:
			var lines := []
			for i in range(start, end):
				lines.append(RiddleGame.multi_centered_line(g, texts[i], 250 + (i - start) * 50))
			AbstractPage.show_lines(g, lines)
		g.finishText()
