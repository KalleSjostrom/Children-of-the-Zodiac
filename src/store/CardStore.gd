class_name CardStore
extends AbstractStore
## Port of store.CardStore: a card store in a village where the player can
## buy cards and merge five equal cards into one of a higher level.

static var testInfo = null
var storeName = ""
var currentDeck = null # Deck
var menuMode: int = 0
var stocked: int = 0
var scrollBar = null # menu.ScrollBar (MenuScrollBar)
var tutorial = null # Tutorial
var mergeScrollBar = null # MenuScrollBar

static var MERGE: int = BASE
static var CONFIRM_MERGE: int = BASE + 1

var map: Dictionary = {} # sorting value -> CardStoreCardInfo


## Initiates the card store with the information in the given map.
func init(info, lab = null, hinders = null):
	if info == null:
		info = testInfo
	super.init(info)
	initStore()
	storeName = info.get("storeName")
	loadFromInfo(info)
	activeNode = MenuNode.new(null, "Card Shop")
	menuMode = MENU

	fillRoot()
	setStoreImages(CARD_STORE)
	setMenuImagesUsed(0x000000ff)

	logicLoading = false


## Moves to the previous place in the store (exits from the root menu).
func circlePressed():
	if menuMode == MENU:
		exit(Values.SWITCH_BACK)
	else:
		if menuMode == CONFIRM_BUY:
			menuMode = BUY
		elif menuMode == CONFIRM_MERGE:
			menuMode = MERGE
		else:
			menuMode = MENU
			setMenuImagesUsed(0x000000ff)
	setDialogVisibility(false)


## Takes the appropriate action for a directional button press depending on
## the state of the store.
func dirPressed(dir):
	if menuMode == MENU:
		dirMenuPressed(activeNode, dir)
	elif menuMode == BUY:
		dirBuyPressed(dir)
	elif menuMode == CONFIRM_BUY:
		dirMenuPressed(confirmNode, dir)
	elif menuMode == CONFIRM_MERGE:
		dirMenuPressed(confirmNode, dir)
	elif menuMode == MERGE:
		dirMergePressed(confirmNode, dir)


## Translates the given direction into a move in the current deck.
func dirBuyPressed(dir):
	if dir == Values.UP:
		currentDeck.up()
	elif dir == Values.RIGHT:
		currentDeck.right()
	elif dir == Values.DOWN:
		currentDeck.down()
	elif dir == Values.LEFT:
		currentDeck.left()
	updateNumbers()


func dirMergePressed(p_confirmNode, dir):
	if dir == Values.UP:
		currentDeck.up()
	elif dir == Values.RIGHT:
		currentDeck.right()
	elif dir == Values.DOWN:
		currentDeck.down()
	elif dir == Values.LEFT:
		currentDeck.left()


## Updates the number of owned cards equal to the currently selected card.
func updateNumbers():
	var inCharDeck: int = 0
	if currentDeck != null:
		var c = currentDeck.getCurrent()
		for i in Load.getCharacters().size():
			var cd = Load.getCharacters()[i].getDeck()
			inCharDeck += cd.search(c)
		var d = Load.getPartyItems().getMainDeck()
		stocked = d.search(c) + inCharDeck


## Called when the player presses the cross button.
func crossPressed():
	var n
	var choice: String
	if menuMode == MENU:
		n = activeNode.getCurrentChild()
		choice = n.getName()
		if choice == "Tutorial - Cards":
			tutorial = Tutorial.new("cardstore", true)
			if tutorial.increment():
				menuMode = TUTORIAL
				tutorial.setActive(true)
		elif choice == "Buy cards":
			fillCards()
		elif choice == "Merge cards":
			fillMerge()
		elif choice == "Exit":
			exit(Values.SWITCH_BACK)
			return
		updateNumbers()
	elif menuMode == MERGE:
		var currentCard = currentDeck.getCurrent()
		if currentCard != null:
			var sortValues = currentCard.getSortingValue()
			var info: CardStoreCardInfo = map.get(sortValues)
			menuMode = CONFIRM_MERGE
			if info.enabled:
				positiveConfirm("Merge cards", POSITIVE_MERGE)
			else:
				negativeConfirm(CANT_MERGE)
	elif menuMode == TUTORIAL:
		if tutorial.crossedPressed():
			menuMode = MENU
	elif menuMode == BUY:
		var currentCard = currentDeck.getCurrent()
		if currentCard != null:
			checkBuy(currentCard.getPrice())
			menuMode = CONFIRM_BUY
	elif menuMode == CONFIRM_BUY:
		n = confirmNode.getCurrentChild()
		choice = n.getName()
		if choice == "Buy card":
			var c = currentDeck.getCurrent().copyCard()
			var price: int = c.getPrice()
			var p = Load.getPartyItems()
			p.addGold(-price)
			p.getMainDeck().addCard(c)
			var removedCard = currentDeck.removeCurrent()
			Database.addStatus(removedCard.getDatabaseName(), 0)
			if currentDeck.getCurrentDeckSize() == 0:
				circlePressed()
				updateNumbers()
				return
			updateNumbers()
		menuMode = BUY
	elif menuMode == CONFIRM_MERGE:
		n = confirmNode.getCurrentChild()
		choice = n.getName()
		if choice == "Merge cards":
			var c = currentDeck.getCurrent()
			var p = Load.getPartyItems()
			p.getMainDeck().removeCard(c, 5)
			c = Card.createCard(ClassRegistry.getClassName(c), c.getLevel() + 1, c.isAll())
			p.getMainDeck().addCard(c)
			setMergeDeck(p.getMainDeck(), currentDeck.getMenuCursor())
		menuMode = MERGE


