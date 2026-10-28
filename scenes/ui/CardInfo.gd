extends Control
## The card info popup (phase 3 step B, docs/ARCHITECTURE.md section 12): the
## card's picture with its level's balls, its name, its description and its
## effect on the menu piece, as the legacy DeckPage.drawCardInfo draws it
## (under a dialog that gives a card, in the card store, on the menu's deck
## page). The legacy drawing hands it the card where it would have drawn it
## (Graphics.show_ui).

## The x of each ball from the picture's left edge, by level (1 to 3).
@export var ball_columns: Array[PackedInt32Array] = [
	PackedInt32Array([65]), PackedInt32Array([50, 80]), PackedInt32Array([40, 65, 90])]

@onready var _panel: Panel = $Panel
@onready var _picture: TextureRect = $Picture
@onready var _balls: Array[TextureRect] = [$Picture/Ball1, $Picture/Ball2, $Picture/Ball3]
@onready var _name: BaselineLabel = $Name
@onready var _lines: Array[BaselineLabel] = [$Line1, $Line2, $Line3]
@onready var _effect: BaselineLabel = $Effect


## Starts what a frame shows: the menu piece alone. top is the y the legacy
## drawing places the popup at, tint the colour its images are drawn in, mat
## the material of the legacy drawing (Graphics.canvas_material), bold the
## font.
func show_info(top: int, tint: Color, mat: Material, bold: bool) -> void:
	position = Vector2(0, top)
	material = mat
	_panel.self_modulate = tint
	_picture.visible = false
	for label: BaselineLabel in [_name, _effect] + _lines:
		label.visible = false
		label.bold = bold
	_picture.self_modulate = tint
	for ball in _balls:
		ball.self_modulate = tint


## The card: its picture and its level's balls (none below 1 or above 3).
func show_card(picture: Texture2D, ball: Texture2D, level: int) -> void:
	_picture.visible = true
	_picture.texture = picture
	var columns := ball_columns[level - 1] if level >= 1 and level <= ball_columns.size() \
			else PackedInt32Array()
	for i in _balls.size():
		_balls[i].visible = i < columns.size()
		if i < columns.size():
			_balls[i].texture = ball
			_balls[i].position.x = columns[i]


## The texts: the name line and the effect line in color, the three lines of
## the description in lines_color.
func show_texts(name_line: String, lines: PackedStringArray, effect: String, color: Color,
		lines_color: Color) -> void:
	_name.visible = true
	_name.text = name_line
	_name.color = color
	_effect.visible = true
	_effect.text = effect
	_effect.color = color
	for i in _lines.size():
		_lines[i].visible = true
		_lines[i].text = lines[i]
		_lines[i].color = lines_color
