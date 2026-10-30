extends Control
## A menu list (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the
## choices of a legacy MenuNode and its hand, as MenuNode.drawAllChildren
## draws them: each choice a line of text at its baseline in the colour of its
## state (enabled or disabled), then the hand pointing at the current choice.
## The legacy MenuNode stays in charge of the choices, the cursor and the
## key repeat; each frame its twin (MenuNode.show_all_children) hands this
## node what it would have drawn (Graphics.show_ui), on the title, the game
## pad lost overlay and, later, the stores and the menu pages.
##
## The choices take the theme role of their font size (MenuChoice<size>;
## Text<size> for a size without one): the legacy list is drawn at whatever
## size its mode set.

@onready var _choices: Control = $Choices
@onready var _hand: TextureRect = $Hand


## The choices, [text, position (the baseline's start), colour] each, in
## drawing order, at font_size in the bold font or not; the hand's image
## (null: none) at hand_at in hand_tint (a dimmed hand's alpha is .3). mat is
## the material of the legacy drawing (Graphics.canvas_material).
func show_menu(choices: Array, font_size: int, bold: bool, hand: Texture2D, hand_at: Vector2i,
		hand_tint: Color, mat: Material) -> void:
	material = mat
	var role := StringName("MenuChoice%d" % font_size)
	if not has_theme_font_size(&"font_size", role):
		role = StringName("Text%d" % font_size)
	var entries := []
	for c: Array in choices:
		entries.append([c[0], c[1], role, c[2], bold, HORIZONTAL_ALIGNMENT_LEFT])
	_choices.show_labels(entries)
	_hand.texture = hand
	_hand.position = Vector2(hand_at)
	_hand.self_modulate = hand_tint
	_hand.visible = hand != null
