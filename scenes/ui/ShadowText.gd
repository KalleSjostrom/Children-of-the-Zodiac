extends Control
## A line of text over its shadow (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14), as Graphics.drawWithShadow draws it: the line in the shadow's
## colour (black) 1 px down and to the right, then the line itself. The
## title's difficulty description; the battle's texts with shadows later.

@onready var _shadow: BaselineLabel = $Shadow
@onready var _text: BaselineLabel = $Text


## The line text with its baseline starting at at, in the theme role role
## (its size), the shadow in shadow_color and the line in color, in the bold
## font or not; mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_text(text: String, at: Vector2i, role: StringName, shadow_color: Color, color: Color,
		bold: bool, mat: Material) -> void:
	material = mat
	for label: BaselineLabel in [_shadow, _text]:
		label.text = text
		label.theme_type_variation = role
		label.bold = bold
	_shadow.position = Vector2(at + Vector2i.ONE)
	_shadow.color = shadow_color
	_text.position = Vector2(at)
	_text.color = color
