class_name GLDeck
extends AbstractDeck
## Port of battle.equipment.GLDeck: the deck the player draws cards from in
## battle: a pile of cards, the shown slots, the save slot and the weapon.
##
## Port notes (merged overloads):
## * update() and update(Character c): call update(c) to resynchronize this
##   deck with the character's deck, update() for the per-frame update.
## * drawTopCard(): without arguments it is the Java private drawTopCard()
##   (takes the top card from the pile); with (g, deck) it is
##   AbstractDeck.drawTopCard(g, deck).
## * hasRoomFor(t) and hasRoomFor(t, undecided).

const SAVED_CARD = -1
var shownCards: Array = []
var deckCards: Array = []
var allCards: Array = []
var deck = null
var savedCard = null
var weaponDeck = null
var xsOffset: int = 0
var saveDeckPos: float = 0.0
var change: bool = false
var needUpdate: bool = true


func _init() -> void:
	super(3)
	shownCards = []
	deckCards = []
	allCards = []
	selectedCard = 0
	setAxis(Y)
	setLimit(false)
	setMovementSpeed(false)
	instantHide()


func initDraw(g: Graphics):
	super.initDraw(g)
	weaponDeck.initDraw(g)
	initCards(g)


func update(progress = null):
	if progress != null:
		_updateFromCharacter(progress)
		return
	super.update()
	weaponDeck.update()


## Wraps the given deck into this 3D deck.
func setDeck(d, handSize):
	deck = d
	nrOfSlots = handSize
	saveDeckPos = AbstractDeck.xs[nrOfSlots - 1] + 0.25

	if not change:
		for i in deck.getCurrentDeckSize():
			var card := GLCard.new()
			card.setCard(deck.getCard(i))
			deckCards.append(card)
			allCards.append(card)


func setWeaponDeck(deck):
	weaponDeck = deck


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	weaponDeck.draw(g)
	super.draw(g)
	drawDeck(g, shownCards, BattleValues.CARD_SELECTED_OFFSET)
	drawSavedCard(g)
	drawTopCard(g, deckCards)
	var c = null
	if shownCards.size() > 0:
		if selectedCard != -1:
			c = shownCards[selectedCard].getCard()
		elif savedCard != null:
			c = savedCard.getCard()

		var xRight: float = 1.080
		var xLeft: float = 0.51
		var yBottom: float = -0.145 + getYtrans()
		var yTop: float = 0.146 + getYtrans()

		g.drawGradient(
				Vector3f.ZERO, CreatureRow.BACK_ALPHA_TOP, CreatureRow.BACK_ALPHA_BOTTOM,
				xRight, xLeft, yBottom, yTop, true, true)

		if c != null:
			var x: int = 760
			g.startText(-1, 0, 34)
			var y: int = J.round(660 + 200 * (-getYtrans() - 0.65))
			var y2: int = y + 40
			g.drawMultiString(c.getName(), x + 2, y + 2)
			g.setTextColorAndApply(1, 1)
			g.drawMultiString(c.getName(), x, y)
			g.finishText()

			g.startText(-1, 0, 50)
			var size: int = deckCards.size()
			var textx: int = 70
			if size > 0:
				if size >= 10 and size <= 19:
					textx -= 5
				g.drawMultiCenteredText(str(deckCards.size()), y + 62, textx + 2)
				g.setTextColorAndApply(1, 1)
				g.drawMultiCenteredText(str(deckCards.size()), y + 60, textx)
			g.finishText()
			textx = 47
			var texty: int = y + 10

			g.startText(-1, 0, 24)
			var info: Array = c.getVeryShortInfo()
			g.drawMultiString(info[0], x + 2, y2 + 2)
			g.drawMultiString(info[1], x + 2, y2 + 27)
			g.drawMultiString("Deck", textx + 2, texty + 2)
			g.setTextColorAndApply(1, 1)
			g.drawMultiString(info[0], x, y2)
			g.drawMultiString(info[1], x, y2 + 25)
			g.drawMultiString("Deck", textx, texty)
			g.finishText()


func initCards(g):
	for i in allCards.size():
		allCards[i].initDraw(g)


func drawSavedCard(g):
	if savedCard != null:
		if selectedCard == -1:
			savedCard.draw(g, getYtrans() + BattleValues.CARD_SELECTED_OFFSET)
			drawHand(g, nrOfSlots, 0.05)
		else:
			savedCard.draw(g, getYtrans())


func getShowCards():
	return shownCards


func getY():
	return BattleValues.DECK_HEIGHT_SLOTS


## Empties the visible slots and puts all the cards in the deck.
func empty():
	for i in shownCards.size():
		shownCards[i].reset()
	deckCards.append_array(shownCards)
	shownCards.clear()
	weaponDeck.empty()


## Fills the slots with the nrOfSlots first cards in the deck.
func fill():
	var i: int = 0
	while i < nrOfSlots and deckCards.size() > 0:
		shownCards.append(J.removeAt(deckCards, 0))
		shownCards[i].setTarget(AbstractDeck.xs[i])
		i += 1


