extends Control
## A cutscene's text (phase 3 step B, docs/ARCHITECTURE.md section 12): one or
## two lines centred on the screen, on the Transition layer over the
## cutscene's own fade, as the legacy story.Text draws them. The legacy Text
## and its timeline stay in charge of the lines and their fade; each frame
## the drawing hands this node what it would have drawn (Graphics.show_ui).

## How far below the first line the second line's baseline is.
@export var line_distance := 70

@onready var _lines: Array[BaselineLabel] = [$FirstLine, $SecondLine]


## The lines with the first one's baseline at y (a second line "" is not
## drawn), in the font size font_size and color (alpha included); mat is the
## material of the legacy drawing (Graphics.canvas_material), bold the font.
func show_text(first: String, second: String, y: int, font_size: int, color: Color,
		mat: Material, bold: bool) -> void:
	material = mat
	var texts := [first, second]
	for i in _lines.size():
		var label := _lines[i]
		label.position.y = y + i * line_distance
		label.theme_type_variation = StringName("Text%d" % font_size)
		label.text = texts[i]
		label.color = color
		label.bold = bold
