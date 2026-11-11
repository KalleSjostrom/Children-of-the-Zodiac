class_name ResultScreen
extends ResultScreenBase
## Port of battle.resultScreen.ResultScreen: the result screen in battle
## displaying the result of a normal attack.

static var X_POS = [200, 330, 460, 590, 720]
static var Y_POS = [240, 275, 310, 345, 380]
var cards = []
var team = []
var attack = null


## Sets the team (list of creatures) containing the targeted creature.
## Enemies are copied.
func init(selTeam):
	team.clear()
	for i in range(selTeam.size()):
		var c = selTeam[i]
		if c is Enemy:
			c = c.copy()
		team.append(c)


## Sets the list of hit elements that the result should be based upon.
func setHitElements(list):
	cards.clear()
	for i in range(team.size()):
		team[i].resetTempValues()
	for i in range(list.size()):
		cards.append(list[i].getCard())
	calcResult(list)


## Calculates the result of one round of battle.
func calcResult(hitElements):
	attack = J.array2d(team.size(), 3, 0)
	for i in range(hitElements.size()):
		var h = hitElements[i]
		var att: int = h.getAttackDamage(0)
		var index: int = h.getTest()
		if h.onAll():
			for j in range(team.size()):
				if not h.isMiss(j):
					attack[j][h.getType()] += h.getAttackDamage(j)
		elif not h.isMiss(index):
			attack[index][h.getType()] += 0 if att == -2 else att


## Draws the result screen on the given graphics.
func drawResult(g):
	if not Main.is_legacy("battle_screens"):
		_show_result(g)
		return
	drawBackground(g)

	var x: Array = X_POS
	var y: Array = Y_POS

	g.setFontSize(26)
	g.drawWithShadow("Result", x[0], y[0])
	g.drawWithShadow("Attack", x[0], y[1])
	g.drawWithShadow("Magic", x[0], y[2])
	g.drawWithShadow("Support", x[0], y[3])
	g.drawWithShadow("Total", x[0], y[4])

	for i in range(team.size()):
		var c = team[i]
		g.drawWithShadow(c.getName(), x[i + 1], y[0])
		var color: Color
		for j in range(3):
			color = JColor.red if j < 2 else JColor.green
			g.drawValueWithShadow(attack[i][j], x[1 + i], y[j + 1], color)
		var total: int = attack[i][0] + attack[i][1] - attack[i][2]
		color = JColor.red if total > 0 else JColor.green
		g.drawValueWithShadow(absi(total), x[i + 1], y[4], color)
	for i in range(cards.size()):
		var c = cards[i]
		if c != null:
			c.drawCard(g, 175 + (i * 80), 385)


## Bridge (phase 4.4 step B, docs/ARCHITECTURE.md section 15): drawResult
## without the drawing (the state changes in the same order: the
## background's, the font size 26, each line's text colours and
## setColor(color), the cards' binds), and its nodes in the frame's order: the
## background (show_background), a MenuText with every line over its shadow,
## a CardView per played card (AbstractCard.place_at at drawCard's 0.7).
func _show_result(g) -> void:
	show_background(g)

	var x: Array = X_POS
	var y: Array = Y_POS

	g.setFontSize(26)
	var lines := []
	lines += shadow_lines(g, "Result", x[0], y[0])
	lines += shadow_lines(g, "Attack", x[0], y[1])
	lines += shadow_lines(g, "Magic", x[0], y[2])
	lines += shadow_lines(g, "Support", x[0], y[3])
	lines += shadow_lines(g, "Total", x[0], y[4])

	for i in range(team.size()):
		var c = team[i]
		lines += shadow_lines(g, c.getName(), x[i + 1], y[0])
		var color: Color
		for j in range(3):
			color = JColor.red if j < 2 else JColor.green
			lines += value_lines(g, attack[i][j], x[1 + i], y[j + 1], color)
		var total: int = attack[i][0] + attack[i][1] - attack[i][2]
		color = JColor.red if total > 0 else JColor.green
		lines += value_lines(g, absi(total), x[i + 1], y[4], color)
	AbstractPage.show_lines(g, lines)
	for i in range(cards.size()):
		var c = cards[i]
		if c != null:
			var images: Array = c.place_at(g, 175 + (i * 80), 385, 0.7)
			var view = g.show_ui(CARD_VIEW, Graphics.UI_LAYER)
			if view != null:
				view.show_card(images, [], g.canvas_material())
