extends Control
## The info lines at the bottom of the menu column (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): the party's gold, steps and play time,
## as StartPage.drawInfo draws them (the start, equip, help, map and tutorial
## pages; the Inn). The stores draw three lines of their own in the same
## places ("Equipped", "Total", "Gold"; "Stocked", "Price", "Gold") and show
## them with this node too.

@onready var _lines: Array[BaselineLabel] = [$First, $Second, $Third]


## The three lines in colors (one per line), at font_size (MenuText<size>,
## else Text<size>), in the bold font or not; mat is the material of the
## legacy drawing (Graphics.canvas_material).
func show_info(lines: PackedStringArray, colors: Array[Color], font_size: int, bold: bool,
		mat: Material) -> void:
	material = mat
	var role := MenuText.role(font_size)
	for i in _lines.size():
		_lines[i].text = lines[i]
		_lines[i].color = colors[i]
		_lines[i].theme_type_variation = role
		_lines[i].bold = bold
