extends Control
## "Paused" over the frame (phase 3 step B, docs/ARCHITECTURE.md section 12),
## on the Transition layer after the mode's fade, as GameCore.testDraw draws
## it while the game is paused (START). The dim under it is the Fade node
## (Graphics.show_fade at 0.5); GameCore keeps the pause.

@onready var _title: BaselineLabel = $Title


## The title in color; mat is the material of the legacy drawing
## (Graphics.canvas_material), bold the font.
func show_paused(color: Color, mat: Material, bold: bool) -> void:
	material = mat
	_title.color = color
	_title.bold = bold