func fillMerge():
	var d = Load.getPartyItems().getMainDeck()
	setMergeDeck(d, 0)
	makeNewDialog("The following cards can be merged.", "")
	setDialogVisibility(true)


## Fills the store with the cards of this store.
func fillCards():
	var d = CardStoreFactory.getCardsFor(storeName)
	setDeck(d)
	if d.getTotalNrOfLines() > 2:
		scrollBar = MenuScrollBar.new(710, 430, 300)


## Sets the given deck as the current deck.
func setDeck(d):
	currentDeck = d
	currentDeck.reset()
	currentDeck.setActive(true)
	currentDeck.setShownLines(2)
	currentDeck.setLineLength(7)
	currentDeck.setNrOfShownCards(currentDeck.getCurrentDeckSize())
	currentDeck.setHandPosRelative(0, -19)
	currentDeck.setCoordinates(8, 430)
	currentDeck.setXDistance(98)
	currentDeck.setYDistance(150)
	setMenuImagesUsed(0x0000ffff)
	menuMode = BUY


## Creates the deck of cards that can be merged from the given deck.
func setMergeDeck(d, cursor):
	map.clear()
	for c in d.iterator():
		var s = c.getSortingValue()
		var ci: CardStoreCardInfo = map.get(s)
		if ci == null:
			map[s] = CardStoreCardInfo.new(c, 1, c.canBeMerged() and c.getLevel() < 3)
		else:
			ci.quantity += 1
			map[s] = ci
	var deck = Deck.new(null)

	for ci in map.values():
		if ci.isEnabled():
			deck.addCard(ci.c)

	deck.sort()
	deck.setActive(true)
	deck.setShownLines(2)
	deck.setLineLength(7)
	deck.setNrOfShownCards(deck.getCurrentDeckSize())
	deck.setHandPosRelative(0, -19)
	deck.setCoordinates(8, 230)
	deck.setXDistance(98)
	deck.setYDistance(150)
	currentDeck = deck
	setMenuImagesUsed(0x00000fff)
	menuMode = MERGE
	mergeScrollBar = MenuScrollBar.new(700, 350, 330)
	for i in cursor:
		currentDeck.right(false)


## Fills the root menu.
func fillRoot():
	var n = activeNode
	n.insertChild("Buy cards")
	n.insertChild("Merge cards")
	n.insertChild("Tutorial - Cards")
	n.insertChild("Exit")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


func fillPositiveConfirm(n):
	n.insertChild("Buy card")


## Draws the card store.
##
## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): each part is
## shown by its node where it was drawn, or drawn with its --legacy flag
## (AbstractPage.draw_list, draw_title, drawMerge's and drawBuy's parts,
## drawInfo, the confirm boxes; the card info and the tutorial are phase 3's
## nodes).
func draw3D(g3D):
	var g = g3D
	AbstractPage.draw_list(g, activeNode, false, true, false, false, false)
	var title = activeNode.getName() if menuMode == MENU else activeNode.getCurrentChild().getName()
	AbstractPage.draw_title(g, title)
	var c
	if menuMode == MENU:
		pass
	elif menuMode == MERGE:
		drawMerge(g)
	elif menuMode == CONFIRM_MERGE:
		drawMerge(g)
		c = currentDeck.getCurrent()
		drawConfirmDialog(g, c.getName(), 0)
	elif menuMode == CONFIRM_BUY:
		c = currentDeck.getCurrent()
		drawBuy(g, c)
		drawConfirmDialog(g, c.getName(), c.getPrice())
	elif menuMode == BUY:
		c = currentDeck.getCurrent()
		drawBuy(g, c)
	elif menuMode == TUTORIAL:
		tutorial.drawTopLayer(g)


