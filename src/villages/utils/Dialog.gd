class_name Dialog
extends RefCounted
## Port of villages.utils.Dialog: manages a dialog between player and
## villager. A singleton (Dialog.getDialog()).

const FIRST = 0
const SECOND = 1
const DIALOG = 0
const NAME = 1
const FIRST_LINE = 2
const SECOND_LINE = 3
var xs = [[0, 30], [45, 75], [65, 95], [65, 90]]
var ys = [[20, 50], [75, 105], [110, 140], [145, 170]]
static var dialog = null
var dialogSec = null
static var DIALOG_1: String = ImageHandler.addPermanentlyLoadNow(
		Values.MenuImages + "dialog/dialog1.png")
static var DIALOG_2: String = ImageHandler.addPermanentlyLoadNow(
		Values.MenuImages + "dialog/dialog2.png")
var hand = ""
var alternatives = null
var handX = [25, 330]
var handY = [50, 110]
var index: int = 0
var xChoice: int = 0
var yChoice: int = 0
var secondHasBeenShown: bool = false
var end: bool = false
var responses = null
var questionNumer: int = 0
var input: int = 0
var current: int = 0
var inputNr = [0, 0, 0, 0]
var alpha: float = 0.0
var speed: float = 0.03

func _init() -> void:
	hand = MenuHand.handRight


## Gets the dialog object (singleton; created on first use).
static func getDialog():
	if dialog == null:
		dialog = Dialog.new()
	return dialog


## Resets the internal values for drawing back to default.
func resetDialog():
	secondHasBeenShown = false
	end = false
	input = 0
	index = 0
	inputNr = [0, 0, 0, 0]
	alternatives = null
	current = 0
	xChoice = 0
	yChoice = 0


## Moves the pointer hand, if the current dialog is a question.
func move(i):
	if dialogSec[index].isInputQ():
		moveInputQ(i)
	else:
		moveQuestion(i)


func moveInputQ(i):
	xChoice = -1
	if i == GameMode.UP or i == GameMode.DOWN:
		inputNr[current] += 1 if i == GameMode.UP else -1
		inputNr[current] = (inputNr[current] + 10) % 10
	else:
		if i == GameMode.RIGHT:
			current += 1
		else:
			current -= 1
		current = (current + 4) % 4


func moveQuestion(i):
	if isQuestion():
		if i == GameMode.UP or i == GameMode.UP + 2:
			yChoice = absi(yChoice - 1)
			if alternatives[xChoice + yChoice * 2] == " ":
				yChoice = absi(yChoice - 1)
		else:
			xChoice = absi(xChoice - 1)
			if alternatives[xChoice + yChoice * 2] == " ":
				xChoice = absi(xChoice - 1)


func isQuestion():
	# dialogSec is null before the first dialog is set (e.g. pressing cross
	# on a trigger door whose dialog was shown in an earlier visit).
	return dialogSec != null and index < dialogSec.size() and dialogSec[index].question


func isFinished():
	if alpha > 0:
		if alpha >= 2:
			speed = -speed
		return false
	elif dialogSec != null and index < dialogSec.size() - 1 and not end:
		var DS = dialogSec[index]
		end = DS.end
		if not end:
			index += 1
		if not dialogSec[index].first and not secondHasBeenShown:
			secondHasBeenShown = true
		return end
	return true


func checkIsFinished():
	return not (index < dialogSec.size() - 1 and not end)


## Java overloads: setDS(ArrayList<DialogSequence> ds, HashMap responses) and
## setDS(DialogSequence ds).
func setDS(ds, responses = null):
	if not (ds is Array):
		var list := []
		list.append(ds)
		setDS(list, null)
		return
	resetDialog()
	dialogSec = ds
	self.responses = responses


## Java overloads: draw(Graphics g),
## draw(g, boolean first, String name, String fl, String sl, boolean small)
## and the private draw(g, String name, String fl, String sl, int pos, boolean small).
func draw(g, first = null, name = null, fl = null, sl = null, small = null):
	if first == null and name == null and fl == null:
		_drawCurrent(g)
	elif first is bool:
		_drawDialog(g, first, name, fl, sl, small)
	else:
		_drawLines(g, first, name, fl, sl, small)


