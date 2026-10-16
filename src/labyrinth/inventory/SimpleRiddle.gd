class_name SimpleRiddle
extends Inventory
## Port of labyrinth.inventory.SimpleRiddle: a text (inscription) on a wall
## that shows its dialogs when activated.
##
## dialogs is an Array of [speaker, line1, line2] arrays.

var dialogs = []
var current: int = 0
var first: bool = true


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, t = null) -> void:
	super(n, dir, nrOfTexs, image, status)
	if status == 1:
		currentTex = Object2D.INVISIBLE
		current = J.INT_MAX
	else:
		current = 0
		currentTex = 0
		while t.hasMoreTokens():
			var dial: Array = J.array(3, null)
			var s: Array = Parser.getArgument(t.nextToken())
			dial[0] = s[0]
			s = Parser.getText(t, s[1])
			dial[1] = s[0]
			dial[2] = s[1] if s.size() > 1 else ""
			dialogs.append(dial)


func setSettings():
	scale = BattleValues.CARD_SCALE
	zOff = 1.99
	scale2 = 2


func activate(labyrinth):
	if current < dialogs.size():
		var d: Array = dialogs[current]
		labyrinth.drawDialog(first, "", d[1], d[2], false)
		current += 1
	else:
		current = 0


func getMapImage():
	return LabyrinthMap.riddle[0]


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
