class_name ScrollableTexts
extends RefCounted
## Port of story.ScrollableTexts: texts that scroll up the screen (credits).

const LEFT_ALIGNED = 0
const CENTERED = 1
const CENTERED_AT = 2
const RIGHT_ALIGNED = 3
var texts = null
var y: float = 800.0
var speed: float = 1.0

func _init() -> void:
	texts = []

func add(st):
	texts.append(st)

func update(elapsedTime):
	y -= speed

func draw(g):
	g.setTextColorAndApply(1, 1)
	var yVal: float = y
	for i in range(texts.size()):
		var st = texts[i]
		if yVal > -50:
			st.draw(g, yVal)
		elif yVal > 800:
			break
		yVal += st.distance

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

	func draw(g, y):
		g.setFontSize(fontsize, isBold)
		match mode:
			LEFT_ALIGNED:
				g.drawString(text, x, J.round(y))
			CENTERED:
				g.drawSingleCenteredText(text, J.round(y))
			CENTERED_AT:
				g.drawSingleCenteredText(text, J.round(y), x)
			RIGHT_ALIGNED:
				g.drawStringRightAligned(text, J.round(y), x)
			_:
				pass