## Bridge (phase 4.2 step B): the pieces (--legacy=menu_frame), the deck,
## its scroll bar and the merge preview (--legacy=deck) are nodes where they
## were drawn (AbstractPage.show_pieces, Deck.show_deck,
## MenuScrollBar.show_bar, _show_merge_preview).
func drawMerge(g):
	if Main.is_legacy("menu_frame"):
		g.drawImage(AbstractPage.images[13], 4, 195)
		g.drawImage(AbstractPage.images[12], 4, 565)
	else:
		var pieces := [g.place_image(AbstractPage.images[13], 4, 195)]
		pieces.append(g.place_image(AbstractPage.images[12], 4, 565))
		AbstractPage.show_pieces(g, pieces)
	var deck: bool = Main.is_legacy("deck")
	if deck:
		currentDeck.drawDeck(g, currentDeck.getCurrent(), map)
	else:
		currentDeck.show_deck(g, currentDeck.getCurrent(), map)
	if currentDeck.getTotalNrOfLines() > currentDeck.getShowLines():
		if deck:
			mergeScrollBar.draw(g, currentDeck.getCurrentLine() - 1, currentDeck.getTotalNrOfLines())
		else:
			mergeScrollBar.show_bar(g, currentDeck.getCurrentLine() - 1, currentDeck.getTotalNrOfLines())
	var c = currentDeck.getCurrent()
	if c != null and c.getLevel() < 3:
		if not deck:
			_show_merge_preview(g, c)
		else:
			var fs: int = g.getFontSize()
			g.setFontSize(40)
			c.drawCard(g, 10, 554, 1.0)
			g.drawString("x 5 merges to", 200, 654)
			c.drawCard(g, 400, 554, 1.0, AbstractCard.NORMAL, c.getLevel() + 1)
			g.setFontSize(fs)

	drawInfo(g)


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the merge
## preview without the drawing (the font size 40 and back, the cards' binds,
## drawString's setColor(color)): the card in a CardView node, "x 5 merges
## to" in a MenuText node, the card at the next level in a second CardView
## (AbstractCard.place_at with the level), each in its slot (Graphics.show_ui).
func _show_merge_preview(g, c) -> void:
	var fs: int = g.getFontSize()
	g.setFontSize(40)
	var mat = g.canvas_material()
	var card = g.show_ui(DeckPage.Animator.CARD_VIEW, Graphics.UI_LAYER)
	var images: Array = c.place_at(g, 10, 554, 1.0)
	if card != null:
		card.show_card(images, [], mat)
	AbstractPage.show_lines(g, [["x 5 merges to", Vector2i(200, 654), g.getFontSize(),
			Graphics.text_color(1.0), Graphics.font_bold(), HORIZONTAL_ALIGNMENT_LEFT]])
	g.setColor(g.color)
	var next = g.show_ui(DeckPage.Animator.CARD_VIEW, Graphics.UI_LAYER)
	images = c.place_at(g, 400, 554, 1.0, AbstractCard.NORMAL, c.getLevel() + 1)
	if next != null:
		next.show_card(images, [], mat)
	g.setFontSize(fs)


func drawMergedCard(g):
	var c = currentDeck.getCurrent()
	DeckPage.drawCardInfo(g, c, 530)


## Bridge (phase 4.2 step B): the deck and its scroll bar (--legacy=deck)
## are nodes where they were drawn (Deck.show_deck, MenuScrollBar.show_bar).
func drawBuy(g, c):
	c = currentDeck.getCurrent()
	if c != null:
		var gold: int = Load.getPartyItems().getGold()
		var deck: bool = Main.is_legacy("deck")
		if deck:
			currentDeck.drawDeck(g, gold, true, currentDeck.getCurrent(), null)
		else:
			currentDeck.show_deck(g, gold, true, currentDeck.getCurrent(), null)
		DeckPage.drawCardInfo(g, currentDeck.getCurrent(), -23)
		drawInfo(g)
		if currentDeck.getTotalNrOfLines() > 2:
			if deck:
				scrollBar.draw(g, currentDeck.getCurrentLine() - 1, currentDeck.getTotalNrOfLines())
			else:
				scrollBar.show_bar(g, currentDeck.getCurrentLine() - 1, currentDeck.getTotalNrOfLines())


## Draws the number of stocked cards equal to the selected card, its price
## and the party's gold. Bridge (phase 4.2 step B): with --legacy=menu_frame
## off, a MenuInfo node shows the three lines (StartPage.show_info).
func drawInfo(g):
	var x: int = MenuValues.MENU_TEXT_X
	if not Main.is_legacy("menu_frame"):
		var cur = currentDeck.getCurrent()
		StartPage.show_info(g, PackedStringArray(["Stocked: " + str(stocked),
				"Price: " + str(0 if cur == null else cur.getPrice()),
				"Gold: " + str(Load.getPartyItems().getGold())]))
		return

	g.drawString("Stocked: " + str(stocked), x, 648)
	var c = currentDeck.getCurrent()
	var price: int = 0 if c == null else c.getPrice()
	g.drawString("Price: " + str(price), x, 689)
	g.drawString("Gold: " + str(Load.getPartyItems().getGold()), x, 730)


static func setTestMap(info):
	testInfo = info


## Java: store.CardStore.CardInfo (renamed: shadowed a global class).
class CardStoreCardInfo extends RefCounted:
	var c = null
	var quantity: int = 0
	var enabled: bool = false

	func _init(card = null, quantity = null, enabled = null) -> void:
		c = card
		if quantity != null:
			self.quantity = quantity
		if enabled != null:
			self.enabled = enabled

	func getIndex():
		return quantity

	func isEnabled():
		return enabled and quantity >= 5
