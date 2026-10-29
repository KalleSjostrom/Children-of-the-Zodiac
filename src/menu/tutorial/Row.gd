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

## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): draw without the
## drawing: the same text colour and alpha changes. Returns the words drawMultiString
## would draw, [text, position (the baseline's start), colour] each (a
## coloured word's shadow before it); a word's place is the previous one's
## plus its JOGL ink width (Graphics.getStringWidth) and 7.
func place_words(g) -> Array:
	var words := []
	var offset: int = 0
	for i in range(row.size()):
		var s: String = row[i]
		if colorMap != null:
			var c = colorMap.get(i)
			if c != null:
				g.setTextColorAndApply(0, 1)
				words.append([s, Vector2i(x + offset + 1, y + 1), Graphics.text_color(g.text_alpha())])
				g.setTextColorAndApply(c)
			else:
				g.setTextColorAndApply(0, 1)
		else:
			g.setTextColorAndApply(0, 1)
		words.append([s, Vector2i(x + offset, y), Graphics.text_color(g.text_alpha())])
		offset += Graphics.getStringWidth(s) + 7
	return words

## Bridge (phase 3 step B): drawRows without the drawing (place_words, then
## the icons: Icon.place_icon). Returns {"words": [...], "icons": [[texture,
## rect, tint] ...]}.
static func place_rows(g, rows) -> Dictionary:
	var words := []
	var icons := []
	g.startText()
	for r in rows:
		words.append_array(r.place_words(g))
	g.finishText()
	for r in rows:
		if r.icon != null:
			var placed: Array = r.icon.place_icon(g, r.x, r.y)
			if not placed.is_empty():
				icons.append(placed)
	return {"words": words, "icons": icons}