## Puts the selected card in the weapon and draws a new card from the deck.
## Returns true if the round is done.
func chooseSelectedCard():
	if not weaponDeck.isFull() and selIsInRange():
		var c = getSelectedCard()
		if c != null:
			SoundPlayer.playSound(SoundMap.BATTLE_CHOOSE_CARD)
			updateCards(weaponDeck.receive(c))
		else:
			SoundPlayer.playSound(SoundMap.ERROR)
		if selectedCard == -1:
			selectedCard = 0
		return false
	elif selectedCard == -1 and savedCard != null:
		allCards.append(savedCard)
		var c = savedCard
		savedCard = null
		updateCards(weaponDeck.receive(c))
		selectLeft()
		return false
	return weaponDeck.isFull()


func updateCards(enabled):
	for i in shownCards.size():
		updateCard(shownCards[i], enabled)
	if savedCard != null:
		updateCard(savedCard, enabled)


func updateCard(card, enabled):
	if enabled != null:
		var c = card.getCard()
		var enable: bool = false
		if c.getType() == AbstractCard.NEUTRAL:
			enable = (enabled[Slot.MAGIC] + enabled[Slot.SUPPORT]) > 0
		else:
			enable = enabled[card.getType()] != 0
		card.setEnabled(enable)


## Gets (and removes) the selected card if it is enabled, shifts the cards
## and draws a new card. Returns null if the card is not enabled.
func getSelectedCard():
	if selIsInRange():
		var c = shownCards[selectedCard]
		if c.isEnabled():
			J.removeAt(shownCards, selectedCard)
			for i in selectedCard:
				shownCards[i].setTarget(AbstractDeck.xs[i + 1 + xsOffset])
			drawNewCard()
			return c
	return null


## Removes and returns the selected card (or the saved card).
func discardCard():
	if selIsInRange():
		var c = J.removeAt(shownCards, selectedCard)
		for i in selectedCard:
			shownCards[i].setTarget(AbstractDeck.xs[i + 1 + xsOffset])
		drawNewCard()
		if selectedCard == -1:
			selectedCard = 0
		return c
	elif selectedCard == -1 and savedCard != null:
		allCards.append(savedCard)
		var c = savedCard
		savedCard = null
		selectLeft()
		return c
	push_warning("GLDeck: discard null")
	return null


## Puts the current card in the save slot (discarding any saved card).
func saveCard():
	if selectedCard != -1:
		if savedCard != null:
			allCards.append(savedCard)
		savedCard = discardCard()
		if savedCard != null:
			if shownCards.size() == 0:
				selectedCard = SAVED_CARD
			var found: bool = false
			var i: int = 0
			while i < allCards.size() and not found:
				if allCards[i] == savedCard:
					J.removeAt(allCards, i)
					found = true
				i += 1
			savedCard.setTarget(saveDeckPos)


func selIsInRange():
	return selectedCard < shownCards.size() and selectedCard >= 0


## Draws a new card and puts it to the right of the deck.
func drawNewCard():
	var card = drawTopCard()
	if card != null:
		updateCard(card, weaponDeck.getFreeSlots())
		shownCards.insert(0, card)
		shownCards[0].setTarget(AbstractDeck.xs[0])
		return
	elif selectedCard >= 0:
		selectedCard -= 1
	xsOffset += 1


## Removes the cards in the slots, shuffles all the cards and deals.
func shuffleAndDeal():
	shownCards.clear()
	deckCards.clear()
	deckCards.append_array(shuffleCards(allCards))
	xsOffset = 0
	fill()


func drawTopCard(g = null, deck = null):
	if g != null:
		super.drawTopCard(g, deck)
		return null
	if deckCards.size() == 0:
		return null
	return J.removeAt(deckCards, 0)


func selectRight():
	if selectedCard == SAVED_CARD:
		SoundPlayer.playSound(SoundMap.BATTLE_ERROR)
		return
	else:
		selectedCard += 1
		if selectedCard == shownCards.size():
			if savedCard == null:
				selectedCard -= 1
				SoundPlayer.playSound(SoundMap.BATTLE_ERROR)
				return
			else:
				selectedCard = SAVED_CARD
	SoundPlayer.playSound(SoundMap.BATTLE_NAVIAGATE)


func selectLeft():
	if selectedCard == SAVED_CARD:
		selectedCard = shownCards.size() - 1
	else:
		selectedCard -= 1
		if selectedCard < 0:
			SoundPlayer.playSound(SoundMap.BATTLE_ERROR)
			selectedCard += 1
			return
	SoundPlayer.playSound(SoundMap.BATTLE_NAVIAGATE)


func hide(time = null):
	super.hide()
	weaponDeck.hide()


func show():
	super.show()
	weaponDeck.show()


func toggle():
	if visible:
		hide()
	else:
		show()


## Flips the weapon mode. Returns the new mode, or -1 if unavailable.
func flipMode():
	var pointToParty: int = weaponDeck.switchSide()
	updateCards(weaponDeck.getFreeSlots())
	return pointToParty


func getMode():
	return weaponDeck.getMode()


## Finishes the round: returns the cards of the weapon and hides the deck.
func finish():
	weaponDeck.setToAttackMode()
	hide()
	return weaponDeck.getCards()


