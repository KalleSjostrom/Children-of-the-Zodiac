@tool
class_name BaselineLabel
extends Control
## A line of text whose baseline starts at the node's position, in the font of
## its theme type: BaselineLabel and its variations in
## resources/theme/game_theme.tres (the game's two fonts, a font size per
## variation). The legacy text API placed text by its baseline
## (Graphics.drawString, as JOGL's TextRenderer did), so a node at the legacy
## coordinates draws every glyph where the legacy drawing put it (phase 3 step
## B, docs/ARCHITECTURE.md section 12).

## The text; "" draws nothing.
@export var text := "":
	set(value):
		if text != value:
			text = value
			queue_redraw()
## Draw with the theme's bold_font instead of font.
@export var bold := false:
	set(value):
		if bold != value:
			bold = value
			queue_redraw()
## The colour of the text, alpha included.
@export var color := Color.BLACK:
	set(value):
		if color != value:
			color = value
			queue_redraw()
## The scale the glyphs are rasterized at: 1 rasterizes them for the 1024 x
## 768 screen and lets the window's stretch scale them, as the legacy text
## (sharp at that size, softer in a larger window); 0 rasterizes them at the
## window's scale (Godot's default for Controls: sharper in full screen, a
## look change).
@export var oversampling := 1.0:
	set(value):
		if oversampling != value:
			oversampling = value
			queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	if theme_type_variation == &"":
		theme_type_variation = &"BaselineLabel"


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	if text == "":
		return
	var font := get_theme_font(&"bold_font" if bold else &"font")
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			get_theme_font_size(&"font_size"), color, TextServer.JUSTIFICATION_KASHIDA
			| TextServer.JUSTIFICATION_WORD_BOUND, TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL, oversampling)
