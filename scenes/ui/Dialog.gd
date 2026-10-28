extends Control
## The dialog box (phase 3 step B, docs/ARCHITECTURE.md section 12): the two
## papers, the speaker's name and two lines, a question's four alternatives
## and the hand, the input question's digits, and a shown image, as the
## legacy Dialog (src/villages/utils/Dialog.gd) draws them. The legacy Dialog
## and DialogSequence stay in charge of the text, the choices and the timing;
## each frame the legacy drawing hands this node what it would have drawn
## (begin, then show_*), where it would have drawn it (Graphics.show_ui).
## Positions are the legacy screen pixels; each paper holds the places of its
## speech.

## Paper 1 (dialog1.png): the speech of the side that starts a dialog; also
## the paper of questions. Paper 2 (dialog2.png): the other side's.
const PAPER_1 := 0
const PAPER_2 := 1

## How far the lines of a speech move up when it names no speaker: the first
## line, the second line.
@export var unnamed_shift := Vector2i(-25, -10)
## Where the hand points at a question's choice: x by column, y by row.
@export var hand_columns := PackedInt32Array([25, 330])
@export var hand_rows := PackedInt32Array([50, 110])
## Where the hand points at the input question's digit: x by digit, and y.
@export var input_hand_columns := PackedInt32Array([30, 60, 90, 120])
@export var input_hand_y := 110
## The shown image is centred on this x, at the top of the screen.
@export var image_center_x := 512

@onready var _image: TextureRect = $Image
@onready var _papers: Array[Panel] = [$Paper1, $Paper2]
@onready var _question: Control = $Question
@onready var _input: Control = $InputQuestion
@onready var _hand: TextureRect = $Hand

## The baselines of each paper's lines (first, second) with a speaker.
var _line_y: Array[Vector2] = []


func _ready() -> void:
	for paper in _papers:
		_line_y.append(Vector2(_text(paper, "FirstLine").position.y,
				_text(paper, "SecondLine").position.y))


## Starts what a frame shows: everything hidden. mat is the material of the
## legacy drawing (its blending and alpha test, Graphics.canvas_material),
## bold whether its text is in the bold font.
func begin(mat: Material, bold: bool) -> void:
	material = mat
	for part: CanvasItem in [_image, _papers[0], _papers[1], _question, _input, _hand]:
		part.visible = false
	for parent: Node in [_papers[0], _papers[1], _question, _input]:
		for label in _labels(parent):
			label.visible = false
			label.bold = bold


## The papers, front (PAPER_1 or PAPER_2) over the other one, which shows when
## back_shown; tint is the colour they are drawn in.
func show_papers(front: int, back_shown: bool, tint: Color) -> void:
	var front_paper := _papers[front]
	var back_paper := _papers[1 - front]
	if front_paper.get_index() < back_paper.get_index():
		move_child(front_paper, back_paper.get_index())
	front_paper.visible = true
	back_paper.visible = back_shown
	front_paper.self_modulate = tint
	back_paper.self_modulate = tint


## A speech on paper (PAPER_1 or PAPER_2): the speaker ("": none, the lines
## move up) and the colour of the name, the two lines and their colour; a
## whisper is in the smaller size.
func show_speech(paper: int, speaker: String, speaker_color: Color, lines: PackedStringArray,
		line_color: Color, whisper: bool) -> void:
	var p := _papers[paper]
	var name_label := _text(p, "Name")
	name_label.visible = speaker != ""
	name_label.text = speaker
	name_label.color = speaker_color
	var shift := Vector2.ZERO if speaker != "" else Vector2(unnamed_shift)
	var labels: Array[BaselineLabel] = [_text(p, "FirstLine"), _text(p, "SecondLine")]
	for i in labels.size():
		var label := labels[i]
		label.visible = true
		label.text = lines[i]
		label.color = line_color
		label.position.y = _line_y[paper][i] + shift[i]
		label.theme_type_variation = &"DialogWhisper" if whisper else &"DialogLine"


## A question's four alternatives (" " for an empty one) in color, and the
## hand at choice (column, row) in hand_tint.
func show_question(alternatives: PackedStringArray, color: Color, choice: Vector2i,
		hand_tint: Color) -> void:
	_question.visible = true
	var labels := _labels(_question)
	for i in labels.size():
		labels[i].visible = true
		labels[i].text = alternatives[i]
		labels[i].color = color
	_show_hand(Vector2(hand_columns[choice.x], hand_rows[choice.y]), hand_tint)


## The input question: its title, the four digits in color, and the hand at
## the current digit in hand_tint.
func show_input(title: String, digits: PackedInt32Array, color: Color, current: int,
		hand_tint: Color) -> void:
	_input.visible = true
	var labels := _labels(_input)
	for label in labels:
		label.visible = true
		label.color = color
	labels[0].text = title
	for i in digits.size():
		labels[i + 1].text = str(digits[i])
	_show_hand(Vector2(input_hand_columns[current], input_hand_y), hand_tint)


## A shown image (a dialog line of an image, without papers), in tint.
func show_image(texture: Texture2D, tint: Color) -> void:
	_image.visible = true
	_image.texture = texture
	_image.position = Vector2(image_center_x - floori(texture.get_width() / 2.0 + 0.5), 0)
	_image.self_modulate = tint


func _show_hand(at: Vector2, tint: Color) -> void:
	_hand.visible = true
	_hand.position = at
	_hand.self_modulate = tint


func _text(parent: Node, label: String) -> BaselineLabel:
	return parent.get_node(label) as BaselineLabel


func _labels(parent: Node) -> Array[BaselineLabel]:
	var labels: Array[BaselineLabel] = []
	for child in parent.get_children():
		if child is BaselineLabel:
			labels.append(child)
	return labels
