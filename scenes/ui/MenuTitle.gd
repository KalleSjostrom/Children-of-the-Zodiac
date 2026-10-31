extends Control
## A menu page's title line (phase 4.2 step B, docs/ARCHITECTURE.md section
## 14): the page's (or its current list's) name at the top of the menu
## column, as the pages draw it (Graphics.drawString at MenuValues.MENU_TEXT_X,
## MENU_TITLE_Y). The stores draw their titles at the same place.

@onready var _line: BaselineLabel = $Line


## The title text in color at font_size (MenuText<size>, else Text<size>),
## in the bold font or not; mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_title(text: String, font_size: int, color: Color, bold: bool, mat: Material) -> void:
	material = mat
	_line.text = text
	_line.theme_type_variation = MenuText.role(font_size)
	_line.color = color
	_line.bold = bold
