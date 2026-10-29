extends Control
## A cutscene's scrolling text (phase 3 step B, docs/ARCHITECTURE.md section
## 12): the credits of "Ending - Part 3", lines that move up the screen, on
## the Transition layer, as the legacy story.ScrollableTexts draws them. The
## legacy ScrollableTexts stays in charge of the lines and the scroll; each
## frame its drawing hands this node the lines it would have drawn (also those
## still below the screen, as it draws them) (Graphics.show_ui).

@onready var _lines: Control = $Lines


## The lines, each [text, position (the baseline's start, centre or end),
## font size, colour, bold, alignment (HORIZONTAL_ALIGNMENT_*)], in the
## legacy drawing's order; mat is its material (Graphics.canvas_material).
func show_lines(lines: Array, mat: Material) -> void:
	material = mat
	var entries := []
	for l: Array in lines:
		entries.append([l[0], l[1], StringName("Text%d" % l[2]), l[3], l[4], l[5]])
	_lines.show_labels(entries)
