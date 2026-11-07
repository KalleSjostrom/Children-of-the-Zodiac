class_name HelpText
extends RefCounted
## Port of menu.tutorial.HelpText: a help text loaded from a .help file.

var loader = null
var rows = null

func _init(name = null, x = null, y = null) -> void:
	name = name.to_lower()
	var filename: String = name + ".help"
	loader = ColorTextLoader.new(x, y)
	loader.parseFile(filename)
	rows = loader.getFirstPage()

func drawTopLayer(g):
	g.setFontSize(34)
	Graphics.setTextColor(0)
	g.setFontSize(26)
	Row.drawRows(g, rows)

## Bridge (phase 4.2 step B, the stores, docs/ARCHITECTURE.md section 14):
## drawTopLayer without the drawing: the same font sizes and text colour,
## then Row.place_rows (startText, the words' colours, finishText, the icons'
## binds). Returns place_rows' {"words", "icons"} (the Church's bless page).
func place_top_layer(g) -> Dictionary:
	g.setFontSize(34)
	Graphics.setTextColor(0)
	g.setFontSize(26)
	return Row.place_rows(g, rows)
