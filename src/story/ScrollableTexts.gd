class_name ScrollableTexts
extends RefCounted
## Port of story.ScrollableTexts: texts that scroll up the screen (credits).

const LEFT_ALIGNED = 0
const CENTERED = 1
const CENTERED_AT = 2
const RIGHT_ALIGNED = 3
## Bridge (phase 3 step B): the UI node of the lines.
const SCROLL_VIEW := "res://scenes/ui/ScrollText.tscn"
var texts = null
var y: float = 800.0
var speed: float = 1.0

func _init() -> void:
	texts = []

func add(st):
	texts.append(st)

## The texts moved speed per update at the original's frame rate, which the
## sequences are timed to, so the port moves them that much per
## ORIGINAL_FRAME_MS of elapsedTime (ms).
func update(elapsedTime):
	y -= speed * elapsedTime / Values.ORIGINAL_FRAME_MS

func draw(g):
	show_texts(g)

## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): the legacy draw
## without the drawing: the same state changes (the text colour, each line's font size
## and bold font, which stay set; drawString's and finishText's setColor),
## and the node scenes/ui/ScrollText.tscn on the Transition layer shows the
## lines draw would draw (ScrollableText.place_text). The legacy drawing
## (--legacy=story_texts, ScrollableText.draw) is removed (closing phase 3,
## plan 8.4).
func show_texts(g):
	g.setTextColorAndApply(1, 1)
	var mat = g.canvas_material()
	var lines := []
	var yVal: float = y
	for i in range(texts.size()):
		var st = texts[i]
		if yVal > -50:
			var line: Array = st.place_text(g, yVal)
			if not line.is_empty():
				lines.append(line)
		elif yVal > 800:
			break
		yVal += st.distance
	var view = g.show_ui(SCROLL_VIEW, Graphics.TRANSITION_LAYER)
	if view != null:
		view.show_lines(lines, mat)

func setSpeed(speed):
	self.speed = speed


class ScrollableText extends RefCounted:
	var text: String = ""
	var x: int = 0
	var mode: int = 0
	var distance: float = 40.0
	var fontsize: int = 30
	var isBold: bool = false

	func setText(text):
		self.text = text

	func setX(x):
		self.x = x

	func setMode(mode):
		self.mode = mode

	func setDistance(distance):
		self.distance = distance

	func setFontSize(fontsize):
		self.fontsize = fontsize

	func setIsBold(bold):
		isBold = bold

	## Bridge (phase 3 step B): the legacy draw(g, y) without the drawing: the same state
	## changes (setFontSize with the bold font; drawString's setColor(color);
	## drawSingleCenteredText's startText and finishText). Returns [text,
	## position, font size, colour, bold, alignment] (the position is the
	## baseline's start, centre or end, as the alignment says), or [] when
	## draw draws nothing.
	func place_text(g, y) -> Array:
		g.setFontSize(fontsize, isBold)
		var size: int = g.getFontSize()
		var bold: bool = Graphics.font_bold()
		var at := Vector2i(x, J.round(y))
		var align := HORIZONTAL_ALIGNMENT_LEFT
		var color: Color
		match mode:
			LEFT_ALIGNED, RIGHT_ALIGNED:
				color = Graphics.text_color(1.0)
				g.setColor(g.color)
				if mode == RIGHT_ALIGNED:
					align = HORIZONTAL_ALIGNMENT_RIGHT
			CENTERED, CENTERED_AT:
				g.startText(1.0, 1.0)
				color = Graphics.text_color(g.text_alpha())
				g.finishText()
				align = HORIZONTAL_ALIGNMENT_CENTER
				if mode == CENTERED:
					at.x = Values.ORIGINAL_RESOLUTION[Values.X] / 2
			_:
				return []
		return [text, at, size, color, bold, align]
