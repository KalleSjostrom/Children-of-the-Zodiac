class_name Row
extends RefCounted
## Port of menu.tutorial.Row: a row of words, optionally colored per word
## (colorMap: word index -> Vector3f) and with an icon.

var row: Array = []
var colorMap = null
var icon = null
var x: int = 0
var y: int = 0

## Java overloads: Row(r, x, y) and Row(r, x, y, colorMap, icon).
func _init(r = null, x = null, y = null, colorMap = null, icon = null) -> void:
	row = []
	var rs: Array = J.split(r, " ")
	for s in rs:
		row.append(s + " ")
	self.x = x
	self.y = y
	self.colorMap = colorMap
	self.icon = icon

func draw(g):
	var offset: int = 0
	for i in range(row.size()):
		var s: String = row[i]
		if colorMap != null:
			var c = colorMap.get(i)
			if c != null:
				g.setTextColorAndApply(0, 1)
				g.drawMultiString(s, x + offset + 1, y + 1)
				g.setTextColorAndApply(c)
			else:
				g.setTextColorAndApply(0, 1)
		else:
			g.setTextColorAndApply(0, 1)
		g.drawMultiString(s, x + offset, y)
		offset += Graphics.getStringWidth(s) + 7

func drawIcon(g):
	if icon != null:
		icon.draw(g, x, y)

static func drawRows(g, rows):
	g.startText()
	for r in rows:
		r.draw(g)
	g.finishText()
	for r in rows:
		r.drawIcon(g)
