class_name Sign
extends RefCounted
## Port of villages.utils.Sign: a sign in a village (or a message such as
## "The door is locked.") that is shown as a dialog when read.

const DEFAULT_WIDTH = 20
var text = ["", ""]
var pos = null
var c: int = 0
var width: int = 0
var content = null
var directions = null


## Java overloads:
##   Sign(int x, int y, int w, ArrayList<Integer> dirs)
##   Sign(String one, String two, Object content)
##   Sign()
func _init(x = null, y = null, w = null, dirs = null) -> void:
	if x is int:
		pos = Values.createNormalPoint(x, y)
		directions = dirs
		width = DEFAULT_WIDTH if w == -1 else int(w)
	elif x == null and y == null and w == null and dirs == null:
		pass # Empty constructor.
	else:
		text[0] = x
		text[1] = "" if y == null else y
		content = w


## Adds a line of text. Returns true if both lines have been added.
func addText(t):
	text[c] = t
	c += 1
	return c == 2


## Checks if the given position is close enough to read the sign when
## looking in the given direction.
func isInRange(p, dir):
	var inRange := false
	if canBeSeen(dir):
		var dist := int(J.round(Vector2(p[1], p[0]).distance_to(Vector2(pos[1], pos[0]))))
		inRange = dist < width
	return inRange


func canBeSeen(dir):
	var found := false
	var i := 0
	while i < directions.size() and not found:
		found = directions[i] == dir
		i += 1
	return found


func getText():
	return text


func getContent():
	return content


func _to_string():
	return "Sign at pos " + str(pos) + " with text \n\t" + str(text[0]) + "\n\t" + str(text[1])