## Java: draw(Graphics g).
func _drawCurrent(g) -> void:
	var DS = dialogSec[index]
	if DS.inputQ:
		drawInputQuestion(g, DS)
		questionNumer = DS.questionNr
	elif DS.question and not end:
		_drawQuestion(g, DS.first, DS.alternatives)
		questionNumer = DS.questionNr
	elif DS.getGift() != null:
		drawGift(g, DS)
	elif DS.image:
		g.setColor(1, 1, 1, alpha)
		g.drawImage(Graphics.fadeImage, 0, -384, 2)
		if speed > 0 and alpha <= 2:
			alpha += speed
		elif speed < 0 and alpha >= 0:
			alpha += speed
			if alpha <= 0:
				alpha = 0.0
				isFinished()
		g.setColor(1, 1, 1, alpha - 1)
		g.drawCenteredImage(DS.getImage(), 0)
	else:
		_drawDialog(g, DS.first, DS.name, DS.firstLine, DS.secondLine, DS.whisper)


func drawInputQuestion(g, ds):
	input = inputNr[0] * 1000 + inputNr[1] * 100 + inputNr[2] * 10 + inputNr[3]
	xChoice = -1
	g.setFontSize(26)
	if secondHasBeenShown:
		g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND])
	g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])

	g.startText()
	g.drawMultiString(ds.name, xs[NAME][FIRST], ys[NAME][FIRST])
	g.drawMultiString(str(inputNr[0]), 70, 130)
	g.drawMultiString(str(inputNr[1]), 100, 130)
	g.drawMultiString(str(inputNr[2]), 130, 130)
	g.drawMultiString(str(inputNr[3]), 160, 130)
	g.finishText()
	var x: int = 0
	match current:
		0:
			x = 30
		1:
			x = 60
		2:
			x = 90
		3:
			x = 120
	g.drawImage(hand, x, 110)


## Draws the current dialog in the sequence as a message.
func drawAsMessage(g):
	var DS = dialogSec[index]
	drawMessages(g, DS.firstLine, DS.secondLine, true)


## Java: draw(Graphics g, boolean first, String name, String fl, String sl, boolean small).
func _drawDialog(g, first: bool, name, fl, sl, small) -> void:
	var fontSize: int = g.getFontSize()
	if fontSize != 30:
		g.setFontSize(30)
	Graphics.setTextColor(JColor.black)
	if first:
		if secondHasBeenShown:
			g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND])
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])
		_drawLines(g, name, fl, sl, FIRST, small)
	else:
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])
		g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND])
		_drawLines(g, name, fl, sl, SECOND, small)
	if fontSize != 30:
		g.setFontSize(fontSize)


## Java: private draw(Graphics g, String name, String fl, String sl, int pos, boolean small).
func _drawLines(g, name, fl, sl, pos: int, small) -> void:
	var y1: int = ys[FIRST_LINE][pos]
	var y2: int = ys[SECOND_LINE][pos]
	var size: int = 24
	if name != null and name != "":
		g.drawString(name + ":", xs[NAME][pos], ys[NAME][pos])
	else:
		y1 -= 25
		y2 -= 10
		size = 24
	if sl == "" and (name == null or name == ""):
		g.setFontSize(size if small else size + 6)
		g.drawString(fl, xs[FIRST_LINE][pos], y1)
	else:
		g.setFontSize(size if small else size + 6)
		g.startText()
		g.drawMultiString(fl, xs[FIRST_LINE][pos], y1)
		g.drawMultiString(sl, xs[SECOND_LINE][pos], y2)
		g.finishText()


