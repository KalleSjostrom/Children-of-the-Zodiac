class_name DeckPage
extends AbstractPage
## Port of menu.DeckPage: the page in the menu where the player can organize
## the decks. The player can exchange cards between the character's deck and
## the main party deck, and sort the decks.

const NO_DECK = -1
const CHARACTER_DECK = 0
const MAIN_DECK = 1
static var cardHelp = Values.MenuImages + "Pieces/10.png"
var selectedCard = null
var charDeck = null
var mainDeck = null
var currentDeck = null
var c = null
var charScrollBar = null
var mainScrollBar = null
var characterIndex: int = 0
var showLines: int = 4
var lineLength: int = 5
var edit: bool = false
var displayCardHelp: bool = false
var charName = ""
var activeDeck: int = NO_DECK
var animators: Array = []

func _init(character = null, m = null, activeDeck = null, index = null) -> void:
	c = Load.getCharacters()[character]
	characterIndex = character
	charDeck = c.getDeck()
	charName = c.getName()
	charDeck.setCoordinates(MenuValues.CHAR_DECK_X, MenuValues.DECK_Y)
	charScrollBar = MenuScrollBar.new(450, 282, 418)

	mainDeck = m
	mainDeck.setCoordinates(MenuValues.MAIN_DECK_X, MenuValues.DECK_Y)
	mainScrollBar = MenuScrollBar.new(940, 282, 418)

	initDecks()
	activeNode = MenuNode.new(null, "Deck")
	fillRoot(true)
	activeNode.setMenuCursor(0)
	displayCardHelp = true
	setPage(DECK_PAGE)

	self.activeDeck = activeDeck
	if activeDeck != NO_DECK:
		startEditing(activeDeck)
		var i: int = 0
		while i < index and i < currentDeck.getCurrentDeckSize():
			currentDeck.right(false)
			i += 1


func fillRoot(resetCursor = null):
	var n = activeNode
	n.removeChildren(resetCursor)
	n.insertChild("Edit")
	n.insertChild("Back")
	n.setDistance(35)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MAIN_MENU_TEXT_Y_FOR_DECK)
	n.updateHandPos()


func initDecks():
	var decks: Array = J.array(2, null)
	decks[0] = charDeck
	decks[1] = mainDeck

	for i in range(decks.size()):
		var d = decks[i]
		d.setNrOfShownCards(d.getDeckSize())
		d.setShownLines(showLines)
		d.setLineLength(lineLength)
		d.setHandPosRelative(-21, -20)
		d.reset()


func update(elapsedTime = null):
	for a in animators.duplicate():
		a.update(elapsedTime)
		if a.isDone():
			a.addCardToDeck()
			animators.erase(a)


func rightPressed():
	if edit:
		currentDeck.right()


func leftPressed():
	if edit:
		currentDeck.left()


func upPressed():
	if edit:
		currentDeck.up()
	else:
		activeNode.nextChild()


func downPressed(playSound = null):
	if edit:
		currentDeck.down()
	else:
		activeNode.nextChild()


func R2Pressed():
	if edit:
		currentDeck.setActive(false)
		SoundPlayer.playSound(SoundMap.MENU_SWITCH_DECK)
		switchDeck()


func L2Pressed():
	R2Pressed()


func R1Pressed():
	SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER)
	characterIndex += 1
	MainMenu.getMainMenu().initDeckPage(characterIndex, activeDeck, currentDeck)


func L1Pressed():
	SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER)
	characterIndex -= 1
	MainMenu.getMainMenu().initDeckPage(characterIndex, activeDeck, currentDeck)


func circlePressed(pressAnyWay = null):
	if edit:
		edit = false
		activeNode.setDimmedHand(false)
		currentDeck.setActive(false)
		currentDeck = null
		activeDeck = NO_DECK
	else:
		MainMenu.getMainMenu().initStartPage(0)


func crossPressed(playSound = null):
	if edit:
		selectCard()
	else:
		var command = activeNode.getCurrentChild().getName()
		if command == "Edit":
			SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
			startEditing(CHARACTER_DECK)
		elif command == "Back":
			if currentDeck != null:
				currentDeck.setActive(false)
				currentDeck = null
			SoundPlayer.playSound(SoundMap.MENU_BACK)
			circlePressed()


func startEditing(ad):
	edit = true
	activeNode.setDimmedHand(true)
	activeDeck = ad
	currentDeck = charDeck if ad == CHARACTER_DECK else mainDeck
	currentDeck.setActive(true)


func selectPressed():
	if edit:
		displayCardHelp = not displayCardHelp
	else:
		SoundPlayer.playSound(SoundMap.MENU_ERROR)


func squarePressed():
	if edit:
		var d = mainDeck if isInMainDeck() else c.getDeck()
		d.sort()
	else:
		SoundPlayer.playSound(SoundMap.MENU_ERROR)


func selectCard():
	var from = mainDeck if isInMainDeck() else c.getDeck()
	var to = c.getDeck() if isInMainDeck() else mainDeck

	selectedCard = from.getCurrent()
	if selectedCard == null:
		return
	if not to.isFull(animators.size()):
		SoundPlayer.playSound(SoundMap.MENU_CHOOSE_CARD)
		var p = from.getPosFor(selectedCard)
		from.removeCurrent()
		animators.append(Animator.new(selectedCard, p, isInMainDeck(), to, to.getLastPos()))
	else:
		selectedCard = null
		SoundPlayer.playSound(SoundMap.MENU_ERROR)
	if from.isEmpty():
		circlePressed()


