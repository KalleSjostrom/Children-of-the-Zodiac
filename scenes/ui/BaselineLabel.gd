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
## Where the node's position is on the line: its start (left), its centre or
## its end (right). Centred and right-aligned text starts at the position
## minus half or all of the line's advance width rounded half up, as the
## legacy Graphics.calcAlignCenter and calcAlignRight place it.
@export var alignment := HORIZONTAL_ALIGNMENT_LEFT:
	set(value):
		if alignment != value:
			alignment = value
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
	var size := get_theme_font_size(&"font_size")
	var x := 0.0
	if alignment == HORIZONTAL_ALIGNMENT_CENTER or alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if alignment == HORIZONTAL_ALIGNMENT_CENTER:
			width /= 2.0
		x = -floorf(width + 0.5)
	draw_string(font, Vector2(x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color,
			TextServer.JUSTIFICATION_KASHIDA | TextServer.JUSTIFICATION_WORD_BOUND,
			TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL, oversampling)
	# A Control is culled by its rect (its size from its position, set before
	# _draw), which here is the empty rect at the baseline: a line whose
	# baseline is off the screen (the credits' lines as they scroll in and
	# out) would vanish with glyphs still on it. Without the custom rect the
	# item is culled by what it draws, as the legacy canvas items are.
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), false)
