class_name Deck
extends RefCounted
## Port of equipment.Deck: an array of cards and a pointer hand, with methods
## to move around in the deck.

const X_DISTANCE = 75
const Y_DISTANCE = 113

const UP = 0
const DOWN = 1
const DEFAULT_DECK_SIZE = 500
## Bridge (phase 4.2 step B): the node of show_deck.
const VIEW := "res://scenes/ui/DeckView.tscn"

var hand = null # MenuHand

var deck: Array = []
var pos: Array = [0, 0]
var relOffset: Array = [0, 0]
var lineLength: int = 0
var nrOfCardsShown: int = 0
var handLine: int = 1
var currentLine: int = 1
var shownLines: int = 1
var owner = null # Character
var menuCursor: int = 0
var xDistance: int = X_DISTANCE
var yDistance: int = Y_DISTANCE
var active: bool = false
var change: bool = false


## Creates an empty deck and the menu hand.
func _init(owner = null) -> void:
	self.owner = owner
	deck = []
	hand = MenuHand.new(Values.DOWN)


## Java overloads: insert(Card c) and insert(int i, Card c).
## Inserts a card (at the given index). If the deck is full, nothing happens.
## Returns true if the card was inserted.
func insert(i, c = null):
	if i is int:
		if deck.size() < getDeckSize():
			deck.insert(i, c)
			change = true
			return true
		return false
	if deck.size() < getDeckSize():
		deck.append(i)
		change = true
		return true
	return false


func removeCard(c, nrOfCards):
	var i := 0
	while i < deck.size():
		if deck[i].compareTo(c) == 0:
			deck.remove_at(i)
			nrOfCards -= 1
			if nrOfCards <= 0:
				return
		else:
			i += 1


## Removes whatever the hand is pointing to in the deck and returns it.
func removeCurrent():
	var c = J.removeAt(deck, menuCursor)
	change = true
	if menuCursor == deck.size():
		left()
	return c


## Activates or inactivates the deck. If active the hand is shown.
func setActive(p_active):
	active = p_active


func isEmpty():
	return deck.size() == 0


## Java overloads: right() (= right(true)) and right(boolean playSound).
## Moves the cursor one step to the right.
func right(playSound = null):
	if playSound == null:
		playSound = true
	if not isEmpty():
		menuCursor += 1
		if menuCursor >= deck.size():
			menuCursor -= 1
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
			return
		if playSound:
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK)
		if menuCursor == currentLine * lineLength:
			currentLine += 1
			updateHandpos(DOWN)
		else:
			updateHandpos(-1)


## Moves the cursor one step to the left.
func left():
	if not isEmpty():
		menuCursor -= 1
		if menuCursor < 0:
			menuCursor += 1
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
			return
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK)
		if menuCursor < (currentLine - 1) * lineLength:
			currentLine -= 1
			if currentLine < 1:
				currentLine = getTotalNrOfLines()
				menuCursor = deck.size() - 1
				updateHandpos(DOWN)
			else:
				updateHandpos(UP)
		else:
			updateHandpos(-1)


## Moves the cursor down one line.
func down():
	if not isEmpty():
		if currentLine == getTotalNrOfLines():
			menuCursor += lineLength
			if menuCursor >= deck.size():
				SoundPlayer.playSound(SoundMap.MENU_ERROR)
				menuCursor -= lineLength
				return
			else:
				currentLine += 1
		else:
			menuCursor += lineLength
			if menuCursor >= deck.size():
				currentLine += 1
				menuCursor = deck.size() - 1
			else:
				currentLine += 1
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK)
		updateHandpos(DOWN)


## Moves the cursor up one line.
func up():
	if not isEmpty():
		menuCursor -= lineLength
		if menuCursor < 0:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
			menuCursor += lineLength
			return
		else:
			currentLine -= 1
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK)
		updateHandpos(UP)


## Updates the position of the hand (dir: the direction of the move).
func updateHandpos(dir):
	if dir == DOWN and handLine != shownLines:
		handLine += 1
	elif dir == UP:
		if handLine == 1:
			if currentLine == getTotalNrOfLines():
				handLine -= 1
		else:
			handLine -= 1
		if handLine <= 0:
			handLine = mini(getTotalNrOfLines(), shownLines)
	setHandPos()


