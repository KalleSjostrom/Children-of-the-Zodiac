class_name CesadurRiddle
extends RiddleGame
## Port of miniGames.CesadurRiddle: the anagram riddle on Mt. Cesadur. The
## letters of "HUMAN ATONE OR STREW" are moved into four words (SUN, EARTH,
## MOON, WATER).
##
## Port notes: the fields texts and mode are texts_ and mode_ (RiddleGame
## and GameMode declare texts and mode). Java's inner class Text is
## CesadurRiddle.CesadurRiddleText (Text.Letter is CesadurRiddleText.Letter).

const MIDDLE = 6
const LINE_LENGTH = 20
const WORD_LENGTH = 7

var hand = MenuHand.new(Values.RIGHT)
var wordHand = MenuHand.new(Values.RIGHT)
var ys = [250, 340, 430]
var xs = [220, 220 + (MIDDLE + WORD_LENGTH) * CesadurRiddleText.OFFSET]
var cursory: int = 0
var cursorx: int = 0
var texts_ = J.array2d(2, 3, null) # new Text[xs.length][ys.length]
var states = [] # Stack<State>

const SELECT_WORD = 0
const SELECT_LETTER = 1
var mode_: int = SELECT_WORD
var currentWord = null


## Constructs a new riddle; it is set up in init(name, lab, hinders).
func _init() -> void:
	super()
	pass


func init(name, lab = null, p_hinders = null):
	super.init(name, lab, p_hinders)
	if not (name is String):
		return # Java: init(HashMap info), not overridden here.
	wordHand.setVisible(true)
	wordHand.setXpos(xs[cursorx])
	wordHand.setYpos(ys[cursory])
	hand.setVisible(false)
	hand.setXpos(xs[0])
	hand.setYpos(ys[2])

	for i in xs.size():
		for j in ys.size() - 1:
			texts_[i][j] = CesadurRiddleText.new("", xs[i], ys[j], WORD_LENGTH)

	texts_[0][ys.size() - 1] = CesadurRiddleText.new(
		"HUMAN ATONE OR STREW", xs[0], ys[ys.size() - 1], LINE_LENGTH)


## Checks the input for changes.
func checkInput():
	match mode_:
		SELECT_WORD:
			checkSelectWordInput()
		SELECT_LETTER:
			checkSelectLetterInput()


func checkSelectWordInput():
	var t = getCurrentText()
	if gameActions[UP].isPressed():
		if cursory != 0:
			cursory -= 1
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[DOWN].isPressed():
		if cursory != ys.size() - 2:
			cursory += 1
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[LEFT].isPressed():
		if cursorx != 0:
			cursorx -= 1
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[RIGHT].isPressed():
		if cursorx != xs.size() - 1:
			cursorx += 1
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[CIRCLE].isPressed():
		if not states.is_empty():
			var s: State = states.pop_back()
			s.reverse()
			SoundPlayer.playSound(SoundMap.MENU_BACK)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[SQUARE].isPressed():
		isRiddleDone()
	elif gameActions[TRIANGLE].isPressed():
		isRiddleDone()
		fadingDown = true
	elif gameActions[CROSS].isPressed():
		if not texts_[0][2].isEmpty():
			currentWord = getCurrentText()
			mode_ = SELECT_LETTER
			wordHand.setDimmed(true)
			hand.setVisible(true)
			hand.setDimmed(false)
			cursorx = 0
			cursory = 2
			t = getCurrentText()
			var offset: int = t.getOffset() if t != null else 0
			if cursory == ys.size() - 1:
				hand.setXpos(xs[0] - hand.getXOffset() + offset)
			else:
				hand.setXpos(xs[cursorx] - hand.getXOffset() + offset)
			hand.setYpos(ys[cursory] - hand.getYOffset())
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	if not wordHand.isDimmed():
		t = getCurrentText()
		var offset: int = t.getOffset() if t != null else 0
		if cursory == ys.size() - 1:
			wordHand.setXpos(xs[0] - wordHand.getXOffset() + offset)
		else:
			wordHand.setXpos(xs[cursorx] - wordHand.getXOffset() + offset)
		wordHand.setYpos(ys[cursory] - wordHand.getYOffset())


