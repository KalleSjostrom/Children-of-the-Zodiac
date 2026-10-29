extends Control
## The mission display of a labyrinth floor (phase 3 step B,
## docs/ARCHITECTURE.md section 12): the line at the top right ("Bombs
## Disarmed: 1/3", "Time: 2:30", "Mission done!"), as the legacy
## labyrinth.mission classes draw it. The legacy Mission stays in charge of
## the status, the timer and the slide in and out (it slides out while a
## dialog shows); each frame its drawing hands this node the line where it
## would have drawn it (Graphics.show_ui).

@onready var _line: BaselineLabel = $Line


## The line text with its baseline starting at x (the slide moves it), in
## color; mat is the material of the legacy drawing (Graphics.canvas_material),
## bold the font.
func show_line(text: String, x: int, color: Color, mat: Material, bold: bool) -> void:
	material = mat
	_line.position.x = x
	_line.text = text
	_line.color = color
	_line.bold = bold
