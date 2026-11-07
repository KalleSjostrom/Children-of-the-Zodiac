class_name GriveraRiddle
extends RiddleGame
## Port of miniGames.GriveraRiddle: shows the texts of the riddle file as
## pages ("text pagebreak" ends a page, "text empty" is an empty line and
## "text distance=N" sets the line distance of the page).

var pages = []
var pageNr: int = 0


## Constructs a new riddle; it is set up in init(name, lab, hinders).
func _init() -> void:
	super()
	pass


func checkInput():
	if pageNr < pages.size():
		if not isRiddleFading():
			if gameActions[CROSS].isPressed():
				pageNr += 1
				if pageNr == pages.size():
					fadingDown = true


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.
	var p := Page.new()
	for t in texts:
		if t == "pagebreak":
			pages.append(p)
			p = Page.new()
		elif t == "empty":
			p.text.append("")
		elif String(t).begins_with("distance"):
			p.distance = J.parseInt(String(t).replace("distance=", ""))
		else:
			p.text.append(t)


## Bridge (phase 4.2 step B): the page's lines are a MenuText node
## (AbstractPage.show_lines, centred as drawMultiCenteredText, at the riddle's
## fade).
func drawTopLayer(g):
	super.drawTopLayer(g)
	if pageNr < pages.size():
		g.startText(fade, 0, 28)
		var p: Page = pages[pageNr]
		var lines := []
		for i in p.text.size():
			lines.append(RiddleGame.multi_centered_line(g, p.text[i], 250 + i * p.distance))
		AbstractPage.show_lines(g, lines)
		g.finishText()


class Page extends RefCounted:
	var distance: int = 60
	var text = []
