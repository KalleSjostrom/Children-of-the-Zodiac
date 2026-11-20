extends Control
## A battle's attack texts (the damage, "Miss!", "Critical Hit!", a heal in
## green, the shuffle's "Shuffle"; phase 4.4's rollout, part 4, step B,
## docs/ARCHITECTURE.md section 15): each text at the screen point its
## eye-space position projects to, at the pixel size its font size scales to
## there (AttackText.place_3d_text: the 3D text of JOGL's TextRenderer, drawn
## in screen space), in its colour at its life. The legacy AttackText keeps
## the texts, their life and their rise; its twin hands this node the texts
## of one AttackText.draw where they would have been drawn (Graphics.show_ui).
##
## A text is drawn as the legacy drawing drew it (Font.draw_string at the
## projected point, which is not a whole pixel, and the scaled size, which is
## not a theme size: 37 for bold 20): no BaselineLabel, whose position and
## size are whole pixels and theme sizes.

## The game's theme, whose BaselineLabel fonts the texts are drawn in.
const GAME_THEME: Theme = preload("res://resources/theme/game_theme.tres")

## The texts last shown: [text, baseline start (screen pixels), font size
## (pixels), bold, colour] each, in drawing order.
var _texts: Array = []


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## texts: [text, baseline start (Vector2, not rounded), font size (pixels),
## bold, colour (alpha included)] each, in drawing order. mat: the material of
## the legacy drawing (Graphics.canvas_material).
func show_texts(texts: Array, mat: Material) -> void:
	material = mat
	if texts != _texts:
		_texts = texts
		queue_redraw()


func _draw() -> void:
	for t: Array in _texts:
		var font: Font = GAME_THEME.get_font(&"bold_font" if t[3] else &"font", &"BaselineLabel")
		draw_string(font, t[1], t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, t[2], t[4],
				TextServer.JUSTIFICATION_KASHIDA | TextServer.JUSTIFICATION_WORD_BOUND,
				TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL, 1.0)
	# Culled by what it draws, not by its rect (BaselineLabel's reason: a
	# text near an edge of the screen).
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), false)
