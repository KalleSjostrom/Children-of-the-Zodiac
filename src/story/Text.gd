class_name Text
extends Fadeable
## Port of story.Text: one or two lines of text with a fade value.
## Constructors Text(), Text(fl) and Text(fr, sr) are merged.
## draw(g) draws with the fade value, draw(g, alpha) with the given alpha.

## Bridge (phase 3 step B): the UI node of the lines.
const TEXT_VIEW := "res://scenes/ui/StoryText.tscn"

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
	if not Main.is_legacy("story_texts"):
		show_text(g, alpha)
		return
	g.startText(alpha, color, size - 6 if whisper else size)
	g.drawMultiCenteredText(firstLine, pos[1])
	if secondLine != "":
		g.drawMultiCenteredText(secondLine, pos[1] + 70)
	g.finishText()

## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): draw(g, alpha)
## without the drawing: the same state changes (startText's font size, text
## colour and alpha; finishText), and the node scenes/ui/StoryText.tscn on
## the Transition layer shows the lines where they would have been drawn
## (Graphics.show_ui), centred as drawMultiCenteredText centres them, in the
## colour and alpha drawMultiString draws with. --legacy=story_texts keeps the
## drawing.
func show_text(g, alpha):
	g.startText(alpha, color, size - 6 if whisper else size)
	var textColor: Color = Graphics.text_color(g.text_alpha())
	var fontSize: int = g.getFontSize()
	var bold: bool = Graphics.font_bold()
	var mat = g.canvas_material()
	g.finishText()
	var view = g.show_ui(TEXT_VIEW, Graphics.TRANSITION_LAYER)
	if view != null:
		view.show_text(firstLine, secondLine, pos[1], fontSize, textColor, mat, bold)

func _to_string():
	return firstLine + " ; " + secondLine + " ; " + str(pos)

func setPos(pos):
	self.pos = pos

func setWhisper(whisper):
	self.whisper = whisper