func checkSelectLetterInput():
	var t = getCurrentText()
	if gameActions[UP].isPressed():
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
		switchToWordMode(1)
		return
	elif gameActions[DOWN].isPressed():
		SoundPlayer.playSound(SoundMap.ERROR)
	elif gameActions[LEFT].isPressed():
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
		if t != null:
			t.left()
	elif gameActions[RIGHT].isPressed():
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
		if t != null:
			t.right()
	elif gameActions[CIRCLE].isPressed():
		if not states.is_empty():
			var s: State = states.pop_back()
			s.reverse()
			SoundPlayer.playSound(SoundMap.MENU_BACK)
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
	elif gameActions[SQUARE].isPressed():
		isRiddleDone()
	elif gameActions[TRIANGLE].isPressed():
		isRiddleDone()
		fadingDown = true
	elif gameActions[CROSS].isPressed():
		if t != null and t.hasLetter():
			if currentWord.hasRoom():
				var l := CesadurRiddleText.Letter.new("", 0, 0)
				l.letter = t.pickUp()
				var insertIndex: int = currentWord.insert(l)

				var s := State.new(l.letter, t.cursor, t, insertIndex, currentWord)
				states.append(s)
				SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
				if t.isEmpty():
					switchToWordMode(1)
					return
			else:
				SoundPlayer.playSound(SoundMap.ERROR)
	var offset: int = t.getOffset() if t != null else 0
	if cursory == ys.size() - 1:
		hand.setXpos(xs[0] - hand.getXOffset() + offset)
	else:
		hand.setXpos(xs[cursorx] - hand.getXOffset() + offset)
	hand.setYpos(ys[cursory] - hand.getYOffset())


func switchToWordMode(i):
	var t = getCurrentText()
	cursory = i
	mode_ = SELECT_WORD
	wordHand.setDimmed(false)
	hand.setDimmed(true)
	t = getCurrentText()
	var offset: int = t.getOffset() if t != null else 0
	if cursory == ys.size() - 1:
		wordHand.setXpos(xs[0] - wordHand.getXOffset() + offset)
	else:
		wordHand.setXpos(xs[cursorx] - wordHand.getXOffset() + offset)
	wordHand.setYpos(ys[cursory] - wordHand.getYOffset())


func isRiddleDone():
	var done: bool = str(texts_[0][0]) == "SUN"
	done = done and str(texts_[0][1]) == "EARTH"
	done = done and str(texts_[1][0]) == "MOON"
	done = done and str(texts_[1][1]) == "WATER"
	if done:
		SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET)
		InventoryButton.updateDoorStatus(hinders, 1)
		fadingDown = true
	else:
		SoundPlayer.playSound(SoundMap.MENU_ERROR)
	return done


## Java: initDraw(GL2 gl) (and the inherited initDraw(Graphics)).
func initDraw(g):
	pass


func getCurrentText():
	var t
	if cursory == ys.size() - 1:
		t = texts_[0][cursory]
	else:
		t = texts_[cursorx][cursory]
	return t


## Draws the riddle on the given graphics (everything is in drawTopLayer).
func draw(g, alpha = null):
	pass


func drawTopLayer(g):
	super.drawTopLayer(g)
	Graphics.setTextColor(JColor.BLACK)
	g.setColor(0, 0, 0, 1)
	g.startText()
	for i in xs.size():
		for j in ys.size() - 1:
			if texts_[i][j] != null:
				texts_[i][j].draw(g)
	g.finishText()
	g.startText()
	if mode_ == SELECT_WORD:
		g.setColor(0, 0, 0, .3)
	texts_[0][ys.size() - 1].draw(g)
	g.finishText()
	hand.drawHand(g)
	wordHand.drawHand(g)
	drawHelp(g)