func switchDeck():
	if not isInMainDeck():
		activeDeck = MAIN_DECK
		setCurrentDeck(mainDeck, charDeck)
	else:
		activeDeck = CHARACTER_DECK
		setCurrentDeck(charDeck, mainDeck)
	currentDeck.updateHandpos(-1)


func isInMainDeck():
	return activeDeck == MAIN_DECK


func setCurrentDeck(activeDeck, passiveDeck):
	currentDeck = activeDeck
	currentDeck.setActive(true)
	passiveDeck.setActive(false)


func draw3D(g):
	drawStandard(g)
	g.startText()
	g.drawMultiString(charName + "'s Deck - " + str(charDeck.getSizeInfo()),
			MenuValues.CHAR_DECK_X - 10, MenuValues.DECK_Y - 20)
	g.drawMultiString("Party Deck - " + str(mainDeck.getSizeInfo()),
			MenuValues.MAIN_DECK_X - 10, MenuValues.DECK_Y - 20)
	g.finishText()
	match activeDeck:
		NO_DECK:
			g.setImageColor(1, 1, 1, 1)
			charDeck.drawDeck(g)
			mainDeck.drawDeck(g)
		CHARACTER_DECK:
			charDeck.drawDeck(g, currentDeck.getCurrent())
			g.setImageColor(1, 1, 1, .5)
			mainDeck.drawDeck(g)
		MAIN_DECK:
			mainDeck.drawDeck(g, currentDeck.getCurrent())
			g.setImageColor(1, 1, 1, .5)
			charDeck.drawDeck(g)
	var x: int = MenuValues.MENU_TEXT_X
	g.drawString(activeNode.getName(), x, 54)
	activeNode.drawChildren(g)
	var card = null
	if displayCardHelp:
		if currentDeck != null:
			card = currentDeck.getCurrent()
		drawCardInfo(g, card, -29)
		if card == null:
			StatusPage.drawTop(g, self.c)
	charScrollBar.draw(g, charDeck.getCurrentLine() - 1, charDeck.getTotalNrOfLines())
	mainScrollBar.draw(g, mainDeck.getCurrentLine() - 1, mainDeck.getTotalNrOfLines())

	for a in animators:
		a.draw(g)
	match activeDeck:
		NO_DECK:
			drawTopHelp(g)
		_:
			drawDeckHelp(g)


func drawTopHelp(g):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 740
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons)

	var n = activeNode.getCurrentChild().getName()
	g.drawString("Exit", helpx, helpy)
	g.drawString(n, helpx + step, helpy)
	g.drawString("Back", helpx + 2 * step, helpy)


func drawDeckHelp(g):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 740
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], helpxicons + 2 * step, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 3 * step, helpyicons)

	g.drawString("Exit", helpx, helpy)
	g.drawString("Select", helpx + step, helpy)
	g.drawString("Sort", helpx + 2 * step, helpy)
	g.drawString("Back", helpx + 3 * step, helpy)

	helpx += 4 * step + 50
	helpxicons += 4 * step + 40
	step += 70

	g.drawString("Change deck", helpx, helpy)
	g.drawString("Change character", helpx + step, helpy)

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L2R2], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons + step, helpyicons)


static func drawCardInfo(g, c, y):
	g.drawImage(cardHelp, 4, y + 35)
	if c != null:
		var x: int = 150
		c.drawCard(g, 10, y + 25, 1.0)
		var info = c.getInfo()
		var name = info[0]
		y += 75
		g.drawStringSetSize("Name: " + str(name), x, y, 26)

		g.setFontSize(MenuValues.MENU_FONT_SIZE)
		g.startText()
		y += 32
		g.drawMultiString(info[1], x + 20, y)
		y += 27
		g.drawMultiString(info[2], x + 20, y)
		y += 27
		g.drawMultiString(info[3], x + 20, y)
		y += 32
		g.finishText()

		info = c.getVeryShortInfo()
		g.drawStringSetSize("Effect: " + str(info[0]) + str(info[1]), x, y, 20)


class Animator extends RefCounted:
	const VECLOCITY = 2.0
	static var DEFAULT_PARTY_DECK_END = Vector3f.new(200, 600, 0)
	static var DEFAULT_MAIN_DECK_END = Vector3f.new(700, 600, 0)
	var card = null
	var start = null
	var end = null
	var currentTime: float = 0.0
	var endTime: float = 0.0
	var percent: float = 0.0
	var startToEnd = null
	var currentPos = null
	var to = null

	func _init(card = null, p = null, inMainDeck = null, to = null, target = null) -> void:
		self.card = card
		self.to = to
		start = p
		if target != null:
			end = target
		else:
			end = DEFAULT_PARTY_DECK_END if inMainDeck else DEFAULT_MAIN_DECK_END
		startToEnd = end.subtract(start)

		endTime = startToEnd.length() / VECLOCITY
		currentPos = start.add(startToEnd.mult(0.0))

	func isDone():
		return percent >= 1

	func addCardToDeck():
		to.addCard(card)

	func update(elapsedTime):
		currentTime += elapsedTime

		percent = currentTime / endTime
		currentPos = start.add(startToEnd.mult(percent))

	func draw(g):
		g.setColor(1, 1, 1, 1 - percent)
		card.drawCard(g, int(currentPos.x), int(currentPos.y))
		g.setColor(1)
