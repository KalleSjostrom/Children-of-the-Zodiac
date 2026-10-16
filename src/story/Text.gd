class_name Text
extends Fadeable
## Port of story.Text: one or two lines of text with a fade value.
## Constructors Text(), Text(fl) and Text(fr, sr) are merged.
## draw(g) draws with the fade value, draw(g, alpha) with the given alpha.

var firstLine: String = ""
var secondLine: String = ""
const SIZE = 40
var size: int = SIZE
var pos = [0, 0]
var whisper: bool = false
var color: int = 0

func _init(fr = null, sr = null) -> void:
	if fr != null:
		firstLine = fr
	if sr != null:
		secondLine = sr

func setSecondLine(s):
	secondLine = s

func setSize(size):
	self.size = size

func setColor(color):
	self.color = color

func draw(g, alpha = null):
	if alpha == null:
		draw(g, fadeValue)
		return
	g.startText(alpha, color, size - 6 if whisper else size)
	g.drawMultiCenteredText(firstLine, pos[1])
	if secondLine != "":
		g.drawMultiCenteredText(secondLine, pos[1] + 70)
	g.finishText()

func _to_string():
	return firstLine + " ; " + secondLine + " ; " + str(pos)

func setPos(pos):
	self.pos = pos

func setWhisper(whisper):
	self.whisper = whisper