## Draws a message, like "The door is closed". If the second line equals ""
## the first line is centered in height.
func drawMessages(g, fl, sl, loadIdent):
	if loadIdent:
		g.loadIdentity()
		g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
		g.setAlphaFunc(0.1)
	Graphics.setTextColor(JColor.black)
	g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])
	g.setFontSize(MenuValues.MENU_FONT_SIZE_LARGE)
	var yValue: int = 110 if sl == "" else 85
	g.startText()
	g.drawMultiString(fl, 65, yValue)
	g.drawMultiString(sl, 65, 135)
	g.finishText()


func drawGift(g, ds):
	if ds.getName() != null and ds.getName().strip_edges() != "":
		Dialog.getDialog().draw(g, ds.first, ds.name, ds.firstLine, ds.secondLine, ds.whisper)
	else:
		Dialog.getDialog().drawMessages(g, ds.firstLine, ds.secondLine, true)
	var content = ds.getGift().getContent()
	if content != null:
		if content is Card:
			DeckPage.drawCardInfo(g, content, 530)


## Java: static drawGift(Graphics g, String first, String second, Loot l).
static func drawGiftStatic(g, first, second, l):
	Dialog.getDialog().drawMessages(g, first, second, true)
	var content = l.getContent()
	if content != null:
		if content is Card:
			DeckPage.drawCardInfo(g, content, 530)


## Java overloads: the private drawQuestion(g, first, alt) and the public
## drawQuestion(g, first, alt, String title).
func drawQuestion(g, first, alt, title = null):
	if title == null:
		_drawQuestion(g, first, alt)
		return
	alternatives = alt
	g.setFontSize(26)
	if secondHasBeenShown:
		g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND])
	g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])

	g.startText()
	g.drawMultiString(title, xs[NAME][FIRST], ys[NAME][FIRST])
	g.drawMultiString(alt[0], xs[FIRST_LINE][FIRST], ys[FIRST_LINE][FIRST])
	g.drawMultiString(alt[1], 370, ys[SECOND_LINE][FIRST])
	g.drawMultiString(alt[2], xs[SECOND_LINE][FIRST], ys[SECOND_LINE][FIRST])
	g.drawMultiString(alt[3], 370, ys[SECOND_LINE][FIRST])
	g.finishText()
	g.drawImage(hand, handX[xChoice], handY[yChoice])


## Java: private drawQuestion(Graphics g, boolean first, String[] alt).
func _drawQuestion(g, first, alt) -> void:
	alternatives = alt
	g.setFontSize(26)
	if secondHasBeenShown:
		g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND])
	g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST])

	g.startText()
	g.drawMultiString(alt[0], 65, 75)
	g.drawMultiString(alt[1], 370, 75)
	g.drawMultiString(alt[2], 65, 135)
	g.drawMultiString(alt[3], 370, 135)
	g.finishText()
	g.drawImage(hand, handX[xChoice], handY[yChoice])


func shouldTrigger():
	return not end


func loadResponse():
	var idx: int
	if xChoice == -1:
		if questionNumer == input:
			idx = input
		else:
			idx = 0
	else:
		idx = questionNumer + (xChoice + yChoice * 2) + 1
		var ds = dialogSec[self.index]
		var priceChoices = ds.getPrices()
		var gold: int = Load.getPartyItems().getGold()
		var i: int = xChoice + yChoice * 2
		var p: int = priceChoices[i]
		if p > 0 and p > gold:
			idx = questionNumer + 5
	var r = responses.get(idx)
	var res := []
	for i in range(r.size()):
		res.append(r[i])
	for i in range(self.index + 1, dialogSec.size()):
		res.append(dialogSec[i])
	res.insert(0, dialogSec[self.index])
	self.index = 0
	dialogSec = res


func getGift():
	return dialogSec[index].getGift()


func getTriggers():
	return dialogSec[index].getTriggers()


func getBeforeTriggers():
	return dialogSec[index].getBeforeTriggers()


func getTriggerAdds():
	return dialogSec[index].getTriggerAdds()


func getTakeName():
	return dialogSec[index].takeName


func getTakeAmount():
	return dialogSec[index].takeAmount


func _to_string():
	return str(dialogSec[index].firstLine)


func getCurrentAlternative():
	return null if alternatives == null else alternatives[xChoice + yChoice * 2]