func setHandPos():
	var x := Values.X
	var y := Values.Y
	var newX: int = pos[x] + (menuCursor - (currentLine - 1) * lineLength) \
		* xDistance + 45 + relOffset[x]
	var newY: int = pos[y] + yDistance * (handLine - 1) + relOffset[y]
	hand.setXpos(newX)
	hand.setYpos(newY)


## Java's Iterator<Card>: returns the card list itself (iterate with for).
func iterator():
	return deck


## Java overloads:
##   drawDeck(g)                                  -> (MAX, false, null, null)
##   drawDeck(g, Card currentCard)                -> (MAX, false, card, null)
##   drawDeck(g, Card currentCard, HashMap map)   -> (MAX, true, card, map)
##   drawDeck(g, int gold, boolean large, Card currentCard, HashMap map)
## Draws the cards in the deck. Cards that cost more than the given gold
## (or are disabled in the map) are drawn in black and white.
func drawDeck(g, gold = null, large = null, currentCard = null, map = null):
	if not (gold is int):
		currentCard = gold
		map = large
		large = map != null
		gold = J.INT_MAX
	var offset: int = currentLine - handLine
	if offset < 0:
		offset = 0
	var ci: int = 0
	var cj: int = 0
	var fs: int = g.getFontSize()
	g.setFontSize(26, true)
	for i in shownLines:
		for j in lineLength:
			var index: int = lineLength * (i + offset) + j
			if index < deck.size():
				var x: int = pos[Values.X] + j * xDistance
				var y: int = pos[Values.Y] + i * yDistance
				var c = deck[index]
				if currentCard != c:
					var enabled := true
					if map != null:
						var info = map.get(c.getSortingValue())
						enabled = info.isEnabled()
						drawCard(g, large, x, y, c, enabled)
						Graphics.setTextColor(0)
						g.drawStringRightAligned(str(info.getIndex()), y + 171, x + 118)
						Graphics.setTextColor(1)
						g.drawStringRightAligned(str(info.getIndex()), y + 169, x + 116)
					else:
						enabled = c.getPrice() <= gold
						drawCard(g, large, x, y, c, enabled)
				else:
					ci = i
					cj = j
	if currentCard != null:
		var x: int = pos[Values.X] + cj * xDistance
		var y: int = pos[Values.Y] + ci * yDistance
		var enabled := true
		g.setFontSize(28, true)
		if map != null:
			var info = map.get(currentCard.getSortingValue())
			enabled = info.isEnabled()
			if enabled:
				currentCard.drawCard(g, x - 15, y - 20, 1.2 if large else 0.9)
			else:
				currentCard.drawGrayCard(g, x - 15, y - 20, 1.2 if large else 0.9)
			Graphics.setTextColor(0)
			g.drawStringRightAligned(str(info.getIndex()), y + 186, x + 128)
			Graphics.setTextColor(1)
			g.drawStringRightAligned(str(info.getIndex()), y + 184, x + 126)
		else:
			if currentCard.getPrice() <= gold:
				currentCard.drawCard(g, x - 15, y - 20, 1.2 if large else 0.9)
			else:
				currentCard.drawGrayCard(g, x - 15, y - 20, 1.2 if large else 0.9)
	if active:
		hand.drawHand(g)
	Graphics.setTextColor(0)
	g.setFontSize(fs, false)


