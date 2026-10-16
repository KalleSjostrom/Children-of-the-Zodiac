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
