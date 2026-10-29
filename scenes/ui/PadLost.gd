extends Control
## "Connection to game pad lost" over the frame (phase 3 step B,
## docs/ARCHITECTURE.md section 12), on the Transition layer after the mode's
## fade, as GameCore.testDraw draws it while a game pad is lost: the title,
## two lines and the menu ("Try to reconnect", "Use keyboard instead") with
## its hand. The dim under it is the Fade node (Graphics.show_fade at 0.5);
## GameCore and its MenuNode keep the input and the cursor.

@onready var _texts: Array[BaselineLabel] = [$Title, $Line, $Note]
@onready var _menu: Control = $Menu
@onready var _hand: TextureRect = $Hand


## The title and the two lines in their colours; mat is the material of the
## legacy drawing (Graphics.canvas_material), bold the font.
func show_texts(colors: Array[Color], mat: Material, bold: bool) -> void:
	material = mat
	for i in _texts.size():
		_texts[i].color = colors[i]
		_texts[i].bold = bold
	_menu.show_labels([])
	_hand.visible = false


## The menu's choices, [text, position (the baseline's start), colour] each,
## in the font size font_size; the hand's image (null: none) at hand_at, in
## hand_tint.
func show_menu(choices: Array, font_size: int, bold: bool, hand: Texture2D, hand_at: Vector2i,
		hand_tint: Color) -> void:
	var entries := []
	for c: Array in choices:
		entries.append([c[0], c[1], StringName("Text%d" % font_size), c[2], bold,
				HORIZONTAL_ALIGNMENT_LEFT])
	_menu.show_labels(entries)
	_hand.texture = hand
	_hand.position = Vector2(hand_at)
	_hand.self_modulate = hand_tint
	_hand.visible = hand != null
