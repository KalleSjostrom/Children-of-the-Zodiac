extends Control
## "Connection to game pad lost" over the frame (phase 3 step B,
## docs/ARCHITECTURE.md section 12), on the Transition layer after the mode's
## fade, as GameCore.testDraw draws it while a game pad is lost: the title
## and two lines. The dim under it is the Fade node (Graphics.show_fade at
## 0.5); the menu after it ("Try to reconnect", "Use keyboard instead") is a
## MenuList node (since phase 4.2); GameCore and its MenuNode keep the input
## and the cursor.

@onready var _texts: Array[BaselineLabel] = [$Title, $Line, $Note]


## The title and the two lines in their colours; mat is the material of the
## legacy drawing (Graphics.canvas_material), bold the font.
func show_texts(colors: Array[Color], mat: Material, bold: bool) -> void:
	material = mat
	for i in _texts.size():
		_texts[i].color = colors[i]
		_texts[i].bold = bold