func drawCard(g, large, x, y, c, enabled):
	if enabled:
		c.drawCard(g, x, y, 1.0 if large else 0.7)
	else:
		c.drawGrayCard(g, x, y, 1.0 if large else 0.7)


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): drawDeck
## (every overload) without the drawing: the same state changes in the same
## order (the font sizes, the bold font set and turned off again, the
## cards' binds, the text colours and drawString's setColor(color) of the
## card store's numbers, the hand's bind). Returns {"cards": [{"images":
## AbstractCard.place_at's, "index": the card store's number and its shadow
## as [text, position (its end), font size, colour, bold] each}, …] in drawing
## order (the current card last, larger), "hand": MenuHand.place_hand's}.
func place_deck(g, gold = null, large = null, currentCard = null, map = null) -> Dictionary:
	if not (gold is int):
		currentCard = gold
		map = large
		large = map != null
		gold = J.INT_MAX
	var offset: int = currentLine - handLine
	if offset < 0:
		offset = 0
	var ci: int = 0
	var cj: int = 0
	var fs: int = g.getFontSize()
	var cards := []
	g.setFontSize(26, true)
	for i in shownLines:
		for j in lineLength:
			var index: int = lineLength * (i + offset) + j
			if index < deck.size():
				var x: int = pos[Values.X] + j * xDistance
				var y: int = pos[Values.Y] + i * yDistance
				var c = deck[index]
				if currentCard != c:
					var enabled := true
					if map != null:
						var info = map.get(c.getSortingValue())
						enabled = info.isEnabled()
						var card := {"images": _place_card(g, large, x, y, c, enabled), "index": []}
						Graphics.setTextColor(0)
						_place_index(g, str(info.getIndex()), Vector2i(x + 118, y + 171), card.index)
						Graphics.setTextColor(1)
						_place_index(g, str(info.getIndex()), Vector2i(x + 116, y + 169), card.index)
						cards.append(card)
					else:
						enabled = c.getPrice() <= gold
						cards.append({"images": _place_card(g, large, x, y, c, enabled), "index": []})
				else:
					ci = i
					cj = j
	if currentCard != null:
		var x: int = pos[Values.X] + cj * xDistance
		var y: int = pos[Values.Y] + ci * yDistance
		var enabled := true
		g.setFontSize(28, true)
		var size: float = 1.2 if large else 0.9
		var card := {"images": [], "index": []}
		if map != null:
			var info = map.get(currentCard.getSortingValue())
			enabled = info.isEnabled()
			card.images = currentCard.place_at(g, x - 15, y - 20, size,
					AbstractCard.NORMAL if enabled else AbstractCard.GRAY)
			Graphics.setTextColor(0)
			_place_index(g, str(info.getIndex()), Vector2i(x + 128, y + 186), card.index)
			Graphics.setTextColor(1)
			_place_index(g, str(info.getIndex()), Vector2i(x + 126, y + 184), card.index)
		else:
			card.images = currentCard.place_at(g, x - 15, y - 20, size,
					AbstractCard.NORMAL if currentCard.getPrice() <= gold else AbstractCard.GRAY)
		cards.append(card)
	var placed := {"cards": cards, "hand": []}
	if active:
		placed.hand = hand.place_hand(g)
	Graphics.setTextColor(0)
	g.setFontSize(fs, false)
	return placed


## drawCard (the deck's) without the drawing (AbstractCard.place_at).
func _place_card(g, large, x, y, c, enabled) -> Array:
	return c.place_at(g, x, y, 1.0 if large else 0.7,
			AbstractCard.NORMAL if enabled else AbstractCard.GRAY)


## drawStringRightAligned of a card's number without the drawing: the line
## and drawString's setColor(color).
static func _place_index(g, text: String, end: Vector2i, into: Array) -> void:
	into.append([text, end, g.getFontSize(), Graphics.text_color(1.0), Graphics.font_bold()])
	g.setColor(g.color)


## Bridge (phase 4.2 step B): drawDeck without the drawing (place_deck), and
## the frame's next DeckView node on the UI layer shows the deck where it
## would have been drawn (Graphics.show_ui).
func show_deck(g, gold = null, large = null, currentCard = null, map = null) -> void:
	var mat = g.canvas_material()
	var placed := place_deck(g, gold, large, currentCard, map)
	var view = g.show_ui(VIEW, Graphics.UI_LAYER)
	if view == null:
		return
	var hand_view := []
	if not placed.hand.is_empty():
		var t = ImageHandler.getTexture(placed.hand[0])
		hand_view = [t.getGodotTexture() if t != null else null,
				Vector2i(placed.hand[1], placed.hand[2]), placed.hand[3]]
	view.show_deck(placed.cards, hand_view, mat)


func getSeenCard(cardIndex):
	var offset: int = currentLine - handLine
	if offset < 0:
		offset = 0
	var ci: int = 0
	for i in shownLines:
		for j in lineLength:
			var index: int = lineLength * (i + offset) + j
			if index < deck.size() and ci == cardIndex:
				return deck[index]
			ci += 1
	return null


func getLastPos():
	for i in shownLines:
		for j in lineLength:
			var index: int = lineLength * i + j
			if index == deck.size():
				var x: int = pos[Values.X] + j * xDistance
				var y: int = pos[Values.Y] + i * yDistance
				return Vector3f.new(x, y, 0)
	return null


