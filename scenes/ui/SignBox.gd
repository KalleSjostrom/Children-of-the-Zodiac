extends Control
## The message box (phase 3 step B, docs/ARCHITECTURE.md section 12): a sign's
## text, a loot's message or a gift line without a speaker, on the dialog's
## first paper, as the legacy Dialog.drawMessages draws it. The legacy drawing
## hands it the text where it would have drawn it (Graphics.show_ui).

## How far down the first line moves when there is no second line (it is
## centred on the paper).
@export var single_line_shift := 25

@onready var _paper: Panel = $Paper
@onready var _first: BaselineLabel = $Paper/FirstLine
@onready var _second: BaselineLabel = $Paper/SecondLine

var _first_y := 0.0


func _ready() -> void:
	_first_y = _first.position.y


## The message: two lines in color (single: only the first, moved down to the
## middle); tint is the colour the paper is drawn in, mat the material of the
## legacy drawing (Graphics.canvas_material), bold the font.
func show_message(first: String, second: String, single: bool, color: Color, tint: Color,
		mat: Material, bold: bool) -> void:
	material = mat
	_paper.self_modulate = tint
	_first.position.y = _first_y + (single_line_shift if single else 0)
	for label: BaselineLabel in [_first, _second]:
		label.color = color
		label.bold = bold
	_first.text = first
	_second.text = second