func initNewRound():
	weaponDeck.empty()
	weaponDeck.setToAttackMode()
	show()
	updateCards(weaponDeck.getFreeSlots())


## Shuffles the given list in place and returns it.
func shuffleCards(deck):
	for i in deck.size():
		deck[i].reset()
	var random := JRandom.new()
	var length: int = deck.size()
	if length >= 2:
		for i in 300:
			var a: int = random.nextInt(length)
			var b: int = random.nextInt(length)
			var c = deck[a]
			deck[a] = deck[b]
			deck[b] = c
	return deck


func isDefenseMode():
	return weaponDeck.getMode() == GLWeapon.DEFENSE_MODE


func isAttackMode():
	return weaponDeck.getMode() == GLWeapon.OFFENSE_MODE


func isFull():
	return weaponDeck.isFull()


func needsToShuffle():
	return deckCards.size() == 0


## Java update(character.Character c): updates this GLDeck to match the
## character's normal deck exactly.
func _updateFromCharacter(c) -> void:
	if savedCard != null:
		allCards.append(savedCard)
	nrOfSlots = Character.HAND_SIZE
	var size: int = deckCards.size() + shownCards.size()
	deckCards.append_array(shownCards)
	shownCards.clear()
	if size != deckCards.size():
		push_error("Size is not the same for deck cards, exiting12")
		GameCore.exitGame()
	if savedCard != null:
		deckCards.append(savedCard)

	var availableCards: Array = deckCards
	var newCards: Array = getNewCards()
	size = deckCards.size()
	removeFromAllCards()
	if size != deckCards.size():
		push_error("Size is not the same for deck cards, exiting1")
		GameCore.exitGame()
	allCards.append_array(newCards)

	var nrAvailable: int = availableCards.size()
	var cardsLeftInDeck: Array = getCardsLeftInDeck(availableCards)
	var nrAvailableLeft: int = cardsLeftInDeck.size()

	if newCards.size() > 0:
		shuffleCards(newCards)
		for i in nrAvailable - nrAvailableLeft:
			cardsLeftInDeck.append(newCards[i])
	deckCards = cardsLeftInDeck

	if savedCard != null:
		var savedCardStillInDeck: bool = false
		var j: int = 0
		while j < deckCards.size() and not savedCardStillInDeck:
			if savedCard == deckCards[j]:
				savedCardStillInDeck = true
				J.removeAt(deckCards, j)
				var found: bool = false
				var i: int = 0
				while i < allCards.size() and not found:
					if allCards[i] == savedCard:
						J.removeAt(allCards, i)
						found = true
					i += 1
			j += 1
		if not savedCardStillInDeck:
			# The saved card was not left in the deck: it has been replaced.
			savedCard = null
	shuffleCards(deckCards)
	for i in allCards.size():
		allCards[i].reset()
	xsOffset = 0
	fill()
	change = true


func getCardsLeftInDeck(cards):
	var cardsLeft: Array = []
	for i in cards.size():
		var found: bool = false
		var glCard = cards[i]
		var card = glCard.getCard()
		var j: int = 0
		while j < deck.getCurrentDeckSize() and not found:
			found = deck.getCard(j) == card
			if found:
				cardsLeft.append(glCard)
			j += 1
	return cardsLeft


func getNewCards():
	var newCards: Array = []
	for i in deck.getCurrentDeckSize():
		var found: bool = false
		var card = deck.getCard(i)
		var j: int = 0
		while j < allCards.size() and not found:
			var glCard = allCards[j]
			found = glCard.getCard() == card
			j += 1
		if not found:
			var newCard := GLCard.new()
			newCard.setCard(card)
			newCards.append(newCard)
	return newCards


func removeFromAllCards():
	var removeIndex: Array = []
	for i in allCards.size():
		var found: bool = false
		var glCard = allCards[i]
		var card = glCard.getCard()
		var j: int = 0
		while j < deck.getCurrentDeckSize() and not found:
			found = deck.getCard(j) == card
			j += 1
		if not found:
			removeIndex.append(i)
	for i in removeIndex.size():
		J.removeAt(allCards, removeIndex[i] - i)


func setNeedUpdate(needsUpdate):
	needUpdate = needsUpdate


func getNeedUpdate():
	return needUpdate


## Updates the position of the cards in the hand and in the weapon.
func updatePos():
	for i in shownCards.size():
		shownCards[i].update()
	weaponDeck.updatePos()
	if savedCard != null:
		savedCard.update()


func setSelected(i):
	selectedCard = i


func hasRoomFor(t, undecided = null):
	if undecided != null and undecided:
		if t == Card.SUPPORT:
			weaponDeck.switchSide()
			var a: bool = hasRoomFor(t)
			weaponDeck.switchSide()
			return a
	var nr: int
	var s: Array = weaponDeck.getFreeSlots()
	if t == Card.NEUTRAL:
		nr = s[Card.MAGIC] + s[Card.SUPPORT]
	else:
		nr = s[t]
	return nr > 0


func getSaveCard():
	return savedCard