func getPosFor(c):
	var offset: int = currentLine - handLine
	if offset < 0:
		offset = 0
	for i in shownLines:
		for j in lineLength:
			var index: int = lineLength * (i + offset) + j
			if index < deck.size():
				var x: int = pos[Values.X] + j * xDistance
				var y: int = pos[Values.Y] + i * yDistance
				if deck[index] == c:
					return Vector3f.new(x, y, 0)
	return null


## Inserts the given card at the specified index (replacing the card there).
## If the index is out of bounds, the card is appended.
func replace(c, index):
	if index < deck.size():
		deck.remove_at(index)
		if c != null:
			insert(index, c)
	else:
		insert(c)


## Empties this deck.
func clear():
	change = true
	deck.clear()


## Swaps the cards with the given indices.
func swap(a, b):
	var c = deck[a]
	deck[a] = deck[b]
	deck[b] = c


## Copies the card with index i.
func copyCard(i):
	return deck[i].copyCard()


## Java overloads: isFull() and isFull(int size).
func isFull(size = null):
	if size == null:
		return deck.size() >= getDeckSize()
	return (deck.size() + size) >= getDeckSize()


## Sets the deck's coordinates.
func setCoordinates(x, y):
	pos[Values.X] = x - 10
	pos[Values.Y] = y - 20
	setHandPos()


## Sets the number of cards which the player should be able to move amongst.
func setNrOfShownCards(nr):
	nrOfCardsShown = nr


## Sets the length of each line in the deck.
func setLineLength(length):
	lineLength = length


## Sets the number of lines that should be drawn.
func setShownLines(nr):
	shownLines = nr


## Sets the offset of the menu hand relative to its normal position.
func setHandPosRelative(x, y):
	relOffset[Values.X] = x
	relOffset[Values.Y] = y


## Gets whatever the hand is pointing to in the deck (or null).
func getCurrent():
	if menuCursor < deck.size():
		return deck[menuCursor]
	return null


func getCard(i):
	return deck[i]


## Gets the max size of the deck.
func getDeckSize():
	return owner.getAttribute(Creature.DECK_SIZE) if owner != null else DEFAULT_DECK_SIZE


## Gets the current number of cards in the deck.
func getCurrentDeckSize():
	return deck.size()


func getSizeInfo():
	return "(" + str(deck.size()) + "/" + str(getDeckSize()) + ")"


func getNrOfCardsShown():
	return nrOfCardsShown


## Gets the offset used when drawing the scroll bar of the deck menu.
func getScrollBarHeight():
	var t: float = mini(currentLine - handLine, getTotalNrOfLines() - 3)
	return t / float(getTotalNrOfLines())


func getXpos():
	return pos[Values.X]


func getYpos():
	return pos[Values.Y]


## Gets the index in the deck which the hand points at.
func getMenuCursor():
	return menuCursor


## Gets the line in the menu where the hand is currently pointing.
func getCurrentLine():
	return currentLine


## Gets the total number of lines in this deck.
func getTotalNrOfLines():
	if lineLength == 0:
		# Java: (int) Math.ceil(size / 0f) -> (int) NaN = 0 or (int) Infinity.
		return 0 if deck.size() == 0 else J.INT_MAX
	return int(ceil(float(deck.size()) / float(lineLength)))


## Resets some of the deck's values to default.
func reset():
	currentLine = 1
	menuCursor = 0
	handLine = 1
	updateHandpos(-1)
	active = false


## Adds the given card to the deck.
func addCard(c):
	change = true
	deck.append(c)


## Sorts the cards (Java's Arrays.sort: stable, using Card.compareTo).
func sort():
	var pairs: Array = []
	for i in deck.size():
		pairs.append([deck[i], i])
	pairs.sort_custom(func(a, b):
		var r: int = a[0].compareTo(b[0])
		if r != 0:
			return r < 0
		return a[1] < b[1])
	deck.clear()
	for p in pairs:
		deck.append(p[0])


## Counts the number of cards in this deck that are equal (compareTo == 0)
## to the given card.
func search(c):
	if c == null:
		return 0
	var nr: int = 0
	for i in deck.size():
		if c.compareTo(deck[i]) == 0:
			nr += 1
	return nr


## Checks if this deck has changed in any way.
func hasChanged():
	return change


## Resets the change value (after the battle deck has been synchronized).
func resetChange():
	change = false


func setXDistance(d):
	xDistance = d


func setYDistance(d):
	yDistance = d


func getShowLines():
	return shownLines