func drawHelp(g):
	var helpx: int = xs[0] + 20
	var helpy: int = 510
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + 110, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], helpxicons + 295, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 500, helpyicons)

	g.drawString("Exit", helpx, helpy)
	g.drawString("Select " + ("word" if mode_ == SELECT_WORD else "letter"), helpx + 110, helpy)
	g.drawString("Check solution", helpx + 295, helpy)
	g.drawString("Undo", helpx + 500, helpy)


## Java: CesadurRiddle.Text, a row of letter slots.
class CesadurRiddleText extends RefCounted:
	const OFFSET = 28

	var letters = null
	var cursor: int = 0
	var length: int = 0
	var offset: int = 0

	func _init(text = null, x = null, y = null, p_length = null) -> void:
		var chars: String = text
		letters = J.array(p_length, null)
		for i in p_length:
			var s: String = chars[i] if i < chars.length() else ""
			letters[i] = Letter.new(s, x + OFFSET * i, y)
		self.length = p_length

	func setCursor(old, right):
		if old > length:
			old -= CesadurRiddle.MIDDLE
			old %= length
		if length == CesadurRiddle.LINE_LENGTH and right:
			cursor = old + CesadurRiddle.WORD_LENGTH + CesadurRiddle.MIDDLE
		else:
			cursor = old
		offset = cursor * OFFSET

	func pickUp():
		var temp: String = letters[cursor].letter
		letters[cursor].letter = ""
		return temp

	func hasLetter():
		return letters[cursor].letter != "" and letters[cursor].letter != " "

	## Java overloads: int insert(Letter l) puts the letter in the first free
	## slot and returns its index; void insert(String letter, int i).
	func insert(letter, i = null):
		if i == null:
			var l = letter
			var found := false
			var k: int = 0
			while k < letters.size() and not found:
				found = not letters[k].hasLetter()
				if found:
					letters[k].letter = l.letter
				k += 1
			return k - 1
		letters[i].letter = letter
		return null

	func remove(i):
		letters[i].letter = ""

	func hasRoom():
		return not letters[letters.size() - 1].hasLetter()

	func isEmpty():
		var found := false
		var i: int = 0
		while i < letters.size() and not found:
			found = letters[i].hasLetter()
			i += 1
		return not found

	func getOffset():
		return offset

	func reset():
		cursor = 0
		offset = 0

	func left():
		cursor -= 1
		if cursor < 0:
			cursor = length - 1
			offset = cursor * OFFSET
		else:
			offset -= OFFSET
		if not letters[cursor].hasLetter():
			left()

	func right():
		cursor += 1
		if cursor >= length:
			cursor = 0
			offset = 0
		else:
			offset += OFFSET
		if not letters[cursor].hasLetter():
			right()

	func draw(g):
		for l in letters:
			l.draw(g)

	func _to_string():
		var sb: String = ""
		for l in letters:
			sb += l.letter
		return sb


	## Java: CesadurRiddle.Text.Letter.
	class Letter extends RefCounted:
		var letter = ""
		var x: int = 0
		var y: int = 0

		func _init(s = null, p_x = null, p_y = null) -> void:
			letter = s
			self.x = p_x
			self.y = p_y

		func hasLetter():
			return letter != "" and letter != " "

		func draw(g):
			g.drawMultiString(letter, x, y)
			g.drawMultiString("__", x, y + 2)


## Java: CesadurRiddle.State, one move that can be undone.
class State extends RefCounted:
	var letter = ""
	var fromIndex: int = 0
	var toIndex: int = 0
	var fromWord = null
	var toWord = null

	func _init(p_letter = null, p_fromIndex = null, p_fromWord = null, p_toIndex = null, p_toWord = null) -> void:
		self.letter = p_letter
		self.fromIndex = p_fromIndex
		self.fromWord = p_fromWord
		self.toIndex = p_toIndex
		self.toWord = p_toWord

	func reverse():
		toWord.remove(toIndex)
		fromWord.insert(letter, fromIndex)
